function results = spm_tests_class(varargin)
% Unit Testing Framework for Class-Based Tests
% FORMAT results = spm_tests_class(name,value,...)
% name,value  - pairs of optional parameter names and values:
%     verbose:   verbosity level of test run progress report [default: 2]
%     display:   display test results [default: false]
%     coverage:  display code coverage [default: false]
%     cobertura: save code coverage results in the Cobertura XML format [default: false]
%     tag:       test tag selector [default: '', ie all tests]
%     tap:       save a Test Anything Protocol (TAP) file [default: false]
%     test:      name of function to test [default: '', ie all tests]
%     class:     class of test 'regression' or 'unit'. [default: 'unit']
%     testdir:   directory containing test files [default: spm('Dir')/tests and spm('Dir')]
% results     - TestResult array containing information describing the
%               result of running the test suite.
%
% This version is specifically designed to work with class-based tests
% (files named *_class.m that inherit from matlab.unittest.TestCase)
% while maintaining compatibility with the original spm_tests functionality.
%__________________________________________________________________________

% Guillaume Flandin (original spm_tests.m)
% Modified for class-based tests compatibility
% Copyright (C) 2015-2022 Wellcome Centre for Human Neuroimaging

if spm_check_version('matlab','8.3') < 0
    error('Unit Tests require MATLAB R2014a or above.');
end

spm('FnBanner',mfilename);

%-Input parameters
%--------------------------------------------------------------------------
options = struct('verbose',2, 'display',false, 'coverage',false, ...
                 'cobertura',false, 'tag', '', 'tap',false, 'test','',...
                 'class','unit', 'testdir', '');
if nargin
    if isstruct(varargin{1})
        fn = fieldnames(varargin{1});
        for i=1:numel(fn)
            options.(fn{i}) = varargin{1}.(fn{i});
        end
    else
        for i=1:2:numel(varargin)
            options.(varargin{i}) = varargin{i+1};
        end
    end
end

%-Set default test directories
%--------------------------------------------------------------------------
if isempty(options.testdir)
    % Look in both the main SPM directory and the tests subdirectory
    test_dirs = {fullfile(spm('Dir'),'tests'), spm('Dir')};
else
    test_dirs = cellstr(options.testdir);
end

%-Unit tests
%==========================================================================

%-Create a TestSuite
%--------------------------------------------------------------------------
import matlab.unittest.TestSuite;
import matlab.unittest.selectors.*;

suite = [];

if isempty(options.test)
    % Discover all class-based test files
    fprintf('Discovering class-based test files...\n');
    
    for d = 1:numel(test_dirs)
        test_dir = test_dirs{d};
        if ~exist(test_dir, 'dir')
            continue;
        end
        
        % Look for class-based test files (ending with _class.m)
        all_class_files = dir(fullfile(test_dir, '*_class.m'));
        
        % Filter out non-test files
        class_files = [];
        for f = 1:numel(all_class_files)
            file_path = fullfile(test_dir, all_class_files(f).name);
            if isClassBasedTest(file_path)
                if isempty(class_files)
                    class_files = all_class_files(f);
                else
                    class_files(end+1) = all_class_files(f); %#ok<AGROW>
                end
            end
        end
        
        % Also look for files that contain 'classdef' and inherit from TestCase
        all_m_files = dir(fullfile(test_dir, '*.m'));
        
        for f = 1:numel(all_m_files)
            file_path = fullfile(test_dir, all_m_files(f).name);
            
            % Skip if already found as *_class.m file
            if ~isempty(class_files) && any(strcmp(all_m_files(f).name, {class_files.name}))
                continue;
            end
            
            % Check if file contains class-based test structure
            if isClassBasedTest(file_path)
                class_files(end+1) = all_m_files(f); %#ok<AGROW>
            end
        end
        
        % Add discovered class-based tests to suite
        for f = 1:numel(class_files)
            file_path = fullfile(test_dir, class_files(f).name);
            try
                fprintf('  Adding: %s\n', class_files(f).name);
                file_suite = TestSuite.fromFile(file_path);
                suite = [suite, file_suite]; %#ok<AGROW>
            catch ME
                warning('SPM:tests:fileError',...
                    'Could not load test file %s: %s', class_files(f).name, ME.message);
            end
        end
    end
    
    if isempty(suite)
        warning('SPM:tests:noClassTests',...
            'No class-based test files found. Looking for files named *_class.m or containing classdef...TestCase');
    end
    
else
    % Run specific tests
    options.test = cellstr(options.test);
    for i=1:numel(options.test)
        test_found = false;
        
        for d = 1:numel(test_dirs)
            test_dir = test_dirs{d};
            
            % Try different naming patterns for class-based tests
            test_patterns = {
                [options.test{i} '_class.m'],     % test_name_class.m
                [options.test{i} '.m'],           % test_name.m (if already class-based)
                ['test_' options.test{i} '_class.m'], % test_name_class.m with prefix
                ['test_' options.test{i} '.m']    % test_name.m with prefix (if class-based)
            };
            
            for p = 1:numel(test_patterns)
                mtest = fullfile(test_dir, test_patterns{p});
                if spm_existfile(mtest)
                    % Verify it's actually a class-based test
                    if isClassBasedTest(mtest)
                        fprintf('  Adding specific test: %s\n', test_patterns{p});
                        suite = [suite, TestSuite.fromFile(mtest)]; %#ok<AGROW>
                        test_found = true;
                        break;
                    end
                end
            end
            
            if test_found
                break;
            end
        end
        
        if ~test_found
            warning('SPM:tests:fileNotFound',...
                'No class-based tests found for %s', options.test{i});
        end
    end
end

% Filter by test class (regression vs unit) if suite has tests
if ~isempty(suite)
    testNames = {suite.ProcedureName}';
    regressTests = contains(testNames, 'regress', 'IgnoreCase', true);
    
    if strcmp(options.class,'regression')
        suite = suite(regressTests);
    else 
        suite = suite(~regressTests);
    end
end

% Apply tag filtering
if ~isempty(options.tag) && ~isempty(suite)
    suite = suite.selectIf(~HasTag | HasTag(options.tag));
end

%-Create a TestRunner
%--------------------------------------------------------------------------
import matlab.unittest.TestRunner;
import matlab.unittest.plugins.*

if ~options.verbose
    runner = TestRunner.withNoPlugins;
else
    runner = TestRunner.withTextOutput('Verbosity',options.verbose);
end

if options.coverage
    plugin = CodeCoveragePlugin.forFolder(spm('Dir'));
    runner.addPlugin(plugin);
end

if options.cobertura
    d = getenv('WORKSPACE');
    if isempty(d), d = spm('Dir'); end
    coberturaFile = fullfile(d,'spm_CoverageResults.xml');
    plugin = CodeCoveragePlugin.forFolder(spm('Dir'),...
        'Producing',codecoverage.CoberturaFormat(coberturaFile));
    runner.addPlugin(plugin);
end

if options.tap
    d = getenv('WORKSPACE');
    if isempty(d), d = spm('Dir'); end
    tapFile = fullfile(d,'spm_tests_class.tap');
    plugin = TAPPlugin.producingVersion13(ToFile(tapFile));
    runner.addPlugin(plugin);
end

%-Run tests
%--------------------------------------------------------------------------
if ~isempty(suite)
    fprintf('\nRunning %d class-based test(s)...\n', numel(suite));
    results = runner.run(suite);
    fprintf('Test run completed.\n\n');
else
    results = struct('Passed',{},'Failed',{},'Incomplete',{},'Duration',{});
    fprintf('No tests to run.\n');
end

%-Display test results
%--------------------------------------------------------------------------
if options.display || nargout == 0
    if ~isempty(results)
        fprintf(['Totals (%d tests):\n\t%d Passed, %d Failed, %d Incomplete.\n' ...
            '\t%f seconds testing time.\n\n'],numel(results),nnz([results.Passed]),...
            nnz([results.Failed]),nnz([results.Incomplete]),sum([results.Duration]));
        
        if exist('table', 'builtin')
            disp(table(results));
        else
            % Fallback for older MATLAB versions
            for i = 1:numel(results)
                status = 'FAILED';
                if results(i).Passed
                    status = 'PASSED';
                end
                fprintf('%s: %s\n', results(i).Name, status);
            end
        end
    else
        fprintf('No test results to display.\n');
    end
end

end

%==========================================================================
% Helper Functions
%==========================================================================

function isClass = isClassBasedTest(filepath)
% Check if a file contains a class-based test
    isClass = false;
    
    try
        % Read first few lines to check for classdef and TestCase
        fid = fopen(filepath, 'r');
        if fid == -1
            return;
        end
        
        % Read enough lines to find classdef declaration
        lines_to_check = 30;
        content = '';
        for i = 1:lines_to_check
            line = fgetl(fid);
            if ~ischar(line)
                break;
            end
            content = [content, ' ', line]; %#ok<AGROW>
        end
        fclose(fid);
        
        % Check for class-based test pattern
        hasClassdef = contains(content, 'classdef', 'IgnoreCase', true);
        hasTestCase = contains(content, 'matlab.unittest.TestCase', 'IgnoreCase', true);
        hasTestMethods = contains(content, 'methods (Test)', 'IgnoreCase', true) || ...
                        contains(content, 'methods(Test)', 'IgnoreCase', true);
        
        % Must have all three for a valid test class
        isClass = hasClassdef && hasTestCase && hasTestMethods;
        
        % Additional check: exclude the spm_tests_class.m file itself and utility files
        [~, filename] = fileparts(filepath);
        if strcmp(filename, 'spm_tests_class') || strcmp(filename, 'convert_spm_tests_to_class')
            isClass = false;
        end
        
    catch
        if exist('fid', 'var') && fid ~= -1
            fclose(fid);
        end
        isClass = false;
    end
end
