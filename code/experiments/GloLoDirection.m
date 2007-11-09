function e = GloLoDirection(varargin)
    params = namedargs...
        ( 'dummy',      1  ...
        , 'skipFrames', 1  ...
        , 'requireCalibration', 0 ...
        , 'priority', 9 ...
        , 'hideCursor', 0 ...
        , 'diagnostics', 0 ...
        , 'input', struct ...
            ( 'keyboard', KeyboardInput() ...
            , 'knob', PowermateInput() ...
            ) ...
        );
    params = namedargs(params, varargin{:});
    
    e = Experiment...
        ( 'continuing', 0 ...
        , 'trials', GloLoDirectionTrialGenerator...
            ( 'base', GloLoDirectionTrial...
                ( 'cueOnset', 1 ...
                , 'knobTurnThreshold', 3 ...
                , 'fixationPointSize', 0.1 ...
                , 'cueSize', 0.1 ...
                , 'cueLocation', [0 0] ... %must specify this manually.
                , 'cueDuration', 0.1 ...
                , 'patch', CauchyPatch ...
                    ( 'size', [1/2 0.5 0.075] ...
                    , 'velocity', 7.5 ... 
                    ) ...
                , 'motion', CircularMotionProcess...
                    ( 'radius', 10 ...
                    , 'n', 2 ...
                    , 't', 1 ...
                    , 'phase', 0 ...
                    , 'dt', 0.10 ...
                    , 'dphase', 0.75 / 10 ... %dx = 0.75...
                    , 'angle', 90 ...
                    , 'color', [0.25;0.25;0.25] ...
                    )...
                )...
            , 'blocksize', 90 ...
            , 'factors', struct...
                ( 'nTargets', [1 2 3 4 5] ...
                , 'cueOnsetAsynchrony' , [-0.1 : 0.05 : 0.3] ... %one flashes before, one after, space by half a flash
                , 'minOnset', 0.5 ...
                , 'onsetRate', 2 ...
                , 'minGapAtCue', 2*pi/6 ...
                , 'targetGlobal', [1 -1] ...
                , 'targetLocal', [1 -1] ...
                , 'cueRadius', 0.2 ...
                , 'replicate', [1] ...
                ) ...
            ) ...
        , params);
    
    e.run();
end