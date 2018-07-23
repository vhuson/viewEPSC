function [ ephysFltr, compIdx ] = selectEphys( opQuery, idx, ephysFltr )
%findEphys find matching data and returns filtered meta info and indexes
%   Takes in search term and column index (optional), returns meta matching search
%   Optionally add ephysFltr to select within limited meta
if nargin < 3 || isempty(ephysFltr)
    %not meta input load from file
    global dataPath ephysMeta
    ephysFltr = ephysMeta;
end

if nargin < 2 || isempty(idx)
    %no idx search all
    idx = 1:size(ephysFltr,2);
end

%put numeric arrays in cell
if isnumeric(opQuery)
    opQuery = num2cell(opQuery);
end


if iscellstr(opQuery)
    %Convert to normal string with | separator
    cellQuery = opQuery;
    opQuery = cellQuery{1};
    if numel(cellQuery) ~= 1
        for i = 2:numel(cellQuery)
            opQuery = [opQuery,'|',cellQuery{i}];
        end
    end
end
if iscell(opQuery)
    %input is numeric cell array logic not supported just compare
    compIdx = ismember(cell2mat(ephysFltr(:,idx)),cell2mat(opQuery));
else
    %Check if multiple conditions need to be met
    numAnd = regexp(opQuery,'&');
    
    if ~isempty(numAnd)
        stopAnd = [numAnd-1,numel(opQuery)];
        startAnd = [1,numAnd+1];
        
        %Seperate strings
        for i = 1:numel(stopAnd)
            allQuery{i} = opQuery(startAnd(i):stopAnd(i));
        end
    else
        allQuery{1} = opQuery;
    end
    
    for i = 1:numel(allQuery)
        opQuery = allQuery{i};
        
        %find logical operators in query_
        logic = '~|>|<';
        idxLogic = regexpi(opQuery,logic);
        
        %seperate query from operator
        query = opQuery;
        if ~isempty(idxLogic)
            opLogic = query(idxLogic);
            query(idxLogic) = [];
            
        else
            opLogic = '';
        end
        
        %check if char cols are tested
        metaTypes = cellfun(@class,ephysFltr(1,:),'UniformOutput',0);
        charIdx = strcmp(metaTypes(idx),'char');
        
        charQuery = 1;
        if any(charIdx) && isempty(regexpi(opLogic,'>|<'))
            %for char check if query matches any entries and create logical vector
            charCompData = num2cell(~cellfun(@isempty,regexpi(ephysFltr(:,idx(charIdx)),query)));
        end
        
        numOr = regexp(query,'\|');
        numQuery = [];
        if ~isempty(numOr)
            numFound = str2num(query(1:numOr-1));
            if ~isempty(numFound)
                numQuery(end+1) = numFound;
            end
            for j=1:numel(numOr)-1
                numFound = str2num(query(numOr(j)+1:numOr(j+1)-1));
                if ~isempty(numFound)
                    numQuery(end+1) = numFound;
                end
            end
            numFound = str2num(query(numOr(end)+1:end));
            if ~isempty(numFound)
                numQuery(end+1) = numFound;
            end
        else
            numQuery = str2num(query);
        end
        
        if ~isempty(numQuery)
            %for others get Data to be checked and set query to numeric
            numCompData = ephysFltr(:,idx(~charIdx));
        end
        
        %change logical operation depending on input
        charFunc = @(x) x==charQuery; %equals
        numFunc = @(x) x==numQuery; %equals
        if ~isempty(idxLogic)
            switch opQuery(idxLogic)
                case '~'    %not equals
                    charFunc = @(x) x~=charQuery;
                    numFunc = @(x) x~=numQuery;
                case '>'    %Greater than
                    charFunc = @(x) x>charQuery;
                    numFunc = @(x) x>numQuery;
                case '<'    %Less than
                    charFunc = @(x) x<charQuery;
                    numFunc = @(x) x<numQuery;
            end
        end
        
        %Create logical vector with requested logic operation
        if exist('charCompData','var')
            charCompIdx = cellfun(charFunc,charCompData,'UniformOutput',0);
            charCompIdx = cell2mat(cellfun(@(x) any(x(:)),charCompIdx,...
                'UniformOutput',0));
        end
        
        if exist('numCompData','var')
            numCompIdx = cellfun(numFunc,numCompData,'UniformOutput',0);
            numCompIdx = cell2mat(cellfun(@(x) any(x(:)),numCompIdx,...
                'UniformOutput',0));
            
            %Also check first number found in char idxes
            numConvFltr = cellfun(@(x) sscanf(x,'%g'),ephysFltr(:,idx(charIdx)),...
                'UniformOutput',false);
            numConvIdx = cellfun(numFunc,numConvFltr,'UniformOutput',0);
            numConvIdx = cell2mat(cellfun(@(x) any(x(:)),numConvIdx,...
                'UniformOutput',0));
            
            %Combine
            numCompIdx = [numCompIdx,numConvIdx];
        end
        
        
        if exist('charCompIdx','var') && exist('numCompIdx','var') %combine num and char
            compIdx = [charCompIdx,numCompIdx];
        elseif exist('charCompIdx','var')
            compIdx = charCompIdx;
        elseif exist('numCompIdx','var')
            compIdx = numCompIdx;
        end
        
        if size(compIdx,2) > 1 %Reduce from all idx to 1 collumn
            if strcmp(opQuery(idxLogic),'~')
                compIdx = any(~compIdx,2);
                compIdx = ~compIdx;
            else
                compIdx = any(compIdx,2);
            end
        end
        
        allCompIdx{i} = compIdx;
    end
    compIdx = all([allCompIdx{:}],2);
end
ephysFltr = ephysFltr(compIdx,:);   %Create filter
end

