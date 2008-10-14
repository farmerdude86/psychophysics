function e = ConcentricDirection(varargin)

    params = namedargs(localExperimentParams(), varargin{:});
    
    e = Experiment();
    e.trials.base = ConcentricTrial();
    e.trials.base.motion.process = CircularCauchyMotion ...
            ( 'radius', 10 ...
            , 'dt', 0.15 ...
            , 'dphase', 0.75/10 ...
            , 'x', 0 ...
            , 'y', 0 ...
            , 'color', [0.5 0.5 0.5]' ...
            , 'velocity', -5 ... %velocity of peak spatial frequency
            , 'wavelength', 0.5 ...
            , 'width', 0.5 ...
            , 'duration', 0.1 ...
            , 'order', 4 ...
            );
        
    %randomize global and local direction....
    e.trials.add('motion.process.dphase', [-1 1] * e.trials.base.motion.process.dphase);
    e.trials.add('motion.process.velocity', [-1 1] * e.trials.base.motion.process.velocity);

    %pick a number of targets, and spread them around the circle
    e.trials.add('extra.n', 6:2:20);
    e.trials.add('motion.process.phase', @(b) mod(rand()*2*pi + (0:b.extra.n-1)/b.extra.n*2*pi, 2*pi));
    e.trials.add('motion.process.radius', [10 12 15]);
    
    %say, 8 samples for each N, after folding directions?
    e.trials.reps = 4;
    e.trials.blocksize = 80;
end