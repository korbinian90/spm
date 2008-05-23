function [str, tag, cind, ccnt] = gencode(item, tag, tagctx, stoptag, tropts)

% function [str, tag, cind, ccnt] = gencode(item, tag, tagctx, stoptag, tropts)
% Generate code to recreate a generic item. This code does not deal with
% arrays of cfg_items, such a configuration should not exist with the
% current definition of a configuration tree.
%
% Traversal options
% struct with fields
% stopspec - match spec to stop forced setting of eflag
% dflag    - (not used here)
% clvl     - current level in tree
% mlvl     - maximum level to force settings - range 1 (top level only) to
%            Inf (all levels)
% cnt      - item count - used for unique tags
% mcnt     - (not evaluated here)
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: gencode.m 1716 2008-05-23 08:18:45Z volkmar $

rev = '$Rev: 1716 $'; %#ok

%% Parent object
% Generate generic object
[str tag cind ccnt] = gencode(item.cfg_item, tag, tagctx, stoptag, tropts);
% Check whether to generate code - ccnt == 0 means that generic object did
% not return code
if (tropts.clvl > tropts.mlvl || (~isempty(tropts.stopspec) && match(item, tropts.stopspec))) || ccnt == 0
    str = {};
    cind = [];
    ccnt = 0;
    return;
end;
% Reclassify generic object
str{cind} = sprintf('%s         = %s;', tag, class(item));
%% Strtype
% Generate strtype field
if ~isempty(item.strtype)
    str1 = gencode(item.strtype, sprintf('%s.strtype', tag), stoptag, tropts);
    str = {str{:} str1{:}};
end;
%% Num
% Generate num field
str{end+1} = sprintf('%s.num     = [%s];', tag, num2str(item.num));
%% Def
% Do not create deprecated def field
%% Extras
% Generate extras field
if ~isempty(item.extras)
    str1 = gencode(item.extras, sprintf('%s.extras', tag), stoptag, tropts);
    str = {str{:} str1{:}};
end;