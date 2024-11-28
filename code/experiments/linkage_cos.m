function [R, cluster, D] = linkage_cos(x, f1, stop_features)
    % linkage_cos: Performs hierarchical clustering based on cosine similarity.

    % Number of features and initialization
    n_feat = size(x, 1); % Number of feature vectors
    feat_id = 1:n_feat; % Feature indices
    cluster = f1; % Initial cluster (contains only f1)

    % Preallocate and compute pairwise cosine similarity matrix
    D = zeros(n_feat, n_feat); % Pairwise cosine distances
    for i = 1:n_feat - 1
        for j = i + 1:n_feat
            % Compute cosine similarity between feature i and j
            D(j, i) = dot(x(j, :), x(i, :)) / (sqrt(sum(x(j, :).^2)) * sqrt(sum(x(i, :).^2)));
        end
        % Display progress every 1000 rows
        if rem(i, 1000) == 0
            disp(['Worked on row ' num2str(i)]);
        end
    end
    disp('Finished calculating pairwise correlations');

    % Hierarchical clustering loop
    while isempty(intersect(cluster, stop_features))
        % Identify remaining features not in the cluster
        rem_feat = feat_id;
        rem_feat(cluster) = []; % Exclude already clustered features

        % Compute cosine distances for remaining features
        dist = zeros(1, length(rem_feat));
        for i = 1:length(rem_feat)
            if f1 > rem_feat(i)
                dist(i) = D(f1, rem_feat(i));
            else
                dist(i) = D(rem_feat(i), f1);
            end
        end

        % Find the feature with the smallest cosine distance
        [~, I] = min(acosd(dist)); % Use acosd to convert similarity to distance
        disp([num2str(rem_feat(I)) ' cluster size ' num2str(length(cluster)) ...
            ' feature pool size ' num2str(length(rem_feat))]);

        % Update the linkage matrix R
        if length(cluster) == 1
            R = [1, 2, min(acosd(dist))];
        else
            R = [R; (length(cluster) - 1), length(cluster) + 1, min(acosd(dist))];
        end

        % Add the selected feature to the cluster
        cluster = [cluster, rem_feat(I)];
    end

    % Adjust linkage matrix indexing
    R(2:end, 1) = R(2:end, 1) + length(cluster);
end