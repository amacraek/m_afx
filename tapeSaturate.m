function output = tapeSaturate(signal, knob, varargin)
% TAPESATURATE uses a soft curve to saturate an input signal, similar to
%	the distortion caused by loud signals on magnetic tape. The inputted
%	signal is first normalized then saturated, so the outputted signal will
%	be much louder than the input. You can adjust this with the optional
%	'gain' argument. 
%
% Required arguments:
%   signal      the input signal with size = [samples, channels].
%   knob        like a knob on a guitar pedal, this value determines the
%               extent of the saturation effect. Minimum value is 0,
%               maximum value is 10. You can change the max by editing line
%               35 in the function's code. 
%
% Optional arguments:
%   gain        a value, between zero and one, to multiply the outputted
%               signal by, in order to reduce volume. default value is 1.
% 
% Example usage: 
%   output = TAPESATURATE(signal, 5, 0.5);
% Interpretation:
%   saturates (distorts) the signal at a strength of 5/10. The outputted
%   signal is then reduced to 0.5x the normalized amplitude. 
%
% Dependencies:
%   linearNormalize.m, validSignal.m 
%
% github.com/amacraek/m_afx/
% Alex MacRae-Korobkov 2018


    %% parsing inputs 
    p = inputParser;                    %      ___________________________
                                        %     |  ____                     |
                                        %     | |    |  knob's max value  |
                                        %    _| |_   |   is default 10.   |          
                                        %    \   /   |  change the value  |
    addRequired(p, 'signal', @validSignal);%  \_/    |  to 11 so you can  |
    addRequired(p, 'knob', @(x) (x>=0)&&(x <= 10));% | 'turn it to 11' :) |
    addOptional(p, 'gain', 1, @(x) (x>=0)&&(x<=1));% |____________________|  
    parse(p, signal, knob, varargin{:});
    q = p.Results;
    
    %% setting up variables 
    [samples, channels] = size(q.signal);
    output = zeros(samples, channels);
    lin_knob = 10^((-q.knob) / 7.5); % the knob is actually logarithmic 
    normSignal = linearNormalize(q.signal);
    
    %% apply saturation 
    for channel = 1:channels  % for each channel separately 
        for sample = 1:samples
            current_sample = normSignal(sample, channel);
            % basic idea is to make quieter signals louder by transforming
            % the amplitudes with a curved function. check out the graph
            % for y=tanh(x), and picture y as the output signal and x as
            % the input signal
            % i tried a piecewise log growth function for this first, but
            % then decided to use a tanh function to transform the values
            % because it is easy to make steeper (for more saturation) and
            % it maintains the sign of the inputted value without having to
            % use piecewise functions. also its curvature is great for
            % emulating tape saturation (which follows a logarithmic decay
            % pattern due to the physical properties of magnetic tape)
            output(sample, channel) = q.gain*tanh(current_sample/lin_knob);
        end
    end
end

%% acknowledgements
% https://www.soundonsound.com/techniques/analogue-warmth
% desmos graphing calculator was helpful for trying out different functions
%       to emulate tape saturation. 

%% :+) 
%              _                 _____________________________________
% ____  ______/ \-.   _  _______/                                    /_____
% __ .-/     (    o\_// _______/   By Alex MacRae-Korobkov, 2018.   /______ 
% ___ |  ___  \_/\---'________/     github.com/amacraek/m_afx/     /_______  
%     |_||  |_||             /____________________________________/