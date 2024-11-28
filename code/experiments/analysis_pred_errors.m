%% Analysis of Prediction Errors for Ageing Groups
% This script analyzes prediction errors from a regression model for 
% subjects categorized into three groups: 
% 1. Subjects aging normally
% 2. Subjects aging slower than usual (younger outliers)
% 3. Subjects aging faster than usual (older outliers)
% The script calculates error distributions, fits normal distributions to
% the errors, and visualizes the results using histograms and fitted 
% probability density functions (PDFs).

clc; clear;

%% Load required data
load SelectedModels_cntd.mat
load FC_10mm_correlation_ltria_180702.mat
load Outliers.mat
load SelectedLOOMAE_cntd.mat

% Select the best model index (corresponding to model 109)
idx = 42;
best_model = SelectedModels{idx};

% Regressor (X) and target variable (Y) setup
X = fc_vector; % Regressors (predictor variables)
Y = subj_info(:, 2); % Target variable (age)
[Y, order] = sort(Y); % Sort subjects by increasing age
X = X(order, :); % Reorder regressors accordingly

% Handle outliers
original_id = subj_info(:, 1);
outlier_org_id = original_id(order(outliers(1:idx-1)));
X_rem = X(outliers(1:idx-1), :);
Y_rem = Y(outliers(1:idx-1), :);
X(outliers(1:idx-1), :) = [];
Y(outliers(1:idx-1), :) = [];

% Extract features for the best model
Xl = X(:, best_model);
Xt = Xl; 
Yt = Y;

% Train linear regression model
Mdlincv = fitlm(Xt, Yt, 'Intercept', true, 'RobustOpts', 'off');

% Re-prepare original data for predictions
load FC_10mm_correlation_ltria_180702.mat
X = fc_vector; 
Y = subj_info(:, 2); 
[Y, order] = sort(Y);
X = X(order, :);

% Predict using the model and calculate residuals
P = predict(Mdlincv, X(:, best_model));
res = P - Y;

% Separate residuals by group
kept_res = res;
kept_res(outliers(1:idx-1)) = [];
outliers_res = res(outliers(1:idx-1));
older_outliers = outliers_res(outliers_res > 0);
younger_outliers = outliers_res(outliers_res < 0);

% Define bin edges for histograms
min_val = min(younger_outliers);
max_val = max(older_outliers);
range = max_val - min_val;
bin_n = round(range / 2);
edges = min_val + (0:bin_n) * 2;
edges = [edges max_val];

%% Count frequencies for each group
older_counter = histcounts(older_outliers, edges);
kept_counter = histcounts(kept_res, edges);
younger_counter = histcounts(younger_outliers, edges);

% Fit normal distributions to residuals
pd1 = fitdist(older_outliers, 'Normal');
pd2 = fitdist(younger_outliers, 'Normal');
pd3 = fitdist(kept_res, 'Normal');

% Generate PDF values for visualization
x1 = min(older_outliers)-10:max_val+10;
x2 = min_val-10:max(younger_outliers)+10;
x3 = min(kept_res)-10:max(kept_res)+10;
y1 = pdf(pd1, x1) * sum(older_counter) * 2;
y2 = pdf(pd2, x2) * sum(younger_counter) * 2;
y3 = pdf(pd3, x3) * sum(kept_counter) * 2;

%% Plot stacked histogram with PDFs
figure();
hold on;
hist_data = [older_counter; younger_counter; kept_counter];
bar(edges(1:end-1), hist_data', 'stacked', 'BarWidth', 1, 'FaceAlpha', 0.2);
plot(x1, y1, 'Color', [0, 0, 1], 'LineWidth', 2);
plot(x2, y2, 'Color', [0, 0.5, 0], 'LineWidth', 2);
plot(x3, y3, 'Color', [0.85, 0.325, 0.098], 'LineWidth', 2);
xlabel('Prediction Error');
ylabel('Frequency');
legend('Older Outliers', 'Younger Outliers', 'Normal Ageing');
hold off;

%% Plot PDFs only
figure();
hold on;
plot(x1, y1, 'Color', [0, 0, 1], 'LineWidth', 2);
plot(x2, y2, 'Color', [0, 0.5, 0], 'LineWidth', 2);
plot(x3, y3, 'Color', [0.85, 0.325, 0.098], 'LineWidth', 2);
xlabel('Prediction Error');
ylabel('Frequency');
legend('Older Outliers PDF', 'Younger Outliers PDF', 'Normal Ageing PDF');
hold off;
