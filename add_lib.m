function add_lib(rootDir)
    % addAllSubfolders Add all subfolders in rootDir to MATLAB path
    %
    % Example:
    % addAllSubfolders('D:\MyProject')

    if nargin < 1
    rootDir = pwd; % default = current directory
    end
    
    restoredefaultpath;
    addpath(genpath(rootDir));
    fprintf('✔ All subfolders of "%s" have been added to path.\n', rootDir);
end