function spm_clf(F)
% Clear specified figure of objects with visible handles
% FORMAT spm_clf(F)
% F	- Figure number, or 'Tag' string of figure(s) to clear
%___________________________________________________________________________
%
% Clears the specified figure, deleting all objects with visible handles.
% ('HandleVisibility'=='on').
%
% If the current window is 'Tag'ged interactive, then the figures name
% is cleared and the pointer reset.
%
% F Defaults to the current figure, if there is one.
%
% This is just a gateway to spm_figure('Clear',F).
%__________________________________________________________________________
% %W% Andrew Holmes %E%

%-Call spm_figure
%---------------------------------------------------------------------------
if nargin==0
	spm_figure('Clear')
else
	spm_figure('Clear',F)
end
