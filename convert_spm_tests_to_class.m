function convert_spm_tests_to_class(function_test_file, class_test_file)
% CONVERT_SPM_TESTS_TO_CLASS Convert function-based SPM tests to class-based
%
% This utility helps convert SPM's function-based tests to class-based format
% for standalone compatibility.
%
% Usage:
%   convert_spm_tests_to_class('tests/test_spm.m', 'test_spm_standalone.m')
%
% See also: test_spm_core_standalone

if nargin < 2
    [~, name, ~] = fileparts(function_test_file);
    class_test_file = [name, '_standalone.m'];
end

fprintf('Converting %s to class-based format: %s\n', function_test_file, class_test_file);

try
    % Read the original function-based test
    content = fileread(function_test_file);
    
    % Extract test functions
    test_functions = extract_test_functions(content);
    
    % Generate class-based test
    class_content = generate_class_test(test_functions, function_test_file);
    
    % Write the new class-based test
    fid = fopen(class_test_file, 'w');
    if fid == -1
        error('Could not create output file: %s', class_test_file);
    end
    fprintf(fid, '%s', class_content);
    fclose(fid);
    
    fprintf('✓ Conversion completed: %s\n', class_test_file);
    fprintf('  Found %d test functions\n', length(test_functions));
    
    % Test the new file
    if exist('runtests', 'builtin')
        fprintf('Testing converted file...\n');
        try
            results = runtests(class_test_file);
            passed = sum([results.Passed]);
            failed = sum([results.Failed]);
            fprintf('✓ Converted tests work: %d passed, %d failed\n', passed, failed);
        catch ME
            fprintf('⚠ Test execution failed: %s\n', ME.message);
        end
    end
    
catch ME
    fprintf('✗ Conversion failed: %s\n', ME.message);
end

end

function test_functions = extract_test_functions(content)
% Extract test function definitions from function-based test file

test_functions = {};

% Find all function definitions that start with 'test'
pattern = 'function\s+(\w*test\w*)\s*\([^)]*\)';
matches = regexp(content, pattern, 'tokens', 'lineanchors');

for i = 1:length(matches)
    func_name = matches{i}{1};
    
    % Extract the function body
    func_start = strfind(content, ['function ' func_name]);
    if ~isempty(func_start)
        % Find the end of this function (next function or end of file)
        remaining = content(func_start(1):end);
        next_func = regexp(remaining, '\nfunction\s+', 'once');
        if isempty(next_func)
            func_body = remaining;
        else
            func_body = remaining(1:next_func-1);
        end
        
        test_functions{end+1} = struct('name', func_name, 'body', func_body);
    end
end

end

function class_content = generate_class_test(test_functions, original_file)
% Generate class-based test content

[~, original_name, ~] = fileparts(original_file);
class_name = [original_name, '_standalone'];

class_content = sprintf(['classdef %s < matlab.unittest.TestCase\n', ...
    '    %% %s - Class-based version of %s\n', ...
    '    %%\n', ...
    '    %% Auto-converted from function-based to class-based format\n', ...
    '    %% for standalone compatibility.\n', ...
    '    %%\n', ...
    '    %% Original: %s\n', ...
    '    \n'], ...
    upper(class_name), upper(class_name), original_file, original_file);

class_content = [class_content, '    methods (Test)\n\n'];

% Convert each test function
for i = 1:length(test_functions)
    func = test_functions{i};
    
    % Convert function to method
    method_content = convert_function_to_method(func);
    class_content = [class_content, method_content, '\n'];
end

% Add setup/teardown methods
class_content = [class_content, sprintf(['    end\n\n', ...
    '    methods (TestClassSetup)\n', ...
    '        function setupSPM(testCase)\n', ...
    '            %% Setup called once before all tests\n', ...
    '            try\n', ...
    '                spm(''defaults'', ''fmri'');\n', ...
    '                spm_get_defaults(''cmdline'', true);\n', ...
    '            catch ME\n', ...
    '                warning(''SPM setup failed: %%s'', ME.message);\n', ...
    '            end\n', ...
    '        end\n', ...
    '    end\n\n', ...
    '    methods (TestClassTeardown)\n', ...
    '        function teardownSPM(testCase)\n', ...
    '            %% Cleanup called once after all tests\n', ...
    '        end\n', ...
    '    end\n\n', ...
    'end\n'])];

end

function method_content = convert_function_to_method(func)
% Convert a function-based test to a class method

method_content = sprintf('        function %s(testCase)\n', func.name);
method_content = [method_content, sprintf('            %% Converted from function-based test\n')];

% Process the function body
body_lines = strsplit(func.body, '\n');
for i = 1:length(body_lines)
    line = body_lines{i};
    
    % Skip function declaration and end
    if contains(line, 'function ') || strcmp(strtrim(line), 'end')
        continue;
    end
    
    % Convert assertions (basic conversion)
    line = strrep(line, 'verifyThat(', 'testCase.verifyThat(');
    line = strrep(line, 'verifyEqual(', 'testCase.verifyEqual(');
    line = strrep(line, 'verifyTrue(', 'testCase.verifyTrue(');
    line = strrep(line, 'verifyFalse(', 'testCase.verifyFalse(');
    line = strrep(line, 'verifyClass(', 'testCase.verifyClass(');
    line = strrep(line, 'verifySize(', 'testCase.verifySize(');
    line = strrep(line, 'verifyGreaterThan(', 'testCase.verifyGreaterThan(');
    line = strrep(line, 'verifyLessThan(', 'testCase.verifyLessThan(');
    line = strrep(line, 'verifyNotEmpty(', 'testCase.verifyNotEmpty(');
    line = strrep(line, 'verifyEmpty(', 'testCase.verifyEmpty(');
    
    % Add proper indentation
    if ~isempty(strtrim(line))
        method_content = [method_content, '            ', line, '\n'];
    else
        method_content = [method_content, '\n'];
    end
end

method_content = [method_content, sprintf('        end\n')];

end
