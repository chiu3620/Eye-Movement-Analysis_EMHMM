clear; close all;
addpath(genpath('emhmm-toolbox'))
setup

script_dir = fileparts(mfilename('fullpath'));
data_dir   = fullfile(script_dir, 'data');

xlsnames = {'honda_all.xlsx', 'Condition_1.xlsx', 'Condition_2.xlsx', 'Condition_3.xlsx', 'Condition_4.xlsx', ...
    'Condition_5.xlsx', 'Condition_6.xlsx', 'Condition_7.xlsx', 'Condition_8.xlsx', 'Condition_9.xlsx', ...
    'Group_anthro_high_12368.xlsx', 'Group_anthro_low_4579.xlsx',...
    'Group_empathy_high_23489.xlsx', 'Group_empathy_low_1567.xlsx',...
    'Group_like_high_1238.xlsx', 'Group_like_low_45679.xlsx'};         % Gaze data

for ROI = 3:5
    % --- Image output location ---
    K = 1:ROI;
    output_dir = sprintf('K=%d', max(K));
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    % --- Start recording fprintf log ---
    logname = fullfile(output_dir, 'all_conditions_log.txt');
    diary(logname);
    diary on;
    all_param_rows = {};

    % --- Data and image setup -----------------------

    for idx = 1:length(xlsnames)
        close all;
        clearvars -except idx xlsnames output_dir logname K all_param_rows ROI;
        xlsname = xlsnames{idx};          % Extract string from cell array
        faceimg = 'Neutral.jpg';          % Face image

        %% --- Load Fixation Data -------------------
        [data, SubjNames, ~] = read_xls_fixations(xlsname);
        N = length(data);  % Number of subjects

        % Read image size
        img0 = imread(faceimg);

        imgsize = size(img0);
        [H, W, ~] = size(img0);  % H = Height (y), W = Width (x)

        % Convert fixation coordinates from center origin to top-left origin
        for i = 1:length(data)
            for j = 1:length(data{i})
                if ~isempty(data{i}{j})
                    % X-axis: shift right by W/2
                    data{i}{j}(:,1) = data{i}{j}(:,1) + W/2;
                    % Y-axis: flip vertically, then shift down by H/2
                    data{i}{j}(:,2) = -data{i}{j}(:,2) + H/2;
                end
            end
        end

        %% --- VB-HMM Setup and Learning -------------------
        vbopt.alpha0 = 1;
        vbopt.mu0 = [imgsize(2); imgsize(1)]/2;
        vbopt.W0 = 0.001;
        vbopt.beta0 = 1;
        vbopt.v0 = 10;
        vbopt.epsilon0 = 1;
        vbopt.bgimage = faceimg;
        vbopt.seed = 1000;
        vbopt.learn_hyps = 1;
        vbopt.showplot = 0;

        % Build individual HMMs
        [hmms, ~] = vbhmm_learn_batch(data, K, vbopt);

        %% --- HEM Clustering (1 Group) ---------------------
        hemopt.tau = get_median_length(data);
        hemopt.seed = 1001;
        myS = [];

        all_hmms1 = vhem_cluster(hmms, 1, myS, hemopt);

        % Plot the groups
        % vhem_plot(all_hmms1, faceimg);

        fig1 = figure('Visible', 'on');
        vhem_plot(all_hmms1, faceimg);
        drawnow;
        pause(1);
        F = getframe(gcf);
        filename1 = fullfile(output_dir, sprintf('plot_%s_group1.png', erase(xlsname, '.xlsx')));
        imwrite(F.cdata, filename1);
        close(fig1);

        %% --- HEM Clustering (2 Groups) ---------------------
        [group_hmms2] = vhem_cluster(hmms, 2, myS, hemopt)  % 2 groups

        % Plot the groups
        % vhem_plot(group_hmms2, faceimg);

        fig2 = figure('Visible', 'on');
        vhem_plot(group_hmms2, faceimg);
        drawnow;
        pause(1);
        F2 = getframe(gcf);
        filename2 = fullfile(output_dir, sprintf('plot_%s_group2.png', erase(xlsname, '.xlsx')));
        imwrite(F2.cdata, filename2);
        close(fig2);

        % Get the most likely ROI sequences %%%%%%%%%
        fprintf('\n*** top-5 most probable ROI sequences ***\n');
        [seqs{1}, seqs_pr{1}] = stats_stateseq(group_hmms2.hmms{1}, 3);
        [seqs{2}, seqs_pr{2}] = stats_stateseq(group_hmms2.hmms{2}, 3);

        % Show the sequences
        fprintf('prob   : hmm1 ROI seq \n');
        fprintf('-----------------\n');
        for i=1:5
          fprintf('%0.4f : ', seqs_pr{1}(i));
          fprintf('%d ',     seqs{1}{i});
          fprintf('\n');
        end

        % Show the sequences
        fprintf('\nprob   : hmm2 ROI seq \n');
        fprintf('-----------------\n');
        for i=1:5
          fprintf('%0.4f : ', seqs_pr{2}(i));
          fprintf('%d ',     seqs{2}{i});
          fprintf('\n');
        end

        % Statistical test %%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Collect data for group 1 and group 2
        data1 = data(group_hmms2.groups{1});
        data2 = data(group_hmms2.groups{2});

        fprintf('\n*** t-test ***\n');

        % Run t-test for hmm1 
        [p, info, lld] = stats_ttest(group_hmms2.hmms{1}, group_hmms2.hmms{2}, data1);
        fprintf('- test group hmm1 different from group hmm2: t(%d)=%0.4g; p=%0.4f; d=%0.3g\n', info.df, info.tstat, p, info.cohen_d);

        % Run t-test for hmm2
        [p, info, lld] = stats_ttest(group_hmms2.hmms{2}, group_hmms2.hmms{1}, data2);
        fprintf('- test group hmm2 different from group hmm1: t(%d)=%0.4g; p=%0.4f; d=%0.3g\n', info.df, info.tstat, p, info.cohen_d);

        % File name prefix
        name_no_ext = erase(xlsname, '.xlsx');

        % Flatten to row vectors
        prior1_Group1 = all_hmms1.hmms{1}.prior(:)';
        trans1_Group1 = all_hmms1.hmms{1}.trans(:)';
        groups_Group1 = all_hmms1.groups{1};

        prior1_Group2 = group_hmms2.hmms{1}.prior(:)';
        trans1_Group2 = group_hmms2.hmms{1}.trans(:)';
        groups1_Group2 = group_hmms2.groups{1};

        prior2_Group2 = group_hmms2.hmms{2}.prior(:)';
        trans2_Group2 = group_hmms2.hmms{2}.trans(:)';
        groups2_Group2 = group_hmms2.groups{2};

        % Add to results table
        all_param_rows(end+1, :) = {name_no_ext, '1', '1', 'Prior', mat2str(prior1_Group1)};
        all_param_rows(end+1, :) = {name_no_ext, '1', '1', 'Trans', mat2str(trans1_Group1)};
        all_param_rows(end+1, :) = {name_no_ext, '1', '1', 'Subject', mat2str(groups_Group1)};

        all_param_rows(end+1, :) = {name_no_ext, '2', '1', 'Prior', mat2str(prior1_Group2)};
        all_param_rows(end+1, :) = {name_no_ext, '2', '1', 'Trans', mat2str(trans1_Group2)};
        all_param_rows(end+1, :) = {name_no_ext, '2', '1', 'Subject', mat2str(groups1_Group2)};

        all_param_rows(end+1, :) = {name_no_ext, '2', '2', 'Prior', mat2str(prior2_Group2)};
        all_param_rows(end+1, :) = {name_no_ext, '2', '2', 'Trans', mat2str(trans2_Group2)};
        all_param_rows(end+1, :) = {name_no_ext, '2', '2', 'Subject', mat2str(groups2_Group2)};

    end
    T_all = cell2table(all_param_rows, ...
        'VariableNames', {'Source', 'GroupNum', 'Sequence', 'Type', 'Value'});

    writetable(T_all, fullfile(output_dir, sprintf('all_hmm_parameters_K=%d.xlsx', max(K))));

    % --- End log recording ---
    diary off;
end