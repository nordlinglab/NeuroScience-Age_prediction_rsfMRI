% This script performs residual analysis and feature selection using bootstrapping
% and LASSO regression for regression problems.

clc; clear;

% Close existing parallel pool
delete(gcp('nocreate'))

% Set up parallel processing
myCluster = parcluster('local');
N = myCluster.NumWorkers;
parpool(myCluster, N);

% Load required data
load SelectedModels_cntd.mat
load FC_10mm_correlation_ltria_180702.mat
load Outliers.mat
load cutNrTimesSelected_cntd.mat
load nrTimesSelected_cntd.mat
load SelectedLOOMAE_cntd.mat

% Select model index and corresponding regressors
idx = 42; % Corresponding to model 135
best_model = SelectedModels{idx};

% Prepare predictor (X) and target (Y) variables
X = fc_vector; % Predictors (features), one subject per row
Y = subj_info(:, 2); % Target variable (age), one subject per row
[Y, order] = sort(Y); % Sort subjects by increasing age
X = X(order, :);

% Real index tracking for outliers
real_idx = subj_info(:, 1);
real_idx = real_idx(order(outliers(1:idx-1)));

% Remove outliers from X and Y
X_rem = X(outliers(1:idx-1), :);
Y_rem = Y(outliers(1:idx-1), :);
X(outliers(1:idx-1), :) = [];
Y(outliers(1:idx-1), :) = [];

% Extract the predictors for the selected model
Xl = X(:, best_model);

% Fit a linear model for residual analysis
Mdlincv = fitlm(Xl, Y, 'Intercept', true, 'RobustOpts', 'off');

% Predict and calculate residuals for removed subjects
P = predict(Mdlincv, X_rem(:, best_model));
all_outliers_res = P - Y_rem;

% Filter residuals based on a specific condition (e.g., negative residuals)
condition = find(all_outliers_res < 0); % Change condition as needed
real_idx = real_idx(condition);
X_rem = X_rem(condition, :);
Y_rem = Y_rem(condition, :);
selected_outliers_res = all_outliers_res(condition);

% Initialize feature selection parameters
f = 1:length(X(1, :)); % All feature indices
rem_feat = best_model; % Features in the current model
features = setdiff(f, rem_feat); % Remaining features
no_subj = size(X_rem, 1); % Number of subjects for analysis
nrTimesSelected = zeros([length(features), 1]); % Feature selection counter

% Set target variable to residuals of selected outliers
Y_rem = selected_outliers_res;

% Bootstrapping and LASSO regression for feature selection
disp('Starting feature selection with bootstrapping...')
nrTimesSelected_checkpoints = []; % Store checkpoints during bootstrapping

for i = 1:3000
    % Bootstrap sampling
    Random_index = ceil(no_subj * rand(1, no_subj));
    BootstrappedData = X_rem(Random_index, features);

    % LASSO regression with cross-validation
    [Theta{i}, FitInfo{i}] = lassoglm(BootstrappedData, Y_rem(Random_index), ...
        'normal', 'Alpha', 1, 'CV', 5, 'DFmax', size(X, 1) - 1, ...
        'Options', statset('UseParallel', true));

    disp(['Iteration: ', num2str(i)]);

    % Update feature selection count
    indMinimumDeviance = FitInfo{i}.IndexMinDeviance;
    for j = indMinimumDeviance:size(Theta{i}, 2)
        nrTimesSelected(find(Theta{i}(:, j))) = ...
            nrTimesSelected(find(Theta{i}(:, j))) + 1;
    end

    % Save checkpoints every 100 iterations
    if mod(i, 100) == 0
        nrTimesSelected_checkpoints = [nrTimesSelected_checkpoints, nrTimesSelected];
        save nrTimesSelected_younger nrTimesSelected_checkpoints i
    end
end

% Save feature selection results
save nrTimesSelected_younger nrTimesSelected
cutNrTimesSelected = sort(unique(nrTimesSelected), 'descend');
save cutNrTimesSelected_younger cutNrTimesSelected

% Leave-One-Out Cross-Validation (LOOCV) for selected features
disp('Performing LOOCV for feature evaluation...');
NrRegressors = zeros(1, length(cutNrTimesSelected) - 1);
LOOMAE = zeros(1, length(cutNrTimesSelected) - 1);

for i = 1:length(cutNrTimesSelected) - 1
    SelectedRegressors{i} = features(find(nrTimesSelected >= cutNrTimesSelected(i)));
    NrRegressors(i) = length(SelectedRegressors{i});

    Ylin = zeros(no_subj, 1);

    for leftout = 1:no_subj
        X_train = X_rem(:, SelectedRegressors{i});
        X_train(leftout, :) = [];
        Y_train = Y_rem;
        Y_train(leftout) = [];

        % Fit linear model and predict
        Mdl = fitlm(X_train, Y_train, 'Intercept', true, 'RobustOpts', 'off');
        Ylin(leftout) = predict(Mdl, X_rem(leftout, SelectedRegressors{i}));
    end

    % Calculate mean absolute error
    LOOMAE(i) = mean(abs(Ylin - Y_rem));
end

% Plot Number of Regressors vs LOOMAE
figure;
plot(NrRegressors, LOOMAE, 'LineWidth', 1.2);
xlabel('Number of Regressors');
ylabel('Leave-One-Out MAE');
title('Number of Regressors vs LOOMAE');
saveas(gcf, 'Regressors_vs_LOOMAE.pdf');

% Save final results
save('Feature_Selection_Results.mat', 'SelectedRegressors', 'LOOMAE', 'NrRegressors', 'cutNrTimesSelected');
disp('Feature selection and evaluation complete!');