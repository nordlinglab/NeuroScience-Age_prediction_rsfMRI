% Cleaned and Documented MATLAB Code for Outlier Detection and Regressor Selection
clc; clear;

% Set up parallel processing
myCluster = parcluster('local');
N = myCluster.NumWorkers;
parpool(myCluster, N);

% Load initial data
load FC_10mm_correlation_ltria_180702.mat;
path = fullfile(pwd, 'Results'); % Directory for saving results

% Initialize variables
global_id = 1:no_subj; % Global subject indices
outliers = []; % Initial empty list of outliers
save Outliers outliers

% Loop until a maximum of 40 outliers are identified
while length(outliers) < 40
    % Reload data to reset for each iteration
    load FC_10mm_correlation_ltria_180702.mat;
    X = fc_vector; % Predictors (features) - one subject per row
    Y = subj_info(:, 2); % Target variable (age) - one subject per row
    [Y, order] = sort(Y); % Sort subjects by increasing age
    X = X(order, :); % Reorder predictors to match sorted age

    % Remove previously identified outliers
    load Outliers;
    X(outliers, :) = [];
    Y(outliers, :) = [];
    no_subj = size(X, 1); % Number of remaining subjects
    remain = setdiff(global_id, outliers); % Indices of non-outlier subjects

    % Initialize storage for selected regressors
    nrTimesSelected{length(outliers) + 1} = zeros(34716, 1);

    % Perform bootstrap sampling and lasso regression
    for i = 1:100
        % Bootstrap sampling
        Random_index = ceil(no_subj * rand(1, no_subj));
        BootstrappedData = X(Random_index, :);
        
        % Lasso regression with cross-validation
        [Theta{i}, FitInfo{i}] = lassoglm(BootstrappedData, Y(Random_index), ...
            'normal', 'Alpha', 1, 'CV', 5, ...
            'DFmax', size(X, 1) - 1, ...
            'Options', statset('UseParallel', true));
        
        disp(['Iteration: ', num2str(i), ', Subjects Remaining: ', num2str(no_subj - length(outliers))]);

        % Count occurrences of selected regressors
        for j = FitInfo{i}.IndexMinDeviance:size(Theta{i}, 2)
            nrTimesSelected{length(outliers) + 1}(find(Theta{i}(:, j))) = ...
                nrTimesSelected{length(outliers) + 1}(find(Theta{i}(:, j))) + 1;
        end
    end

    % Save the regressor selection frequency
    save nrTimesSelected nrTimesSelected;
    cutNrTimesSelected{length(outliers) + 1} = sort(unique(nrTimesSelected{length(outliers) + 1}), 'descend');
    save cutNrTimesSelected cutNrTimesSelected;

    % Evaluate models with selected regressors
    NrRegressors = zeros(1, length(cutNrTimesSelected{length(outliers) + 1}) - 1);
    for i = 1:length(cutNrTimesSelected{length(outliers) + 1}) - 1
        SelectedRegressors{i} = find(nrTimesSelected{length(outliers) + 1} >= cutNrTimesSelected{length(outliers) + 1}(i));
        NrRegressors(i) = length(SelectedRegressors{i});

        % Leave-one-out cross-validation
        Ylin = zeros(no_subj, 1);
        for leftout = 1:no_subj
            X_train = X(:, SelectedRegressors{i});
            X_train(leftout, :) = [];
            Y_train = Y;
            Y_train(leftout) = [];
            
            Mdl = fitlm(X_train, Y_train, 'Intercept', true, 'RobustOpts', 'off');
            Ylin(leftout) = predict(Mdl, X(leftout, SelectedRegressors{i}));
        end
        LOOMAE(i) = mean(abs(Ylin - Y)); % Mean absolute error
    end

    % Plot Leave-One-Out MAE vs Number of Regressors
    figure;
    plot(NrRegressors, LOOMAE);
    xlabel('Number of Regressors');
    ylabel('Leave-One-Out MAE');
    saveas(gcf, fullfile(path, ['NoRegressors_vs_LOOMAE_', num2str(no_subj), '.pdf']));

    % Identify the best model and update outliers
    [~, bestIndex] = min(LOOMAE);
    BestModel = SelectedRegressors{bestIndex};
    SelectedModels{length(outliers) + 1} = BestModel;
    save SelectedModels SelectedModels;

    % Fit the best model and identify the outlier
    MdlFinal = fitlm(X(:, BestModel), Y, 'Intercept', true, 'RobustOpts', 'off');
    Yhat = predict(MdlFinal);
    R = abs(Yhat - Y); % Absolute errors
    candidate_outlier = find(R == max(R));
    outliers = [outliers, remain(candidate_outlier)];
    save Outliers outliers;

    % Update subject count and selected LOOMAE
    NrSub(length(outliers) + 1) = no_subj;
    SelectedLOOMAE(length(outliers) + 1) = min(LOOMAE);

    % Plot Number of Subjects vs Selected LOOMAE
    figure;
    plot(NrSub, SelectedLOOMAE);
    xlabel('Number of Subjects');
    ylabel('Selected Leave-One-Out MAE');
    title('Subjects vs Selected LOOMAE');
    saveas(gcf, fullfile(path, 'Current_NoSubj_vs_sel_LOOMAE.pdf'));

    % Clear temporary variables
    clear SelectedRegressors LOOMAE;
end

% Final plot of Number of Subjects vs Selected LOOMAE
figure;
plot(NrSub, SelectedLOOMAE);
xlabel('Number of Subjects');
ylabel('Selected Leave-One-Out MAE');
saveas(gcf, fullfile(path, ['NoSubj_vs_sel_LOOMAE_', num2str(no_subj), '.pdf']));
save SelectedLOOMAE SelectedLOOMAE;