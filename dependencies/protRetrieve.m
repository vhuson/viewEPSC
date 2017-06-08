function [ ephysFltr, protMeta ] = protRetrieve( protID, ephysFltr, dataPath)
%protRetrieve find requested or query matching protocols
%   Takes in either a search term (string data Type or condition), 
%   or a protocol ID (numerical) and retrieves matching ephysMeta entries 
%   and protocol meta info.

%Retrieve global variables and set ephysFltr when not given
if nargin < 3
    global dataPath dataDir fileList ephysMeta setDir
end

%Retrieve protocol info: (collumn-wise) 1: protocol ID (incrementing
%int64); 2: protocol meta (cell matrix); 3: Protocol length in data points
%(double);
load(fullfile(dataPath,'Protocols','allProts.mat'));
if nargin == 0 %no input return all prots
    ephysFltr = allProts;
    protMeta = [];
    return
end
if ~exist('ephysFltr','var')
    ephysFltr = ephysMeta;
else
    %only search protocols available in ephysFltr
    fltrProts = unique(cell2mat(ephysFltr(:,21)));
    allProts = allProts(ismember([allProts{:,1}],fltrProts),:);
end



if iscell(protID) && ~iscellstr(protID); protID = [protID{:}]; end

%Find out if ID or search query is given and perform relevant operation
if ~isnumeric(protID) %input is string search protocols
    %Find string matches in dataType and comment collumns and return any
    %protocols containing matches
    searchIdx = cellfun(@(x) cellfun(@isempty,regexpi(x(:,[1,4]),protID)),...
        allProts(:,2),'UniformOutput',false);
    protIdx = cellfun(@(x) any(~x(:)), searchIdx);
    protMeta = allProts(protIdx,:);
else
    protMeta = allProts(ismember([allProts{:,1}],protID),:);
end
if ~isempty(protMeta)
    ephysFltr = selectEphys(protMeta(:,1),21,ephysFltr);
else
    disp('No matches found, ephysFltr not updated');
end
end
    
%save(fullfile(dataPath,'Protocols','allProts.mat'),'allProts')