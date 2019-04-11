function [dat,hdr,list] = load_nii_datas(filename,untouch)
% [dat,hdr,list] = load_nii_datas(filename,untouch) loads nifti files
% if multiple files, the first image is used as reference
% INPUT
%   filename        char (handles wildcards **/ and *) or cell array of char
%   untouch         if false or empty, matrix is rotated to be in LPI
%                    orientation
%
% OUTPUT
%   dat             cell array of 4D matrix
%   hdr             header of the reference image (first image)
%   list            cell array of char listing filenames (useful if wildcards were used)
%
% EXAMPLE
%   [dat,hdr,list] = load_nii_datas('**\*.nii.gz')
%   img = cat(5,dat{:});
%   img = mean(img,5);
%   save_nii_datas(img,hdr,'Tmean.nii.gz')

if ~isdeployed
    A = which('nii_tool');
    if isempty(A)
        warning('Dependency to Xiangrui Li NIFTI tools is missing. http://www.mathworks.com/matlabcentral/fileexchange/42997');
        return
    end
end

if ~iscell(filename)
    if strcmp(filename(1:min(3,end)),'**/') || strcmp(filename(1:min(3,end)),'**\')
        list = tools_ls(filename(4:end),1,1,2,1);
    else
        list = tools_ls(filename,1,1,2,0);
    end
else
    list = filename;
end
list(cellfun(@ischar,list)) = cellfun(@(X) X{1},cellfun(@(X) strsplit(X,','),list(cellfun(@ischar,list)),'uni',0),'uni',0);

if isempty(list)
    error(['no files match ' filename])
end

%reslice images
if isstruct(list{1})
    hdr0 = list{1};
else
    hdr0 = nii_tool('hdr', list{1});
end
quat2R = nii_viewer('func_handle', 'quat2R');
if hdr0.sform_code>0
    R0 = [hdr0.srow_x; hdr0.srow_y; hdr0.srow_z; 0 0 0 1];
elseif hdr0.qform_code>0
    R0 = quat2R(hdr0);
end

del = [];
for ff=2:length(list)
    % same space???
    hdr = nii_tool('hdr', list{ff});
    if hdr.sform_code>0
        R1 = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
    elseif hdr.qform_code>0
        R1 = quat2R(hdr);
    else
        R1 = diag([1 1 1 1]);
    end
    % reslice
    if max(max(abs(R0-R1)))>1e-5
        originalfilename = list{ff};
        list{ff} = [tempname '.nii'];
        nii_xform(originalfilename,list{1},list{ff})
        del = [del ff];
    end
end

dat = {};
for iii=1:length(list)
    if isstruct(list{iii}) && isfield(list{iii},'img')
        nii = list{iii};
    elseif ischar(list{iii})
        nii = nii_tool('load',list{iii});
    else
        continue
    end
    if nargin==1 || (~isempty(untouch) && ~untouch)
        orient = get_orient_hdr(nii.hdr);
        nii = rotateimage(nii,orient);
    end
    if iii==1
        hdr = nii.hdr;
    end
    nii = nii.img;
    dat(end+1:end+size(nii(:,:,:,:,:),5)) = mat2cell(nii(:,:,:,:,:),size(nii,1),size(nii,2),size(nii,3),size(nii,4),ones(1,size(nii(:,:,:,:,:),5)));
end

% delete resliced images
for ff=del
    delete(list{ff})
end

function [list, path]=tools_ls(fname, keeppath, keepext, folders,arborescence,select)
% [list, path]=tools_ls(fname, keeppath?, keepext?, folders?,recursive?)
% Example: tools_ls('ep2d*')
% example 2: tools_ls('*',[],[],1) --> folders only
% example 3: tools_ls('*',[],[],2) --> files only

if nargin < 2, keeppath=0; end
if nargin < 3, keepext=1; end
if nargin < 4 || isempty(folders), folders=0; end
if nargin < 6 || isempty(select), select=0; end
if nargin < 5, arborescence=0; end

% [list, path]=tools_ls('*T.txt);
list=dir(fname);
[path,name,ext]= fileparts(fname); 
path=[path filesep]; name = [name ext];
if strcmp(path,filesep)
    path=['.' filesep];
end

if folders==1
    list=list(cat(1,list.isdir));
elseif folders==2
    list=list(~cat(1,list.isdir));
end

% sort by name
list=sort_nat({list.name})';


% remove files starting with .
list(cellfun(@(x) strcmp(x(1),'.'), list))=[];
if keeppath
    for iL=1:length(list)
        list{iL}=[path list{iL}];
    end
end
pathcur = path;
path = repmat({path},[length(list),1]);

if ~keepext
    list=cellfun(@(x) sct_tool_remove_extension(x,keeppath),list,'UniformOutput',false);
end

if arborescence
    listdir = tools_ls(pathcur,1,1,1);
    for idir = 1:length(listdir)
        [listidir, pathidir]=tools_ls([listdir{idir} filesep name], keeppath, keepext, folders,arborescence,0);
        list = [list; listidir];
        path = cat(1,path, pathidir{:});
    end
end

if select, list=list{select}; end

function nii = rotateimage(nii,orient)
if ~isequal(orient, [1 2 3])
    nii.hdr.dim(nii.hdr.dim==0)=1;
    old_dim = nii.hdr.dim([2:4]);
    
    %  More than 1 time frame
    %
    if ndims(nii.img) > 3
        pattern = 1:prod(old_dim);
    else
        pattern = [];
    end
    
    if ~isempty(pattern)
        pattern = reshape(pattern, old_dim);
    end
    
    %  calculate for rotation after flip
    %
    rot_orient = mod(orient + 2, 3) + 1;
    
    %  do flip:
    %
    flip_orient = orient - rot_orient;
    
    for ii = 1:3
        if flip_orient(ii)
            if ~isempty(pattern)
                pattern = flipdim(pattern, ii);
            else
                nii.img = flipdim(nii.img, ii);
            end
        end
    end
    
    %  get index of orient (rotate inversely)
    %
    [~, rot_orient] = sort(rot_orient);
    
    new_dim = old_dim;
    new_dim = new_dim(rot_orient);
    nii.hdr.dim([2:4]) = new_dim;
    
    new_pixdim = nii.hdr.pixdim([2:4]);
    new_pixdim = new_pixdim(rot_orient);
    nii.hdr.pixdim([2:4]) = new_pixdim;
    
    %  re-calculate originator

    flip_orient = flip_orient(rot_orient);
    nii.hdr.rot_orient = rot_orient;
    nii.hdr.flip_orient = flip_orient;
    
    %  do rotation:
    %
    if ~isempty(pattern)
        pattern = permute(pattern, rot_orient);
        pattern = pattern(:);
        
        if nii.hdr.datatype == 32 | nii.hdr.datatype  == 1792 | ...
                nii.hdr.datatype  == 128 | nii.hdr.datatype  == 511
            
            tmp = reshape(nii.img(:,:,:,1), [prod(new_dim) nii.hdr.dim(5:8)]);
            tmp = tmp(pattern, :);
            nii.img(:,:,:,1) = reshape(tmp, [new_dim       nii.hdr.dim(5:8)]);
            
            tmp = reshape(nii.img(:,:,:,2), [prod(new_dim) nii.hdr.dim(5:8)]);
            tmp = tmp(pattern, :);
            nii.img(:,:,:,2) = reshape(tmp, [new_dim       nii.hdr.dim(5:8)]);
            
            if nii.hdr.datatype == 128 | nii.hdr.datatype == 511
                tmp = reshape(nii.img(:,:,:,3), [prod(new_dim) nii.hdr.dim(5:8)]);
                tmp = tmp(pattern, :);
                nii.img(:,:,:,3) = reshape(tmp, [new_dim       nii.hdr.dim(5:8)]);
            end
            
        else
            nii.img = reshape(nii.img, [prod(new_dim) nii.hdr.dim(5:8)]);
            nii.img = nii.img(pattern, :);
            nii.img = reshape(nii.img, [new_dim       nii.hdr.dim(5:8)]);
        end
    else
        if nii.hdr.datatype == 32 | nii.hdr.datatype == 1792 | ...
                nii.hdr.datatype == 128 | nii.hdr.datatype == 511
            
            nii.img(:,:,:,1) = permute(nii.img(:,:,:,1), rot_orient);
            nii.img(:,:,:,2) = permute(nii.img(:,:,:,2), rot_orient);
            
            if nii.hdr.datatype == 128 | nii.hdr.datatype == 511
                nii.img(:,:,:,3) = permute(nii.img(:,:,:,3), rot_orient);
            end
        else
            nii.img = permute(nii.img, rot_orient);
        end
    end
else
    nii.hdr.rot_orient = [];
    nii.hdr.flip_orient = [];
end

function [cs,index] = sort_nat(c,mode)
%sort_nat: Natural order sort of cell array of strings.
% usage:  [S,INDEX] = sort_nat(C)
%
% where,
%    C is a cell array (vector) of strings to be sorted.
%    S is C, sorted in natural order.
%    INDEX is the sort order such that S = C(INDEX);
%
% Natural order sorting sorts strings containing digits in a way such that
% the numerical value of the digits is taken into account.  It is
% especially useful for sorting file names containing index numbers with
% different numbers of digits.  Often, people will use leading zeros to get
% the right sort order, but with this function you don't have to do that.
% For example, if C = {'file1.txt','file2.txt','file10.txt'}, a normal sort
% will give you
%
%       {'file1.txt'  'file10.txt'  'file2.txt'}
%
% whereas, sort_nat will give you
%
%       {'file1.txt'  'file2.txt'  'file10.txt'}
%
% See also: sort

% Version: 1.4, 22 January 2011
% Author:  Douglas M. Schwarz
% Email:   dmschwarz=ieee*org, dmschwarz=urgrad*rochester*edu
% Real_email = regexprep(Email,{'=','*'},{'@','.'})


% Set default value for mode if necessary.
if nargin < 2
	mode = 'ascend';
end

% Make sure mode is either 'ascend' or 'descend'.
modes = strcmpi(mode,{'ascend','descend'});
is_descend = modes(2);
if ~any(modes)
	error('sort_nat:sortDirection',...
		'sorting direction must be ''ascend'' or ''descend''.')
end

% Replace runs of digits with '0'.
c2 = regexprep(c,'\d+','0');

% Compute char version of c2 and locations of zeros.
s1 = char(c2);
z = s1 == '0';

% Extract the runs of digits and their start and end indices.
[digruns,first,last] = regexp(c,'\d+','match','start','end');

% Create matrix of numerical values of runs of digits and a matrix of the
% number of digits in each run.
num_str = length(c);
max_len = size(s1,2);
num_val = NaN(num_str,max_len);
num_dig = NaN(num_str,max_len);
for i = 1:num_str
	num_val(i,z(i,:)) = sscanf(sprintf('%s ',digruns{i}{:}),'%f');
	num_dig(i,z(i,:)) = last{i} - first{i} + 1;
end

% Find columns that have at least one non-NaN.  Make sure activecols is a
% 1-by-n vector even if n = 0.
activecols = reshape(find(~all(isnan(num_val))),1,[]);
n = length(activecols);

% Compute which columns in the composite matrix get the numbers.
numcols = activecols + (1:2:2*n);

% Compute which columns in the composite matrix get the number of digits.
ndigcols = numcols + 1;

% Compute which columns in the composite matrix get chars.
charcols = true(1,max_len + 2*n);
charcols(numcols) = false;
charcols(ndigcols) = false;

% Create and fill composite matrix, comp.
comp = zeros(num_str,max_len + 2*n);
comp(:,charcols) = double(s1);
comp(:,numcols) = num_val(:,activecols);
comp(:,ndigcols) = num_dig(:,activecols);

% Sort rows of composite matrix and use index to sort c in ascending or
% descending order, depending on mode.
[unused,index] = sortrows(comp);
if is_descend
	index = index(end:-1:1);
end
index = reshape(index,size(c));
cs = c(index);

