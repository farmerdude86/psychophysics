function e = GloLoCued(varargin)
    %An experiment that is aimed to measure the flash lag in glolo motion
    %stimuli as a function of hte local velocity. Use both temporal
    %feequency and spatial frequency as ways of varying local velocity.

    e = Experiment...
        ( 'params', struct...
            ( 'skipFrames', 1  ...
            , 'priority', 9 ...
            , 'hideCursor', 0 ...
            , 'doTrackerSetup', 0 ...
            , 'input', struct ...
                ( 'keyboard', KeyboardInput() ...
                , 'knob', PowermateInput() ...
                ) ...
            )...
        , varargin{:} ...
        );
    
    e.trials.base = GloLoCuedTrial...
        ( 'barOnset', 0.6750 ...                         %4.5 flashes
        , 'barCueDuration', 1/30 ...
        , 'barCueDelay', 0.5 ...
        , 'barFlashColor', [1 1 1] ...
        , 'barFlashDuration', 1/30 ...
        , 'barLength', 2 ...
        , 'barWidth', 0.15 ...
        , 'barPhase', 0 ...                         %randomized below
        , 'barRadius', 10 ...
        , 'fixationPointSize', 0.1 ...
        , 'motion', CircularCauchyMotion ...
            ( 'radius', 8 ...
            , 'dt', 0.15 ...
            , 'dphase', 1.5/8 ... %dx = 1.5
            , 'x', 0 ...
            , 'y', 0 ...
            , 't', 0.15 ...
            , 'n', 7 ...
            , 'color', [0.5 0.5 0.5]' ...
            , 'velocity', 10 ... %velocity of peak spatial frequency
            , 'wavelength', 0.75 ...
            , 'width', 0.5 ...
            , 'duration', 0.1 ...
            , 'order', 4 ...
            ) ...
        );
        
    e.trials.add('barCueDelay', ExponentialDistribution('offset', 0.3, 'tau', 0.15));
    
    %tell the randomizer how to randomize the trial each time.
    
    %The range of temporal offsets:
    %we will measure at just one temporal offset, after 4.5 appearances
    
    %The bar origin is random around the circle and orientation follows
    %motion phase, angle, bar onset, bar phase
    e.trials.add({'motion.phase', 'motion.angle'}, @(b)num2cell(rand()*2*pi * [1 180/pi] + [0 90]));
    
    e.trials.add('motion.dphase', [-e.trials.base.motion.dphase, e.trials.base.motion.dphase]);
    
    %bar phase is sampled in a range...
    e.trials.add('extra.barStepsAhead', (-2:4) / 3);
    %that is centered on the location of the bar.
    e.trials.add('barPhase', @(b)b.extra.barStepsAhead*b.motion.dphase + b.motion.phase + (b.barOnset-b.motion.t(1))*b.motion.dphase ./ b.motion.dt);
            
    %the message to show between blocks.
    e.trials.blockTrial = MessageTrial('message', @()sprintf('Press knob to continue. %d blocks remain', e.trials.blocksLeft()));
    
    %vary local velocity in two ways. These are the values from
    %glolosaccadeCharlie whcih is 12 degrees at 15 degrees/sec, scaled down
    %to 8 degrees at 10 deg/sec.
        e.trials.add...
        ( {'extra.wavelengthScaling', 'motion.velocity', 'motion.color', 'motion.wavelength'} ...
        , ...
            { {1   -15    [.167   .167  .167 ]'    1.125} ...
            , {1   -5     [.5     .5    .5   ]'    0.375} ...
            , {1    5     [.5     .5    .5   ]'    0.375} ...
            , {1    15    [.167   .167  .167 ]' 1.125} ...
            , {0   -15    [.25    .25   .25  ]' 0.75} ...
            , {0.5 -10    [.25    .25   .25  ]' 0.75} ...
            , {0   -5     [.25    .25   .25  ]' 0.75} ...
            , {0    0     [.25    .25   .25  ]' 0.75} ...
            , {0    5     [.25    .25   .25  ]' 0.75} ...
            , {0.5  10    [.25    .25   .25  ]' 0.75} ...
            , {0    15    [.25    .25   .25  ]' 0.75} ...
            } ...
        );
    
    e.trials.fullFactorial = 1;
    e.trials.reps = 8;
    e.trials.blockSize = 88;
