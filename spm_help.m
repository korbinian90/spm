function [R1,R2]=spm_help(Action,P2,P3,P4,P5)
% SPM help and manual facilities
% FORMAT spm_help
%_______________________________________________________________________
%  ___  ____  __  __
% / __)(  _ \(  \/  )  Statistical Parametric Mapping
% \__ \ )___/ )    (   The Wellcome Department of Cognitive Neurology
% (___/(__)  (_/\/\_)  University College London
%
%_______________________________________________________________________
%
% SEE ALSO:   spm.man      - "About SPM"
%
% There is no 'manual' for SPM; these help routines and the code
% itself constitute a manual.
%
% The "Help" facilities are about software and implementation. The
% underlying mathematics, concepts and operational equations have been
% (or will be) published in the peer reviewed literature and the
% interested user is referred to these sources. An intermediate
% theoretical exposition is given in the SPM course notes. This and
% other resources are available via the SPM Web site. Visit
% http://www.fil.ion.ucl.ac.uk/spm
%
%-----------------------------------------------------------------------
%
% spm_help sets up a GUI help system for the SPM package.
% `spm_help('Topic')` or `spm_help Topic` displays the help for a
% particular topic in the SPM help window.
%
% Help topics are displayed in a special help window. Initially, a
% representation of the SPM Menu window is drawn. Clicking buttons in
% this representation leads to the help pages for the appropriate
% topic.
% 
% The SPM Help ToolBar contains controls for the help system.
%
%  ---  Routines and manual pages (generically referred to as help
%       "topics") referenced by the currently displayed help file are
%       listed in the "Referenced Topics..." pull-down menu on the help
%       interface. Selecting a routine there displays it's help
%       information.
%
%  ---  Alternatively, a specific function name (with the ".m"
%       extension) can be entered into the lilac editable text widget in
%       the help window toolbar. It's help will be displayed.
%
%  ---  As the tree of routines is explored, the "Previous Topics"
%       pulldown menu keeps track of recently visited help topics,
%       allowing easy backtracking and exploration of the "tree" of SPM
%       functions and dependencies.
%
% Special topic buttons lead to "About SPM", "Menu", and "Help" topics.
% "About SPM" displays the introduction file for this version of SPM.
% "Menu" displays the help representation of the SPM Menu window.
% "Help" displays this file.
%
% Multi-page help files are displayed by the help facility with pagination
% controls at the bottom right of the Graphics window.
%
% The print button enables printing to the specified Print device. This
% is set in the Defaults area, initially to the PostScript file
% "spm.ps" in the current directory. Multi page topics are paged on
% screen, and printed page by page.
%
%
%-----------------------------------------------------------------------
% The SPM package provides help at three levels, the first two being
% available via the SPM graphical help system:
%
% (i)   Manual pages on specific topics.
%       These give an overview of specific components or topics its
%       relation to other components, the inputs and outputs and
%       references to further information.
%
%       Many of the buttons in the help menu window lead to such "man"
%       pages.  These are contained in ASCII files named spm_*.man.
%       These can be viewed on the MatLab command line with the `help`
%       command, e.g. `help spm_help.m` prints out this manual file in
%       the MatLab command window.
%
% (ii)  Help information for each routine within SPM (E.g. This is the).
%       help information for spm_help.m - the help function.)
%       This help information is the help header of the actual MatLab
%       function, and can be displayed on the command line with the
%       `help` command, e.g. `help spm_help`.
%
%       Commented header text from that spm_*.m file is displayed in the 
%       following format:
%
%	     A one line description
%	     FORMAT [outputs] = spm_routine(inputs);
%	     inputs  -  the input arguments
%	     outputs -  the output arguments
%	     A short paragraph detailing what the routine does and other
%	     pertinent information
%	     ref:  citations
%
% (iii) SPM is (mainly) implemented as MatLab functions and scripts.
%       These are ASCII files named spm_*.m, which can be viewed in the
%       MatLab command window with the `type` command, e.g. `type
%       spm_help`, or read in a text editor.
%
%  ---  Matlab syntax is very similar to standard matrix notation that
%       would be found in much of the literature on matrices. In this
%       sense the SPM routines can be used (with Matlab) for data
%       analysis, or they can be regarded as the ultimate pseudocode
%       specification of the underlying ideas.
%
%  ---  The coding is concise but clear, and annotated with comments
%       where necessary.
%
% In addition, the MatLab help system provides keyword searching
% through the H1 lines (the first comment line) of the help entries of
% *all* M-files found on MATLABPATH. This can be used to identify
% routines from keywords. Type `help lookfor` in the MatLab command
% window for further details.
%
%__________________________________________________________________________
% %W% Andrew Holmes, Karl Friston %E%

%=======================================================================
% - FORMAT specifications for embedded CallBack functions
%=======================================================================
%( This is a multi function function, the first argument is an action  )
%( string, specifying the particular action function to take. Recall   )
%( MatLab's command-function duality: `spm_help Menu` is equivalent to )
%( `spm('Menu')`.                                                      )
%
% FORMAT spm_help
% Makes Help window visible if there is one around. Otherwise
% defaults to spm_help('!Topic','Menu').
%
% FORMAT spm_help('Topic')
% Defaults to spm_help('!Topic','Topic').
%
% FORMAT spm_help('!Quit')
% Hides the Help window.
% (Re)Shows the welcome splash screen if it exists.
%
% FORMAT spm_help('!DrawMenu')
% Draws representation of Menu window in help window, with button
% CallBacks for the appropriate help topics.
%
% FORMAT [S,Err] = spm_help('!ShortTopics',Topic)
% Returns help text (as a string) for special topics. If the topic is
% not found then S contains an error topic, and Err is true.
% Topic     - Special internal help topic
% S         - String vector containing help topic
% Err       - True if the topic is not found
%
% FORMAT spm_help('!Topic',Topic)
% Topic     - Help topic: Either name of file from which to display help,
%             or name of an internal help topic
%             Defaults to the "Menu" topic. (See '!ShortTopics')
% Loads file Topic (which must be on the MATLABPATH), parses it for
% references to other spm_* routines, puts these in the Help ToolBars
% "Referenced routines" pulldown (with callbacks to display their
% help), and sets up the "Previous topics" pulldown. Puts Topic in the
% editable topic window on the ToolBar. Then calls spm_help('!Disp') to
% display the help portion of the file.
% Special internal topics are tried if Topic file doesn't exist.
% "Menu" Topic prints a short message and displays the help
% representation of the Menu window.
%
% FORMAT spm_help('!Disp',Fname,S,F)
% Fname     - Name of file from which to display help
% S         - [Optional] String vector containing a previously read in
%             contents of file Fname
% F         - Figure to use
% Displays the help for the given file in the Help window (creating
% one if required). Paginates and provides paging buttons if necessary.
%
% FORMAT F = spm_help('!Create')
% F        - Handle of figure created
% Creates central Help window 'Tag'ged 'Help', with Help ToolBar
%
% FORMAT F = spm_help('!CreateHelpWin')
% F        - Handle of figure created
% Creates central Help window 'Tag'ged 'Help'. If one already exists
% then it's handle is returned.
%
% FORMAT spm_help('!CreateBar',F)
% F        - Handle (or 'Tag') of window to use. Defaults to 'Help'.
% Creates Help ToolBar.
%
% spm_help('!Clear',F)
% F        - Handle (or 'Tag') of window to use. Defaults to 'Help'.
% Clears help window, leaving ToolBar intact. Any 'HelpMenu' objects
% (with 'UserData' 'HelpMenu') are merely hidden, to speed up
% subsequent use.
%
% FORMAT h = spm_help('!ContextHelp',Topic)
% Sets up a small green "?" help button in the bottom right corner of
% the SPM Interactive window with callback to spm_help('Topic'). If SPM
% is in CommandLine mode then an appropriate message is printed in the
% MatLab command window.
% Topic     - Help topic
% h         - handle of button (if one is created)
%_______________________________________________________________________


%-Condition arguments for all uses
%-----------------------------------------------------------------------
if nargin==0
	Fhelp = spm_figure('FindWin','Help');
	if ~isempty(Fhelp)
		set(Fhelp,'Visible','on')
		return
	else
		Action='';
	end
end
if isempty(Action), Action='Menu'; nargin=1; end

%-All actions begin '!' - Other actions are topics
%-----------------------------------------------------------------------
if Action(1)~='!', nargin=2; P2=Action; Action='!Topic'; end



if strcmp(lower(Action),lower('!Quit'))
%=======================================================================
Fhelp   = spm_figure('FindWin','Help');
set(Fhelp,'Visible','off')
Fwelcom = spm_figure('FindWin','Welcome');
if ~isempty(Fwelcom), set(Fwelcom,'Visible','on'), end
return


elseif strcmp(lower(Action),lower('!DrawMenu'))
%=======================================================================
% Fhelp = spm_help('!DrawMenu');

%-Find help window
%-----------------------------------------------------------------------
Fhelp = spm_figure('FindWin','Help');
if isempty(Fhelp), error('No Help window'), end

H = findobj(Fhelp,'UserData','HelpMenu');
if length(H)
	set(H,'Visible','on')
	return
end

%-Create window frame
%-----------------------------------------------------------------------
S     = get(Fhelp,'Position');
A     = [S(3)/600 S(4)/865 S(3)/600 S(4)/865];
O     = [600/2-400/2 100 0 0].*A;

uicontrol(Fhelp,'Style','PushButton',...
	'String',spm('Ver'),...
	'CallBack','spm_help(''spm.m'')',...
	'Position',[-2,447,404,30]+O,...
	'Tag','NoDelete','UserData','HelpMenu')

%uicontrol(Fhelp,'Style','Text',...
%	'String',spm('Ver'),...
%	'Position',[0,452,400,20]+O,...
%	'Tag','NoDelete','UserData','HelpMenu')

uicontrol(Fhelp,'Style','Frame',...
	'Position',[-2,-2,404,449]+O,...
	'Tag','NoDelete','UserData','HelpMenu')

uicontrol(Fhelp,'Style','Frame',...
	'Position',[0,0,400,445]+O,...
	'Tag','NoDelete','UserData','HelpMenu',...
	'BackgroundColor',spm('Colour'))

%-Create help buttons with callbacks
%-----------------------------------------------------------------------
%-Special overview man pages
uicontrol(Fhelp,'String','About SPM',...
	'Position',[010 410 087 30].*A+O,...
	'CallBack','spm_help(''spm.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'ForegroundColor',[0 1 1])
uicontrol(Fhelp,'String','Data format',...
	'Position',[107 410 088 30].*A+O,...
	'CallBack','spm_help(''spm_format.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'ForegroundColor','b')
uicontrol(Fhelp,'String','Methods',...
	'Position',[205 410 088 30].*A+O,...
	'CallBack','spm_help(''spm_methods.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'ForegroundColor','b')
uicontrol(Fhelp,'String','Variables',...
	'Position',[303 410 087 30].*A+O,...
	'CallBack','spm_help(''spm_ui.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'ForegroundColor','b')

uicontrol(Fhelp,'String','PET Overview',...
	'Position',[040 285 140 30].*A+O,...
	'CallBack','spm_help(''spm_pet.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'ForegroundColor','b')
uicontrol(Fhelp,'String','fMRI Overview',...
	'Position',[220 285 140 30].*A+O,...
	'CallBack','spm_help(''spm_fmri.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'ForegroundColor','b')

uicontrol(Fhelp,'String','Graphics',...
	'Position',[165 122 070 24].*A+O,...
	'CallBack','spm_help(''spm_figure.m'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'ForegroundColor','b')

%-Man pages for specific functions
uicontrol(Fhelp,'String','Realign',...
	'Position',[040 370 080 30].*A+O,...
	'CallBack','spm_help(''spm_realign.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Normalize',...
	'Position',[150 350 100 30].*A+O,...
	'CallBack','spm_help(''spm_sn3d.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Smooth',...
	'Position',[280 370 080 30].*A+O,...
	'CallBack','spm_help(''spm_smooth.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Coregister',...
	'Position',[040 330 080 30].*A+O,...
	'CallBack','spm_help(''spm_coregister.m'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Segment',...
	'Position',[280 330 080 30].*A+O,...
	'CallBack','spm_help(''spm_segment.m'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')


uicontrol(Fhelp,'String','PET Statistics',...
	'Position',[040 245 140 30].*A+O,...
	'CallBack','spm_help(''spm_spm.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','fMRI Statistics',...
	'Position',[040 215 140 30].*A+O,...
	'CallBack','spm_help(''spm_fmri_spm.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Eigenimages',...
	'Position',[220 245 140 30].*A+O,...
	'CallBack','spm_help(''spm_svd.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')

uicontrol(Fhelp,'String','SPM{F}',...
	'Position',[045 165 070 30].*A+O,...
	'CallBack','spm_help(''spm_F.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Results',...
	'Position',[165 165 070 30].*A+O,...
	'CallBack','spm_help(''spm_results.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','SPM{Z}',...
	'Position',[285 165 070 30].*A+O,...
	'CallBack','spm_help(''spm_projections.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')

uicontrol(Fhelp,'String','Analyze',...
	'Position',[020 088 082 024].*A+O,...
	'CallBack','spm_help(''Analyze_Button'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Display',...
	'Position',[112 088 083 024].*A+O,...
	'CallBack','spm_help(''spm_image.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Render',...
	'Position',[205 088 083 024].*A+O,...
	'CallBack','spm_help(''spm_render.m'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','PET/fMRI',...
	'Position',[298 088 082 024].*A+O,...
	'CallBack','spm_help(''spm_modality.man'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','GhostView',...
	'Position',[020 054 082 024].*A+O,...
	'CallBack','spm_help(''GhostView_Button'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','CD',...
	'Position',[112 054 083 024].*A+O,...
	'CallBack','spm_help(''CD_Button'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Mean',...
	'Position',[205 054 083 024].*A+O,...
	'CallBack','spm_help(''spm_average.m'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','ImCalc',...
	'Position',[298 054 082 024].*A+O,...
	'CallBack','spm_help(''spm_image_funks.m'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Help',...
	'Position',[020 020 082 024].*A+O,...
	'CallBack','spm_help(''spm_help.m'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Defaults',...
	'Position',[112 020 083 024].*A+O,...
	'CallBack','spm_help(''spm_defaults_edit.m'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String',['<',getenv('USER'),'>'],...
	'Position',[205 020 083 024].*A+O,...
	'CallBack','spm_help(''UserButton'');',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'Interruptible','yes')
uicontrol(Fhelp,'String','Quit',...
	'Position',[298 020 082 024].*A+O,...
	'ForegroundColor','r',...
	'Tag','NoDelete','UserData','HelpMenu',...
	'CallBack','spm_help(''Quit'')')
return


elseif strcmp(lower(Action),lower('!ShortTopics'))
%=======================================================================
% [S,Err] = spm_help('!ShortTopics',Topic)
if nargin<2, Topic='!Topics'; else, Topic=P2; end

Usep = sprintf('%%%s',setstr('_'*ones(1,71)));
Err = 0;

if strcmp(Topic,'!Topics')
	S = 'Menu';
elseif strcmp(Topic,'spm_motd.man')
	S = sprintf([...
		'\n%% %s : Message of the Day\n',...
		'%s\n%%\n',...
		'%% No message of the day has been set.\n',...
		'%%\n',...
		'%% File spm_motd.man contains the message, which is',...
			' displayed at startup\n',...
		'%% if it exists.\n',...
		'%s\n%%\n%% Andrew Holmes\n'],...
		spm('Ver'),Usep,Usep);
elseif strcmp(Topic,'Menu')
	S = sprintf([...
		'\n%% %s : Statistical Parametric Mapping\n',...
		'%s\n%%\n',...
		'%% SPM functions are called from the main SPM window.\n',...
		'%% Click on the buttons in the representation below for',...
			' for help on that topic...\n',...
		'%%\n',...
		'%% Click on "Help" for instructions on using SPMhelp.\n',...
		'%s\n%%\n%% Andrew Holmes\n'],...
		spm('Ver'),Usep,Usep);
elseif strcmp(Topic,'Analyze_Button')
	S = sprintf([...
		'\n%% Launches Mayo Analyze\n',...
		'%s\n%%\n',...
		'%% Executes `!analyze` in the base MatLab workspace.\n',...
		'%% Requires the `analyze` binary to be in the path',...
			' of the users shell.\n',...
		'%s\n%%\n%% Andrew Holmes\n'],Usep,Usep);
elseif strcmp(Topic,'GhostView_Button')
	S = sprintf([...
		'\n%% Launches GhostView for a selected file\n',...
		'%s\n%%\n',...
		'%% Calls spm_get prompting for a PostScript file, and\n',...
		'%% uses MatLab''s `unix` command to call `ghostscript`',...
			' view it.\n',...
		'%% Requires the `ghostview` binary to be in the path',...
			' of the users shell.\n',...
		'%s\n%%\n%% Andrew Holmes\n'],Usep,Usep);
elseif strcmp(Topic,'CD_Button')
	S = sprintf([...
		'\n%% Change current working directory\n',...
		'%s\n%%\n',...
		'%% Calls spm_get prompting for a directory, and',...
			' changes directory to it.\n',...
		'%%\n',...
		'%% With the exception of the spatial routines, SPM now',...
			' writes results\n',...
		'%% (i.e. spm.ps and results "mat" files) in the current',...
			' working directory.\n',...
		'%s\n%%\n%% Andrew Holmes\n'],Usep,Usep);
elseif strcmp(Topic,'Quit')
	S = sprintf([...
		'\n%% Quit SPM and cleanup the MatLab workspace\n',...
		'%s\n%%\n',...
		'%% Closes all windows, clears workspace variables,',...
			' global variables\n',...
		'%% compiled functions and MEX links. This leaves',...
			' MatLab in "startup" condition\n',...
		'%% except that it doesn''t release the memory claimed',...
			' during the session.\n',...
		'%% You need to `quit` MatLab to release it''s memory.',...
			' It is advisable to do.\n',...
		'%% reasonably frequently, especially after large',...
			' analyses.\n',...
		'%%\n',...
		'%% It is *not* necessary to quit SPM after an SPM error.',...
			' Simply `clear` the \n',...
		'%% workspace (type `clear` in the MatLab command window)',...
			' and clear the\n',...
		'%% "Results" and "Interactive" with the `clear` button',...
			' in the "Results" window.\n',...
		'%% (SPMs defaults are held as global variables.)\n',...
		'%%\n',...
		'%% The `Quit` button in the "Help" window merely hides',...
			' the SPMhelp window.\n',...
		'%%\n',...
		'%s\n%%\n%% Andrew Holmes\n'],Usep,Usep);
elseif strcmp(Topic,'UserButton')
	S = sprintf([...
		'\n%% User specific button\n',...
		'%s\n%%\n',...
		'%% SEE ALSO: spm.m\n',...
		'%%\n',...
		'%% This button will invoke USERNAME.m, where USERNAME',...
			' is the login name\n',...
		'%% of the current user (you).  If no such routine',...
			' exists, this friendly\n',...
		'%% message is displayed.\n',...
		'%%\n',...
		'%% This facility is included to allow customised',...
			' routines to be called\n',...
		'%% upon from the user interface.  The routine should be',...
			' in a\n',...
		'%% directory listed in MATLABPATH.',...
			' (E.g. ~/matlab)\n',...
		'%%\n',...
		'%% Warmest regards,\n',...
		'%%\n',...
		'%% Karl Friston\n',...
		'%%\n',...
		'%s\n%%\n%% FIL Methods Group\n'],Usep,Usep);
else
	S = sprintf([...
		'\n%% ! - Topic not found\n',...
		'%s\n%%\n',...
		'%% This topic is not recognised by the help system.\n',...
		'%s\n%%\n%% Andrew Holmes\n'],Usep,Usep);
	Err = 1;
end
R1 = S; R2 = Err;
return


elseif strcmp(lower(Action),lower('!Topic'))
%=======================================================================
% spm_help('!Topic',Topic)
if nargin<2, Topic='Menu'; else, Topic=P2; end
bMenu = strcmp(Topic,'Menu');

%-Callback from PrevTopics passes integer Topic
if ~isstr(Topic)
	%-Current object contains new Topic
	Topic = get(gco,'String');
	n     = get(gco,'Value');
	if  n==1, return, end		% Don't process the prompt!
	Topic = deblank(Topic(n,:));
end

%-Find (or create) help window.
%-----------------------------------------------------------------------
Fhelp = spm_figure('FindWin','Help');
if isempty(Fhelp)
	Fhelp = spm_help('!Create');
else
	set(Fhelp,'Visible','on')
end
set(Fhelp,'Pointer','Watch')

%-Load text file or get text from 'ShortTopics'
%-----------------------------------------------------------------------
fid = fopen(Topic,'r');
if fid<0
	[S,Err] = spm_help('!ShortTopics',Topic);
else
	S = setstr(fread(fid))';
	Err = 0;
	fclose(fid);
end

%-Display the current help comments
%-----------------------------------------------------------------------
spm_help('!Disp',Topic,S,Fhelp);

%-Display Menu graphic if required
%-----------------------------------------------------------------------
if bMenu
	spm_help('!DrawMenu')
end

%-Sort out control objects
%-----------------------------------------------------------------------
set(findobj(Fhelp,'UserData','Topic'),'String',Topic);

%-If unknown topic then return
%-----------------------------------------------------------------------
if Err, set(Fhelp,'Pointer','Arrow'), return, end

%-Sort out previous topics pulldown
%-----------------------------------------------------------------------
hPTopics   = findobj(Fhelp,'UserData','PrevTopics');
PrevTopics = get(hPTopics,'String');
Prompt     = PrevTopics(1,:); PrevTopics(1,:)=[];
PrevTopics = str2mat(Topic,PrevTopics);
%-Delete any replications of Topic within PrevTopics
if size(PrevTopics,1)>1
	IDRows=[0, all( PrevTopics(2:size(PrevTopics,1),:)'==...
		setstr(ones(size(PrevTopics,1)-1,1)*PrevTopics(1,:))' ) ];
	PrevTopics(IDRows,:)=[];
end
%-Truncate to 20 items max.
if size(PrevTopics,1)>20 PrevTopics(21:size(PrevTopics,1),:)=[]; end
%-Update popup
set(hPTopics,'String',str2mat(Prompt,PrevTopics),'Value',1)

%-Find referenced topics
%-----------------------------------------------------------------------
hRTopics   = findobj(Fhelp,'UserData','RefdTopics');
RefdTopics = get(hRTopics,'String');
RefdTopics = [deblank(RefdTopics(1,:)),'|',Topic];
q     = findstr(S,'spm_');
for i = 1:length(q)
    d = [0:32] + q(i);
    Q = S(d(d <= length(S)));
    d = find((Q == ';') | (Q == '(') | (Q == 10) | (Q == '.') | (Q == ' '));
	if length(d)
	  tmp = [0:3]+min(d); tmp = Q(tmp(tmp<=length(Q)));
	  if strcmp(tmp,'.man')
	    Q   = [Q(1:(min(d) - 1)) '.man'];
	  else
	    Q   = [Q(1:(min(d) - 1)) '.m'];
	  end
	  if exist(Q) == 2 & ~length(findstr(RefdTopics,Q))
	    RefdTopics = [RefdTopics,'|',Q]; end
    end
end
%-Update popup
set(hRTopics,'String',strrep(RefdTopics,['|',Topic],''),'Value',1)

set(Fhelp,'Pointer','Arrow')
return


elseif strcmp(lower(Action),lower('!Disp'))
%=======================================================================
% spm_help('!Disp',Fname,S,F,TTitle)
if nargin<5, TTitle=''; else, TTitle=P5; end
if nargin<4, F='Help'; else, F=P4; end
if nargin<3, S=''; else, S=P3; end
if nargin<2, Fname='spm.man'; else, Fname=P2; end
if isempty(TTitle), TTitle=Fname; end


%-Find (or create) window to print in
Fhelp = spm_figure('FindWin',F);
if isempty(Fhelp)
	Fhelp = spm_help('!CreateHelpWin');
else
	set(Fhelp,'Visible','on')
end
set(Fhelp,'Pointer','Watch')
spm_help('!Clear',Fhelp)

%-Parse text file/string
%-----------------------------------------------------------------------
if isempty(S)
	%-Load text file or get text from 'ShortTopics'
	fid = fopen(Fname,'r');
	if fid<0
		[S,Err] = spm_help('!ShortTopics',Fname);
	else
		S = setstr(fread(fid))';
		Err = 0;
		fclose(fid);
	end
end
q     = min([length(S),findstr(S,setstr([10 10]))]);	% find empty lines
q     = find(S(1:q(1)) == 10);				% find line breaks

figure(Fhelp)
hAxes = axes('Position',[0.05,0.05,0.8,0.85],...
		'Units','Points','Visible','off');
y     = floor(get(hAxes(1),'Position'));
y0    = y(3);
set(hAxes(1),'Ylim',[0,y0])
text(-0.05,y0,TTitle,'FontSize',16,'FontWeight','bold');
y     = y0 - 24;


%-Loop over pages & lines of text
%-----------------------------------------------------------------------
Vis     = 'on';
FmtLine = 1;
for i = 1:(length(q) - 1)
	d = S((q(i) + 1):(q(i + 1) - 1));
	if d(1) == abs('%');
		%-For some reason, '|' characters cause a CR.
		d = strrep(d,'|','I');
		h = text(0,y,d(2:length(d)),...
			'FontName','Courier','FontSize',10,'Visible',Vis);
		if FmtLine
			set(h,'FontWeight','bold',...
				'FontName','Times','FontSize',12);
			y=y-5;
			FmtLine=0;
		end
		y = y - 7;
	end
	if y<0 %-Start new page
		text(0.5,-10,['Page ',num2str(length(hAxes))],...
			'FontSize',8,'FontAngle','Italic',...
			'Visible',Vis)
		spm_figure('NewPage',get(gca,'Children'))
		hAxes = [hAxes,axes('Position',[0.05,0.05,0.8,0.85],...
			'Units','Points','Visible','off')];
		set(hAxes(length(hAxes)),'Ylim',[0,y0])
		y     = y0;
		Vis   = 'off';
	end
end
if strcmp(Vis,'off')
	%-Label last page
	text(0.5,-10,['Page ',num2str(length(hAxes))],...
		'FontSize',8,'FontAngle','Italic',...
		'Visible',Vis)
	spm_figure('NewPage',get(gca,'Children'))
end
set(Fhelp,'Pointer','Arrow')
return


elseif strcmp(lower(Action),lower('!Create'))
%=======================================================================
% F = spm_help('!Create')
%-Condition arguments

F = spm_help('!CreateHelpWin');
spm_help('!CreateBar',F)
spm_figure('WaterMark',F,spm('Ver'),'NoDelete')
R1 = F;
return


elseif strcmp(lower(Action),lower('!CreateHelpWin'))
%=======================================================================
% F = spm_help('!CreateHelpWin')

F = spm_figure('FindWin','Help');
if any(F), return, end

%-Draw window
%-----------------------------------------------------------------------
S0     = get(0,'ScreenSize');
WS     = [S0(3)/1152 S0(4)/900 S0(3)/1152 S0(4)/900];

F      = figure('Position',[S0(3)/2-300 008 600 865].*WS,...
	'Name','SPMhelp',...
	'Tag','Help',...
	'NumberTitle','off',...	'Tag','Help',...
	'Resize','off',...
	'Visible','off',...
	'PaperPosition',[.75 1.5 7 9.5],...
	'PaperType','a4letter',...
	'DefaultTextFontSize',2*round(12*min(WS)/2),...
	'Color','w',...
	'Colormap',gray(64));
whitebg(F,'w')
set(F,'Visible','on')
R1 = F;
return


elseif strcmp(lower(Action),lower('!CreateBar'))
%=======================================================================
% spm_help('!CreateBar',F)
%-----------------------------------------------------------------------
% Print | Clear		| Current Topic		| Menu	| Help | Quit
%   SPMver		| Referenced Topics	| Previous Topics
%-----------------------------------------------------------------------

if nargin<2, F='Help'; else, F = P2; end
F=spm_figure('FindWin',F);
if isempty(F), error('Help figure not found'), end

%-Get position and size parameters
%-----------------------------------------------------------------------
figure(F);
set(F,'Units','Pixels');
P     = get(F,'Position'); P  = P(3:4);		% Figure dimensions {pixels}
S_Gra = P./[600, 865];				% x & y scaling coefs

nBut  = 10;
nGap  = 4;
sx    = floor(P(1)./(nBut+(nGap+2)/6));		% uicontrol object width
dx    = floor(2*sx/6);				% inter-uicontrol gap
sy    = floor(20*S_Gra(1));			% uicontrol object height
x0    = dx;					% initial x position
x     = dx;					% uicontrol x position
y     = P(2) - sy;				% uicontrol y position
y2    = P(2) - 2.25*sy;				% uicontrol y position

%-Delete any existing 'NoDelete' ToolBar objects
%-----------------------------------------------------------------------
h = findobj(F,'Tag','NoDelete');
delete(h);

%-Create Frame for controls
%-----------------------------------------------------------------------
uicontrol(F,'Style', 'Frame',...
	'Position',[-4 (P(2) - 2.50*sy) P(1)+8 2.50*sy+4],...
	'Tag','NoDelete','UserData','HelpBar');

%-Create uicontrol objects
%-----------------------------------------------------------------------
uicontrol(F,'String','Print' ,'Position',[x y sx sy],...
	'CallBack','spm_figure(''Print'',gcf)',...
	'Interruptible','No',...
	'Tag','NoDelete','ForegroundColor','b'); x = x+sx;

uicontrol(F,'String','Clear' ,'Position',[x y sx sy],...
	'CallBack','spm_help(''!Clear'',gcf)',...
	'Interruptible','No',...
        'Tag','NoDelete','ForegroundColor','b'); x = x+sx+dx;

uicontrol(F,'String',sprintf('About %s',spm('Ver')),...
	'Position',[x0 y2 2*sx sy],...
	'HorizontalAlignment','Center',...
	'Callback','spm_help(''spm.man'')',...
	'Tag','NoDelete','ForegroundColor',[0 1 1])

uicontrol(F,'Style','Text','String','Topic ',...
	'Position',[x y sx sy],...
	'HorizontalAlignment','Right',...
	'Tag','NoDelete','ForegroundColor','k')

uicontrol(F,'Style','PopUp',...
	'Position',[x-1,y2-1,4*sx+1,sy],...
	'String','Referenced Topics...',...
	'Callback',...
		'spm_help(get(gco,''Value''))',...
	'Tag','NoDelete',...
	'UserData','RefdTopics',...
	'HorizontalAlignment','Left',...
	'ForegroundColor','k'), x = x+sx;

uicontrol(F,'Style','Edit',	'String','<topic>',...
	'Position',[x y 3*sx sy],...
	'CallBack','spm_help(get(gco,''String''))',...
	'Tag','NoDelete',...
	'UserData','Topic',...
	'ForegroundColor','k','BackgroundColor',[.8,.8,1],...
	'HorizontalAlignment','Center'), x = x+3*sx+dx;

uicontrol(F,'String','Menu',   'Position',[x y sx sy],...
	'CallBack','spm_help(''Menu'')',...
	'Interruptible','No',...
	'Tag','NoDelete','ForegroundColor',[0 1 1])

uicontrol(F,'Style','PopUp',...
	'Position',[x-1,y2-1,3*sx+2*dx+1,sy],...
	'String',str2mat('Previous Topics...','spm.man'),...
	'Callback',...
		'spm_help(get(gco,''Value''))',...
	'Tag','NoDelete',...
	'UserData','PrevTopics',...
	'HorizontalAlignment','Left',...
	'ForegroundColor','k'), x = x+sx+dx;

uicontrol(F,'String','Help',   'Position',[x y sx sy],...
	'CallBack','spm_help(''spm_help.m'')',...
	'Interruptible','No',...
	'Tag','NoDelete','ForegroundColor','g'), x = x+sx+dx;

uicontrol(F,'String','Quit',   'Position',[x y sx sy],...
	'CallBack','spm_help(''!Quit'')',...
	'Interruptible','No',...
	'Tag','NoDelete','ForegroundColor','r')
return


elseif strcmp(lower(Action),lower('!Clear'))
%=======================================================================
% spm_help('!Clear',F)
%-Clear window, leaving 'NoDelete' 'Tag'ed objects, hiding 'HelpMenu'
% 'UserData' Tagged objects.

%-Sort out arguments
%-----------------------------------------------------------------------
if nargin<2, F='Help'; else, F = P2; end
F=spm_figure('FindWin',F);
if isempty(F), return, end

%-Clear figure & make 'HelpMenu' objects invisible
%-----------------------------------------------------------------------
for h = get(F,'Children')'
	if ~strcmp(get(h,'Tag'),'NoDelete'), delete(h), end
end
set(findobj(F,'UserData','HelpMenu'),'Visible','off')
return


elseif strcmp(lower(Action),lower('!ContextHelp'))
%=======================================================================
% h = spm_help('!ContextHelp',Topic)
if nargin<2, return, end

if spm('isGCmdLine')
	fprintf('\nSPM: Type `help %s` for help on this routine.\n',Topic)
else
	Finter = spm_figure('FindWin','Interactive');
	if isempty(Finter), error('Can''t find interactive window'), end
	S2 = get(Finter,'Position');
	h = uicontrol(Finter,'String','?',...
		'CallBack',['spm_help(''',Topic,''')'],...
		'ForegroundColor','g',...
		'Position',[S2(3)-20 5 15 15]);
	R1 = h;
end
return


else
%=======================================================================
error('Unknown action string')

%=======================================================================
end
