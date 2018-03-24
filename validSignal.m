function valid = validSignal(signal)
% VALIDSIGNAL checks if an inputted signal is in a valid form.
%   It makes sure that there are more samples than channels and warns if
%   not, and throws an error if the signal is not double. 

    [samples, channels] = size(signal);
    
    % warnings
    if channels > samples
        warning('signal:signalSizeWarning', ...
           '''signal'' should have more samples (%u) than channels (%u).', ...
            samples, channels);
    end
    % errors
    if ~isa(signal, 'double')
        error('signal:FormatError', ...
              '''signal'' must be double, not %s.', ...
              class(signal)); 
    else
        valid = true;
    end
    
end

%% :+) 
%              _                 _____________________________________
% ____  ______/ \-.   _  _______/                                    /_____
% __ .-/     (    o\_// _______/   By Alex MacRae-Korobkov, 2018.   /______ 
% ___ |  ___  \_/\---'________/     github.com/amacraek/m_afx/     /_______  
%     |_||  |_||             /____________________________________/