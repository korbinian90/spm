function V = spm_create_vol(V,varargin)
% Create an image file.
% FORMAT Vo = spm_create_vol(Vi,['noopen'])
% Vi   - data structure containing image information.
%      - see spm_vol for a description.
% 'noopen' - optional flag to say "don't open/create the image file".
% Vo   - data structure after modification for writing.
%_______________________________________________________________________
% %W% John Ashburner %E%
for i=1:prod(size(V)),
	v = create_vol(V(i),varargin{:});
	f = fieldnames(v);
	for j=1:size(f,1),
		%eval(['V(i).' f{j} ' = v.' f{j} ';']);
		V = setfield(V,{i},f{j},getfield(v,f{j}));
	end;
end;
return;
%_______________________________________________________________________
%_______________________________________________________________________
function V = create_vol(V,varargin)
if ~isfield(V,'n')       | isempty(V.n),       V.n       = 1;                 end;
if ~isfield(V,'descrip') | isempty(V.descrip), V.descrip = 'SPM2 compatible'; end;
if ~isfield(V,'hdr')     | isempty(V.hdr),     V.hdr     = create_defaults;   end;

% Orientation etc...
M = V.mat;
if spm_flip_analyze_images, M = diag([-1 1 1 1])*M; end;
vx     = sqrt(sum(M(1:3,1:3).^2));
if det(M(1:3,1:3))<0, vx(1) = -vx(1); end;
origin = M\[0 0 0 1]';
origin = round(origin(1:3));

V.hdr.dime.pixdim(2:4) = vx;
V.hdr.dime.dim(2:4)    = V.dim(1:3);
V.hdr.dime.dim(5)      = V.n;
V.hdr.hist.origin(1:3) = origin;

dt = spm_type(spm_type(V.dim(4)));
if any(dt == [128+2 128+4 128+8]),
	% Convert to a form that Analyze will support
	dt = dt - 128;
	if spm_type(V.dim(4),'swapped')
		V.dim(4) = dt*256;
	end;
end;
V.hdr.dime.datatype    = dt;
V.hdr.dime.bitpix      = spm_type(dt,'bits');

if spm_type(dt,'intt'),

	if 0, % Allow DC offset
	V.hdr.dime.glmax    = spm_type(dt,'maxval');
	V.hdr.dime.glmin    = spm_type(dt,'minval');
	V.hdr.dime.cal_max  = max(V.hdr.dime.glmax*V.pinfo(1,:) + V.pinfo(2,:));
	V.hdr.dime.cal_min  = min(V.hdr.dime.glmin*V.pinfo(1,:) + V.pinfo(2,:));
	V.hdr.dime.funused1 = 0;
	scal                = (V.hdr.dime.cal_max - V.hdr.dime.cal_min)/...
	                      (V.hdr.dime.glmax   - V.hdr.dime.glmin);
	dcoff               =  V.hdr.dime.cal_min - V.hdr.dime.glmin*scal;
	V.pinfo             = [scal dcoff 0]';

	else, % Don't allow DC offset
	V.hdr.dime.glmax    = spm_type(dt,'maxval');
	V.hdr.dime.glmin    = 0;
	V.hdr.dime.cal_max  = max(V.hdr.dime.glmax*V.pinfo(1,:) + V.pinfo(2,:));
	V.hdr.dime.cal_min  = 0;
	V.hdr.dime.funused1 = V.hdr.dime.cal_max/V.hdr.dime.glmax;
	V.pinfo             = [V.hdr.dime.funused1 0 0]';
	end;

else,
	V.hdr.dime.glmax    = 1;
	V.hdr.dime.glmin    = 0;
	V.hdr.dime.cal_max  = 1;
	V.hdr.dime.cal_min  = 0;
	V.hdr.dime.funused1 = 1;
end;

d                      = 1:min([length(V.descrip) 79]);
hist.descrip	       = char(zeros(1,80));
V.hdr.hist.descrip(d)  = V.descrip(d);
V.hdr.hk.db_name       = char(zeros(1,18));
[pth,nam,ext]          = fileparts(V.fname);
d                      = 1:min([length(nam) 17]);
V.hdr.hk.db_name(d)    = nam(d);
mach                   = 'native';

fname         = fullfile(pth,[nam, '.hdr']);
[hdr,swapped] = spm_read_hdr(fname);

if ~isempty(hdr) & (hdr.dime.dim(5)>1 | V.n>1),
	% cannot simply overwrite the header

	hdr.dime.dim(5) = max(V.hdr.dime.dim(5),hdr.dime.dim(5));
	if any(V.hdr.dime.dim(2:4) ~= hdr.dime.dim(2:4))
		error('Incompatible image dimensions');
	end;

	if sum((V.hdr.dime.pixdim(2:4)-hdr.dime.pixdim(2:4)).^2)>1e-6,
		error('Incompatible voxel sizes');
	end;

	V.dim(4) = spm_type(hdr.dime.datatype);
	if swapped,
		if spm_platform('bigend'), mach = 'ieee-le'; else, mach = 'ieee-be'; end;
	end;

	if hdr.dime.funused1,
		scal  = hdr.dime.funused1;
		dcoff = 0;
	else
		if hdr.dime.glmax-hdr.dime.glmin & hdr.dime.cal_max-hdr.dime.cal_min,
			scal  = (hdr.dime.cal_max-hdr.dime.cal_min)/(hdr.dime.glmax-hdr.dime.glmin);
			dcoff = hdr.dime.cal_min - scal*hdr.dime.glmin;
		else,
			scal  = 1;
			dcoff = 0;
			warning(['Assuming a scalefactor of 1 for "' V.fname '".']);
		end;
	end;
	V.pinfo(1:2)    = [scal dcoff]';
	hdr.dime.dim(5) = max(hdr.dime.dim(5),V.hdr.dime.dim(5));
	V.hdr           = hdr;
end;

V.pinfo(3) = prod(V.hdr.dime.dim(2:4))*V.hdr.dime.bitpix/8*(V.n-1);

fid           = fopen(fname,'w',mach);
if (fid == -1),
	error(['Error opening ' fname '. Check that you have write permission.']);
end;

write_hk(fid,V.hdr.hk);
write_dime(fid,V.hdr.dime);
write_hist(fid,V.hdr.hist);
fclose(fid);

fname = fullfile(pth,[nam, '.mat']);
off   = -vx'.*origin;
mt    = [vx(1) 0 0 off(1) ; 0 vx(2) 0 off(2) ; 0 0 vx(3) off(3) ; 0 0 0 1];
if spm_flip_analyze_images, mt = diag([-1 1 1 1])*mt; end;

if sum((V.mat(:) - mt(:)).*(V.mat(:) - mt(:))) > eps*eps*12 | exist(fname)==2,
	if exist(fname)==2,
		clear mat
		str = load(fname);
		if isfield(str,'mat'),
			mat = str.mat;
		elseif isfield(str,'M'),
			mat = str.M;
			if spm_flip_analyze_images,
				for i=1:size(mat,3),
					mat(:,:,i) = diag([-1 1 1 1])*mat(:,:,i);
				end;
			end;
		end;
		mat(:,:,V.n) = V.mat;
		try,
			save(fname,'mat','-append');
		catch, % Mat-file was probably Matlab 4
			save(fname,'mat');
		end;
	else,
		clear mat
		mat(:,:,V.n) = V.mat;
		save(fname,'mat');
	end;
end;

if ~(nargin>1 & strcmp(varargin{1},'noopen')),
	fname         = fullfile(pth,[nam, '.img']);
	V.fid         = fopen(fname,'r+',mach);
	if (V.fid == -1),
		V.fid     = fopen(fname,'w',mach);
		if (V.fid == -1),
			error(['Error opening ' fname '. Check that you have write permission.']);
		end;
	end;
end;
return;
%_______________________________________________________________________
%_______________________________________________________________________
function write_hk(fid,hk)
% write (struct) header_key
%-----------------------------------------------------------------------
fseek(fid,0,'bof');
fwrite(fid,hk.sizeof_hdr,	'int32');
fwrite(fid,hk.data_type,	'char' );
fwrite(fid,hk.db_name,		'char' );
fwrite(fid,hk.extents,		'int32');
fwrite(fid,hk.session_error,'int16');
fwrite(fid,hk.regular,		'char' );
if fwrite(fid,hk.hkey_un0,		'char' )~= 1,
	error(['Error writing '  fopen(fid) '. Check your disk space.']);
end;
return;
%_______________________________________________________________________
%_______________________________________________________________________
function write_dime(fid,dime)
% write (struct) image_dimension
%-----------------------------------------------------------------------
fseek(fid,40,'bof');
fwrite(fid,dime.dim,		'int16');
fwrite(fid,dime.vox_units,	'uchar' );
fwrite(fid,dime.cal_units,	'uchar' );
fwrite(fid,dime.unused1,	'int16' );
fwrite(fid,dime.datatype,	'int16');
fwrite(fid,dime.bitpix,		'int16');
fwrite(fid,dime.dim_un0,	'int16');
fwrite(fid,dime.pixdim,		'float');
fwrite(fid,dime.vox_offset,	'float');
fwrite(fid,dime.funused1,	'float');
fwrite(fid,dime.funused2,	'float');
fwrite(fid,dime.funused2,	'float');
fwrite(fid,dime.cal_max,	'float');
fwrite(fid,dime.cal_min,	'float');
fwrite(fid,dime.compressed,	'int32');
fwrite(fid,dime.verified,	'int32');
fwrite(fid,dime.glmax,		'int32');
if fwrite(fid,dime.glmin,		'int32')~=1,
	error(['Error writing '  fopen(fid) '. Check your disk space.']);
end;
return;
%_______________________________________________________________________
%_______________________________________________________________________
function write_hist(fid,hist)
% write (struct) data_history
%-----------------------------------------------------------------------
fseek(fid,148,'bof');
fwrite(fid,hist.descrip,	'uchar');
fwrite(fid,hist.aux_file,	'uchar');
fwrite(fid,hist.orient,		'uchar');
fwrite(fid,hist.origin,		'int16');
fwrite(fid,hist.generated,	'uchar');
fwrite(fid,hist.scannum,	'uchar');
fwrite(fid,hist.patient_id,	'uchar');
fwrite(fid,hist.exp_date,	'uchar');
fwrite(fid,hist.exp_time,	'uchar');
fwrite(fid,hist.hist_un0,	'uchar');
fwrite(fid,hist.views,		'int32');
fwrite(fid,hist.vols_added,	'int32');
fwrite(fid,hist.start_field,'int32');
fwrite(fid,hist.field_skip,	'int32');
fwrite(fid,hist.omax,		'int32');
fwrite(fid,hist.omin,		'int32');
fwrite(fid,hist.smax,		'int32');
if fwrite(fid,hist.smin,		'int32')~=1,
	error(['Error writing '  fopen(fid) '. Check your disk space.']);
end;
return;
%_______________________________________________________________________
%_______________________________________________________________________
function hdr = create_defaults
hk.sizeof_hdr	= 348;
hk.data_type	= ['dsr      ' 0];
hk.db_name		= char(zeros(1,18));
hk.extents		= 0;
hk.session_error= 0;
hk.regular		= 'r';
hk.hkey_un0		= 0;

dime.dim		= [4 0 0 0 1 0 0 0];
dime.vox_units	= ['mm ' 0];
dime.cal_units	= char(zeros(1,8));
dime.unused1	= 0;
dime.datatype	= -1;
dime.bitpix		= 0;
dime.dim_un0	= 0;
dime.pixdim		= [0 1 1 1 1 0 0 0];
dime.vox_offset	= 0;
dime.funused1	= 1;
dime.funused2	= 0;
dime.funused3	= 0;
dime.cal_max	= 1;
dime.cal_min	= 0;
dime.compressed	= 0;
dime.verified	= 0;
dime.glmax		= 1;
dime.glmin		= 0;

hist.descrip	= char(zeros(1,80));
hist.descrip(1:length('SPM2 compatible')) = 'SPM2 compatible';
hist.aux_file	= char(zeros(1,24));
hist.orient		= char(0);
hist.origin		= [0 0 0  0 0];
hist.generated	= char(zeros(1,10));
hist.scannum	= char(zeros(1,10));
hist.patient_id	= char(zeros(1,10));
hist.exp_date	= char(zeros(1,10));
hist.exp_time	= char(zeros(1,10));
hist.hist_un0	= char(zeros(1,3));
hist.generated(1:5)	= 'today';
hist.views		= 0;
hist.vols_added	= 0;
hist.start_field= 0;
hist.field_skip	= 0;
hist.omax		= 0;
hist.omin		= 0;
hist.smax		= 0;
hist.smin		= 0;

hdr.hk   = hk;
hdr.dime = dime;
hdr.hist = hist;
return;
%_______________________________________________________________________
%_______________________________________________________________________
function savestruct(t,fname)
f=fieldnames(t);

