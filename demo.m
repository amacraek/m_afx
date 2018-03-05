[test, f_s] = audioread('sample.wav');
comp = stereoDynamics(test, -38, 0.3, -40, -.009);
sat = tapeSaturate(comp, 10);
fcoef = ones(1,30);
coef = filterHelper.coefficients(fcoef, 1, sat);
lp1 = filterHelper.lowpass1(1000, f_s, sat);

disp('Playing dry signal');
sound(linearNormalize(test), f_s, 24);
pause(8);
disp('Playing compressed signal');
sound(linearNormalized(sat), f_s, 24);
pause(8);
disp('Playing tape saturated signal');
sound(linearNormalize(sat, .25), f_s, 24);
pause(8);
disp('Playing FIR lowpassed signal');
sound(linearNormalize(coef), f_s, 24);
pause(8);
disp('Playing lowpassed signal');
sound(linearNormalize(lp1), f_s, 24);

