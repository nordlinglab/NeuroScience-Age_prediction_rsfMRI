% Function: ID2BrainRegion
% Purpose:
%   This function identifies the brain regions corresponding to a given
%   feature index in a connectivity matrix. It maps the feature ID to a
%   pair of brain regions (row and column indices) and associates them 
%   with pre-defined brain network categories.
function [R1, R2] = ID2BrainRegion(x)

    % Define the number of nodes in the brain connectivity matrix
    NN = 264; 
    M1 = zeros(NN, NN); % Initialize an NN x NN matrix
    aux = 1; % Counter for feature indexing

    % Create a lower triangular feature mapping matrix
    for i = 1:NN-1
        for j = i+1:NN
            M1(j, i) = aux;
            aux = aux + 1;
        end
    end

    % Find the row and column indices corresponding to the feature index
    [r, c] = find(M1 == x);

    % Define brain network categories and their associated indices
    Motor = [13:41, 255];
    CON = [47:60];
    Aud = [61:73];
    DMN = [74:83, 86:131, 137, 139];
    Vis = [143:173];
    FPN = [174:181, 186:202];
    SAN = [203:220];
    Subc = [222:234];
    VAN = [235:242];
    DAN = [251:252, 256:264];

    % Organize the brain networks and their names
    networks_id = {Motor, CON, Aud, DMN, Vis, FPN, SAN, Subc, VAN, DAN};
    networks_names = {'Motor', 'CON', 'Aud', 'DMN', 'Vis', 'FPN', 'SAN', 'Subc', 'VAN', 'DAN'};

    % Determine the brain network for the row index
    R1 = findBrainRegion(r, networks_id, networks_names);

    % Determine the brain network for the column index
    R2 = findBrainRegion(c, networks_id, networks_names);

end

% Helper Function: findBrainRegion
% Purpose:
%   Identifies the brain network name corresponding to an index.
%
% Input:
%   - idx: The index to check.
%   - networks_id: Cell array of brain network indices.
%   - networks_names: Cell array of brain network names.
%
% Output:
%   - regionName: The name of the brain network or the raw index as a string.
function regionName = findBrainRegion(idx, networks_id, networks_names)
    regionName = num2str(idx); % Default to the raw index
    for i = 1:length(networks_id)
        if ismember(idx, networks_id{i})
            regionName = networks_names{i};
            break;
        end
    end
end