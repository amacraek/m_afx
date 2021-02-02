# m_afx
MATLAB Digital Signal Processing and Audio Effects  
By Alex MacRae-Korobkov, 2018  

# Video

[![Digital Signal Processing and Audio Effects in MATLAB [YouTube]](http://img.youtube.com/vi/M5rrg5rFgQs/0.jpg)](http://www.youtube.com/watch?v=M5rrg5rFgQs "Digital Signal Processing and Audio Effects in MATLAB")

# Purpose
The purpose of this repository is to offer insight into digital (i.e. discrete) signal processing, specifically **in the context of audio engineering** applications. Though there might practical applications for this repository, it is designed primarily for **educational purposes,** and as such the code will contain long (and ugly) comment blocks in which I try to add context and develop understanding.  

## Why MATLAB???
Admittedly, MATLAB is a peculiar choice for an open-source educational repository, on part of its many ~~black-box~~ built-in features and its ~~inflated price~~ financial inaccessibility. First, a full disclosure: I'm writing this in MATLAB so I can submit it in a programming contest at the University of Alberta. Though this is my primary motivation for choosing MATLAB, there are actually some unexpected benefits:  
1. MATLAB offers the benefit of readability, and I don't imagine it would be overtly difficult to translate this code to a different platform.
2. The function and class structure in MATLAB forces me to split these scripts into individual files, which makes the project easy to navigate.
3. The 'help' function in MATLAB allows learners to access documentation from the console with relative ease, if using MATLAB.

### Do I need to buy MATLAB to learn from this repository?
No, you can even just read the code! The code is extensively commented, and it also includes citations to **freely-available online resources** that should help you understand what's going on. Also, **no complicated built-in MATLAB functions are used** to process the signal; I've done my best to design everything from scratch using standard operators and trigonometric functions, so all the important functions will be open-source.  

### How do I use this without MATLAB?
The code should be easy to translate to most other languages. Were you to use this code outside of MATLAB, the only difficulties you would probably encounter would be in translating MATLAB's matrix notation, e.g. switching from 1-indexed to 0-indexed, rewriting basic matrix functions, etc. Considering this, I would recommend Python as a free alternative, because numpy and scipy (free Python databases) will contain almost all (if not all) of the same basic functions that I use for matrix operations.  


# Features (v. 0.4)
The code is commented extensively with detailed explanations and free online resources, as I hope to offer some insights and further your understanding in the field of digital signal processing. I'll continue to proofread the comments between releases and make edits or additions in the interests of thoroughness and clarity.  
All scripts feature complete documentation, accessible via the `help` command in the MATLAB console (e.g. `help tapeSaturate`). For MATLAB non-users, the same documentation can also be read at the beginning of each function script. 

**linearNormalize.m**  
A function for normalizing signals based on the maximum peak amplitude across all channels.  

**stereoDynamics.m**  
A simple compresser/expander pair that dynamically adjusts the amplitude of the signal based on root-mean-squared values.  

**tapeSaturate.m**  
A distortion effect that emulates magnetic tape saturation, a.k.a. 'analog warmth'.  

**filterHelper.m**  
A class of static methods used for filtering signals. Includes:
- `allpass1` - a first-order allpass filter.
- `lowpass1` - a first-order lowpass filter.
- `highpass1` - a first-order highpass filter.
- `lowshelf1` - a first-order low shelf filter.
- `highshelf1` - a first-order high shelf filter.
- `allpass2` - a second-order allpass filter.
- `bandpass2` - a second-order band pass filter.
- `bandreject2` - a second-order bend reject filter.
- `bell2` - a second-order bell peak filter.
- `coefficients` - a function for custom filtering with feed-forward and feed-backward coefficients.  

**reverb.m**  
An acoustic reverberation emulator with customizable parameters.  

**demo.m**  
A demo script for MATLAB users. The script reads in the "sample.wav" drum sample and plays it back with different effects. It narrates what its doing, using the MATLAB console display.  

**validSignal.m**  
A short script that validates the input signal for these functions.  

**also includes**  
sample.wav - a short drum loop used for the demo.  
44100Hz.csv - a .csv of the "sample.wav" data.  

# Version history
### v 0.4e
Same as v 0.4, but with edits and additions to comments & documentation.  

### v 0.4
Includes a simple linear normalizer, a multi-channel dynamic compresser, a tape saturator, a filter class, a reverb, and a demo file.  
Changes:
- **Bugfix** in filterHelper.m: fixed error when specifying allpass1 filter purpose via optional string. 
- **Reverb no longer in beta!** New algorithm attenuates high frequencies and has a couple new name-value pairs.
- Demo script produces a prettier console output and displays the features more effectively -- including an FX chain!
- Script dependencies added to documentation.
- filterHelper.m now includes a second-order allpass filter, a bandpass, a bandreject, and a bell peak filter.  

### v 0.3
Includes a simple linear normalizer, a multi-channel dynamic compresser, a tape saturator, a filter class, a beta reverb, and a demo file.  
Changes:
- Demo file now prints information in console.
- All functions now include input parsing and validation (except reverb, which is in beta still).
- **New reverb effect** which is in beta. It sounds super metallic and ringy, but will sound better for v 0.4.
- Minor changes to comments for clarity. 
- Now includes '44100Hz.csv'. which is a csv version of 'sample.wav' for anyone who isn't using MATLAB.  

### v 0.2 
Includes a simple linear normalizer, a multi-channel dynamic compresser, a tape saturator, a filter class, and a demo file.  
Changes:
- **New filterHelper.m class with first-order allpass, lowpass, highpass, and a 'filter via coefficients' function.**
- Fixed broken links in .m file comments
- Renamed argument 'input' to 'signal' in functions  

### v 0.1
Includes a simple linear normalizer, a multi-channel dynamic compresser, and a tape saturator. The "demo.m" file uses the sample.wav drum loop to demonstrate the effects. 