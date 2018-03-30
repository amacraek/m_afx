function output = linearNormalize(signal, varargin)
% LINEARNORMALIZE is designed to normalize linearly-scaled signals. By 
%   default, it will normalize the signal to [-1, +1]. You can specify a
%   different level if you want. It will normalize all channels by the same
%   value, which is the maximum peak amplitude between channels. This
%   preserves the relative volumes between channels. 
%
% Required arguments:
%    signal      the audio input, with size = [samples, channels].
%
% Optional arguments
%    level      the magnitude to normalize the signal to (v > 0). Default
%               value is 1.
%
% Output: 
%   normalized signal matrix with the same size as input. 
%
% Example usage:
%   output = LINEARNORMALIZE(signal, 255)
% Interpretation:
%       Returns the input signal, normalized to [-255, 255]. 
%
% Dependencies:
%   validSignal.m 
%
% github.com/amacraek/m_afx/
% Alex MacRae-Korobkov 2018
    
    %% parsing inputs
    p = inputParser;
    addRequired(p, 'signal', @validSignal);
    addOptional(p, 'level', 1, @(x) (x>0));
    parse(p, signal, varargin{:});
    q = p.Results;

    %% set up variables 
    max_amplitude = max(abs(q.signal(:))); % max across all channels
    [samples, channels] = size(q.signal);
    output = zeros(samples, channels); % preallocate!

    %% normalize signal
    for sample = 1:samples
       output(sample, :) = ...
           (q.signal(sample,:) ./ max_amplitude) .* q.level;
    end
end

%% :+) 
%              _                 _____________________________________
% ____  ______/ \-.   _  _______/                                    /_____
% __ .-/     (    o\_// _______/   By Alex MacRae-Korobkov, 2018.   /______ 
% ___ |  ___  \_/\---'________/     github.com/amacraek/m_afx/     /_______  
%     |_||  |_||             /____________________________________/