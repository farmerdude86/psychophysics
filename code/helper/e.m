function varargout = e(thing, varargin)

if isnumeric(thing)
    varargout{1} = thing;    
elseif isstruct(thing) && isfield(thing, 'e')
    [varargout{1:nargout}] = thing.e(varargin{:});
elseif isa(thing, 'function_handle')
    [varargout{1:nargout}] = thing(varargin{:});
else
    varargout{1} = thing;
end