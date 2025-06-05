% Modified version of David LK Murphy (david.murphy@duke.edu)'s importBS("BStext")
% bsData = importBS("BStext")
% importBS is a function that converts brainsight text into a MATLAB 
% structure. 
% input: "BStext" is the filename or fullpath filename of the Brainsight
% data text export.
% output:"bsData" contians session information: Brainsight 
% application info, samples, targets, and landmarks. 
%
% bsData Structure:
% bsData.Info
% bsData.Targets
% bsData.Samples
% bsData.PlannedLandmarks
% bsData.SessionLandmarks
% bsData.SessionName
% 
% All structure fields are in MATLAB table format, with the exception of 
% "Info" which is a cell array. Variable names of each table correspond to
% those found in Brainsight.
%   
% Sample data includes location, timestamp, and MEP values if recorded by
% the Brainsight EMG system. The MEP/EMG part of the table in the "Samples"
% field can be filled out with the recorded BrainVision EMG data.
% Version: 0v2
% Date: April 1, 2022
% Author: David LK Murphy (david.murphy@duke.edu)

%% Setup working directory
function bsData = importBS_mod(BStext)
% BStext should be the full path to the file.
rtrnPath=pwd;
casa = pwd;
if nargin<1||exist(BStext)==0
    [BStext,BSpath] =uigetfile([casa filesep '*Brainsight_Export.txt']);
    BStext = [BSpath BStext];
end

if isnumeric(BStext)||isempty(BStext)
%     alertFig = uifigure;
    warndlg('Import canceled: no file selected');
return
end
firstLine = 8; % first line of session target data. Lines 1-7 are BS info.
%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 1);

% Specify range and delimiter
opts.DataLines = [1, inf];
opts.Delimiter = "\t";

% Specify column names and types
% opts.VariableNames = ["Version12", "Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31", "Var32", "Var33", "Var34", "Var35"];
% opts.SelectedVariableNames = "Version12";
% opts.VariableTypes = ["char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char"];

% Specify file level properties
% opts.ExtraColumnsRule = "ignore";
% opts.EmptyLineRule = "read";

bsData0 =readtable([BStext], opts);

%% Convert to output type
bsData0 = table2cell(bsData0);
numIdx = cellfun(@(x) ~isnan(str2double(x)), bsData0);
bsData0(numIdx) = cellfun(@(x) {str2double(x)}, bsData0(numIdx));
bsData.Info = bsData0(1:7,1);
targStart = find(contains({bsData0{:,1}}','Target Name'));
sampStart = find(contains({bsData0{:,1}}','Sample Name'));
plnStart = find(contains({bsData0{:,1}}','Planned Landmark Name'));
slnStart = find(contains({bsData0{:,1}}','Session Landmark Name'));
snmStart = find(contains({bsData0{:,1}}','Session Name'));
%% Clear temporary variables
clear opts bsData0

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 13);

% Specify range and delimiter
opts.DataLines = [targStart+1 sampStart-1];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["TargetName", "LocX", "LocY", "LocZ", "m0n0", "m0n1", "m0n2", "m1n0", "m1n1", "m1n2", "m2n0", "m2n1", "m2n2"];
opts.SelectedVariableNames = ["TargetName", "LocX", "LocY", "LocZ", "m0n0", "m0n1", "m0n2", "m1n0", "m1n1", "m1n2", "m2n0", "m2n1", "m2n2"];
opts.VariableTypes = ["string", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double" ];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["TargetName"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["TargetName"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, ["LocX", "LocY","LocZ"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["LocX","LocY", "LocZ"], "ThousandsSeparator", ",");

% Import the data
bsData.Targets = readtable([BStext], opts);
%% Clear temporary variables
clear opts bsData0
%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 35);

% Specify range and delimiter

opts.DataLines = [sampStart+1, plnStart-1];
opts.Delimiter = "\t";



% Specify column names and types
opts.VariableNames = ["SampleName", "SessionName", "Index", "AssocTarget", "LocX", "LocY", "LocZ", "m0n0", "m0n1", "m0n2", "m1n0", "m1n1", "m1n2", "m2n0", "m2n1", "m2n2", "DistToTarget", "TargetError", "AngularError", "TwistError", "StimPowerA", "StimPulseInterval", "StimPowerB", "Date", "Time", "CreationCause", "CrosshairsDriver", "Offset", "Comment", "EMGStart", "EMGEnd", "EMGRes", "EMGChannels", "EMGWindowStart", "EMGWindowEnd"];
opts.VariableTypes = ["string", "string", "double", "string", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "datetime", "string", "string", "string", "double", "string", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["SampleName", "SessionName", "AssocTarget", "Time", "CreationCause", "CrosshairsDriver", "Comment"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["SampleName", "SessionName", "AssocTarget", "Time", "CreationCause", "CrosshairsDriver", "Comment"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "Date", "InputFormat", "yyyy-MM-dd");
opts = setvaropts(opts, ["StimPowerA", "StimPulseInterval", "StimPowerB", "EMGStart", "EMGEnd", "EMGRes", "EMGChannels", "EMGWindowStart", "EMGWindowEnd"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["StimPowerA", "StimPulseInterval", "StimPowerB", "EMGStart", "EMGEnd", "EMGRes", "EMGChannels", "EMGWindowStart", "EMGWindowEnd"], "ThousandsSeparator", ",");

% Import the data
bsData.Samples  = readtable([BStext], opts);




%% Clear temporary variables
clear opts bsData0
opts = delimitedTextImportOptions("NumVariables", 4);

opts.DataLines = [plnStart+1 slnStart-1];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["PlannedLandmarkName", "LocX", "LocY", "LocZ"];
    opts.SelectedVariableNames = ["PlannedLandmarkName", "LocX", "LocY", "LocZ"];
opts.VariableTypes = ["string", "double", "double", "double" ];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["PlannedLandmarkName"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["PlannedLandmarkName"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, ["LocX","LocY", "LocZ"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["LocX","LocY", "LocZ"], "ThousandsSeparator", ",");

% Import the data
bsData.PlannedLandmarks = readtable([BStext], opts);

%% Clear temporary variables
clear opts

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 6);

% Specify range and delimiter
opts.DataLines = [slnStart+1 snmStart-1];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["SessionLandmarkName", "SessionName", "Used", "LocX", "LocY", "LocZ"];
opts.SelectedVariableNames = ["SessionLandmarkName", "SessionName", "Used", "LocX", "LocY", "LocZ"];
opts.VariableTypes = ["string", "string", "string", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["SessionLandmarkName", "SessionName", "Used"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["SessionLandmarkName", "SessionName", "Used"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "LocX", "TrimNonNumeric", true);
opts = setvaropts(opts, "LocX", "ThousandsSeparator", ",");

% Import the data
bsData.SessionLandmarks = readtable([BStext], opts);

%% Clear temporary variables
clear opts
cd(rtrnPath)
end