function this = OutsideTrigger(bounds_, range_, offset_, fn_)
%An object that fires a trigger when x and y are outside the bounds
%given by a function
if nargin == 3
    set_ = 1;
else
    set_ = 0;
end

log_ = [];

this = final(@check, @draw, @set, @unset, @setLog, @getFn);

    function check(s)
        if set_ && all(~isnan([s.x, s.y])) && ~inRect(...
                bounds_() + range_ .* [-1 -1 1 1] + [offset_, offset_],...
                s.x, s.y)
            log_('TRIGGER %s %s', func2str(fn_), struct2str(s));
            fn_(s); %call function when eye is inside
        end
    end

    function set(bounds, range, offset, fn)
        range_ = range;
        offset_ = offset;
        fn_ = fn;
        bounds_ = bounds;
        set_ = 1;
    end

    function unset()
        set_ = 0;
    end

    function draw(window, toPixels)
        if set_
            Screen('FrameRect', window, [255 0 0],...
                toPixels(bounds_() + range_ .*[-1 -1 1 1] + [offset_, offset_]));
        end
    end

    function setLog(log)
        log_ = log;
    end

    function fn = getFn()
        fn = fn_;
    end
end