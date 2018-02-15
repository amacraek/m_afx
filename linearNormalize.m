function output = linearNormalize(input, varargin)
% linearNormalize is designed to normalize linearly-scaled signals. By 
%   default, it will normalize the signal to [-1, +1]. You can specify a
%   different level if you want. It will normalize all channels by the same
%   value, which is the maximum peak amplitude between channels. This
%   preserves the relative volumes between channels. 
%
% Required arguments:
%   input       the audio input, with size = [samples, channels].
%
% Optional arguments
%    level      the magnitude to normalize the signal to (v > 0). Default
%               value is 1.
%
% Output: 
%   normalized signal matrix with the same size as input. 
%
% Example usage:
%   output = linearNormalize(input, 255)
% Interpretation:
%       Returns the input signal, normalized to [-255, 255]. 
%
% github.com/amacraek/m_fx/
% Alex MacRae-Korobkov 2018
    
    %% parsing inputs
    p = inputParser;
    addRequired(p, 'input');
    addOptional(p, 'level', 1, @(x) (x>0));
    parse(p, input, varargin{:});
    q = p.Results;

    %% set up variables 
    max_amplitude = max(abs(q.input(:)));
    [samples, channels] = size(q.input);
    output = zeros(samples, channels);

    %% normalize signal
    for sample = 1:samples
       output(sample, :) = ...
           (q.input(sample,:) ./ max_amplitude) .* q.level;
    end
end