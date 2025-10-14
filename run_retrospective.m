function run_retrospective(subj, subjects_folder, mask, hairthickness, intensity, BS_file, ...
    exp_args, setup_args)
arguments % Argument Validation
    % variables that tend to vary by subject
    subj char % subject ID
    subjects_folder {mustBeFolder} % subject parent folder 
    mask {mustBeFile} % absolute path to mask
    hairthickness {mustBeNonnegative} % hair thickness measured during the session
    intensity {mustBeInteger} % stimulation intensity; negative means reverse current
    BS_file {mustBeFile} % absolute path to brainsight file

    % variables that tend to vary by experiment
    exp_args.Efield_display_decimal_places {mustBeInteger, mustBeNonnegative} = 7;
    exp_args.biphasic_waveform logical = true;
    exp_args.coil_name char = 'MagVenture_Cool-B65.ccd';
    exp_args.outputfolder char = 'post_analysis';
    exp_args.BS_target_name char = '';

    % setup
    setup_args.fsl_path {mustBeFolder} = '/usr/local/packages/fsl-6.0.3/';
    setup_args.simnibs_folder {mustBeFolder} ='/usr/local/packages/simnibs/4.1.0/';
    setup_args.freesurfer_matlab_folder {mustBeFolder} = '/usr/local/packages/freesurfer_v7.3.2/matlab/';
    setup_args.coil_models_are_here char = 'resources/coil_models/Drakaki_BrainStim_2022/';
    setup_args.root_folder char = [pwd filesep];
end

% distribute name-value variables
fsl_path = setup_args.fsl_path;
simnibs_folder = setup_args.simnibs_folder;
freesurfer_matlab_folder = setup_args.freesurfer_matlab_folder;
coil_models_are_here = setup_args.coil_models_are_here;
global root_folder;
root_folder=setup_args.root_folder;

if (ispc)
    sep='\';
    not_sep='/';
    rep_space = ' ';
elseif (ismac || isunix)
    sep='/';
    not_sep='\';
    rep_space = '\ ';
end
space = ' ';

if isunix && ~ismac
    setenv('LD_LIBRARY_PATH', sprintf('%s/simnibs/external/lib/linux:%s', simnibs_folder, getenv('LD_LIBRARY_PATH'))); % needed for running SimNIBS on certain linux clusters
end
% change separators and spaces
fsl_path=strrep(fsl_path,not_sep,sep);
fsl_path=strrep(fsl_path,space,rep_space);
simnibs_folder=strrep(simnibs_folder,not_sep,sep);
simnibs_folder=strrep(simnibs_folder,space,rep_space);
root_folder=strrep(root_folder,not_sep,sep);
root_folder=strrep(root_folder,space,rep_space);
coil_models_are_here=strrep(coil_models_are_here,not_sep,sep);
coil_models_are_here=strrep(coil_models_are_here,space,rep_space);
Original_MRI=strrep(Original_MRI,not_sep,sep);
Original_MRI=strrep(Original_MRI,space,rep_space);
addpath(char([simnibs_folder filesep 'matlab_tools']));
addpath(char([root_folder sep 'matlab']));
addpath(char(freesurfer_matlab_folder));
addpath(char(fsl_path));

%% identify coil location
% import Brainsight file
BS = importBS_mod(BS_file);
% remove stimulation aimed at different targets
if isempty(exp_args.BS_target_name)
    [counts,targets] = groupcounts(BS.Samples.AssocTarget);
    ROI = BS.Samples(strcmp(BS.Samples.AssocTarget, targets(counts == max(counts))), :);
else
    ROI = BS.Samples(strcmp(BS.Samples.AssocTarget, exp_args.BS_target_name));
end
% remove nan entries
ROI = ROI(~isnan(ROI.LocX), :);
% remove outliers
ROI = ROI(any(isoutlier(ROI(:, 5:20)), 2), :);
% find coil location closest to median
locs = [ROI.LocX ROI.LocY ROI.LocZ];
[~, minind] = min(sum((locs-median(locs)).^2, 2));
% make matrix
T = [reshape(ROI{minind, 8:16}, 3, 3) ROI{minind, 5:7}'; 0 0 0 1];
T(:, 4) = T(:, 4)+T(:, 3)*hairthickness;
T(:, [1 3]) = -T(:, [1 3]);
%% run SimNIBS
cd([subjects_folder filesep subj])
% General information
S = sim_struct('SESSION');
S.subpath = ['m2m_' subj]; % subject folder
S.pathfem = exp_args.outputfolder; % folder for the simulation output
% Define TMS simulation
S.poslist{1} = sim_struct('TMSLIST');
S.poslist{1}.fnamecoil = [setup_args.simnibs_folder filesep
    setup_args.coil_models_are_here filesep
    exp_args.coil_name]; % Choose a coil model
[~, max_didt_from_coil]=load_coil(S.poslist{1}.fnamecoil);
S.poslist{1}.pos(1).didt = max_didt_from_coil*intensity/100;
if biphasic_waveform
    S.poslist{1}.pos(1).didt = -S.poslist{1}.pos(1).didt;
end
% Define Position
S.poslist{1}.pos(1).matsimnibs = T;
% Run Simulation
run_simnibs(S);
%% convert mesh to NIfTI
cd(S.pathfem)
fn_mesh = dir('*msh');
fn_mesh = fn_mesh.name;
fn_reference = [subjects_folder filesep subj filesep S.subpath];
system([setup_args.simnibs_folder filesep 'bin/msh2nii ' fn_mesh ' ' fn_reference ' post']);
%% find E50
mask_nifti = niftiread(mask);
post_simulation = niftiread('post_magnE.nii.gz');
normE = sort(post_simulation(mask_nifti>0),'descend');
fprintf(['%.' num2str(exp_args.Efield_display_decimal_places) 'f%s'], ...
    normE(50), newline)