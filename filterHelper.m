classdef filterHelper
    % FILTERHELPER is a class of static methods used for filtering signals.
    %                     By Alex MacRae-Korobkov, 2018. 
    %                       github.com/amacraek/m_afx/
    % References:
    % <a href="matlab:web('http://www2.cs.sfu.ca/~tamaras/filters889/Recursive_Filters.html')">[1]</a> <a href="matlab:web('https://ccrma.stanford.edu/~jos/fp/Difference_Equation_I.html')">[2]</a> <a href="matlab:web('https://en.wikipedia.org/wiki/Impulse_response')">[3]</a> <a href="matlab:web('https://ccrma.stanford.edu/realsimple/DelayVar/Phasing_First_Order_Allpass_Filters.html')">[4]</a> <a href="matlab:web('https://ccrma.stanford.edu/~jos/pasp/Allpass_Two_Combs.html')">[5]</a> 

    % Don't open the comment block above, it contains a very wide line. 
    
    methods(Static)
        function output = coefficients(cForward, cBackward, signal)
% COEFFICIENTS is for filtering a signal based on filter coefficients.
%   It is an implementation of the general difference equation for a linear
%   time-invariant (LTI) filter, as described in [1] and [2]. This function
%   can be used for both non-recursive (finite impulse response, or FIR)
%   filters and recursive (infinite impulse response, or IIR) filters. To
%   use an FIR filter, set the cBackward parameter equal to one, or another
%   single value to normalize the filter to.
%
% See filterHelper.m for more details about the algorithm. 
%
% Required arguments:
%   cForward    A vector containing the filter-forward coefficients to use 
%               when filtering the signal. 
%   cBackward   A vector containing the filter-backward coefficients to use
%               when filtering the signal. If you are using an FIR filter,
%               this can be a single value (e.g. 1).
%   signal      The signal to filter, with size = [samples, channels].
%
% Example usage (a):
%   output = filterHelper.COEFFICIENTS([1, .5, .25], 2, signal);
% Interpretation (a):
%   Applies a simple low-pass FIR filter to the signal, which is normalized
%   by the value 2, given by the difference equation:
%       output(n) = (1*signal(n) + 0.5*signal(n-1) + 0.25*signal(n-2)) / 2
%
% Example usage (b):
%   output = filterHelper.COEFFICIENTS([1, .5, .25], [2, .125], signal);
% Interpretation (b):
%   Applies a simple low-pass IIR filter to the signal, which is normalized
%   by the value 2, given by the difference equation:
%       output(n) = ( 1*signal(n) + 0.5*signal(n-1) + 0.25*signal(n-2) ...
%                     - .125*output(n-1)) / 2
%
% For references see filterHelper by clicking below:
% See also filterHelper.
%
% github.com/amacraek/m_afx/
% Alex MacRae-Korobkov 2018
    
    % Here's a rough overview of how this works:
    %
    % The basic idea behind filtering via coefficients is that to 'filter'
    % the signal is to change the value of the individual samples in the
    % signal based on its surrounding values. The difference equation used
    % to calculate the filtered value of the signal is an implementation of
    % this concept:
    %
    %   output(n) = A*input(n) + B*input(n-1) + C*input(n-2) + ...
    %
    % The output signal at sample number 'n' is calculated as the input
    % signal at sample 'n' multiplied by A, added to the input signal at 
    % sample number 'n-1' multiplied by B, etc. This is called
    % 'feed-forward' filtering because it is based on feeding the previous
    % input samples forward to calculate the new sample. It is also called
    % a 'non-recursive' or a 'finite impulse response' filter because the
    % output sample is not calculated recursively (i.e. based on other
    % values of the output sample) and because the impulse response of the
    % filter is limited to the number of coefficients (this is a more 
    % complex topic that has to do with the frequency domain of the filter,
    % the definition of LTI systems, etc, but you can read [3] for more
    % details).
    % 
    % A 'feed-backward' filter takes the output signal and feeds it back
    % into calculating more output samples. This is called 'recursive' or 
    % 'infinite impulse response' because the output sample is defined
    % recursively by other output samples, and the impulse response is not
    % limited to the number of coefficients. A feed-backward filter might
    % have a difference equation as follows:
    %
    %   output(n) = A*input(n) + B*input(n-1) + C*input(n-2) + ...
    %               - C*output(n-1) - D*output(n-2) - ...
    %
    % Where C and D are the feed-backward coefficients. 
    %
    % Okay now let's get into the code:
    
            % get the size of the input signal:
            [samples, channels] = size(signal);
            
            % pre-allocate memory for the output:
            output = zeros([samples, channels]);
            
            % count how many coefficients we will use to calculate each
            % filtered sample. the first coefficient in the backward
            % coefficient matrix is used to normalize the other
            % coefficients, so the total number of backward coefficients we
            % need to account for is one less than the number of
            % coefficients given. 
            num_forward = length(cForward);
            num_backward = length(cBackward) - 1;
            
            % here we normalize the coefficients based on the first
            % feed-backward coefficient. this is because the difference
            % equation is given as:
            %   b(1)*output(n) = f(1)*input(n) + f(2)*input(n-1) ...
            %                    - b(2)*output(n-1) - b(3)*output(n-2) ...
            % where 'b' is backward coefficients and 'f' is forward
            % coefficients. because we want the value of 'output(n)' and
            % not 'b(1)*output(n)', we need to divide both sides by 'b(1)',
            % which is the same as dividing every coefficient on the right
            % side by 'b(1)' beforehand. we only need the backward
            % coefficients starting from the second coefficient after this.
            norm_cForward = cForward ./ cBackward(1);
            norm_cBackward = cBackward(2:end) ./ cBackward(1);
            
            % now we loop through the samples to apply the filter
            for sample_index = 1:samples
                
                % value of filtered sample starts at zero, then we add
                % values based on the difference equation
                filtered_sample = 0;
                
                % f index is used for calculating the feed-forward terms of
                % the difference equation. (f_index + 1) is the index of
                % the coefficient used in the cForward vector, while 
                % (sample_index - f_index) is the index of the sample from
                % the input signal to multiply the coefficient by.
                f_index = 0; 
                
                % this loop will increase the f_index by one, each time
                % adding term as defined in the difference equation. the
                % loop will break if we run out of coefficients (i.e.
                % f_index < num_forward) or if there are not enough samples
                % before the current sample to multiply the coefficient by
                % (i.e. f_index < sample_index).
                while (f_index < num_forward && f_index < sample_index)
                    filtered_sample = filtered_sample ...
                        + norm_cForward(1 + f_index) .* ...
                        signal(sample_index - f_index, :);
                    f_index = f_index + 1;
                end
                
                % b_index is the same as f_index, except it starts at 1
                % because the first backward coefficient was already used. 
                b_index = 1;
                
                % also, the index of the backward coefficient used is given
                % by the value of b_index, and not (1 + b_index). this is
                % because we removed the first backward coefficient when we
                % normalized the coefficients earlier. 
                while (b_index < num_backward && b_index < sample_index)
                    filtered_sample = filtered_sample ...
                        + norm_cBackward(b_index) .* ... % not b_index + 1
                        output(sample_index - b_index, :);
                end
                output(sample_index, :) = filtered_sample;
            end
        end
        
        function output = allpass1(centre_freq, sampling_freq, signal)
% ALLPASS1 is a first-order tuneable all-pass filter.
%   It is based on a dual-comb filter system, as described in [5], where
%   two comb filters work in a feed-forward/feed-backward system with
%   opposite-sign coefficients so that the comb filters' constructive and
%   destructive interference patterns cancel one another out. This way, the
%   output signal's gain is not affected by the filter, but the phase
%   relationship between different frequencies is shifted, with the phase
%   shift equal to 90 degrees (pi/2) at the centre frequency.
%
% See filterHelper.m for more details about the algorithm. 
%
% Required arguments:
%   centre_frequency    the frequency (in Hz) where the phase shift of the 
%                       filter is equal to -90 degrees.
%   sampling_frequency  the sampling frequency (in Hz) of the inputted
%                       signal.
%   signal              the input signal with size = [samples, channels].
%
% Example usage:
%   output = ALLPASS1(5000, 44100, signal);
% Interpretation:
%   Returns the input signal with the phase shifted continuously over the
%       signal, with a phase shift of -90 degrees at 5000Hz. 
%
% For references see filterHelper by clicking below:
% See also filterHelper.
%
% github.com/amacraek/m_afx/
% Alex MacRae-Korobkov 2018
            
            % pole is calculated based on value of p_d from [4], where the
            % value of omega_b is 2*pi*cutoff_frequency, and the value of T
            % is 1/sampling_frequency. the equation given for p_d can be
            % rearranged so that p_d = 2 / (tan( omega_b * f_s / 2 )+1) -1
            pole = 2 / (tan(pi * centre_freq/sampling_freq) + 1) - 1;
            
            % get the size of the input signal:
            [samples, channels] = size(signal);
            
            % pre-allocate memory for the output:
            output = zeros([samples, channels]);
            output(1,:) = signal(1,:) * pole;
            
            % by [5]: 
            for sample_index = 2:samples
                output(sample_index,:) = ...
                    signal(sample_index - 1,:) ...
                    - pole.*signal(sample_index,:) ...
                    + pole.*output(sample_index - 1,:);
            end
            
        end
        
        function output = lowpass1(centre_freq, sampling_freq, signal)
% LOWPASS1 is a first-order tuneable lowpass filter.
%   It uses a first-order allpass filter's phase shift to reduce
%   frequencies above a centre frequency.
%
% Required arguments:
%   centre_freq         the frequency (in Hz) where the phase shift of the 
%                       filter is equal to -90 degrees, i.e. the cutoff
%                       frequency of the filter. 
%   sampling_frequency  the sampling frequency (in Hz) of the inputted
%                       signal.
%   signal              the input signal with size = [samples, channels].
%
% Example usage:
%   output = LOWPASS1(5000, 44100, signal);
% Interpretation:
%   Returns the input signal after applying a first-order lowpass on the
%       signal at 5000Hz.
%
% See also allpass1.
%
% github.com/amacraek/m_afx/
% Alex MacRae-Korobkov 2018

        % basic idea is that since an allpass filter will shift the phase
        % of a signal at the centre frequency, and out-of-phase signals
        % have constructive and destructive interference effects when
        % added, if we add the original signal from the phase-shifted
        % signal and then average the result, the interference effects will
        % result in a low-pass filter where higher frequencies than the
        % centre frequency will be made quieter and lower frequencies will
        % be made louder.    
            ap = filterHelper.allpass1(centre_freq, sampling_freq, signal);
            output = (signal + ap) ./ 2;
        end
        
        function output = highpass1(centre_freq, sampling_freq, signal)
% HIGHPASS1 is a first-order tuneable highpass filter.
%   It uses a first-order allpass filter's phase shift to reduce
%   frequencies below a centre frequency.
%
% Required arguments:
%   centre_freq         the frequency (in Hz) where the phase shift of the 
%                       filter is equal to -90 degrees, i.e. the cutoff
%                       frequency of the filter. 
%   sampling_frequency  the sampling frequency (in Hz) of the inputted
%                       signal.
%   signal              the input signal with size = [samples, channels].
%
% Example usage:
%   output = HIGHPASS1(5000, 44100, signal);
% Interpretation:
%   Returns the input signal after applying a first-order highpass on the
%       signal at 5000Hz.
%
% See also allpass1.
%
% github.com/amacraek/m_afx/
% Alex MacRae-Korobkov 2018   

        % basic idea is that since an allpass filter will shift the phase
        % of a signal at the centre frequency, and out-of-phase signals
        % have constructive and destructive interference effects when
        % added, if we subtract the original signal from the phase-shifted
        % signal and then average the result, the interference effects will
        % result in a high-pass filter where higher frequencies than the
        % centre frequency will be made louder and lower frequencies will
        % be made quieter.
        
            ap = filterHelper.allpass1(centre_freq, sampling_freq, signal);
            output = (signal - ap) ./ 2;
        end
    end
end

%% References
% [1] http://www2.cs.sfu.ca/~tamaras/filters889/Recursive_Filters.html 
% [2] https://ccrma.stanford.edu/~jos/fp/Difference_Equation_I.html 
% [3] https://en.wikipedia.org/wiki/Impulse_response 
% [4] https://ccrma.stanford.edu/realsimple/DelayVar/Phasing_First_Order_Allpass_Filters.html  
% [5] https://ccrma.stanford.edu/~jos/pasp/Allpass_Two_Combs.html 
