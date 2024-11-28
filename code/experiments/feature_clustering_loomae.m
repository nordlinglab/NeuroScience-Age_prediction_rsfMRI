function [R, cluster, D] = linkage_loomae(x, f1, stop_features)
    % LINKAGE_LOOMAE - Performs feature clustering using leave-one-out MAE (LOOMAE).
    % 
    % Inputs:
    %   x             - Input feature set matrix.
    %   f1            - Initial feature to start clustering.
    %   stop_features - Features that stop the clustering process.
    %
    % Outputs:
    %   R       - Cluster linkage information.
    %   cluster - Selected feature cluster.
    %   D       - LOOMAE distances for all features.
    %
    % The function identifies clusters of features based on their contribution to
    % predicting residuals of the target variable, using LOOMAE as a metric.

    % Load required data and model information
    load SelectedModels_cntd.mat; % Precomputed selected models
    load FC_10mm_correlation_ltria_180702.mat; % Feature and target data
    load Outliers.mat; % Identified outliers

    % Initialization
    n_feat = size(x, 1); % Number of features
    feat_id = 1:n_feat;  % Feature indices
    idx = 42;           % Model index for reference
    best_model = SelectedModels{idx}; % Load the best model's features

    % Prepare predictors and response
    X = fc_vector; % Feature matrix (predictors)
    Y = subj_info(:, 2); % Target variable (e.g., age)
    [Y, order] = sort(Y); % Sort subjects by increasing target variable
    X = X(order, :);      % Reorder predictors to match target sorting

    % Handle previously identified outliers
    X_rem = X(outliers(1:idx - 1), :);
    Y_rem = Y(outliers(1:idx - 1), :);
    X_lm135 = X(:, best_model);
    Y_lm135 = Y;
    X_lm135(outliers(1:idx - 1), :) = [];
    Y_lm135(outliers(1:idx - 1), :) = [];

    % Train the regression model
    Mdlincv = fitlm(X_lm135, Y_lm135, 'Intercept', true, 'RobustOpts', 'off');
    disp('Finished training model 135.');

    % Predict and calculate residuals
    kept_res = predict(Mdlincv, X_lm135) - Y_lm135;
    outliers_res = predict(Mdlincv, X_rem(:, best_model)) - Y_rem;

    % Separate outliers into older and younger categories
    Y_older_outliers = outliers_res(outliers_res > 0);
    Y_younger_outliers = outliers_res(outliers_res < 0);
    X_older_outliers = X_rem(outliers_res > 0, :);
    X_younger_outliers = X_rem(outliers_res < 0, :);

    % Load additional feature information
    load Model135added_features_older.mat; % Older group features
    older_features = rem_feat(40:end);
    load Model135added_features_younger.mat; % Younger group features
    younger_features = rem_feat(40:end);

    % Determine feature group (older/younger) for the starting feature
    if ismember(f1, older_features)
        features = older_features;
        features(features == f1) = []; % Remove starting feature from pool
        disp(['Working with features: ', num2str(features')]);
        LOOMAE = compute_loomae(X_older_outliers, Y_older_outliers, features, n_feat);
        D = LOOMAE;
    elseif ismember(f1, younger_features)
        features = younger_features;
        features(features == f1) = []; % Remove starting feature from pool
        disp(['Working with features: ', num2str(features')]);
        LOOMAE = compute_loomae(X_younger_outliers, Y_younger_outliers, features, n_feat);
        D = LOOMAE;
    else
        disp('Selected feature is not in the younger or older feature sets.');
        return;
    end

    % Start clustering process
    [~, I] = min(LOOMAE); % Start cluster with the feature having min LOOMAE
    cluster = I;
    R = [];
    while isempty(intersect(cluster, stop_features))
        rem_feat = feat_id;
        rem_feat(cluster) = []; % Remaining features
        dist = LOOMAE(rem_feat); % Distances to remaining features
        [~, I] = min(dist); % Find closest feature

        % Update cluster and linkage information
        disp(['Adding feature ', num2str(rem_feat(I)), ...
              ' | Cluster size: ', num2str(length(cluster)), ...
              ' | Feature pool size: ', num2str(length(rem_feat))]);
        if length(cluster) == 1
            R = [1 2 min(dist)];
        else
            R = [R; (length(cluster) - 1) length(cluster) + 1 min(dist)];
        end
        cluster = [cluster, rem_feat(I)];
    end
    R(2:end, 1) = R(2:end, 1) + length(cluster); % Adjust linkage indices
end

function LOOMAE = compute_loomae(X_group, Y_group, features, n_feat)
    % Compute LOOMAE for feature selection
    LOOMAE = zeros(1, n_feat);
    no_subj = length(Y_group); % Number of subjects
    for i = 1:n_feat
        train_features = [features; i];
        Ylin = zeros(no_subj, 1);
        for leftout = 1:no_subj
            X_train = X_group(:, train_features);
            X_train(leftout, :) = [];
            Y_train = Y_group;
            Y_train(leftout) = [];
            Mdlincv = fitlm(X_train, Y_train, 'Intercept', true, 'RobustOpts', 'off');
            Ylin(leftout) = predict(Mdlincv, X_group(leftout, train_features));
        end
        LOOMAE(i) = mean(abs(Ylin - Y_group'));
        if rem(i, 500) == 0
            disp(['Feature ', num2str(i), ' processed.']);
        end
    end
end
