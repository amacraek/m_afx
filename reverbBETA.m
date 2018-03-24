function output = reverbBETA(signal)
 % REVERBBETA is a simple feedback delay network reverb, in its beta stage.
 %  It still sounds bad, and will be released in better shape and with
 %  complete documentation in a later version. 
    
    warning('off', 'backtrace');
    warning('The reverb feature is in BETA mode -- it sounds pretty bad!');
    
    % feedback matrix proposed by Stautner and Puckette, see [1].
    matrix = [  ...
                0   1   1   0;
               -1   0   0  -1;
                1   0   0  -1;
                0   1  -1   0   ...
             ];
    gain = 0.97;
    matrix = matrix .* (gain/sqrt(2));
    
    % sadly, the reverb isn't stereo yet - the algorithm needs some love
    % first. I want it to sound a little better before I work in the
    % complexities of stereo processing. 
    mono = (signal(:,1) + signal(:,2)) / 2;
    
    % here, we choose the delay lengths to be primes, suggested in [2].
    % For more choices, see [3].
    delaylines = [233, 659, 977, 1013]; 
    
    % out decay -> how much to decay the signal after the delay line
    % in decay -> how much to decay the signal before the delay line
    outDecays = [.8; .8; .8; .8];
    inDecays = [1, 1, 1, 1];
    
    % a bit of a trick here is to use a 'circular buffer' [4] for the
    % sample delays. e.g. for our delay line = 1013 samples, we want the
    % value to be 1013 samples before the current sample's value, but for
    % all samples between the first and the 1014th sample, there isnt a
    % sample that's 1013 samples before. so we make an empty 'buffer' array
    % that is 1013 samples long, which we populate from the beginning as we 
    % go along. if we read the last value of this array, it will represent
    % a delay of 1013 samples, but if there is no sample then it'll be
    % zero. then, after adding a new value to the beginning of array 1014
    % times, the last value of the array will be sample number 1.
    buffers = zeros(max(delaylines), 4);
    
    output = zeros(length(mono),1);
    
    for sample_index = 1:length(mono)
        % read the buffers at their respective delay lengths
        readBuffer = [ ...
                        buffers(delaylines(1), 1),      ...
                        buffers(delaylines(2), 2),      ...
                        buffers(delaylines(3), 3),      ...
                        buffers(delaylines(4), 4)       ...
                     ];
        
        % decay by given proportion, then add to output
        output(sample_index) = readBuffer*outDecays;
        
        % feed the transformed buffer value back into the original signal
        feedbacks = inDecays*mono(sample_index) + readBuffer*matrix';
        
        % add the transformed signal to the buffer, to read later. 
        buffers = vertcat(feedbacks, buffers(1:end-1,:));
    end
    
end



%% References
% [1] https://ccrma.stanford.edu/~jos/pasp/History_FDNs_Artificial_Reverberation.html
% [2] https://ccrma.stanford.edu/~jos/pasp/Choice_Delay_Lengths.html
% [3] http://www.primos.mat.br/primeiros_10000_primos.txt
% [4] https://en.wikipedia.org/wiki/Circular_buffer

%% :+) 
%              _                 _____________________________________
% ____  ______/ \-.   _  _______/                                    /_____
% __ .-/     (    o\_// _______/   By Alex MacRae-Korobkov, 2018.   /______ 
% ___ |  ___  \_/\---'________/     github.com/amacraek/m_afx/     /_______  
%     |_||  |_||             /____________________________________/