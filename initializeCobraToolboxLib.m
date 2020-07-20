function initializeCobraToolboxLib()
%      _____   _____   _____   _____     _____     |
%     /  ___| /  _  \ |  _  \ |  _  \   / ___ \    |   COnstraint-Based Reconstruction and Analysis
%     | |     | | | | | |_| | | |_| |  | |___| |   |   The COBRA Toolbox - 2017
%     | |     | | | | |  _  { |  _  /  |  ___  |   |
%     | |___  | |_| | | |_| | | | \ \  | |   | |   |   Documentation:
%     \_____| \_____/ |_____/ |_|  \_\ |_|   |_|   |   http://opencobra.github.io/cobratoolbox
%                                                  |
%
%     initCobraToolbox Initialize COnstraint-Based Reconstruction and Analysis Toolbox
%
%     Defines default solvers and paths, tests SBML io functionality.
%     Function only needs to be called once per installation. Saves paths afer script terminates.
%
%     In addition add either of the following into startup.m (generally in MATLAB_DIRECTORY/toolbox/local/startup.m)
%
%     initCobraToolbox
%           -or-
%     changeCobraSolver('gurobi');
%     changeCobraSolver('gurobi', 'MILP');
%     changeCobraSolver('tomlab_cplex', 'QP');
%     changeCobraSolver('tomlab_cplex', 'MIQP');
%     changeCbMapOutput('svg');
%
%     Maintained by Ronan M.T. Fleming, Sylvain Arreckx, Laurent Heirendt

    % define GLOBAL variables
    global CBTDIR;
    global SOLVERS;
    global OPT_PROB_TYPES;
    global CBT_LP_SOLVER;
    global CBT_MILP_SOLVER;
    global CBT_QP_SOLVER;
    global CBT_MIQP_SOLVER;
    global CBT_NLP_SOLVER;
    global GUROBI_PATH;
    global ILOG_CPLEX_PATH;
    global TOMLAB_PATH;
    global MOSEK_PATH;
    global WAITBAR_TYPE;
    global ENV_VARS;
    global gitBashVersion;
    global CBT_MISSING_REQUIREMENTS_ERROR_ID;

    saveCobraPath = 0;
    if ~exist('updateToolbox','var')
        updateToolbox = false;
    end
    % define a base version of gitBash that is tested
    gitBashVersion = '2.13.3';

     % Set the Requirements Error Message ID:
    CBT_MISSING_REQUIREMENTS_ERROR_ID = 'COBRA:RequirementsNotMet';

    % default waitbar is of type text
    if isempty(WAITBAR_TYPE)
        WAITBAR_TYPE = 1;
    end

    % Linux only - default save path location
    defaultSavePathLocation = '~/pathdef.m';

    % initialize the cell of solvers
    SOLVERS = {};

    % declare that the environment variables have not yet been configured
    ENV_VARS.STATUS = 0;

    % initialize the paths
    if exist('GUROBI_PATH', 'var') ~= 1
        GUROBI_PATH = '';
    end
    if exist('ILOG_CPLEX_PATH', 'var') ~= 1
        ILOG_CPLEX_PATH = '';
    end
    if exist('TOMLAB_PATH', 'var') ~= 1
        TOMLAB_PATH = '';
    end
    if exist('MOSEK_PATH', 'var') ~= 1
        MOSEK_PATH = '';
    end

    % print header
    if ~isfield(ENV_VARS, 'printLevel') || ENV_VARS.printLevel
        docLink = 'http://opencobra.github.io/cobratoolbox';
        if usejava('desktop')
            docLink = ['<a href=\"', docLink, '\">', docLink, '</a>'];
        end

        c = clock;
        fprintf('\n\n      _____   _____   _____   _____     _____     |\n');
        fprintf('     /  ___| /  _  \\ |  _  \\ |  _  \\   / ___ \\    |   COnstraint-Based Reconstruction and Analysis\n');
        fprintf(['     | |     | | | | | |_| | | |_| |  | |___| |   |   The COBRA Toolbox - ' num2str(c(1)) '\n']);
        fprintf('     | |     | | | | |  _  { |  _  /  |  ___  |   |\n');
        fprintf('     | |___  | |_| | | |_| | | | \\ \\  | |   | |   |   Documentation:\n');
        fprintf(['     \\_____| \\_____/ |_____/ |_|  \\_\\ |_|   |_|   |   ', docLink, '\n']);
        fprintf('                                                  | \n\n');
        ENV_VARS.printLevel = true;
    end

    % retrieve the current directory
    currentDir = pwd;

    % define the root path of The COBRA Toolbox and change to it.
    CBTDIR = fileparts(which('initCobra306'));
    cd(CBTDIR);

    % add the external install folder
    addpath(genpath([CBTDIR filesep 'external' filesep 'base' filesep 'install']));

    %And the rdir directory
    addpath(genpath([CBTDIR filesep 'external' filesep 'base' filesep 'utilities' filesep 'rdir']));

    % add the install folder
    addpath(genpath([CBTDIR filesep 'src' filesep 'base' filesep 'install']));

    % change to the root of The COBRA Tooolbox
    cd(CBTDIR);

    %get the current content of the init Folder
    dirContent = getFilesInDir('type','all');

    % add the folders of The COBRA Toolbox
    folders = {'binary', 'src', 'docs', 'test'};

    if ENV_VARS.printLevel
        fprintf(' > Adding all the files of The COBRA Toolbox ... ')
    end

    % add the root folder
    addpath(CBTDIR);

    % add the external folder
    addpath(genpath([CBTDIR filesep 'external']));

    % add specific subfolders
    for k = 1:length(folders)
        tmpDir = [CBTDIR, filesep, folders{k}];
        if exist(tmpDir, 'dir') == 7
            addpath(genpath(tmpDir));
        end
    end

    %Adapt the mac path depending on the mac version.
    if ismac
        adaptMacPath()
    end


    % Define default CB map output
    if ENV_VARS.printLevel
        fprintf(' > Define CB map output...');
    end
    for CbMapOutput = {'svg', 'matlab'}
        CbMapOutputOK = changeCbMapOutput(char(CbMapOutput));
        if CbMapOutputOK
            break;
        end
    end
    if CbMapOutputOK
        if ENV_VARS.printLevel
            fprintf(' set to %s.\n', char(CbMapOutput));
        end
    else
        if ENV_VARS.printLevel
            fprintf('FAILED.\n');
        end
    end

    % define xml test file
    xmlTestModel = 'ecoli_core_model.xml';
    xmlTestFile = [getDistributedModelFolder(xmlTestModel) filesep xmlTestModel];

    % save the userpath
    originalUserPath = path;

    % Set global LP solution accuracy tolerance
    changeCobraSolverParams('LP', 'optTol', 1e-6);

    % Check that SBML toolbox is installed and accessible
    if ~exist('TranslateSBML', 'file')
        if ENV_VARS.printLevel
            warning('libsbml binaries not on Matlab path: COBRA Toolbox will be unable to read/write SBML files');
        end
    else
        % Test the installation with:
        try
            TranslateSBML(xmlTestFile);
            if ENV_VARS.printLevel
                fprintf(' > TranslateSBML is installed and working properly.\n');
            end
        catch
            if ENV_VARS.printLevel
                warning(' > TranslateSBML is installed but is not working properly.');
                fprintf([' > Try running\n   >> TranslateSBML(\''', strrep(xmlTestFile, '\', '\\'), '\'');\n   in order to debug.\n']);
            end
        end
    end

    if ENV_VARS.printLevel
        fprintf(' > Configuring solver environment variables ...\n');
        configEnvVars(1);
        fprintf('   Done.\n');
        fprintf(' > Checking available solvers and solver interfaces ...');
    end

    % define categories of solvers: LP, MILP, QP, MIQP, NLP
    OPT_PROB_TYPES = {'LP', 'MILP', 'QP', 'MIQP', 'NLP'};

    %Define a set of "use first" solvers, other supported solvers will also be added to the struct.
    %This allows to assign them in any order but keep the most commonly used ones on top of the struct.
    SOLVERS = struct('gurobi',struct(),...
                     'ibm_cplex',struct(),...
                     'tomlab_cplex',struct(),...
                     'glpk',struct(),...
                     'mosek',struct(),...
                     'matlab',struct());
    % active support - supported solvers
    SOLVERS.cplex_direct.type = {'LP', 'MILP', 'QP'};
    SOLVERS.dqqMinos.type = {'LP'};
    SOLVERS.glpk.type = {'LP', 'MILP'};
    SOLVERS.gurobi.type = {'LP', 'MILP', 'QP', 'MIQP'};
    SOLVERS.ibm_cplex.type = {'LP', 'MILP', 'QP', 'MIQP'};
    SOLVERS.matlab.type = {'LP', 'NLP'};
    SOLVERS.mosek.type = {'LP', 'QP'};
    SOLVERS.pdco.type = {'LP', 'QP'};
    SOLVERS.quadMinos.type = {'LP'};
    SOLVERS.tomlab_cplex.type = {'LP', 'MILP', 'QP', 'MIQP'};

    % passive support - solver interfaces
    SOLVERS.qpng.type = {'QP'};
    SOLVERS.tomlab_snopt.type = {'NLP'};

    % legacy solvers
    %SOLVERS.gurobi_mex.type = {'LP', 'MILP', 'QP', 'MIQP'};
    %SOLVERS.lindo_old.type = {'LP'};
    %SOLVERS.lindo_legacy.type = {'LP'};
    SOLVERS.lp_solve.type = {'LP'};
    %SOLVERS.opti.type = {'LP', 'MILP', 'QP', 'MIQP', 'NLP'};

    % definition of category of solvers with active support
    SOLVERS.cplex_direct.categ = 'active';
    SOLVERS.dqqMinos.categ = 'active';
    SOLVERS.glpk.categ = 'active';
    SOLVERS.gurobi.categ = 'active';
    SOLVERS.ibm_cplex.categ = 'active';
    SOLVERS.matlab.categ = 'active';
    SOLVERS.mosek.categ = 'active';
    SOLVERS.pdco.categ = 'active';
    SOLVERS.quadMinos.categ = 'active';
    SOLVERS.tomlab_cplex.categ = 'active';

    % definition of category of solvers with passive support
    SOLVERS.qpng.categ = 'passive';
    SOLVERS.tomlab_snopt.categ = 'passive';

    % definition of category of solvers with legacy support
    %SOLVERS.gurobi_mex.categ = 'legacy';
    %SOLVERS.lindo_old.categ = 'legacy';
    %SOLVERS.lindo_legacy.categ = 'legacy';
    SOLVERS.lp_solve.categ = 'legacy';
    %SOLVERS.opti.categ = 'legacy';

    % definition of categories of solvers
    supportedSolversNames = fieldnames(SOLVERS);
    catSolverNames.LP = {}; catSolverNames.MILP = {}; catSolverNames.QP = {}; catSolverNames.MIQP = {}; catSolverNames.NLP = {};
    for i = 1:length(supportedSolversNames)
        SOLVERS.(supportedSolversNames{i}).installed = false;
        SOLVERS.(supportedSolversNames{i}).working = false;
        types = SOLVERS.(supportedSolversNames{i}).type;
        for j = 1:length(types)
            catSolverNames.(types{j}){end + 1} = supportedSolversNames{i};
        end
    end

    % check the installation of the solver
    for i = 1:length(supportedSolversNames)
        %We will validate all solvers in init. After this, all solvers are
        %checked, whether they actually work and the SOLVERS field is set.
        [solverOK,solverInstalled] = changeCobraSolver(supportedSolversNames{i},...
                                     SOLVERS.(supportedSolversNames{i}).type{1},...
                                     0, 2);
        if solverOK
            SOLVERS.(supportedSolversNames{i}).working = true;
        end
        SOLVERS.(supportedSolversNames{i}).installed = solverInstalled;
    end

    if ENV_VARS.printLevel
        fprintf(' Done.\n');
    end

    % set the default solver and print out the default variables
    if ENV_VARS.printLevel
        fprintf(' > Setting default solvers ...');
        changeCobraSolver('glpk', 'LP', 0);
        changeCobraSolver('glpk', 'MILP', 0);
        changeCobraSolver('qpng', 'QP', 0);
        changeCobraSolver('matlab', 'NLP', 0);
        for k = 1:length(OPT_PROB_TYPES)
            varName = horzcat(['CBT_', OPT_PROB_TYPES{k}, '_SOLVER']);
        end
        fprintf(' Done.\n');
    end

    % fill the summary table
    solverTypeInstalled = zeros(length(OPT_PROB_TYPES), 1);
    solverStatus = -1 * ones(length(supportedSolversNames), length(OPT_PROB_TYPES) + 1);
    catList = cell(length(supportedSolversNames), 1);
    for i = 1:length(supportedSolversNames)
        types = SOLVERS.(supportedSolversNames{i}).type;
        catList{i} = SOLVERS.(supportedSolversNames{i}).categ;
        for j = 1:length(types)
            k = find(ismember(OPT_PROB_TYPES, types{j}));
            if SOLVERS.(supportedSolversNames{i}).installed
                solverStatus(i, k + 1) = 1;
                solverTypeInstalled(k) = solverTypeInstalled(k) + 1;

                % set the default MIQP solver based on the solvers that are installed
                if strcmpi(types{j}, 'MIQP')
                    changeCobraSolver(supportedSolversNames{i}, types{j}, 0);
                end
            else
                solverStatus(i, k + 1) = 0;
            end
        end
    end

    catList{end + 1} = '----------';
    catList{end + 1} = '-';

    rowNames = [supportedSolversNames; '----------'; 'Total'];

    solverStatus(end + 1, :) = ones(1, length(OPT_PROB_TYPES) + 1);
    solverStatus(end + 1, 2:end) = solverTypeInstalled';

    statusTable = {};
    for k = 1:5
        statusTable{k} = cellstr(num2str(solverStatus(:, k+1)));
        for p = 1:length(solverStatus(:, k+1))
            if strcmp(statusTable{k}(p), '-1')
                statusTable{k}(p) = {'-'};
            end
        end
    end

    % restore the original path
    path(originalUserPath);
    addpath(originalUserPath);

    % saves the current path
    if saveCobraPath == 1
        try
            if ENV_VARS.printLevel
                fprintf(' > Saving the MATLAB path ...');
            end
            if ispc || ismac
                savepath;
                if ENV_VARS.printLevel
                    fprintf(' Done.\n');
                    fprintf('   - The MATLAB path was saved in the default location.\n');
                end
            else
                [~, values] = fileattrib(which('pathdef.m'));
                if values.UserWrite
                    savepath
                else
                    savepath(defaultSavePathLocation);
                end
                if ENV_VARS.printLevel
                    fprintf(' Done.\n');
                    fprintf(['   - The MATLAB path was saved as ', defaultSavePathLocation, '.\n']);
                end
            end
        catch
            if ENV_VARS.printLevel
                fprintf(' > The MATLAB path could not be saved.');
            end
        end
    end
    % print out a summary table
    if ENV_VARS.printLevel
        colFormat = '\t%-12s \t%-13s \t%5s \t%5s \t%5s \t%5s \t%5s\n';
        sep = '\t----------------------------------------------------------------------\n';
        fprintf('\n > Summary of available solvers and solver interfaces\n\n');
        if ispc
            topLineFormat = '\t\t\t\t\tSupport        %5s \t%5s \t%5s \t%5s \t%5s\n';
        else
            topLineFormat = '\t\t\tSupport \t%5s \t%5s \t%5s \t%5s \t%5s\n';
        end
        fprintf(topLineFormat, OPT_PROB_TYPES{1}, OPT_PROB_TYPES{2}, OPT_PROB_TYPES{3}, OPT_PROB_TYPES{4}, OPT_PROB_TYPES{5})
        fprintf(sep);
        for i = 1:length(catList)-2
            fprintf(colFormat, rowNames{i}, catList{i}, statusTable{1}{i}, statusTable{2}{i}, statusTable{3}{i}, statusTable{4}{i}, statusTable{5}{i})
        end
        fprintf(sep);
        fprintf(colFormat, rowNames{end}, catList{end}, statusTable{1}{end}, statusTable{2}{end}, statusTable{3}{end}, statusTable{4}{end}, statusTable{5}{end})
        fprintf('\n + Legend: - = not applicable, 0 = solver not compatible or not installed, 1 = solver installed.\n\n\n')
    end

    % provide clear instructions and summary
    for i = 1:length(OPT_PROB_TYPES)
        if sum(solverStatus(:, i + 1) == 1) == 0
            if ENV_VARS.printLevel
                fprintf(' > You cannot solve %s problems. Consider installing an %s solver.\n', char(OPT_PROB_TYPES(i)), char(OPT_PROB_TYPES(i)));
            end
        else
            if ENV_VARS.printLevel
                fprintf(' > You can solve %s problems using: ', char(OPT_PROB_TYPES(i)));
            end
            k = 1;
            for j = 1:length(catSolverNames.(OPT_PROB_TYPES{i}))
                if SOLVERS.(catSolverNames.(OPT_PROB_TYPES{i}){j}).working
                    if k == 1
                        msg = '''%s'' ';
                    else
                        msg = '- ''%s'' ';
                    end
                    if ENV_VARS.printLevel
                        fprintf(msg, catSolverNames.(OPT_PROB_TYPES{i}){j});
                    end
                    k = k + 1;
                end
            end
            if ENV_VARS.printLevel
                fprintf('\n');
            end
        end
    end
    if ENV_VARS.printLevel
        fprintf('\n');
    end

    % use Gurobi (if installed) as the default solver for LP, QP and MILP problems
    changeCobraSolver('gurobi', 'ALL', 0);

    % set up the COBRA System path
    addCOBRABinaryPathToSystemPath();

    % change back to the current directory
    cd(currentDir);

    % cleanup at the end of the successful run
    removeTempFiles(CBTDIR, dirContent);

    % clear all temporary variables
    % Note: global variables are kept in memory - DO NOT clear all the variables!
    if ENV_VARS.printLevel
        clearvars
    end
end