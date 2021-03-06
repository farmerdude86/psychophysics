function joined = join(str, strs)
%joins STRS together with the string STR. Note, using STRCAT this way
%strips whitespace.
    strs = strcat(strs, {str});
    last = strs{end};
    last(end-numel(str)+1:end) = [];
    strs{end} = last;
    joined = strcat(strs{:});
end