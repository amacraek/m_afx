function output = reverb(signal, sampling_freq, wet_dry, varargin)
% REVERB is a feedback delay network (FDN) reverberation filter. 
%   It uses an FDN with four delay lines to simulate acoustic
%   reverberation. The algorithm copies the input signal to four channels 
%   that are delayed by different numbers of samples, performs a few 
%   transformations to each channel, then feeds them all back into the 
%   beginning. This creates a time-delayed cascade of the signal that 
%   sounds like the reverberation (or 'echo') of a large hall, for example. 
%   To reduce 'metallic' feedback, the algorithm attenuates (reduces the
%   intensity of) higher frequencies through a series of lowpass filters at
%   different steps of processing. 
%
% Required arguments:
%   signal          the audio input, with size = [samples, 2]. Stereo.
%   sampling_freq   sampling frequency in Hz.
%   wet_dry         ratio of wet to dry signal, 0<=x<=1. i.e:
%                           (amount of reverb) / (amount of original)
%
% Optional name-value pairs:
%   'gain'          gain of the feedback signal, 0<x<=1 (default 1).
%   'delayLines'    vector of delay lengths, in samples. Must be sized
%                   [1,4]. Should be prime numbers. Default values are
%                   [887, 1279, 2089, 3167]
%   'outDecays'     decay amount of the signal after the decay line, but
%                   before the tonal correction. Must be sized [4,1].
%                   Default values are [.8; .8; .8; .8].
%   'inDecays'      decay amount before the decay line. Must be sized
%                   [1,4]. Default values are [1, 1, 1, 1].
%   'decay_lo       the time, in seconds, for frequencies at 0 Hz to decay
%                   by 60 dB. Fooling with this can be glitchy :) Default
%                   value is 1.5.
%   'decay_hi'      the time, in seconds, for frequencies at half of 
%                   sampling freq to decay by 60 dB. Fooling with this can 
%                   be glitchy :) Default value is 0.7.
%   'post_lp_cut'   the cutoff frequency for the lowpass filter on the wet
%                   (reverberated) signal before it is added back into the
%                   original. Default is 10000 Hz.
%   'pre_lp_cut'    the cutoff frequency for the lowpass filter before the
%                   reverb is generated. Default is 13000
%
% Example usage:
%   output = REVERB(signal, 44100, 0.7, 'gain', 0.9)
% Interpretation:
%       Returns a signal consisting of 30% input signal and 70%
%       reverberated signal. Alters the feedback gain to be 0.9 instead of
%       1.
%
% Dependencies:
%   filterHelper.m, validSignal.m
%
% github.com/amacraek/m_afx/
% Alex MacRae-Korobkov 2018
    
    %% default values
    % here, we choose the delay lengths to be primes, suggested in [2].
    % this way we don't get resonant harmonics, which are caused by delay
    % lines that share a common multiple. this would come through as a
    % 'ringing' tone in the reverberation, because the frequency that is
    % accentuated by the common multiple would be accentuated by two
    % different delay lines, so it would be louder than others.
    % For more choices, see [3].
    delaylines = [887, 1279, 2089, 3167]; 
    
    % out decay -> how much to decay the signal after the delay line
    % in decay -> how much to decay the signal before the delay line
    outDecays = [.8; .8; .8; .8];
    inDecays = [1, 1, 1, 1];
     
    % time for low/high frequencies to decay by 60 dB, in seconds. 
    decay_lo = 1.5;
    decay_hi = 0.7;
    
    % we'll be using this later to filter the reverb signal.
    % See filterHelper.m if you don't know what this is :+)
    fh = filterHelper;
    
    %% parsing inputs
    p = inputParser;
    addRequired(p, 'signal', @validSignal);
    addRequired(p, 'sampling_freq', @(x) (x~=0));
    addRequired(p, 'wet_dry', @(x) (0<=x && x<=1));
    addParameter(p, 'gain', 1, @(x) (x>0) && (x<=1));
    addParameter(p, 'delaylines', delaylines, @(x) (length(x)==4));
    addParameter(p, 'outDecays', outDecays, @(x) (size(x)==[4,1]));
    addParameter(p, 'inDecays', inDecays, @(x) (size(x)==[1,4]));
    addParameter(p, 'decay_lo', decay_lo, @(x) (x>0));
    addParameter(p, 'decay_hi', decay_hi, @(x) (x>0));
    addParameter(p, 'post_lp_cut', 10000, @(x) (x<0.5*sampling_freq));
    addParameter(p, 'pre_lp_cut', 12000, @(x) (x<0.5*sampling_freq));
    parse(p, signal, sampling_freq, wet_dry, varargin{:});
    q = p.Results;
    if (q.decay_lo~=decay_lo)||(q.decay_hi~=decay_hi)
        warning('Changing the decay time can be glitchy.');
    end
    
    %% feedback matrix
    % feedback matrix proposed by Stautner and Puckette, see [1].
    % I've tried a few other feedback matrices, but this one seemed to work
    % the best. The feedback matrix functions to disperse the energy of
    % the delay lines. We multiply a vector of each delayed signal at a
    % given sample number, lets call it [a b c d], by the feedback matrix,
    % which produces a new vector [a' b' c' d'] with the same magnitude
    % as [a b c d] but with the amplitudes of each component modified. this
    % scatters the output across the different delay lines to make the
    % reverberation sound more realistic, as opposed to having each delay
    % line feed directly back into itself which would sound too polished
    % and robotic to be real acoustic reverberation.
    matrix = [  ...
                0   1   1   0;
               -1   0   0  -1;
                1   0   0  -1;
                0   1  -1   0   ...
             ];
    matrix = matrix .* (q.gain/sqrt(2));
    
    %% convert to mono
    % sadly, the reverb isn't stereo yet - the algorithm needs some love
    % first. I want it to sound a little better before I work in the
    % complexities of stereo processing. 
    mono = (q.signal(:,1) + q.signal(:,2)) / 2; 
    
    %% pre lowpass filter
    % pre-reverb lowpass. this dampens the intensity of the high-end
    % frequencies, which don't reverberate in air as readily as low-end
    % frequencies.
    mono = fh.lowpass1(q.pre_lp_cut, q.sampling_freq, mono);
    
    %% attenuating high frequencies 
    % the values below are for adjusting the decay times as a function of
    % frequency, as described in [5]. the idea is that higher frequencies
    % should decay faster to model acoustic reverberation, i.e. when we
    % create our reverb, which is essentially a form of echo, we want the
    % higher frequencies to echo less (decay faster). since we have four
    % delay lines, each with different lengths, we need to calculate the
    % coefficients 'g' and 'p' for each delay line's implementation of the
    % difference equation:
    %           y(n) = g*x(n) - p*y(n-1)
    % which is just a simple feedback lowpass. the r_lo and r_hi are
    % approximations of rates of decay at 0 Hz and (sampling_freq/2) Hz [5]
    % for each delay line length. we want the rates across delay lines to 
    % amount to the same decay time between the instance of any frequency
    % in the input and the instance where that frequency has become 60dB    
    % quieter, therefore each delay line will need a different decay rate 
    % so that delays that begin later will decay at a higher rate as to 
    % synchronize with other decays.
    
    % this equation is from [5], and it is an approximation of decay rate
    r_lo = 1 - (ones(1,4)*(6.91/(q.sampling_freq*q.decay_lo))).* ...
                q.delaylines;
    r_hi = 1 - (ones(1,4)*(6.91/(q.sampling_freq*q.decay_hi))).* ...
                q.delaylines;
    % these are the coefficients for the lowpass filter on decay rate, for
    % each delay line. 
    g = (2*r_lo .* r_hi) ./ (r_lo + r_hi);
    p = (r_lo - r_hi) ./ (r_lo + r_hi);
    
    %% tonal correction 
    % a tonal correction filter, proposed by Jot and outlined in [6], is a
    % simple compensation for the filter outlined above. when we make the
    % higher frequencies decay faster, it shifts the tonal properties of
    % the outputted reverb, because the amount of sound energy that is
    % contributed by the higher frequencies is reduced. this constant is
    % used in a simple one-zero lowpass filter with difference equation:
    %       y(n) = (1 / tonal_const) * (x(n) - tonal_const*x(n-1))
    tonal_constant = (1 - q.decay_hi/q.decay_lo) / ...
                     (1 + q.decay_hi/q.decay_lo);
    
    %% setting up buffer variables and preallocation
    % a bit of a trick here is to use a 'circular buffer' [4] for the
    % sample delays. e.g. for a delay line = 887 samples, we want the
    % value to be 887 samples before the current sample's value, but for
    % all samples between the first and the 888th sample, there isnt a
    % sample that's 887 samples before. so we make an empty 'buffer' array
    % that is 887 samples long, which we populate from the beginning as we 
    % go along. if we read the last value of this array, it will represent
    % a delay of 887 samples, but if there is no sample then it'll be
    % zero. then, after adding a new value to the beginning of array 887
    % times, the last value of the array will be sample number 1.
    buffers = zeros(max(q.delaylines), 4);
    
    % same thing with the delay buffers, except smaller versions for the
    % signal after passing through the lowpass filters, and the output
    % after tonal correction
    filterBuffer = [0,0,0,0];
    tonalBuffer = 0;
    
    % preallocate
    reverb_signal = zeros(length(mono),1);
    
    %% generate reverb iteratively
    for sample_index = 1:length(mono)
        
        % read the buffers at their respective delay lengths
        readBuffer = [ ...
                        buffers(q.delaylines(1), 1),      ...
                        buffers(q.delaylines(2), 2),      ...
                        buffers(q.delaylines(3), 3),      ...
                        buffers(q.delaylines(4), 4)       ...
                     ];
        
        % decay the signal by given proportions, apply tonal correction
        % filter, then add this to output and update the buffer.
        % note: this ____   ____ is a dot product, so we get a single value
        %                \_/
        samp = (readBuffer*q.outDecays/4 - tonal_constant*tonalBuffer)...
            / (1 - tonal_constant);
        reverb_signal(sample_index)= samp;
        tonalBuffer = samp;
        
        % difference equation for y(n) = g*x(n) - p*y(n-1)
        % x(n) and y(n-1) are readBuffer and filterBuffer, respectively
        filterBuffer = readBuffer.*g - filterBuffer.*p;
        
        % feed the transformed buffer value back into the original signal,
        % this is what makes it a 'feedback' delay network 
        feedbacks = q.inDecays*mono(sample_index) + filterBuffer*matrix';
        
        % add the transformed signal to end of buffer, to be read later. 
        buffers = vertcat(feedbacks, buffers(1:end-1,:));
        
    end
    
    %% add reverb to original signal
    % post-reverb lowpass, which attenuates higher frequencies again
    reverb_signal = fh.lowpass1(q.post_lp_cut, ...
                                q.sampling_freq, reverb_signal);
    
	% output value is a combination of the reverb signal (converted to
	% stereo) and the original signal.
    output = (q.wet_dry * horzcat(reverb_signal, reverb_signal) + ...
              (1 - q.wet_dry) * q.signal) / 2; 
    
end



%% References
% [1] https://ccrma.stanford.edu/~jos/pasp/History_FDNs_Artificial_Reverberation.html
% [2] https://ccrma.stanford.edu/~jos/pasp/Choice_Delay_Lengths.html
% [3] http://www.primos.mat.br/primeiros_10000_primos.txt
% [4] https://en.wikipedia.org/wiki/Circular_buffer
% [5] https://ccrma.stanford.edu/~jos/pasp/First_Order_Delay_Filter_Design.html
% [6] https://ccrma.stanford.edu/~jos/pasp/Tonal_Correction_Filter.html

%% :+) 
%              _                 _____________________________________
% ____  ______/ \-.   _  _______/                                    /_____
% __ .-/     (    o\_// _______/   By Alex MacRae-Korobkov, 2018.   /______ 
% ___ |  ___  \_/\---'________/     github.com/amacraek/m_afx/     /_______  
%     |_||  |_||             /____________________________________/