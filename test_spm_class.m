classdef test_spm_class < matlab.unittest.TestCase
% Unit Tests for spm (Class-based version)
%
% CONVERSION NOTES:
% This is a direct conversion of tests/test_spm.m from function-based 
% to class-based format with MINIMAL changes to demonstrate the 
% conversion process.
%
% CHANGES REQUIRED:
% 1. Replace "function tests = test_spm" with "classdef test_spm_class < matlab.unittest.TestCase"
% 2. Replace "tests = functiontests(localfunctions);" with "methods (Test)"
% 3. Add "end" after methods block
% 4. Test functions remain exactly the same (no changes needed!)
% 5. Add optional setup/teardown methods for SPM initialization
%__________________________________________________________________________

% Copyright (C) 2021-2022 Wellcome Centre for Human Neuroimaging

    methods (Test)
        % NOTE: The test functions below are IDENTICAL to the original
        % function-based tests - no changes needed in the test logic!
        
        function test_spm_multi(testCase)
            import matlab.unittest.constraints.*

            d = spm('Dir');
            testCase.verifyThat(d,IsOfClass('char'));

            v = spm('Ver');
            testCase.verifyThat(v,IsOfClass('char'));

            v = spm('Version');
            testCase.verifyThat(v,IsOfClass('char'));

            xTB = spm('TBs');
            testCase.verifyThat(xTB,IsOfClass('struct'));

            u = spm('GetUser');
            testCase.verifyThat(u,IsOfClass('char'));
            u = spm('GetUser','hello %s!');
            testCase.verifyThat(u,IsOfClass('char'));

            t = spm('Time');
            testCase.verifyThat(t,IsOfClass('char'));

            mem = spm('Memory');
            testCase.verifyThat(mem, IsOfClass('double'));
            mem_avail = spm('Memory','available');
            testCase.verifyThat(mem_avail, IsOfClass('double'));
            mem_total = spm('Memory','total');
            testCase.verifyThat(mem_total, IsOfClass('double'));
        end
        
    end
    
    % OPTIONAL: Add setup/teardown methods for SPM initialization
    % (These are not strictly required for conversion but recommended)
    methods (TestClassSetup)
        function setupSPM(testCase)
            % Setup called once before all tests in this class
            try
                spm('defaults', 'fmri');
                spm_get_defaults('cmdline', true);
            catch ME
                % Don't fail if SPM setup has issues
                warning('SPM setup had issues: %s', ME.message);
            end
        end
    end
    
    methods (TestClassTeardown)
        function teardownSPM(testCase)
            % Cleanup called once after all tests in this class
            % (Usually not needed for SPM tests)
        end
    end
    
end

% CONVERSION SUMMARY:
% ===================
% 
% MINIMAL CHANGES REQUIRED:
% 1. File structure: 5 lines changed (header, class declaration, methods block)
% 2. Test functions: 0 lines changed (identical!)
% 3. Setup/teardown: Optional addition for better practices
%
% EFFORT LEVEL: Very Low
% - Structural changes are mechanical and can be automated
% - Test logic remains completely unchanged  
% - Most complex SPM tests would convert with same simplicity
%
% CONCLUSION: 
% Converting SPM's function-based tests to class-based is straightforward
% and can be largely automated. The test logic itself requires no changes.
