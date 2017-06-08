function [ data, loaded] = retrieveEphys( ephysFltr, dataType, dataPath)
%retrieveEphys Retrieves data from matfiles
%   inputs:
%       ephysFltr: ephysMeta file filtered for desired files
%       dataType: string naming data type to be retrieved (see ephysDB for
%       possible entries)

%get global vars and set names and data arrays
if nargin < 3
    global dataPath dataDir
else
    dataDir = 'Data';
end
if ~iscell(ephysFltr)
    ephysFltr = {ephysFltr};
end
if ~iscell(dataType)
    dataType = {dataType};    
end
dataNames = ephysFltr(:,1);
data = cell(size(dataNames,1),numel(dataType));
loaded = true(size(dataNames,1),numel(dataType));

%Loop over names and retrieve data
for i = 1:numel(dataNames)
    if exist(fullfile(dataPath, dataDir, [dataNames{i},'.mat']),'file') == 2
        dataFile = matfile(fullfile(dataPath, dataDir, [dataNames{i},'.mat']));    
        dataFields = who(dataFile);
        
        loaded(i,:) = ismember(dataType,dataFields);
        for j = find(loaded(i,:))
            data{i,j} = dataFile.(dataType{j});
        end
    else
        disp([dataPath, dataDir, dataNames{i},'.mat', ' does not exist']);
    end
end
end

