function output = stereoDynamics(signal, comp_threshold, comp_slope, ...
                                 exp_threshold, exp_slope, varargin)
% STEREODYNAMICS is a simple compresser/expander pair that processes each
%   inputted channel separately. It uses the root-mean-square amplitude of
%   the input signal to dynamically scale the output. It also uses a simple
%   attack/release envelope to preserve natural dynamics. It can handle 
%   mono and >2.0 signals, too. 
%                
% Required arguments:
%   signal          the audio input, with size = [samples, channels]. The
%                   input should be a normalized and linearly-scaled signal 
%                   For normalizing your data, use linearNormalize (bottom)
%   comp_threshold  the volume threshold for compression in dB, (v < 0)
%                   signals louder than this will be compressed.
%   comp_slope      the slope of the compression curve, (m > 0)
%                   A greater value corresponds to more compression. 
%   exp_threshold   the volume threshold for expansion in dB (v < 0)
%                   signals quieter than this will be expanded.
%   exp_slope       the slope of the expansion curve, (m < 0)
%                   A greater value (closer to zero) corresponds to more 
%                   expansion.
%
% Optional name-value pairs:
%   'rms_width'     the width of the root-mean-squared averaging window for 
%                   calculating the signal's amplitude. The smaller you set 
%                   this, the wider the RMS window becomes. Default value 
%                   is 0.1.
%   'attack'        The width of the attack envelope window, which smooths 
%                   the onset of the signal modification. Acts similarly to
%                   RMS window. Setting it to 1 will disable it. Default
%                   value is 0.05.
%   'release'       The width of the release envelope window, which smooths 
%                   the offset of the signal modification. Acts similarly 
%                   to RMS window. Setting it to 1 will disable it. Default
%                   value is 0.005.
%
% Output: 
%   compressed signal matrix with the same size as input. 
%
% Example usage:
%   output = STEREODYNAMICS(signal, -15, 0.3, -25, -0.05, 'rms_width', 0.2)
% Interpretation:
%       Returns a modified signal with compression of 0.3 starting at  
%       -15dB, expansion of -0.05 starting at -25dB, rms_width narrowed to 
%       0.2.
%
% See also linearNormalize. 
%
% github.com/amacraek/m_afx/
% Alex MacRae-Korobkov 2018

%% parsing inputs
    p = inputParser;
    addRequired(p, 'signal');
    addRequired(p, 'comp_threshold', @(x) (x<0));
    addRequired(p, 'comp_slope', @(x) (x>0));
    addRequired(p, 'exp_threshold', @(x) (x<0));
    addRequired(p, 'exp_slope');
    addParameter(p, 'rms_width', 0.1, @(x) (x>=0) && (x<=1));
    addParameter(p, 'attack', 0.05, @(x) (x>0) && (x<=1));
    addParameter(p, 'release', 0.005, @(x) (x>0) && (x<=1))
    parse(p, signal, comp_threshold, comp_slope, ...
          exp_threshold, exp_slope, varargin{:});
    q = p.Results;

%% setting initial values     
    rms_amplitude = 0;
    gain = 1;
    [samples, channels] = size(q.signal);
    output = zeros(samples, channels);

%% iteratively apply dynamic gain modification 
    for channel = 1:channels  % treat each channel separately
        for sample = 1:samples
            current_sample = q.signal(sample, channel);
            
            % assuming we have a signal normalized to [-1, 1], we don't
            % need to actually square root the rms value. the value is
            % recalculated iteratively as a weighted average with rms_width
            rms_amplitude = (1 - q.rms_width) * rms_amplitude ...
                             + q.rms_width * current_sample^2; 
                              
            % converting to dB conveniently makes the signal logarithmic 
            rms_dB = 10 * log10(rms_amplitude); 
            
            % positive comp. slope = scale is negative for val > threshold
            comp_scale = q.comp_slope * (q.comp_threshold - rms_dB);
            
            % negative exp. slope = scale is negative for val < threshold
            exp_scale = q.exp_slope * (q.exp_threshold - rms_dB);
            
            % scaling factor determines how much the sample should be
            % scaled by, 0 < factor < 1. Because of how the comp/exp scales
            % are set up (above), the smallest value will always be the
            % appropriate scaling factor for the given sample. The scaling
            % factor should equal 1 at maximimum. If we take the minimum
            % value between comp_scale, exp_scale, and zero, we can only
            % get a value between 0 and 1 when converting from dB to amp.
            scaling_factor = 10^(min([0, comp_scale, exp_scale]) / 20);
            
            % basic implementation of an attack/release smoothing filter. 
            % gain is recalculated iteratively for each sample (obviously),
            % so if we know that this sample's scaling factor is larger
            % than the previous gain, then the signal is attacking, else it
            % is releasing. we calculate the gain for the current sample as
            % an average of the scaling factor and the previous gain, based 
            % on the width of the appropriate envelope, in order to smooth
            % the compression. 
            if scaling_factor < gain
                gain = (1 - q.attack) * gain + q.attack * scaling_factor;
            else
                gain = (1 - q.release) * gain + q.release * scaling_factor;
            end
            
        % ok now scale this data point, then we're on to the next one
        output(sample, channel) = gain * current_sample;
        end
    end
end


%% acknowledgements
%   Thanks to the wonderful publishers of the following web sources for 
%   releasing their knowledge for free to the commons:
%       http://www.recordingblogs.com/sa/Wiki/topic/Compressor-expander-of-dynamics
%       https://ca.mouser.com/applications/dynamic-processors-audio-applications/
%       http://home.btconnect.com/ssa/whitepaper/whitepaper.htm#comp
%       http://pubmedcentralcanada.ca/pmcc/articles/PMC4111488/#section7-108471380500900202
%       https://varietyofsound.wordpress.com/2011/01/19/compressor-gate-and-expander/