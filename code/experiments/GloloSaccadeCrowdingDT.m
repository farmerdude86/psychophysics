function e = GloloSaccadeCrowdingGB(varargin)
    e = Experiment(varargin{:});
    
    its = Genitive();

    e.trials.base = GloloSaccadeTrial...
        ( 'extra', struct...
            ( 'minSpace', 12 ...
            , 'distractorRelativeContrast', 1 ...
            , 'r', 12 ...
            , 'dt', .15 ...
            , 'l', 1.125 ...
            , 'color', [0.5;0.5;0.5] / sqrt(2) ...
            , 'tf', 20/3 ...
            , 'globalVScalar', 1 ...
            , 'wavelengthScalar', 0.15 ...
            , 'widthScalar', 0.1 ...
            , 'nTargets', 5 ...
            ) ... 
        , 'fixation', FilledDisk ...
            ( 'radius', 0.1 ...
            , 'loc', [0 0] ...
            ) ...
        , 'fixationTime', Inf ...
        , 'fixationLatency', 1.0 ...
        , 'fixationStartWindow', 2 ...
        , 'fixationSettle', 0.4 ...
        , 'fixationWindow', 3 ...
        , 'targetOnset', 0 ...
        , 'usePrecue', 1 ...
        , 'precueOnset', 0 ...
        , 'precueDuration', 0.1 ...
        , 'precue', CauchyDrawer ...
            ( 'source', CircularSmoothCauchyMotion ...
                ('radius', 8 ...
                , 'phase', 0 ...
                , 'angle', 90 ...            
                , 'omega', 0 ...
                , 'color', [0.125 0.125 0.125]' ...
                , 'wavelength', 1 ...
                , 'width', 1 ...
                , 'order', 4 ...
                )...
            )...
        , 'target', CauchyDrawer ...
            ( 'source', CircularSmoothCauchyMotion ...
                ('radius', 8 ...
                , 'phase', 0 ...
                , 'angle', 90 ...            
                , 'omega', 0 ...
                , 'color', [0.125 0.125 0.125]' ...
                , 'wavelength', 1 ...
                , 'width', 1 ...
                , 'order', 4 ...
                )...
            ) ...
        , 'useTrackingTarget', 1 ...
        , 'trackingTarget', CauchySpritePlayer ...
            ('process', CircularCauchyMotion ...
                ( 'radius', 8 ...
                , 'dt', .15 ...
                , 'dphase', [1.5/8] ...
                , 'x', 0 ...
                , 'y', 0 ...
                , 't', .15 ...
                , 'n', [Inf] ...
                , 'color', [0.5 0.5 0.5]' ...
                , 'velocity', 10 ... %velocity of peak spatial frequency
                , 'wavelength', 0.75 ...
                , 'width', 1 ...
                , 'duration', [0.1 0.1] ...
                , 'order', 4 ...
                , 'phase', [0 0] ...
                , 'angle', [90 90] ...
                ) ...
            ) ...
        , 'targetBlank', Inf ...
        , 'cueTime', Inf ... %assuming 200ms latency, this places most saccades right in between for max. effect
        , 'minLatency', 0.1 ... %too short a latency counts as jumping the gun
        , 'maxLatency', 0.5 ...
        , 'maxTransitTime', 0.15 ...
        , 'targetWindow', 8 ...
        , 'rewardSize', 100 ...
        , 'rewardTargetBonus', 0 ...
        , 'rewardLengthBonus', 0 ...
        , 'errorTimeout', 0 ...
        , 'earlySaccadeTimeout', 0.5 ...
        );
    
%%
    %In this section, we build up the array of parameters we will staircase with.
    vars = {};
    
    vars(end+1,:) = {{'extra.r'}, {{10} {20/3} {40/9}}};
    %vars(end+1,:) = {{'extra.r', 'fixationWindow'}, {{10 20/3} {20/3 40/9} {40/9 80/27}}};
    
    %these are multiplied by radius to get global velocity, centereed
    %around 10 deg/dec at 10 radius... that is to say this is merely
    %radians/sec around the circle.
    %%vars(end+1,:) = {{'extra.globalVScalar'}, {2/1 1 1.5}};
    vars(end+1,:) = {{'extra.globalVScalar'}, {.75}};
    
    %temporal frequency is chosen here...
    %%vars(end+1,:) = {{'extra.tf'}, {15 10 20/3}};
    vars(end+1,:) = {{'extra.tf'}, {10}};

    %and wavelength is set to the RADIUS multiplied by this (note
    %this is independent of dt or dx)
    %%vars(end+1,:) = {{'extra.wavelengthScalar'}, {2/30 .1 .15}};
    vars(end+1,:) = {{'extra.wavelengthScalar'}, {.1125}};
    
    %dt changes independently of it all. but it is linked to the stimulus
    %duration.
    vars(end+1,:) = {{'extra.dt'}, {0.10}};
    %%vars(end+1,:) = {'extra.dt', {0.10}};
    
    %expand all the values to be used here.
    parameters = cat(2, vars{:,1});
    indices = fullfact(cellfun('prodofsize', vars(:,2)));

    product = cellfun(@(row)cellfun(@(x,y)x(y), vars(:,2)', num2cell(row)), num2cell(indices, 2), 'UniformOutput', 0);
    product = cellfun(@(row)cat(2, row{:}), product, 'UniformOutput', 0);

    %now create staircases for each...
    parameters{end+1} = 'extra.nTargets';
    for i = 1:numel(product)
        product{i}{end+1} = DiscreteStaircase ...
            ( 'valueSet', [1:30], 'currentIndex', 1 ...
            , 'Nup', 1, 'Ndown', 1 ...
            , 'criterion', @criterion ...
            );
    end
    
    function crowded = criterion(trial, result)
        %gloloSaccadeTrial returns result.success = 1 only if cued AND subject
        %tracked successfuly;
        %0 if cued and saccade failed;
        %else 0.
	%Return 0 in any case if not an opposing trial.
        
        crowded = 0;
        e = trial.getExtra();
        if result.success == 1 && e.localDirection == -e.globalDirection;
            crowded = -1
        elseif result.success == 0 && e.localDirection == -e.globalDirection;
            crowded = 1
        else
            crowded = 0
        end
    end
    
    %now add'em all
    e.trials.add(parameters, product);
%%

    %the target window for saccades
    e.trials.add('targetWindow', @(b)b.extra.r(1)/4 + b.fixationWindow/2);

    %The durations are 2/3 of the dt, at the same global speed
    e.trials.add('trackingTarget.process.duration', @(b)b.extra.dt * 2/3);

    %The target appears on the screen somewhere (but we don't know where
    %the distracctor is yet)
    e.trials.add('target.source.phase(1)', UniformDistribution('lower', 0, 'upper', 2*pi));
    
    %the target onset comes at a somewhat unpredictable time.
    e.trials.add('targetOnset', ExponentialDistribution('offset', 0.3, 'tau', 0.5, 'max', 1.0));
    
    %the cue time comes on unpredictably after the target onset.
    e.trials.add('cueTime', ExponentialDistribution('offset', 0.2, 'tau', 0.7, 'max', 1.0));

    %But on some of trials the monkey is rewarded for just fixating.
    %Not for humans though.
    %e.trials.add('fixationTime', GammaDistribution('offset', 0.7, 'shape', 2, 'scale', 0.8));

    %The precue, if there is one, comes 300 ms before the target onset.
    e.trials.add('precueOnset', @(b)b.targetOnset - 0.3);
    
    %The target tracking time is also variable.
    e.trials.add('targetFixationTime', ExponentialDistribution('offset', 0.3, 'tau', 0.4));
    
    %procedurally set up the global appearance of the stimulus
    e.trials.add([], @appearance);
    function b = appearance(b)
        %This function procedurally sets up the global appearance.
        extra = b.extra;

        trackingProcess = b.trackingTarget.process;
        trackingProcess.setRadius(extra.r);
        trackingProcess.setDt(extra.dt);
        trackingProcess.setT(extra.dt);
        trackingProcess.setDphase(extra.dt .* extra.globalVScalar .* sign(extra.globalDirection));
        
        %the target moves the same as the first stimulus.
        targetSource = b.target.source;
        ph = targetSource.property__(its.phase(1));
        targetSource.setRadius(extra.r(1));
        targetSource.setOmega(extra.globalVScalar(1) .* sign(extra.globalDirection));
        targetSource.setAngle(ph * 180/pi + 90);
        
        %local appearance
        wl = extra.r .* extra.wavelengthScalar;
        v = wl .* extra.tf;
        ph = ph + trackingProcess.getT() .* targetSource.getOmega() + 2*pi*(0:extra.nTargets-1)/extra.nTargets;
        
        if extra.localDirection ~= 0
            %the wheel phase is aligned to the target phase, when the wheel
            %appears. The wheel has spokes.
            trackingProcess.setVelocity(v .* sign(extra.localDirection));
            col = repmat(extra.color, 1, extra.nTargets);
            col(:, 2:end) = col(:, 2:end) .* extra.distractorRelativeContrast;
        else
            ph = reshape(repmat(ph, 2, 1), 1, []);
            trackingProcess.setVelocity(wl .* extra.tf * repmat([-1 1], 1, extra.nTargets));
            col = repmat(extra.color, 1, 2*extra.nTargets) / sqrt(2);
            col(:, 3:end) = col(:, 3:end) .* extra.distractorRelativeContrast;
        end

        trackingProcess.setPhase(ph);
        trackingProcess.setAngle(mod(ph*180/pi + 90, 360));

        trackingProcess.setWavelength(wl);
        trackingProcess.setWidth(extra.r .* extra.widthScalar);
        trackingProcess.setColor(col);

        %the precue is appears unmoving in the location of the original
        %target.
        precueSource = b.precue.source;
        precueSource.setRadius(targetSource.getRadius());
        precueSource.setPhase(targetSource.getPhase());
        precueSource.setAngle(targetSource.getAngle());

        %Make sure that after the changeover to the smooth target, the target
        %stll has the same (mean) contrast and wavelength.
        targetSource = b.target.source;
        targetSource.setColor(extra.color .* trackingProcess.property__(its.duration(1)) ./ trackingProcess.property__(its.dt(1)));
        targetSource.setWavelength(trackingProcess.property__(its.wavelength(:,1)));
        targetSource.setWidth(trackingProcess.property__(its.width(1)));
        
        precueSource = b.precue.source;
        precueSource.setColor(extra.color);
        precueSource.setWavelength(targetSource.getWavelength());
        precueSource.setWidth(targetSource.getWidth());
    end

    e.trials.interTrialInterval = 0.5;
    
%    e.trials.fullFactorial = 1;
%    e.trials.reps = 30;
    e.trials.blockSize = 175;
    e.trials.numBlocks = 5;
    e.trials.requireSuccess = 0;
    e.trials.startTrial = MessageTrial('message', @()sprintf('Move eyes to follow target spot when cued.\nPress space to begin.\n%d blocks in experiment', e.trials.blocksLeft()));
    e.trials.endBlockTrial = MessageTrial('message', @()sprintf('Press space to continue.\n%d blocks remain', e.trials.blocksLeft()));

    %begin with an eye calibration and again every three hundred trials...
    %
    e.trials.blockTrial = EyeCalibrationMessageTrial...
        ( 'minCalibrationInterval', 0 ...
        , 'base.absoluteWindow', Inf ...
        , 'base.minLatency', 0.075 ...
        , 'base.maxLatency', 0.300 ...
        , 'base.fixDuration', 0.8 ...
        , 'base.fixWindow', 4 ...
        , 'base.rewardDuration', 10 ...
        , 'base.settleTime', 0.4 ...
        , 'base.targetRadius', 0.2 ...
        , 'base.plotOutcome', 0 ...
        , 'base.onset', 0 ...
        , 'maxStderr', 0.3 ...
        , 'minN', 10 ...
        , 'maxN', 50 ...
        , 'interTrialInterval', 0.5 ...
        );
    
    e.trials.endTrial = MessageTrial('message', sprintf('All done!\nPress space to save and exit.\nThanks!'));
end
