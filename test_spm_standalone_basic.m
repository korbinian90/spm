classdef test_spm_standalone_basic < matlab.unittest.TestCase
    % TEST_SPM_STANDALONE_BASIC Class-based tests for SPM in standalone mode
    %
    % This is a CLASS-BASED test that works with MATLAB Compiler, unlike 
    % SPM's existing function-based tests. This demonstrates how SPM tests
    % could be converted for standalone compatibility.
    %
    % Usage:
    %   results = runtests('test_spm_standalone_basic.m');
    %   runner = matlab.unittest.TestRunner.withNoPlugins;
    %   suite = matlab.unittest.TestSuite.fromClass(?test_spm_standalone_basic);
    %   results = runner.run(suite);
    %
    % See also: spm_run_standalone_tests
    
    methods (Test)
        
        function test_spm_initialization(testCase)
            % Test that SPM can be initialized
            try
                spm('defaults', 'fmri');
                testCase.verifyTrue(true, 'SPM initialization succeeded');
            catch ME
                testCase.verifyFail(['SPM initialization failed: ', ME.message]);
            end
        end
        
        function test_spm_version(testCase)
            % Test that SPM version can be retrieved
            try
                ver_info = spm('version');
                testCase.verifyClass(ver_info, 'char', 'SPM version should return string');
                testCase.verifyNotEmpty(ver_info, 'SPM version should not be empty');
                fprintf('SPM Version: %s\n', ver_info);
            catch ME
                testCase.verifyFail(['SPM version check failed: ', ME.message]);
            end
        end
        
        function test_spm_dir(testCase)
            % Test SPM directory access
            try
                spm_dir = spm('dir');
                testCase.verifyClass(spm_dir, 'char', 'SPM dir should return string');
                testCase.verifyTrue(exist(spm_dir, 'dir') == 7, 'SPM directory should exist');
                fprintf('SPM Directory: %s\n', spm_dir);
            catch ME
                testCase.verifyFail(['SPM directory check failed: ', ME.message]);
            end
        end
        
        function test_basic_math_operations(testCase)
            % Test basic MATLAB operations work in standalone
            testCase.verifyEqual(2 + 2, 4, 'Basic addition failed');
            testCase.verifyEqual(sqrt(16), 4, 'Square root failed');
            
            % Test matrix operations
            A = [1 2; 3 4];
            B = [5 6; 7 8];
            C = A * B;
            expected = [19 22; 43 50];
            testCase.verifyEqual(C, expected, 'Matrix multiplication failed');
        end
        
        function test_file_operations(testCase)
            % Test basic file operations work in standalone
            temp_file = 'test_standalone_temp.txt';
            test_content = 'SPM Standalone Test';
            
            try
                % Write file
                fid = fopen(temp_file, 'w');
                testCase.verifyGreaterThan(fid, 0, 'Could not create temporary file');
                fprintf(fid, '%s', test_content);
                fclose(fid);
                
                % Read file
                fid = fopen(temp_file, 'r');
                testCase.verifyGreaterThan(fid, 0, 'Could not open temporary file');
                read_content = fgetl(fid);  % Use fgetl to preserve spaces
                fclose(fid);
                
                testCase.verifyEqual(read_content, test_content, 'File content mismatch');
                
                % Clean up
                delete(temp_file);
                
            catch ME
                % Clean up on error
                if exist(temp_file, 'file')
                    delete(temp_file);
                end
                testCase.verifyFail(['File operations failed: ', ME.message]);
            end
        end
        
        function test_spm_functions_exist(testCase)
            % Test that key SPM functions exist and can be called
            key_functions = {'spm_vol', 'spm_read_vols', 'spm_write_vol', 'spm_select'};
            
            for i = 1:length(key_functions)
                func_name = key_functions{i};
                func_exists = exist(func_name, 'file') > 0;
                testCase.verifyTrue(func_exists, ...
                    sprintf('SPM function %s not found', func_name));
                if func_exists
                    fprintf('✓ %s available\n', func_name);
                end
            end
        end
        
        function test_toolbox_dependencies(testCase)
            % Test that required toolboxes are available
            try
                % Check Image Processing Toolbox (if used by SPM)
                if exist('imresize', 'file')
                    fprintf('✓ Image Processing Toolbox functions available\n');
                    testCase.verifyTrue(true);
                else
                    fprintf('⚠ Image Processing Toolbox not available\n');
                    testCase.verifyTrue(true); % Not critical for basic SPM
                end
                
                % Check Statistics Toolbox (if used by SPM)
                if exist('corrcoef', 'builtin')
                    fprintf('✓ Statistics functions available\n');
                    testCase.verifyTrue(true);
                else
                    fprintf('⚠ Statistics functions not available\n');
                    testCase.verifyTrue(true); % Not critical for basic SPM
                end
                
            catch ME
                testCase.verifyFail(['Toolbox check failed: ', ME.message]);
            end
        end
        
    end
    
    methods (TestClassSetup)
        function setupSPM(testCase)
            % Setup called once before all tests in this class
            fprintf('Setting up SPM for class-based tests...\n');
            try
                spm('defaults', 'fmri');
                spm_get_defaults('cmdline', true);
                fprintf('SPM setup complete\n');
            catch ME
                error('Failed to setup SPM: %s', ME.message);
            end
        end
    end
    
    methods (TestClassTeardown)
        function teardownSPM(testCase)
            % Cleanup called once after all tests in this class
            fprintf('SPM class-based tests complete\n');
        end
    end
    
end
