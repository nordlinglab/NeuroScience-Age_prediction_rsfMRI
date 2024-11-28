% Initialize workspace
clc;
clear;

% Parallel processing setup
myCluster = parcluster('local'); % Create cluster for parallel processing
N = myCluster.NumWorkers; % Number of workers in the cluster
% Uncomment the line below to start the parallel pool
% parpool(myCluster, N);

% Load required data
load FC_10mm_correlation_ltria_180702.mat; % Functional connectivity data
load Outliers; % Predefined outliers
load nrTimesSelected_cntd; % Selected regressors from previous runs
load cutNrTimesSelected_cntd; % Thresholded selection frequencies
load SelectedModels_cntd; % Best models from previous runs
load SelectedLOOMAE_cntd; % Leave-One-Out Mean Absolute Errors (LOO MAE)

% Output path for saving results
resultsPath = fullfile(pwd, 'Results');

% Set global subject ID
global_id = 1:size(fc_vector, 1);

% Initialize subject reduction tracking
NrSub = 176:-1:(177 - length(outliers));

% Main iterative algorithm to find outliers
while length(outliers) < 100
    % Reload original data to ensure integrity
    load FC_10mm_correlation_ltria_180702.mat;

    % Define predictors (X) and target variable (Y)
    X = fc_vector; % Predictor variables (regressors)
    Y = subj_info(:, 2); % Target variable (age)
    [Y, order] = sort(Y); % Sort subjects by age
    X = X(order, :);

    % Exclude known outliers from the dataset
    X(outliers, :) = [];
    Y(outliers, :) = [];
    
    % Number of remaining subjects
    no_subj = size(X, 1);

    % Track remaining subject IDs
    remain = setdiff(global_id, outliers);

    % Initialize storage for bootstrap selection frequencies
    nrTimesSelected{length(outliers) + 1} = zeros(size(X, 2), 1);

    % Bootstrap sampling and feature selection
    for i = 1:100
        Random_index = ceil(no_subj * rand(1, no_subj));
        BootstrappedData = X(Random_index, :);
        [Theta{i}, FitInfo{i}] = lassoglm(BootstrappedData, Y(Random_index), 'normal', ...
            'Alpha', 1, 'CV', 5, 'DFmax', no_subj - 1, 'Options', statset('UseParallel', true));
        
        disp(['Iteration ', num2str(i), ', Subjects left: ', num2str(176 - length(outliers))]);
        indMinimumDeviance = FitInfo{i}.IndexMinDeviance;

        % Count frequency of selected features
        for j = indMinimumDeviance:size(Theta{i}, 2)
            nrTimesSelected{length(outliers) + 1}(find(Theta{i}(:, j))) = ...
                nrTimesSelected{length(outliers) + 1}(find(Theta{i}(:, j))) + 1;
        end
    end

    % Save updated frequency data
    save(fullfile(resultsPath, 'nrTimesSelected_cntd.mat'), 'nrTimesSelected');

    % Threshold selected regressors
    cutNrTimesSelected{length(outliers) + 1} = sort(unique(nrTimesSelected{length(outliers) + 1}), 'descend');
    save(fullfile(resultsPath, 'cutNrTimesSelected_cntd.mat'), 'cutNrTimesSelected');

    % Leave-One-Out Cross-Validation (LOO CV) for feature selection
    NrRegressors = zeros(1, length(cutNrTimesSelected{length(outliers) + 1}) - 1);
    for i = 1:length(cutNrTimesSelected{length(outliers) + 1}) - 1
        SelectedRegressors{i} = find(nrTimesSelected{length(outliers) + 1} >= cutNrTimesSelected{length(outliers) + 1}(i));
        NrRegressors(i) = length(SelectedRegressors{i});

        % Predict age using LOO CV
        Ylin = zeros(no_subj, 1);
        for leftout = 1:no_subj
            X_train = X(:, SelectedRegressors{i});
            X_test = X_train(leftout, :);
            X_train(leftout, :) = [];
            Y_train = Y;
            Y_train(leftout) = [];

            Model = fitlm(X_train, Y_train, 'Intercept', true, 'RobustOpts', 'off');
            Ylin(leftout) = predict(Model, X_test);
        end

        % Calculate LOO MAE
        LOOMAE(i) = mean(abs(Ylin - Y));
    end

    % Plot LOO MAE vs Number of Regressors
    figure;
    plot(NrRegressors, LOOMAE);
    xlabel('Number of Regressors');
    ylabel('Leave-One-Out MAE');
    saveas(gcf, fullfile(resultsPath, ['NoRegressors_vs_LOOMAE_', num2str(no_subj), '.pdf']));

    % Select the best model
    BestModel = SelectedRegressors{find(LOOMAE == min(LOOMAE))};
    SelectedModels{length(outliers) + 1} = BestModel;
    save(fullfile(resultsPath, 'SelectedModels_cntd.mat'), 'SelectedModels');

    % Fit the best model and calculate residuals
    BestModelFit = fitlm(X(:, BestModel), Y, 'Intercept', true, 'RobustOpts', 'off');
    Yhat = predict(BestModelFit);
    R = abs(Yhat - Y);

    % Update outliers and save results
    candidate_outlier = find(R == max(R));
    outliers = [outliers, remain(candidate_outlier)];
    save(fullfile(resultsPath, 'Outliers.mat'), 'outliers');

    % Update performance metrics
    NrSub(length(outliers) + 1) = no_subj;
    SelectedLOOMAE(length(outliers) + 1) = min(LOOMAE);
    save(fullfile(resultsPath, 'SelectedLOOMAE_cntd.mat'), 'SelectedLOOMAE');

    % Plot current performance
    figure;
    plot(NrSub, SelectedLOOMAE);
    xlabel('Number of Subjects');
    ylabel('Selected LOO MAE');
    saveas(gcf, fullfile(resultsPath, 'Current_NoSubj_vs_sel_LOOMAE.pdf'));
end