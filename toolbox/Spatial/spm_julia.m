function varargout = spm_julia(opt, varargin)
% Run Julia code from SPM via MATFrost
% FORMAT s = spm_julia('settings')
%     s - a structure containing various settings
%
% FORMAT sts = spm_julia('setup')
% Set up Julia and MATFrost within SPM. Downloads Julia if not found,
% installs MATFrost MATLAB bindings, and instantiates the Julia project
% environment.
%
% FORMAT sts = spm_julia('setup','force')
% Force re-setup of Julia and MATFrost, even if already installed.
%
% FORMAT jl = spm_julia('server')
% Return a MATFrost server handle for calling Julia functions. Starts the
% server if not already running and performs setup if needed.
%
% Example usage:
%     jl = spm_julia('server');
%     result = jl.SPMSpatial.romeo_unwrap_3d(single(phase), single(mag));
%
% FORMAT spm_julia('shutdown')
% Shut down the MATFrost server.
%
% For more information about the Julia language, see https://julialang.org/
% For more information about MATFrost, see https://github.com/ASML-Labs/MATFrost.jl
%__________________________________________________________________________

% John Ashburner
% Copyright (C) 2026 Functional Imaging Lab, UCL Institute of Neurology

    switch lower(opt)
        case 'setup'
            varargout{1} = setup(varargin{:});
        case 'server'
            varargout{1} = get_server;
        case 'shutdown'
            shutdown_server;
        case 'settings'
            varargout{1} = settings;
        otherwise
            error('Unknown option: %s', opt);
    end
end


function s = settings
% Return a structure of configuration paths and settings.
    s = struct;
    s.julia_version = '1.10.10';
    s.spatial_dir   = fullfile(spm('dir'),'toolbox','Spatial');
    s.julia_project = fullfile(s.spatial_dir,'julia');
    s.matfrost_dir  = fullfile(s.spatial_dir,'@matfrostjulia');
    s.iswin         = ispc;
    s.comp          = computer;

    % Julia binary: prefer juliaup, then PATH, then local install
    s.julia_cmd     = find_julia(s);
end


function cmd = find_julia(s)
% Locate the Julia binary. Checks juliaup, then PATH, then local install.
    if s.iswin
        ext = '.exe';
    else
        ext = '';
    end

    % Check for julia on PATH
    [sts,~] = system('julia --version');
    if sts == 0
        cmd = 'julia';
        return
    end

    % Check for juliaup-managed julia
    [sts,~] = system('juliaup status');
    if sts == 0
        cmd = 'julia';
        return
    end

    % Check for locally installed Julia
    local_dir = fullfile(spm('dir'),'toolbox','Spatial','Apps',lower(s.comp));
    candidates = dir(fullfile(local_dir,'julia-*'));
    for i = 1:length(candidates)
        local_cmd = fullfile(local_dir,candidates(i).name,'bin',['julia' ext]);
        if exist(local_cmd,'file')
            cmd = local_cmd;
            return
        end
    end

    cmd = '';
end


function sts = setup(varargin)
% Set up Julia and MATFrost.
    sts = 0;
    s   = settings;

    force = nargin >= 1 && any(strcmp(varargin,'force'));

    % Step 1: Ensure Julia is available
    if isempty(s.julia_cmd) || force
        sts = install_julia(s);
        if sts ~= 0, return; end
        s = settings; % Refresh settings after install
    end

    % Step 2: Install MATFrost MATLAB bindings
    if ~exist(s.matfrost_dir,'dir') || force
        sts = install_matfrost(s);
        if sts ~= 0, return; end
    end

    % Step 3: Instantiate the Julia project environment
    sts = instantiate_project(s);
end


function sts = install_julia(s)
% Download and install Julia if not present.
    sts = 0;

    % Check that the user is happy to have Julia installed
    str = { 'This functionality needs the Julia language',...
            '(https://julialang.org/) and MATFrost.jl',...
            '(https://github.com/ASML-Labs/MATFrost.jl),',...
            'which will be installed automatically from the internet.',...
            '',...
            'Are you happy for Julia to be installed?'};
    if spm_input(str,1,'bd','Yes|No',[0,1],1,mfilename)
        fprintf('%-40s: %30s\n\n',...
            'Abort...   (User does not want Julia)',spm('time'));
        sts = 1;
        return
    end

    version = s.julia_version;
    json_file = websave(tempname,'https://julialang-s3.julialang.org/bin/versions.json');
    if isempty(json_file)
        error('Cannot obtain the versions.json file from the web.')
    end
    json = spm_jsonread(json_file);
    delete(json_file);

    files = json.(['x' replace(version,'.','_')]).files;
    switch s.comp
        case 'GLNXA64'
            opt = findfile('x86_64-linux-gnu', files);
        case 'PCWIN64'
            opt = findfile('x86_64-w64-mingw32', files);
        case 'MACI64'
            opt = findfile('x86_64-apple-darwin14', files);
        case 'MACA64'
            opt = findfile('aarch64-apple-darwin14', files);
        case 'ARM'
            opt = findfile('aarch64-linux-gnu', files);
        otherwise
            error('Unsupported platform: %s', s.comp);
    end

    if isempty(opt)
        error('No suitable Julia binary found for %s.', s.comp);
    end

    appdir = fullfile(spm('dir'),'toolbox','Spatial','Apps',lower(s.comp));
    if ~exist(appdir,'dir'), mkdir(appdir); end

    fprintf('Downloading "%s" ... ', opt.url)
    compr_file = fullfile(appdir,['install.' opt.extension]);
    websave(compr_file, opt.url);
    fprintf('Done\n')

    fprintf('Unpacking "%s" ... ', compr_file);
    switch opt.extension
        case {'tar.gz','tar','tgz'}
            untar(compr_file,appdir)
        case 'zip'
            unzip(compr_file,appdir)
        otherwise
            error('Unknown archive format: %s', opt.extension);
    end
    delete(compr_file);
    fprintf('Done\n')
end


function sts = install_matfrost(s)
% Install MATFrost MATLAB bindings into the Spatial toolbox directory.
    sts = 0;
    fprintf('Installing MATFrost MATLAB bindings... ')
    julia_code = 'import Pkg; Pkg.instantiate(); using MATFrost; MATFrost.install(ARGS[1])';
    cmd = sprintf('%s --project="%s" -e "%s" "%s"',...
                  s.julia_cmd, s.julia_project, julia_code, s.spatial_dir);
    [sts, result] = run_julia_cmd(s, cmd);
    if sts ~= 0
        fprintf('Failed!\n')
        disp(result)
        error('MATFrost installation failed.')
    end
    fprintf('Done\n')
end


function sts = instantiate_project(s)
% Instantiate the Julia project environment (download/precompile packages).
    sts = 0;
    fprintf('Instantiating Julia project environment... ')
    cmd = sprintf('%s --project="%s" -e "import Pkg; Pkg.instantiate()"',...
                  s.julia_cmd, s.julia_project);
    [sts, result] = run_julia_cmd(s, cmd);
    if sts ~= 0
        fprintf('Failed!\n')
        disp(result)
        error('Julia project instantiation failed.')
    end
    fprintf('Done\n')
end


function jl = get_server
% Return the MATFrost server handle, starting it if needed.
    jl_server = server_state('get');

    if isempty(jl_server) || ~isvalid_server(jl_server)
        % Ensure setup is complete
        s = settings;
        if isempty(s.julia_cmd)
            setup;
            s = settings;
        end
        if ~exist(s.matfrost_dir,'dir')
            setup;
            s = settings;
        end

        % Add MATFrost to MATLAB path if needed
        if ~exist('matfrostjulia','class')
            addpath(s.matfrost_dir);
        end

        % Start MATFrost server with SPM's Julia project
        try
            jl_server = matfrostjulia(project=s.julia_project);
        catch ME
            error('spm_julia:server', ...
                  ['Failed to start MATFrost server. Ensure Julia is installed and\n' ...
                   'the project environment is set up (run spm_julia(''setup'')).\n' ...
                   'Error: %s'], ME.message);
        end
        server_state('set', jl_server);
    end

    jl = jl_server;
end


function shutdown_server
% Shut down the MATFrost server.
    jl_server = server_state('get');
    if ~isempty(jl_server)
        try
            delete(jl_server);
        catch
            % Server may already be stopped
        end
        server_state('set', []);
    end
end


function jl = server_state(action, val)
% Manage the persistent MATFrost server handle.
    persistent jl_server
    switch action
        case 'get'
            jl = jl_server;
        case 'set'
            jl_server = val;
            jl = jl_server;
    end
end


function valid = isvalid_server(jl)
% Check if a MATFrost server handle is still valid.
    try
        valid = isvalid(jl);
    catch
        valid = false;
    end
end


function [sts, result] = run_julia_cmd(s, cmd)
% Execute a Julia command via system call.
    if isunix
        paths = getenv('LD_LIBRARY_PATH');
        setenv('LD_LIBRARY_PATH');
    end
    if nargout < 2
        sts = system(cmd);
    else
        [sts, result] = system(cmd);
    end
    if isunix
        setenv('LD_LIBRARY_PATH', paths);
    end
end


function opt = findfile(arch, files)
% Find the matching file entry for the given architecture.
    opt = {};
    for i = 1:length(files)
        if strcmp(arch, files{i}.triplet) && ~strcmp('exe', files{i}.extension)
            opt = files{i};
            return
        end
    end
end

