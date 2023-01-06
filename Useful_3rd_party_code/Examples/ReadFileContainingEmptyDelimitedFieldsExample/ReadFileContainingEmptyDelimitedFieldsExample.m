clc %% Read File Containing Empty Delimited Fields
% Write two matrices to a file, and then read the entire file using
% |dlmread|.
%%
% Export a matrix to a file named |myfile.txt|. Then, append an additional matrix to the
% file that is offset one row below the first.

% Copyright 2015 The MathWorks, Inc.

X = magic(3);
dlmwrite('myfile.txt',[X*5 X/5],' ')
dlmwrite('myfile.txt',X,'-append', ...
   'roffset',1,'delimiter',' ')
%%
% View the file contents.
type myfile.txt
%% 
% Read the entire file using |dlmread|.
M = dlmread('myfile.txt')
%%
% When |dlmread| imports a file containing nonrectangular data, it fills empty
% fields with zeros.