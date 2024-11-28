% This script performs agglomerative clustering and related analyses on features
% extracted from a dataset to identify meaningful patterns and relationships.

clc; clear;
delete(gcp('nocreate')); % Close any existing parallel pool

% Initialize Parallel Pool
myCluster = parcluster('local');
N = myCluster.NumWorkers;

% Load Required Data
load SelectedModels_cntd.mat;  % Previously selected models
load FC_10mm_correlation_ltria_180702.mat; % Dataset of feature correlations
load Outliers.mat;            % Indices of outliers
load SelectedLOOMAE_cntd.mat; % Leave-One-Out Mean Absolute Error data

% Configuration Parameters
idx = 42; % Index of the model to analyze
best_model = SelectedModels{idx}; % Extract the best model based on index

% Data Preprocessing
X = fc_vector;               % Predictors (features) - one subject per row
Y = subj_info(:, 2);         % Target variable (age) - one subject per row
[Y, order] = sort(Y);        % Sort subjects by increasing age
X = X(order, :);             % Reorder predictors to match sorted target variable

% Load Additional Feature Data
load older_selected_regressors.mat; % Features selected for older subjects
[~, idx_min] = min(LOOMAE(1:23));
older_features = SelectedRegressors{idx_min}';

load younger_selected_regressors.mat; % Features selected for younger subjects
[~, idx_min] = min(LOOMAE(1:18));
younger_features = SelectedRegressors{idx_min}';

% Cluster Analysis
stop_features = [best_model; older_features; younger_features];
stop_features = unique(stop_features); % Ensure unique features

% Load Precomputed Distances
load distances.mat;
dist = zeros(1, size(D, 1)); % Initialize distance array
feat_id = 1:size(D, 1);      % Feature indices

% Calculate Cosine Similarity Distances
for i = 1:size(D, 1)
    if i > stop_features(1)
        dist(i) = D(i, stop_features(1));
    elseif i == stop_features(1)
        dist(i) = 1;
    else
        dist(i) = D(stop_features(1), i);
    end
end

dist = acosd(dist);          % Convert to angles (degrees)
[dist, order] = sort(dist);  % Sort distances
feat_id = feat_id(order);

% Highlight Specific Features in the Plot
n_normal_features = length(best_model);
n_older_features = length(older_features);
n_younger_features = length(younger_features);

figure();
hold on;
plot(dist, 'LineWidth', 1.0); % Plot distances
scatter(1:n_normal_features, dist(1:n_normal_features), 42, 'r*', 'LineWidth', 1.7);
scatter(n_normal_features + 1:n_normal_features + n_older_features, ...
    dist(n_normal_features + 1:n_normal_features + n_older_features), ...
    42, [0.4660 0.6740 0.1880], 'd', 'LineWidth', 1.7);
scatter(n_normal_features + n_older_features + 1:end, ...
    dist(n_normal_features + n_older_features + 1:end), ...
    42, [0.4940 0.1840 0.5560], 'LineWidth', 1.7);

% Finalize Plot
legend('Linkage', 'Model 135', 'Older Features', 'Younger Features');
xlabel('Features');
ylabel('Angle (deg)');
title('Feature Distance Analysis');
saveas(gcf, 'Feature_Distance_Analysis.pdf'); % Save plot as PDF