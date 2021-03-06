function [z, x, y, t, xi, yi, ti] = movie(this, cal)
% function [z, x, y, t] = movie(this, cal)
% 
% evaluates the patch at appropriate points.
% Range of z should be from -1 (black) to 1 (white).
% Returns the coordinates used in mesh format.
if ~exist('cal', 'var')
	cal = Calibration();
end

[x, y, t, xi, yi, ti] = sampling(this, this, cal);

%try evaluating the patch at pixel centers:

z = evaluate(this, x, y, t);
