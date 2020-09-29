close all;
clear;
clc;

%% Make Model Coefficients
% Input terms
numFilters = 128;       % Number of Filters
lenOfBM = 3.5;          % Whole length of Basiliar Membrane
fMax = 20000;           % Maximum Processable Frequency

% arrays
N = 0:numFilters-1;
dx = lenOfBM/numFilters;
fResonPole = fMax*10.^(-0.667*N*dx);
fResonZero = 1.0429.*fResonPole;

pQualFirst = 10;                                    % First Pole Quality
pQualLast = 5.5;                                    % Last Pole Quality                                     
zQualFirst = 22;                                    % First Zero Quality
zQualLast = 12;                                     % Last Zero Quality
pQualInt = (pQualFirst-pQualLast)/(numFilters-1);   % Pole Quality Interval
zQualInt = (zQualFirst-zQualLast)/(numFilters-1);   % Zero Quality Interval

pQuality = pQualFirst - pQualInt.*N;
zQuality = zQualFirst - zQualInt.*N;
pBandWidth = fResonPole./pQuality;
zBandWidth = fResonZero./zQuality;

% Input terms
fSamp = 48000;          % Sampling Frequency

% Generate arrays
pRadius = 1 - pBandWidth./fSamp*pi;
zRadius = 1 - zBandWidth./fSamp*pi;
pTheta = 2*pi*fResonPole/fSamp;
zTheta = 2*pi*fResonZero/fSamp;
b1 = 2*cos(pTheta).*pRadius;
a1 = 2*cos(zTheta).*zRadius;
b2 = pRadius.^2;
a2 = zRadius.^2;
fLowPass = fResonZero*1.4;
thetaLowPass = 2*pi*fLowPass/fSamp;
a0 = 2 - cos(thetaLowPass) - sqrt((2 - cos(thetaLowPass)).^2 - 1);
K = pTheta./zTheta;
gain0 = 1 - a0;
pGain = 1 - b1 + b2;
zGain = 1./(1-a1+a2);


%% Basilar Membrane Model Frequency Analysis
% Input Terms
n = 71;                 % Filter number selection

% Filter Frequency Responses
pH = freqz(1 - b1(n) + b2(n), [1 -b1(n) b2(n)], fSamp/2);
zH = freqz([1 -a1(n) a2(n)], 1 - a1(n) + a2(n), fSamp/2);
pH = 20*log(abs(pH));
zH = 20*log(abs(zH));

% Plot
figure; movegui("west");
subplot 311; semilogx(pH); title("Pole Filter Frequency Response");
xlabel("Frequency (Hz)"); ylabel("Magnitude (dB)"); 
grid on; xlim([0 fSamp/2]);
subplot 312; semilogx(zH); title("Zero Filter Frequency Response");
xlabel("Frequency (Hz)"); ylabel("Magnitude (dB)"); 
grid on; xlim([0 fSamp/2]);


% Membrane Output Frequency Response
vMemH = freqz(K(n)*gain0(n)*pGain(n), ...
    conv([1 -a0(n)], [1 -b1(n) b2(n)]), fSamp/2);
vMemH = 20*log(abs(vMemH));

% Plot
subplot 313; semilogx(vMemH); title(" Basilar Membrane Frequency Response");
xlabel("Frequency (Hz)"); ylabel("Magnitude (dB)");
grid on; xlim([0 fSamp/2]);

fprintf("Press any key to continue\n");
pause;

%% Basilar Membrane Model Displacement Analysis
clear VLowPass Vm VPole Vo Vi

% Input terms
length = 8000;          % Length of Sample
f1 = 1000;              % First Frequency
f2 = 5000;              % Second Frequency
f3 = 10000;             % Third Frequency
m = 4000;               % Sample slice number

% % Impulse input
Vi(1, :) = [1 zeros(1, length-1)];

% % Sine input
Vi(1, :) = sin(2*pi*f1/fSamp.*(1:length));

% % Multiple Sine input
v1 = sin(2*pi*f1/fSamp.*(1:length));
v2 = sin(2*pi*f2/fSamp.*(1:length));
v3 = sin(2*pi*f3/fSamp.*(1:length));
Vi(1, :) = v1 + v2 + v3;

% Recorded input
Vi = rot90(audioread('three.wav'));
length = size(Vi, 2);

% Middle ear filter
Vi(1, :) = middleFilter(Vi(1, :));

% Generate output
Vm = zeros(numFilters, length);
for  n = N+1
    VLowPass(n, :) = filter(gain0(n), [1 -a0(n)], Vi(n, :)).*K(n);
    Vm(n, :) = filter(pGain(n), [1 -b1(n) b2(n)], VLowPass(n, :));
    VPole(n, :) = filter(pGain(n), [1 -b1(n) b2(n)], VLowPass(n, :));
    Vo(n, :) = filter([1 -a1(n) a2(n)]*zGain(n), 1, VPole(n, :));
    Vi(n+1, :) = Vo(n, :);
end

% Rescale for Plot
t = (1:length)/length*1000;

% Plot Impulse Responses
figure; movegui("north")
subplot 311; plot(t, Vm(30, :)); title("Impulse Response for Filter 30");
xlabel("Time (ms)"); ylabel("Displacement"); xlim([0 20]);
subplot 312; plot(t, Vm(60, :)); title("Impulse Response for Filter 60");
xlabel("Time (ms)"); ylabel("Displacement"); xlim([0 60]);
subplot 313; plot(t, Vm(90, :)); title("Impulse Response for Filter 90");
xlabel("Time (ms)"); ylabel("Displacement"); xlim([0 200]);

% Filter through second order differentiation
fprintf("Calculating.....\n");
Si = diff(diff(Vm));
fprintf("Done\n");

% Plot filtered sine output
figure; movegui("south");
plot(Si(:, m)); xlim([0 numFilters]); title("Filtered Displacement Output");
xlabel("Filter number"); ylabel("Displacement");

fprintf("Press any key to continue\n");
pause;

%% Inner Hair Cell Filter Model
% Terms
c0 = exp(-30*2*pi/fSamp);   % Filter Coefficient
m = 11500;                  % Choose slice of input

% Rectify Hair Cell input
Sr = Si;
Sr(Si<0) = 0;

% Generate Electrical output
Eo(:, 1) = (1 -c0).*Sr(:, 1);
for n = 2:size(Sr, 2)
    Eo(:, n) = (1-c0)*Sr(:, n) + c0*Eo(:, n-1);
end


% Data Output
[ePeakM, ePeakN] = max(Eo(:, m));
ePeakF = fMax*10.^(-0.667*ePeakN*dx);
fprintf("Peak filter "+ePeakN+" at "+ePeakF+" Hz\n");

% Plot Ear Model input and outputs
fig = figure; movegui("east");
subplot 311; plot(Vi(1, :)); xlim([0 length]);
line([m,m], ylim,'Color', [1 0 0], 'LineWidth',2);title("Input Waveform"); 
xlabel("Sample Number"); ylabel("Amplitude");
subplot 312; plot(Si(:, m)); xlim([0 numFilters]); 
line([ePeakN, ePeakN], ylim,'Color', [0 1 0], 'LineWidth',2); 
title("Displacement Output at Sample " + m); 
xlabel("Filter number"); ylabel("Displacement");
subplot 313; plot(Eo(:, m)); xlim([0 numFilters]); 
line([ePeakN, ePeakN], ylim,'Color', [0 1 0], 'LineWidth',2)
title("Electrical Output at Sample " + m); 
xlabel("Filter number"); ylabel("Displacement");

fprintf("Script done.\n")
saveas(fig, "Output.png")
