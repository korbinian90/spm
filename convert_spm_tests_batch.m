function convert_spm_tests_batch()
% CONVERT_SPM_TESTS_BATCH Batch convert SPM tests to standalone format
%
% This function automatically converts prioritized SPM tests from 
% function-based to class-based format for standalone compatibility.

fprintf('=== SPM Test Conversion Batch Process ===\n\n');

% Get priority list
priorities = get_spm_test_priority();

% Convert Phase 2 (Mathematical Core) first
fprintf('Converting Phase 2: Mathematical Core Tests\n');
fprintf('==========================================\n');

phase2_tests = priorities.phase2_math;
converted_count = 0;

for i = 1:length(phase2_tests)
    test_file = phase2_tests{i};
    
    if exist(test_file, 'file')
        [~, name, ~] = fileparts(test_file);
        output_file = [name, '_standalone.m'];
        
        fprintf('Converting: %s -> %s\n', test_file, output_file);
        
        try
            convert_spm_tests_to_class(test_file, output_file);
            converted_count = converted_count + 1;
        catch ME
            fprintf('  ✗ Conversion failed: %s\n', ME.message);
        end
    else
        fprintf('  ⚠ Test file not found: %s\n', test_file);
    end
end

fprintf('\n✓ Phase 2 conversion completed: %d/%d tests converted\n\n', ...
    converted_count, length(phase2_tests));

% Test all converted files
fprintf('Testing Converted Files\n');
fprintf('======================\n');

standalone_tests = dir('*_standalone.m');
total_passed = 0;
total_failed = 0;

for i = 1:length(standalone_tests)
    test_file = standalone_tests(i).name;
    fprintf('Testing: %s\n', test_file);
    
    if exist('runtests', 'builtin')
        try
            results = runtests(test_file);
            passed = sum([results.Passed]);
            failed = sum([results.Failed]);
            total_passed = total_passed + passed;
            total_failed = total_failed + failed;
            
            fprintf('  Results: %d passed, %d failed\n', passed, failed);
            
            if failed > 0
                failed_tests = results([results.Failed]);
                for j = 1:length(failed_tests)
                    fprintf('    ✗ %s\n', failed_tests(j).Name);
                end
            end
        catch ME
            fprintf('  ✗ Test execution failed: %s\n', ME.message);
        end
    else
        fprintf('  ⚠ runtests not available\n');
    end
end

fprintf('\n=== Batch Conversion Summary ===\n');
fprintf('Converted test files: %d\n', converted_count);
fprintf('Total tests passed: %d\n', total_passed);
fprintf('Total tests failed: %d\n', total_failed);

if total_failed == 0 && total_passed > 0
    fprintf('✓ All converted tests passing!\n');
elseif total_passed > 0
    fprintf('⚠ %d tests passing, %d failing\n', total_passed, total_failed);
else
    fprintf('✗ No tests passing - check conversion process\n');
end

fprintf('\nNext steps:\n');
fprintf('1. Review failed tests and fix conversion issues\n');
fprintf('2. Add converted tests to spm_run_standalone_tests.m\n');
fprintf('3. Update GitHub Actions workflows to include new tests\n');
fprintf('4. Continue with Phase 3 conversion\n');

end
