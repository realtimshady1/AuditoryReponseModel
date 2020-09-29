function midOutput = middleFilter(input)
% Filters an input modelling the response of 
% the Middle and Outer Human Ear

% Modelling Constant Terms
outerNum = [1 -0.824 -0.697 0.340 0.2025];  % Numerator of Outer Filter
outerDen = [1 -1.674 0.81];                 % Denominator of Outer Filter
middleNum = [1 -1.728 0.595 0.125 0.009];   % Numerator of Middle Filter
middleDen = [1 -1.876 0.884];               % Denominator of Middle Filter

% Build Output
outerOutput = filter(outerNum, outerDen, input);
midOutput = filter(middleNum, middleDen, outerOutput);

end