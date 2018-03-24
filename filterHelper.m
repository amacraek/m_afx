classdef filterHelper
    % FILTERHELPER is a class of static methods used for filtering signals.
    %   Although you don't *need* to construct a new FILTERHELPER object to 
    %   call its methods, I recommend creating an object named 'fh' to save
    %   you a few characters.
    %           e.g.
    %               fh = FILTERHELPER;
    %               output = fh.coefficients([1 0 0 0], 1, signal);
    % References:
    % <a href="matlab:web('http://www2.cs.sfu.ca/~tamaras/filters889/Recursive_Filters.html')">[1]</a> <a href="matlab:web('https://ccrma.stanford.edu/~jos/fp/Difference_Equation_I.html')">[2]</a> <a href="matlab:web('https://en.wikipedia.org/wiki/Impulse_response')">[3]</a> <a href="matlab:web('https://ccrma.stanford.edu/realsimple/DelayVar/Phasing_First_Order_Allpass_Filters.html')">[4]</a> <a href="matlab:web('https://ccrma.stanford.edu/~jos/pasp/Allpass_Two_Combs.html')">[5]</a> 
    
% ****Don't open the comment block above, it contains a very wide line.**** 

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
    
            % parsing inputs
            p = inputParser;
            addRequired(p, 'cForward', @(x) (nnz(x~=0))>0);
            addRequired(p, 'cBackward', @(x) (nnz(x~=0))>0);
            addRequired(p, 'signal', @validSignal);
            parse(p, cForward, cBackward, signal);
            q = p.Results;
            % get the size of the input signal:
            [samples, channels] = size(q.signal);
            
            % pre-allocate memory for the output:
            output = zeros([samples, channels]);
            
            % count how many coefficients we will use to calculate each
            % filtered sample. the first coefficient in the backward
            % coefficient matrix is used to normalize the other
            % coefficients, so the total number of backward coefficients we
            % need to account for is one less than the number of
            % coefficients given. 
            num_forward = length(q.cForward);
            num_backward = length(q.cBackward) - 1;
            
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
            norm_cForward = q.cForward ./ q.cBackward(1);
            norm_cBackward = q.cBackward(2:end) ./ q.cBackward(1);
            
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
                    filtered_sample = filtered_sample   ...
                        + norm_cForward(1 + f_index) .* ...
                        q.signal(sample_index - f_index, :);
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
                        + norm_cBackward(b_index) .*  ... % not b_index + 1
                        output(sample_index - b_index, :);
                end
                output(sample_index, :) = filtered_sample;
            end
        end
        
        function output = allpass1(centre_freq, sampling_freq, signal,  ...
                varargin)
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
% Optional arguments:
%   purpose             Specifies what the allpass filter's purpose is. If
%                       using the allpass for a high/low shelf filter,
%                       small modifications need to be made to the
%                       algorithm. Accepted purposes are 'general',
%                       'lowshelf', and 'highshelf'. Default is 'general'.
%   gain                The gain of the filter, in dB. Required argument 
%                       for lowshelf and highshelf purpose allpass filters.
%                       Default value is 0 dB.
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
            
            % parsing inputs
            p = inputParser;
            addRequired(p, 'centre_freq', @(x) (x<0.5*sampling_freq));
            addRequired(p, 'sampling_freq', @(x) (x~=0));
            addRequired(p, 'signal', @validSignal);
            addOptional(p, 'purpose', 'general', @allpassType);
            addOptional(p, 'gain', 0, @(x) (isnumeric(x)));
            parse(p, centre_freq, sampling_freq, signal, varargin{:});
            q = p.Results;
            
            if (q.gain >= 0)
                % pole is calculated based on value of p_d from [4], where
                % the value of omega_b is 2*pi*cutoff_frequency, and the 
                % value of T is 1/sampling_frequency. the equation given 
                % for p_d can be rearranged so that: 
                %     p_d = 2 / (tan( omega_b * f_s / 2 ) + 1 ) - 1
                pole = 2/(tan(pi * q.centre_freq/q.sampling_freq) + 1) - 1;
            
            % if we're gonna use an allpass filter for cutting frequencies
            % in a shelf filter (see **3 for image representation), i.e. if
            % the gain is negative, then we actually need to flip the phase
            % response of the allpass filter so that when we use it in the
            % shelf it will remove frequencies instead of boost them.
            % look at the bode plots of  e.g. **1 versus e.g. **2, which
            % are at the bottom of this file.
            %
            % Note the difference in the appearance of the bode plots'
            % phase vs. frequency graphs, which is a good summary of the
            % effect of an allpass filter. 
            %
            % Explanation:
            %   **1 is a 'general' allpass function with the pole
            %       calculated as shown *above* for centre = 4410Hz. By
            %       looking at the bode plot, it is clear that if we were
            %       to add this filtered signal to the original, it would
            %       constructively interfere with frequencies before
            %       approx. 10^4 Hz, and destructively interfere
            %       afterwards. Therefore this would be a 'low shelf boost'
            %       filter. 
            %   **2 is a 'lowshelf' allpass with the pole calculated as 
            %       shown *below* for centre = 4410Hz and gain = -2dB.If we
            %       were to *subtract* this filtered signal from the 
            %       original (we would subtract it because the gain is
            %       negative), then this would remove frequencies before
            %       around 4000 Hz. This would be a 'low shelf cut' filter.
            %
            % 
            elseif (q.purpose == 'lowshelf') && (q.gain < 0)
                c = (10^(q.gain/20));
                pole = 2*c/(tan(pi * q.centre_freq/q.sampling_freq) + c)-1;
            elseif (q.purpose == 'highshelf') && (q.gain < 0)
                c = (10^(q.gain/20));
                pole = 2/(c*tan(pi * q.centre_freq/q.sampling_freq) + 1)-1;
            else
                error('allpass purpose %s does not accept a negative gain', ...
                        q.purpose);
            end
            
            % get the size of the input signal:
            [samples, channels] = size(q.signal);
            
            % pre-allocate memory for the output:
            output = zeros([samples, channels]);
            output(1,:) = q.signal(1,:) * pole;
            
            % here we use the difference equation from [5] (equation 3.15),
            % except we flip the signs of the terms because we are using
            % H_d(z) from [4] instead of H(z) from [5]. 
            for sample_index = 2:samples
                output(sample_index,:) =                ...
                    q.signal(sample_index - 1,:)        ...
                    - pole.*q.signal(sample_index,:)    ...
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

            % parsing inputs
            p = inputParser;
            addRequired(p, 'centre_freq', @(x) (x<0.5*sampling_freq));
            addRequired(p, 'sampling_freq', @(x) (x~=0));
            addRequired(p, 'signal', @validSignal);
            parse(p, centre_freq, sampling_freq, signal);
            q = p.Results;
            
        % basic idea is that since an allpass filter will shift the phase
        % of a signal at the centre frequency, and out-of-phase signals
        % have constructive and destructive interference effects when
        % added, if we add the original signal from the phase-shifted
        % signal and then average the result, the interference effects will
        % result in a low-pass filter where higher frequencies than the
        % centre frequency will be made quieter and lower frequencies will
        % be made louder.    
            ap = filterHelper.allpass1(q.centre_freq, q.sampling_freq, ...
                q.signal);
            output = (q.signal + ap) ./ 2;
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

            % parsing inputs
            p = inputParser;
            addRequired(p, 'centre_freq', @(x) (x<0.5*sampling_freq));
            addRequired(p, 'sampling_freq', @(x) (x~=0));
            addRequired(p, 'signal', @validSignal);
            parse(p, centre_freq, sampling_freq, signal);
            q = p.Results;
            
        % basic idea is that since an allpass filter will shift the phase
        % of a signal at the centre frequency, and out-of-phase signals
        % have constructive and destructive interference effects when
        % added, if we subtract the original signal from the phase-shifted
        % signal and then average the result, the interference effects will
        % result in a high-pass filter where higher frequencies than the
        % centre frequency will be made louder and lower frequencies will
        % be made quieter.
        
            ap = filterHelper.allpass1(q.centre_freq, q.sampling_freq,  ...
                q.signal);
            output = (q.signal - ap) ./ 2;
        end
        
        function output = lowshelf1(centre_freq, sampling_freq, gain,   ... 
                signal)
% LOWSHELF1 is a first-order tuneable low shelf filter.
%   It uses a first-order allpass filter's phase shift to alter frequencies
%   below a given centre frequency, and then adds the altered signal to the
%   original as to reduce or enhance frequencies by the specified gain.
%
% Required arguments:
%   centre_freq         the frequency (in Hz) where the phase shift of the 
%                       filter is equal to -90 degrees.
%   sampling_frequency  the sampling frequency (in Hz) of the inputted
%                       signal.
%   gain                the gain of the shelf filter, in dB. Can be
%                       positive or negative.
%   signal              the input signal with size = [samples, channels].
%
% Example usage:
%   output = LOWSHELF1(5000, 44100, -5, signal);
% Interpretation:
%   Returns the input signal after applying a first-order low shelf on the
%       signal at 5000Hz, with a gain of -5 dB (low cut).
%
% See also lowpass1, allpass1.
%
% github.com/amacraek/m_afx/
% Alex MacRae-Korobkov 2018   

            % parse inputs
            p = inputParser;
            addRequired(p, 'centre_freq', @(x) (x<0.5*sampling_freq));
            addRequired(p, 'sampling_freq', @(x) (x~=0));
            addRequired(p, 'gain', @(x) (isnumeric(x)));
            addRequired(p, 'signal', @validSignal);
            parse(p, centre_freq, sampling_freq, gain, signal);
            q = p.Results;
            
            % calculate the allpass signal for the given arguments. note
            % that we use the 'lowshelf' allpass type here, so that the
            % allpass phase will be flipped in the case that we want to cut
            % frequencies in the low shelf. 
            ap = filterHelper.allpass1(q.centre_freq, q.sampling_freq, ...
                q.signal, 'lowshelf', q.gain);
            
            % convert the gain from dB value to a proportional scale. 
            scale = 10^(q.gain/20) - 1;
            
            % to understand the shelf filter, consider a low shelf boost: 
            % this is basically the same as a lowpass, except instead of
            % stopping after adding the phase shifted signal to the 
            % original signal, we add a proportion of this filtered signal
            % to the original, i.e. we add some fraction of this lowpassed 
            % signal to the original. this produces an output with low
            % frequencies enhanced by the specified gain.
            % see the code for  'allpass1' for some more info.
            output = scale .* (q.signal + ap) ./ 2 + q.signal;
            
        end
        
        function output = highshelf1(centre_freq, sampling_freq, gain,  ... 
                signal)
% HIGHSHELF1 is a first-order tuneable high shelf filter.
%   It uses a first-order allpass filter's phase shift to alter frequencies
%   above a given centre frequency, and then adds the altered signal to the
%   original as to reduce or enhance frequencies by the specified gain.
%
% Required arguments:
%   centre_freq         the frequency (in Hz) where the phase shift of the 
%                       filter is equal to -90 degrees.
%   sampling_frequency  the sampling frequency (in Hz) of the inputted
%                       signal.
%   gain                the gain of the shelf filter, in dB. Can be
%                       positive or negative.
%   signal              the input signal with size = [samples, channels].
%
% Example usage:
%   output = HIGHSHELF1(5000, 44100, -5, signal);
% Interpretation:
%   Returns the input signal after applying a first-order high shelf on the
%       signal at 5000Hz, with a gain of -5 dB (high cut).
%
% See also highpass1, allpass1.
%
% github.com/amacraek/m_afx/
% Alex MacRae-Korobkov 2018   

            % parse inputs
            p = inputParser;
            addRequired(p, 'centre_freq', @(x) (x<0.5*sampling_freq));
            addRequired(p, 'sampling_freq', @(x) (x~=0));
            addRequired(p, 'gain', @(x) (isnumeric(x)));
            addRequired(p, 'signal', @validSignal);
            parse(p, centre_freq, sampling_freq, gain, signal);
            q = p.Results;
            
            % calculate the allpass signal for the given arguments. note
            % that we use the 'highshelf' allpass type here, so that the
            % allpass phase will be flipped in the case that we want to cut
            % frequencies in the high shelf. 
            ap = filterHelper.allpass1(q.centre_freq, q.sampling_freq, ...
                q.signal, 'highshelf', q.gain);
            
            % convert the gain from dB value to a proportional scale. 
            scale = 10^(q.gain/20) - 1;
            
            % to understand the shelf filter, consider a high shelf boost: 
            % this is basically the same as a highpass, except instead of
            % stopping after subtracting the phase shifted signal from the 
            % original signal, we add a proportion of this filtered signal
            % to the original, i.e. we add some fraction of this highpassed 
            % signal to the original. this produces an output with high
            % frequencies enhanced by the specified gain.
            % see the code for  'allpass1' for some more info.
            output = scale .* (q.signal - ap) ./ 2 + q.signal;
            
        end
        
    end
end

function valid = allpassType(x)
    
    % list of currently allowed purposes of allpass filter:
    allowedTypes = [string('general'),  ...
                    string('lowshelf'), ...
                    string('highshelf')];
    
    % string that lists the allowed types, so we can display in error msg:
    typeList = join( [join('''' + allowedTypes(1,1:end-1) + ''','),     ...
                      'or ''' + allowedTypes(1,end) + '''.' ] );
    
    if string(class(x))~='string' && string(class(x))~='char'
        error('allPassPurpose:notString', ...
            'Allpass purpose must be format ''string'' or ''char'', not format ''%s''.', class(x));
        
    elseif ~any(allowedTypes == x)
        error('allPassPurpose:invalidPurpose', ...
            'Allpass purpose ''%s'' is not an accepted purpose.\n\nAccepted purposes:\n%s', ...
            x, typeList);       
    else
        valid = true;
    end
end

%% References
% [1] http://www2.cs.sfu.ca/~tamaras/filters889/Recursive_Filters.html 
% [2] https://ccrma.stanford.edu/~jos/fp/Difference_Equation_I.html 
% [3] https://en.wikipedia.org/wiki/Impulse_response 
% [4] https://ccrma.stanford.edu/realsimple/DelayVar/Phasing_First_Order_Allpass_Filters.html  
% [5] https://ccrma.stanford.edu/~jos/pasp/Allpass_Two_Combs.html 

%% e.g.
% **1 http://www.wolframalpha.com/input/?i=transfer+function+(-0.509525449494+%2B+1%2Fz)%2F(1+-+0.509525449494%2Fz)+sampling+period+1%2F44100
% **2 http://www.wolframalpha.com/input/?i=transfer+function+(-1.38794521732+%2B+1%2Fz)%2F(1+-+1.38794521732%2Fz)+sampling+period+1%2F44100
% **3 http://www.bhphotovideo.com/images/EQ-04z.jpg

%% :+) 
%              _                 _____________________________________
% ____  ______/ \-.   _  _______/                                    /_____
% __ .-/     (    o\_// _______/   By Alex MacRae-Korobkov, 2018.   /______ 
% ___ |  ___  \_/\---'________/     github.com/amacraek/m_afx/     /_______  
%     |_||  |_||             /____________________________________/
