%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        __                    _                          % 
%  _ __  _   _  _ __    / _|  ___   _ __    __| |  ___  _ __ ___    ___   % 
% | '__|| | | || '_ \  | |_  / _ \ | '__|  / _` | / _ \| '_ ` _ \  / _ \  %
% | |   | |_| || | | | |  _|| (_) || |    | (_| ||  __/| | | | | || (_) | %
% |_|    \__,_||_| |_| |_|   \___/ |_|     \__,_| \___||_| |_| |_| \___/  %
%                                                                         %   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% read in sample.wav file
fprintf('--------------Reading sample--------------');
fprintf('\nReading file ''sample.wav''...\n');
% read in the audio file 'sample.wav', which is on github. Alternatively,
% the file '44100Hz.csv' contains this data in csv format.
[test, sampling_freq] = audioread('sample.wav');
disp('File read.');

%% apply a series of effects
fprintf('\n----------Applying audio effects----------\n');
% see documentation for each effect via 'help' command if using MATLAB.
% e.g. type 'help stereoDynamics' into MATLAB console 

% stereo dynamics (a.k.a. audio compression)
tic; 
disp('Applying stereoDynamics...');
comp = stereoDynamics(test, -38, 0.3, -40, -.009);
fprintf('\tStereodynamics applied.\n\tTime: %.4f sec.\n', toc);

% tape saturation
tic; 
disp('Applying tapeSaturate...');
sat = tapeSaturate(comp, 10);
fprintf('\ttapeSaturate applied.\n\tTime: %.4f sec.\n', toc);

% FIR lowpass filter via 'coefficients' function
tic; 
disp('Applying filterHelper.coefficients...');
coef = filterHelper.coefficients(ones(1,30), 1, comp);
fprintf('\tfilterHelper.coefficients applied.\n\tTime: %.4f sec.\n', toc);

% first-order lowpass filter
tic; 
disp('Applying filterHelper.lowpass1...');
lp1 = filterHelper.lowpass1(1000, sampling_freq, comp);
fprintf('\tfilterHelper.lowpass1 applied.\n\tTime: %.4f sec.\n', toc);

% reverb, 50/50 wet/dry
tic; 
disp('Applying reverb...');
rvb = reverb(test, sampling_freq, 0.5);
fprintf('\treverb applied.\n\tTime: %.4f sec.\n', toc);

%% big FX chain
tic;
disp('Applying effects chain (multiple effects)...');

% first bus: 
%   reverb -> highshelf cut -> lowshelf cut -> lo bell cut -> normalize
bus1_a = rvb;
bus1_b = filterHelper.highshelf1(12000,sampling_freq,-12,bus1_a);
bus1_c = filterHelper.lowshelf1(700, sampling_freq, -3, bus1_b);
bus1_d = filterHelper.bell2(340, 0.3, sampling_freq, -2, bus1_c);
bus1_out = linearNormalize(bus1_d);

% second bus: 
%   highshelf cut -> lowshelf cut -> normalize
bus2_a = filterHelper.highshelf1(14000, sampling_freq, -1, test);
bus2_b = filterHelper.lowshelf1(1200, sampling_freq, -1.5, bus2_a);
bus2_out = linearNormalize(bus2_b);

% third bus: 
%   saturation -> highshelf cut -> hi bell cut -> lowshelf cut -> normalize
bus3_a = tapeSaturate(test,7.4);
bus3_b = filterHelper.highshelf1(12000, sampling_freq, -4, bus3_a);
bus3_c = filterHelper.bell2(17000, 0.35, sampling_freq, -2, bus3_b);
bus3_d = filterHelper.lowshelf1(400, sampling_freq, -3, bus3_c);
bus3_out = linearNormalize(bus3_d);

% master_bus: 
%   mix inputs -> high shelf cut -> lo bell cut -> dynamics -> normalize
master_in = 0.33*bus1_out + 0.45*bus2_out + 0.22*bus3_out;
master_a = filterHelper.highshelf1(15500, sampling_freq, -2.8, master_in);
master_b = filterHelper.bell2(340,0.3,sampling_freq, -0.7, master_a);
master_c1 = linearNormalize(master_b);
master_c2 = stereoDynamics(master_c1, -5, 0.3, -7, -.009);
master_out = linearNormalize(master_c2);

fprintf('\tEffects chain applied.\n\tTime: %.4f sec.\n', toc);

%% play the effects 
fprintf('\n-----------Playing the effects------------\nNow playing:\n');
fprintf('\t\t\tdry signal.\n');
sound(linearNormalize(test), sampling_freq, 24);
pause(4);
fprintf('\t\t\tcompressed signal.\n');
sound(linearNormalize(comp), sampling_freq, 24);
pause(4);
fprintf('\t\t\ttape saturated signal.\n');
sound(linearNormalize(sat, .15), sampling_freq, 24);
pause(4);
fprintf('\t\t\tFIR lowpassed signal.\n');
sound(linearNormalize(coef), sampling_freq, 24);
pause(4);
fprintf('\t\t\tfirst-order lowpassed signal.\n');
sound(linearNormalize(lp1), sampling_freq, 24);
pause(4);
fprintf('\t\t\treverberated signal.\n');
sound(linearNormalize(rvb), sampling_freq, 24);
pause(4);
fprintf('\t\t\tdry signal, again. compare with effects chain, up next!\n');
sound(linearNormalize(test), sampling_freq, 24);
pause(4);
fprintf('\t\t\teffects chain: 3 bus + master:\n');
fprintf('\t\t\t\tBus 1 (33%% volume):\n');
fprintf('\t\t\t\t\t a. reverb, wet only\n');
fprintf('\t\t\t\t\t b. high shelf, -12dB at 12000Hz \n'); 
fprintf('\t\t\t\t\t c. low shelf, -3dB at 700Hz \n');
fprintf('\t\t\t\t\t c. low bell cut, -2dB at 340Hz, Q=0.3 \n');
fprintf('\t\t\t\tBus 2 (45%% volume):\n');
fprintf('\t\t\t\t\t a. high shelf, -1dB at 14000Hz \n');
fprintf('\t\t\t\t\t b. low shelf, -1.5dB at 1200Hz \n');
fprintf('\t\t\t\tBus 3 (22%% volume):\n');
fprintf('\t\t\t\t\t a. tape saturation, knob at 7.4\n');
fprintf('\t\t\t\t\t b. high shelf, -4dB at 12000Hz \n');
fprintf('\t\t\t\t\t c. high bell cut, -6dB at 17000Hz, Q=0.35\n');
fprintf('\t\t\t\t\t d. low shelf, -3dB at 400Hz \n');
fprintf('\t\t\t\tMaster bus:\n');
fprintf('\t\t\t\t\t a. high shelf, -2.8dB at 15500Hz\n');
fprintf('\t\t\t\t\t b. low bell cut, -0.7dB at 340Hz, Q=0.3\n');
fprintf('\t\t\t\t\t c. stereo dynamics, CT=-5, CS=.3, ET=-7, ES=-.009\n');
sound(master_out, sampling_freq, 24);
pause(4);

%% :+) 
elephant = [ horzcat(char(10), ...
'            _                 _____________________________________   ');
'___  ______/ \-.   _  _______/                                    /____';
'_ .-/     (    o\_// _______/   By Alex MacRae-Korobkov, 2018.   /_____';
'__ |  ___  \_/\---''________/     github.com/amacraek/m_afx/     /______'; 
'   |_||  |_||             /____________________________________/       ';
];
elephant(:,end+1) = char(10);
fprintf('%c', elephant');
pause(4);