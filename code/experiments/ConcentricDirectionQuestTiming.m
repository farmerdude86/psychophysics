function e = ConcentricDirectionMixQuest(varargin)

    params = namedargs ...
        ( localExperimentParams() ...
        , 'skipFrames', 1  ...
        , 'priority', 0 ...
        , 'hideCursor', 0 ...
        , 'doTrackerSetup', 1 ...
        , 'inputUsed', {'keyboard', 'eyes', 'knob', 'audioout'} ...
        , 'eyelinkSettings.sample_rate', 250 ...
        , varargin{:});
    
    params.input.audioout.property__('samples.ding', Ding('freq', 880, 'decay', 0.1, 'damping', 0.04));
    params.input.audioout.property__('samples.cue', Chirp('beginfreq', 1000, 'endfreq', 1e-6, 'length', 0.05, 'decay', 0.01, 'release', 0.005, 'sweep', 'exponential'));
    
    e = Experiment('params', params);
   
    e.trials.base = ConcentricTrial...
        ( 'extra', struct...
            ( 'r', 10 ...
            , 'responseWindowLatency', 0.5 ...
            , 'audioCueLatency', [-0.7 -0.3 0.1] ...
            , 'globalVScalar', 0.5 ...
            , 'tf', 10 ...
            , 'wavelengthScalar', .05 ...
            , 'dt', 0.1 ...
            , 'widthScalar', 0.075 ...
            , 'durationScalar', 2/3 ...
            , 'nTargets', 10 ...
            , 'phase', 0 ...
            , 'globalDirection', 1 ...
            , 'localDirection', 1 ...
            , 'color', [0.5;0.5;0.5] / sqrt(2)...
            ) ...
        , 'requireFixation', 1 ...
        , 'feedbackFailedFixation', 1 ...
        , 'fixationStartWindow', 3 ...
        , 'fixationSettle', 0.2 ...
        , 'fixationWindow', 2.8 ...
        , 'motion', CauchySpritePlayer ...
            ( 'process', CircularCauchyMotion ...
                ( 'x', 0 ...
                , 'y', 0 ...
                , 't', 0.15 ...
                , 'n', 6 ...
                , 'color', [0.5 0.5 0.5] ...
                , 'duration', 0.1 ...
                , 'order', 4 ...
                ) ...
            ) ...
        , 'maxResponseLatency', 0.2 ...
        );
    
    e.trials.interTrialInterval = 0.8;
    
    %what worked well in the wheels demo is 0.75 dx, 0.75 wavelength, 0.15
    %dt, 5 velocity at 14 radius! The crowding was 3.1 degrees! Use the
    %same parameters at 10 degrees eccentricity.
    
    %the target and distractor are selected from a grid of stimulus
    %parameters.

%%
    %In this section, we build up the array of parameters we will quest with.
    vars = {};
    
    vars(end+1,:) = {{'extra.r'}, {80/27 10 20/3 40/9}};
    %%vars(end+1,:) = {{'extra.r'}, {80/27}};
    
    %these are multiplied by radius to get global velocity, centereed
    %around 10 deg/dec at 10 radius... that is to say this is merely
    %radians/sec around the circle.
    %%vars(end+1,:) = {{'extra.globalVScalar'}, {.5 .75 1.125}};
    vars(end+1,:) = {{'extra.globalVScalar'}, {.75}};
    
    %temporal frequency is chosen here...
    %%vars(end+1,:) = {{'extra.tf'}, {15 10 20/3}};
    vars(end+1,:) = {{'extra.tf'}, {10}};

    %and wavelength is set to the RADIUS multiplied by this (note
    %this is independent of dt or dx)
    %%vars(end+1,:) = {{'extra.wavelengthScalar'}, {.05 .075 .1125}};
    vars(end+1,:) = {{'extra.wavelengthScalar'}, {.075}};
    
    %dt changes independently of it all, but it is linked to the stimulus
    %duration.
    %%vars(end+1,:) = {{'extra.dt', 'motion.process.n'}, {{2/30 9}, {0.10 6} {0.15 4}}};
    vars(end+1,:) = {{'extra.dt', 'motion.process.n'}, {{0.10 4}}};
    
    %Finally, vary the cue time
    vars(end+1, :) = {{'extra.responseWindowLatency'}, {0.3 0.4 0.5 0.6 0.7}};
    
    %expand all the values to be used here.
    parameters = cat(2, vars{:,1});
    indices = fullfact(cellfun('prodofsize', vars(:,2)));
    product = cellfun(@(row)cellfun(@(x,y)x(y), vars(:,2)', num2cell(row)), num2cell(indices, 2), 'UniformOutput', 0);
    product = cellfun(@(row)cat(2, row{:}), product, 'UniformOutput', 0);

    %now create quests for each stimulus combination...
    parameters{end+1} = 'extra.nTargets';

    for i = 1:numel(product)
        product{i}{end+1} = Quest ...
            ( 'pThreshold', 0.5, 'gamma', 0 ... %yes-no experiment...
            , 'guess', 15, 'range', 40, 'grain', 0.1, 'guessSD', 15 ... %conservative initial guess
            , 'criterion', @criterion, 'restriction', PickNearest('set', 5:40, 'dither', 2) ... %experiment constraints
            );
    end
    
    %now add'em all
    e.trials.add(parameters, product);
%%
    %variable onset
    e.trials.add('motion.process.t', ExponentialDistribution('offset', 0.5, 'max', 1.5, 'tau', 1));        

    %randomize global and local direction....
    e.trials.add('extra.phase', UniformDistribution('lower', 0, 'upper', 2*pi));
    
    %here's where local and global are randomized
    e.trials.add('extra.globalDirection', [1 -1]);
    e.trials.add('extra.localDirection', [1 0 -1]);
    
    e.trials.add('awaitInput', @(b)b.motion.process.t(1) + b.extra.responseWindowLatency);
    e.trials.add('audioCueTimes', @(b)b.awaitInput + b.extra.audioCueLatency);
    
    %we only adjust the QUEST for opposing local and global motion We are
    %trying to find the intensity (nTargets) at whcih the stimulus becomes
    %crowded (local motion dominates.)
    function crowded = criterion(trial, result)
        crowded = 0;
        if result.success == 1
            gd = trial.property__('extra.globalDirection');
            if gd == -trial.property__('extra.localDirection')
                %note the logical reversal; the knob's positive rotation is
                %clockwise and the stimulus' positive rotation is CCW.
                if result.response == gd;
                    crowded = 1;
                elseif result.response == -gd;
                    crowded = -1;
                end
            end
        end
    end
        
    
    %this procedure translates the extra parmeters into lower level values.
    e.trials.add([], @appearance);
    function b = appearance(b)
        extra = b.extra;
        mot = b.motion.process;
        mot.setRadius(extra.r);
        mot.setDt(extra.dt);
        mot.setDphase(extra.dt .* extra.globalVScalar .* extra.globalDirection);
        wl = extra.r * extra.wavelengthScalar;
        mot.setWavelength(wl);
        mot.setWidth(extra.r .* extra.widthScalar);
        mot.setDuration(extra.durationScalar .* extra.dt);
        
        ph = mod(extra.phase + (0:extra.nTargets-1)/extra.nTargets*2*pi, 2*pi);
        %For balance we need to have three kinds of motion: supporting, opposing, and ambiguous.

        if extra.localDirection ~= 0
            mot.setPhase(ph);
            mot.setAngle(mod(ph*180/pi + 90, 360));
            mot.setVelocity(wl .* extra.tf .* extra.localDirection);
            mot.setColor(extra.color);
        else
            %The ambiguous motion is made up of two opposing motions
            %superimposed,
            %so we have to double and elements (and reduce the contrast)
            %for that one.
            ph = reshape(repmat(ph, 2, 1), 1, []);
            mot.setPhase(ph);
            mot.setAngle(mod(ph*180/pi + 90, 360));
            mot.setVelocity(wl .* extra.tf * repmat([-1 1], 1, extra.nTargets));
            mot.setColor(extra.color / sqrt(2));
        end
    end

    %await the input after the stimulus has finished playing.
    e.trials.add('audioCueTimes', @(b) b.awaitInput + [-0.7 -0.3 0.1]);
    
    %say, run 30 trials for each quest, with an estimated threshold value measured in number of
    %targets, somewhere between 5 and 20. This arrives at a threshold
    %estimate very quickly.
    %note that of the global and local combinations, 2 will inform the
    %quest. So 15 reps of the factorial means 30 trials in the quest.
    e.trials.reps = 10; %26 trials per quest...
    e.trials.blockSize = 200;    
    e.trials.fullFactorial = 1;
    e.trials.requireSuccess = 1;
    e.trials.startTrial = MessageTrial('message', @()sprintf('Use knob to indicate direction of rotation.\nPress knob to begin.\n%d blocks in experiment', e.trials.blocksLeft()));
    e.trials.endBlockTrial = MessageTrial('message', @()sprintf('Press knob to continue.\n%d blocks remain', e.trials.blocksLeft()));

    e.trials.blockTrial = EyeCalibrationMessageTrial...
        ( 'minCalibrationInterval', 900 ...
        , 'base.absoluteWindow', Inf ...
        , 'base.minLatency', 0.075 ...
        , 'base.maxLatency', 0.300 ...
        , 'base.fixDuration', 0.8 ...
        , 'base.fixWindow', 4 ...
        , 'base.rewardDuration', 10 ...
        , 'base.settleTime', 0.3 ...
        , 'base.targetRadius', 0.2 ...
        , 'base.plotOutcome', 0 ...
        , 'base.onset', 0 ...
        , 'maxStderr', 0.3 ...
        , 'minN', 10 ...
        , 'maxN', 50 ...
        , 'interTrialInterval', 0.4 ...
        );

    e.trials.endTrial = MessageTrial('message', sprintf('All done!\nPress knob to save and exit.\nThanks!'));
end
