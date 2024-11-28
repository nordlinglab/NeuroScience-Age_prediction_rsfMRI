clc; clear;

% Load required datasets
load SelectedModels_cntd.mat
load FC_10mm_correlation_ltria_180702.mat
load Outliers.mat
load cutNrTimesSelected_cntd.mat
load nrTimesSelected_cntd.mat
load SelectedLOOMAE_cntd.mat

% Index corresponding to model 109
idx = 68; 
best_model = SelectedModels{idx};

% Prepare Data
X = fc_vector; % Predictors (features), one row per subject
Y = subj_info(:, 2); % Target variable (age)
[Y, order] = sort(Y); % Sort subjects by increasing age
X = X(order, :);

% Identify and remove outliers
real_idx = subj_info(:, 1); 
real_idx = real_idx(order(outliers(1:idx - 1)));

X_rem = X(outliers(1:idx - 1), :); 
Y_rem = Y(outliers(1:idx - 1), :);
X(outliers(1:idx - 1), :) = [];
Y(outliers(1:idx - 1), :) = [];

% Prepare selected features
Xl = X(:, best_model);
Xt = Xl; 
Yt = Y;

% Fit the initial model
Mdlincv = fitlm(Xt, Yt, 'Intercept', true, 'RobustOpts', 'off');

% Filter for subjects older than 50
sigma = 48;
older_outliers = outliers(Y_rem < sigma);
real_idx = real_idx(Y_rem < sigma);
X_rem = X_rem(Y_rem < sigma, :); 
Y_rem = Y_rem(Y_rem < sigma, :);

% Predict residuals and filter based on a condition
P = predict(Mdlincv, X_rem(:, best_model));
res = P - Y_rem;

% Condition to explore: residuals greater than 0
condition = find(res > 0);
older_outliers = older_outliers(condition);
real_idx = real_idx(condition);
X_rem = X_rem(condition, :); 
Y_rem = Y_rem(condition, :);

% Residual storage for iterative feature testing
r_dem = cell(1, 5);
r_dem{1} = res(condition);

% Feature set initialization
f = 1:length(X(1, :)); 
rem_feat = best_model;
features = setdiff(f, rem_feat);

% Iterative feature testing to reduce residuals
for j = 1:10
    res = cell(1, length(features));
    LOOMAE = zeros(1, length(features));
    
    % Test each feature
    for i = 1:length(features)
        for leftout = 1:length(r_dem{1})
            Xl = X_rem(:, features(i));
            Xt = Xl; 
            Xt(leftout, :) = [];
            Yt = r_dem{j}; 
            Yt(leftout) = [];
            Mdlincv = fitlm(Xt, Yt, 'Intercept', true, 'RobustOpts', 'off');
            Pred(leftout) = predict(Mdlincv, Xl(leftout, :));
        end
        Pred = reshape(Pred, length(Pred), 1);
        res{i} = Pred - r_dem{j};
        LOOMAE(i) = mean(abs(res{i}));
    end
    
    % Select the best feature
    [~, min_idx] = min(LOOMAE);
    rem_feat = [rem_feat; features(min_idx)];
    features = setdiff(f, rem_feat);
    
    % Train model with selected features
    Mdlincv = fitlm(X_rem(:, min_idx), r_dem{j}, 'Intercept', true, 'RobustOpts', 'off');
    Pred = predict(Mdlincv, X_rem(:, min_idx));
    r_dem{j + 1} = (Pred - r_dem{j});
    
    % Stop if LOOMAE improves
    if mean(abs(Pred - r_dem{j})) < SelectedLOOMAE(idx)
        break;
    end
end

% Output updated residuals and added features
r_dem = r_dem(~cellfun('isempty', r_dem));
Age = cell(1, length(r_dem));
for i = 1:length(r_dem)
    Age{i} = Y_rem + r_dem{i};
end

% Save results
% save ModelUpdated rem_feat Sel_LOOMAE r_dem Age

% Map features to brain regions (example mapping logic below)
NN = 264;
M1 = zeros(NN, NN);
aux = 1;
for i = 1:NN - 1
    for j = i + 1:NN
        M1(j, i) = aux;
        aux = aux + 1;
    end
end
% Example feature mapping
[r, c] = find(M1 == 26171);