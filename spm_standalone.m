function spm_standalone(varargin)
% Gateway function for standalone SPM
%
% References:
%
%   SPM Standalone:  https://www.fil.ion.ucl.ac.uk/spm/docs/installation/standalone/
%   MATLAB Compiler: http://www.mathworks.com/products/compiler/
%
% See also: config/spm_make_standalone.m
%__________________________________________________________________________

% Guillaume Flandin
% Copyright (C) 2010-2023 Wellcome Centre for Human Neuroimaging


%-Options
%--------------------------------------------------------------------------
if ~nargin, action = ''; else action = varargin{1}; end

if strcmpi(action,'run')
    warning('"Run" is deprecated: use "Batch".');
    action = 'batch';
end

%-Default exit code: 0 (SUCCESS)
%--------------------------------------------------------------------------
exit_code = 0;

%-Set maximum number of computational threads to 1 by default
% This replaces the hardcoded mcc option -singleCompThread, allowing for
% the number of threads to be modified at runtime (either in script or in
% spm_my_defaults.m or in startup.m).
%--------------------------------------------------------------------------
if ~strcmpi(spm_check_version,'octave')
    try, maxNumCompThreads(1); end
end

%-Action
%==========================================================================
switch lower(action)
    
    case {'','pet','fmri','eeg','quit'}
    %----------------------------------------------------------------------
        spm(varargin{:});
    
    case {'-h','--help'}
    %----------------------------------------------------------------------
        cmd = 'spm';
        fprintf([...
            '%s - Statistical Parametric Mapping\n',...
            'https://www.fil.ion.ucl.ac.uk/spm/\n',...
            '\n'],...
            upper(cmd));
        fprintf([...
            'Usage: %s [ fmri | eeg | pet ]\n',...
            '       %s COMMAND [arg...]\n',...
            '       %s [ -h | --help | -v | --version ]\n',...
            '\n',...
            'Commands:\n',...
            '    batch          Run a batch job\n',...
            '    script         Execute a script\n',...
            '    function       Execute a function\n',...
            '    eval           Evaluate a MATLAB expression\n',...
            '    test           Run standalone tests\n',...
            '    test_class     Run class-based tests\n',...
            '    [NODE]         Run a specified batch node\n',...
            '\n',...
            'Options:\n',...
            '    -h, --help     Print usage statement\n',...
            '    -v, --version  Print version information\n',...
            '\n',...
            'Run ''%s [NODE] help'' for more information on a command.\n'],...
            cmd, cmd, cmd, cmd);
        
    case {'-v','--version'}
    %----------------------------------------------------------------------
        spm_banner;
        
    case 'batch'
    %----------------------------------------------------------------------
        inputs = varargin(2:end);
        flg = ismember(inputs,'--silent');
        if any(flg)
            quiet = true;
            inputs = inputs(~flg);
        else
            quiet = false;
        end
        flg = ismember(inputs,'--modality');
        if any(flg)
            idx = find(flg);
            try
                modality = inputs{idx+1};
            catch
                error('Syntax is: --modality <modality>.');
            end
            inputs([idx idx+1]) = [];
        else
            modality = 'fmri';
        end
        flg = ismember(inputs,'--cmdline');
        if any(flg)
            cmdline = true;
            inputs = inputs(~flg);
        else
            cmdline = false;
        end
        spm_banner(~quiet);
        spm('defaults',modality);
        spm_get_defaults('cmdline',cmdline);
        spm_jobman('initcfg');
        if isempty(inputs)
            h = spm_jobman;
            waitfor(h,'Visible','off');
        else
            try
                spm_jobman('run', inputs{:});
            catch
                fprintf('Execution failed: %s\n', inputs{1});
                exit_code = 1;
            end
        end
        spm('Quit');
        
    case 'script'
    %----------------------------------------------------------------------
        spm_banner;
        assignin('base','inputs',varargin(3:end));
        try
            if nargin > 1
                spm('Run',varargin(2));
            else
                spm('Run');
            end
        catch
            exit_code = 1;
        end
        
    case 'function'
    %----------------------------------------------------------------------
        spm_banner;
        if nargin == 1
            fcn = spm_input('function name','!+1','s','');
        else
            fcn = varargin{2};
        end
        try
            feval(fcn,varargin{3:end});
        catch
            exit_code = 1;
        end
    
    case 'eval'
    %----------------------------------------------------------------------
        spm_banner;
        if nargin == 1
            expr = spm_input('expression to evaluate','!+1','s','');
        else
            expr = varargin{2};
        end
        try
            eval(expr);
        catch
            exit_code = 1;
        end
    
    case 'test'
    %----------------------------------------------------------------------
        spm_banner;
        fprintf('SPM Standalone Test Mode\n');
        fprintf('========================\n\n');
        
        try
            % Check if we can use Unit Testing Framework
            if exist('runtests', 'builtin') || exist('runtests', 'file')
                fprintf('✓ Unit Testing Framework available\n');
                
                % Try class-based test first (standalone compatible)
                if exist('test_spm_standalone_basic.m', 'file')
                    fprintf('Running class-based tests (standalone compatible)...\n');
                    try
                        results = runtests('test_spm_standalone_basic.m');
                        if ~isempty(results)
                            passed = sum([results.Passed]);
                            failed = sum([results.Failed]);
                            fprintf('\n✓ Class-based tests: %d passed, %d failed\n', passed, failed);
                        end
                    catch class_error
                        fprintf('✗ Class-based test failed: %s\n', class_error.message);
                    end
                else
                    fprintf('⚠ Class-based test file not found\n');
                end
                
                % Run custom test runner
                fprintf('\nRunning custom SPM test runner...\n');
            else
                fprintf('✗ Unit Testing Framework not available\n');
                fprintf('This may be due to batch licensing limitations\n');
                fprintf('Running basic verification only...\n');
            end
            
            % Always run our custom test runner as fallback
            if isempty(varargin(2:end))
                % Run default tests
                results = spm_run_standalone_tests();
            else
                % Run specific test
                results = spm_run_standalone_tests(varargin{2});
            end
            
            % Display results
            if ~isempty(results) && isstruct(results)
                fprintf('\nTest Results Summary:\n');
                if isfield(results, 'Passed')
                    total = length(results);
                    passed = sum([results.Passed]);
                    failed = sum([results.Failed]);
                    fprintf('  Total: %d, Passed: %d, Failed: %d\n', total, passed, failed);
                    
                    if any([results.Failed])
                        exit_code = 1;
                    end
                else
                    fprintf('  Custom test format returned\n');
                end
            else
                fprintf('  No test results returned\n');
            end
        catch ME
            fprintf('Error running tests: %s\n', ME.message);
            exit_code = 1;
        end
        
    case 'test_class'
    %----------------------------------------------------------------------
        spm_banner;
        fprintf('SPM Class-Based Test Mode\n');
        fprintf('=========================\n\n');
        
        try
            % Check for class-based test runner
            if exist('spm_tests_class.m', 'file')
                fprintf('✓ Class-based test runner found\n');
                
                % Initialize SPM
                try
                    spm('defaults', 'fmri');
                    spm_get_defaults('cmdline', true);
                    fprintf('✓ SPM initialized for class-based testing\n');
                catch init_error
                    fprintf('⚠ SPM initialization warning: %s\n', init_error.message);
                end
                
                % Run class-based tests
                if nargin > 1 && ~isempty(varargin{2})
                    % Run specific test
                    fprintf('Running specific class-based test: %s\n', varargin{2});
                    results = spm_tests_class('test', varargin{2}, 'display', true, 'verbose', 2);
                else
                    % Run all class-based tests
                    fprintf('Running all class-based tests...\n');
                    results = spm_tests_class('display', true, 'verbose', 1);
                end
                
                % Display results
                if ~isempty(results)
                    passed = sum([results.Passed]);
                    failed = sum([results.Failed]);
                    incomplete = sum([results.Incomplete]);
                    total = numel(results);
                    
                    fprintf('\n=== Class-Based Test Results ===\n');
                    fprintf('Total tests: %d\n', total);
                    fprintf('Passed: %d\n', passed);
                    fprintf('Failed: %d\n', failed);
                    fprintf('Incomplete: %d\n', incomplete);
                    
                    if failed > 0 || incomplete > 0
                        fprintf('✗ Some class-based tests failed or incomplete\n');
                        exit_code = 1;
                    else
                        fprintf('✓ All class-based tests passed\n');
                    end
                else
                    fprintf('ℹ No class-based test results returned\n');
                end
                
            else
                fprintf('✗ Class-based test runner (spm_tests_class.m) not found\n');
                fprintf('Please ensure spm_tests_class.m is available\n');
                exit_code = 1;
            end
            
        catch ME
            fprintf('Error running class-based tests: %s\n', ME.message);
            fprintf('Stack trace:\n');
            for i = 1:length(ME.stack)
                fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
            end
            exit_code = 1;
        end
        
    otherwise % cli
    %----------------------------------------------------------------------
        %spm('defaults','fmri');
        %spm_get_defaults('cmdline',true);
        spm_jobman('initcfg');
        try
            spm_cli(varargin{:});
        catch
            exit_code = 1;
        end
        
end

%-Display error message and return exit code (or use finish.m script)
%--------------------------------------------------------------------------
if exit_code ~= 0
    err = lasterror;
    msg{1} = err.message;
    if isfield(err,'stack')
        for i=1:numel(err.stack)
            if err.stack(i).line
                l = sprintf(' (line %d)',err.stack(i).line);
            else
                l = '';
            end
            msg{end+1} = sprintf('Error in %s%s',err.stack(i).name,l);
        end
    end
    fprintf('%s\n',msg{:});
    
    exit(exit_code);
end


%==========================================================================
function spm_banner(verbose)
% Display text banner
if nargin && ~verbose, return; end
[vspm,rspm] = spm('Ver');
tlkt = ver(spm_check_version);
if isdeployed, mcr = ' (standalone)'; else mcr = ''; end
fprintf('%s, version %s%s\n',vspm,rspm,mcr);
fprintf('%s, version %s\n',tlkt.Name,version);
spm('asciiwelcome');
