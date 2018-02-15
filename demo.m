test = audioread('sample.wav');
comp = stereoDynamics(test, -38, 0.3, -40, -.009);
comp2 = tapeSaturate(comp, 10);

sound(linearNormalize(test), 41000, 24);
pause(3.5);
sound(linearNormalize(comp), 41000, 24);
pause(3.5);
sound(linearNormalize(comp2, .25), 41000, 24);
pause(3.5);

subplot(5,1,1), plot(linearNormalize(test));
subplot(5,1,2), plot(linearNormalize(comp));
subplot(5,1,3), plot(linearNormalize(comp2));
subplot(5,1,4), plot(linearNormalize(test)-linearNormalize(comp));
subplot(5,1,5), plot(linearNormalize(test)-linearNormalize(comp2));
