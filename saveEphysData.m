function [ unFound ] = saveEphysData( ephysPars, name, ephysFltr, range, dataPath)
%saveEphysData Take in parameters and save ephysData
%   ephysPars in cell array
if isempty(ephysFltr) %No filter assume there's a range
    global ephysMeta
    ephysFltr = ephysMeta;
elseif isempty(range) %No range mark all in filter
    range = 1:size(ephysFltr,1);
end

if ~exist('dataPath','var') || isempty(dataPath)
    %dataPath not given get global
    global dataPath
end

unFound = [];

%Put in cell if necessary
if ~iscell(ephysPars)
    ephysPars = {ephysPars};
end
altPath = [];
if iscell(dataPath)
    if numel(dataPath) > 1
        altPath = dataPath{2};
    end
    dataPath = dataPath{1};
end


%Check if uniform
parSizes = cellfun(@size, ephysPars,'UniformOutput', false);
try
    parSizes = vertcat(parSizes{:});
    if numel(unique(parSizes(:,1))) > 1 || numel(unique(parSizes(:,2))) > 1
        %Dimensions not uniform return
        disp('Warning, input dimensions should be uniform');
        return
    end
catch me
    %Dimensions not uniform return
    disp('Warning, input dimensions should be uniform');
    return
end

%Loop and store parameters
cellNames = ephysFltr(range,1);
for i = 1:numel(cellNames)
    if exist(fullfile(dataPath, 'Data', [cellNames{i},'.mat']),'file') == 2
        dataFile = matfile(fullfile(dataPath, 'Data', [cellNames{i},'.mat']),'Writable',true);
        dataFile.(name) = ephysPars{i};
    elseif exist(fullfile(altPath, 'Data', [cellNames{i},'.mat']),'file') == 2
        dataFile = matfile(fullfile(altPath, 'Data', [cellNames{i},'.mat']),'Writable',true);
        dataFile.(name) = ephysPars{i};
    else
        disp(['Warning, cell: ',fullfile(dataPath, 'Data', [cellNames{i},'.mat'])...
            ' not found']);
        unFound(end+1) = cellNames{i};
        continue
    end
end
end

