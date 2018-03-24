%% run this demo file to hear the effects
textart = [
'_/\/\______/\/\____________________/\/\______/\/\/\/\/\/\__/\/\____/\/\_';
'_/\/\/\__/\/\/\__________________/\/\/\/\____/\/\____________/\/\/\/\___';
'_/\/\/\/\/\/\/\________________/\/\____/\/\__/\/\/\/\/\________/\/\_____';
'_/\/\__/\__/\/\________________/\/\/\/\/\/\__/\/\____________/\/\/\/\___';
'_/\/\______/\/\________________/\/\____/\/\__/\/\__________/\/\____/\/\_';
'_________________/\/\/\/\/\/\___________________________________________';
];
textart(:,end+1) = char(10);
fprintf('%c', textart');
pause(2);

fprintf('\n--------------Reading sample--------------');
fprintf('\nReading file ''sample.wav''...\n');
% read in the audio file 'sample.wav', which is on github. Alternatively,
% the file '44100Hz.csv' contains this data in csv format.
[test, f_s] = audioread('sample.wav');
disp('File read.');

fprintf('\n----------Applying audio effects----------\n');
% run some effects. see documentation for each effect via 'help' command,
% e.g. type 'help stereoDynamics' in console 
tic; 
disp('Applying stereoDynamics...');
comp = stereoDynamics(test, -38, 0.3, -40, -.009);
fprintf('\tStereodynamics applied.\n\tTime: %.4f seconds\n', toc);
tic; 
disp('Applying tapeSaturate...');
sat = tapeSaturate(comp, 10);
fprintf('\ttapeSaturate applied.\n\tTime: %.4f seconds\n', toc);
tic; 
disp('Applying filterHelper.coefficients...');
coef = filterHelper.coefficients(ones(1,30), 1, comp);
fprintf('\tfilterHelper.coefficients applied.\n\tTime: %.4f seconds\n', toc);
tic; 
disp('Applying filterHelper.lowpass1...');
lp1 = filterHelper.lowpass1(1000, f_s, comp);
fprintf('\tfilterHelper.lowpass1 applied.\n\tTime: %.4f seconds\n', toc);
tic; 
disp('Applying reverbBETA...');
rvb = reverbBETA(test);
fprintf('\treverbBETA applied.\n\tTime: %.4f seconds\n', toc);


% Play the sound effects
fprintf('\n-----------Playing the effects------------\nNow playing:\n');
fprintf('\t\t\tdry signal.\n');
sound(linearNormalize(test), f_s, 24);
pause(8);
fprintf('\t\t\tcompressed signal.\n');
sound(linearNormalize(comp), f_s, 24);
pause(8);
fprintf('\t\t\ttape saturated signal.\n');
sound(linearNormalize(sat, .25), f_s, 24);
pause(8);
fprintf('\t\t\tFIR lowpassed signal.\n');
sound(linearNormalize(coef), f_s, 24);
pause(8);
fprintf('\t\t\tlowpassed signal.\n');
sound(linearNormalize(lp1), f_s, 24);
pause(8);
fprintf('\t\t\treverberated signal(BETA).\n');
sound(linearNormalize(rvb), f_s, 24);
pause(8);

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
clear all;
pause(2);