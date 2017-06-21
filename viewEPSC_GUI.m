function viewEPSC_GUI(ephysFltr,dataPath)
%viewEPSC_GUI Creates graphical interface for checking EPSC data
%   Optionally takes in ephysFltr as list for HS data and dataPath for file
%   loading
%Dependencies: retrieveEphys; protRetrieve; selectEphys; roughMiniDetect
%Can save variables:  ChargeIdx; AmpIdx; SyncTrace; predTrace; EmptyTrace;
% CorrTrace; ChargeValue; AmpValue; ArtIdx; Baseline; ChargeSetting; AmpSetting
% ArtSetting; BaseSetting;



%Check if viewEPSC_GUI is already open
if ~isempty(findobj('Tag','viewEPSC'))
    disp('Only one instance of viewEPSC_GUI is allowed');
    figure(findobj('Tag','viewEPSC')) %Make active window
    return
end


%Set up global variables
%global dataPath dataDir fileList ephysMeta setDir
if ~exist('ephysFltr','var') || isempty(ephysFltr) %Check if there is input
    %Set empty
    ephysFltr = [];
end

if ~exist('dataPath','var') || isempty(dataPath) %Check if there is input
    %Set empty
    dataPath = [];
end
if ~iscell(dataPath)
    dataPath = {dataPath};
end

%% Create Figure
viewEPSC = figure('OuterPosition', [100 100 1024 576],'Tag','viewEPSC',...
    'MenuBar','none','Toolbar','figure','Name','Plot EPSC','NumberTitle','off',...
    'CloseRequestFcn',@viewCloseRequest,'WindowStyle','normal');
%viewEPSC.UserData = {ephysFltr,protMeta,[]};
%get toolbar
viewToolbar = findall(viewEPSC,'Type','uitoolbar');
%Remove unnecessary Toolbar elements
pushTools = findall(viewEPSC,'Type','uipushtool');
toggleTools = findall(viewEPSC,'Type','uitoggletool');
brushTool = findall(viewEPSC,'Tag','Exploration.Brushing');
delete(pushTools); delete(brushTool);
delete(toggleTools([1:3,5]));

%% Set up appdata variables
setappdata(viewEPSC,'ephysFltr',[]);
setappdata(viewEPSC,'ephysDB',[]);
setappdata(viewEPSC,'dataPath',dataPath);

%1) Method, 2) Points and range
setappdata(viewEPSC,'baselineValues',[]);
%{{block1};{block2};{etc}}
setappdata(viewEPSC,'artifactSettings',[]);
%setappdata(viewEPSC,'artifactIdx',[]);
setappdata(viewEPSC, 'amplitudeSettings',[]);
setappdata(viewEPSC, 'chargeSettings',[]);
setappdata(viewEPSC,'miniSettings',[]);

setappdata(viewEPSC,'miniCoords',[]);
setappdata(viewEPSC,'miniFeatures',[]);
setappdata(viewEPSC,'miniTargets',[]);

%% Setup axes
viewPlot= axes(viewEPSC,'Position',[0.08,0.1,0.71,0.8],'Tag','viewPlot');
viewPlot.UserData = 0;

%% Datanames dropdown

% namesText = uicontrol(HSgui, 'Style','text','String','Cell:',...
%     'Units','normalized','Position', [0.01 0.93 0.05 0.04], 'Tag',...
%     'namesText');
viewNamesDrop = uicontrol(viewEPSC,'Style','popup','String',{'No data selected'},...
    'Units','normalized','Position', [0.05 0.88 0.23 0.1], 'Tag',...
    'viewNamesDrop','Callback', @viewEPSC_Plot);
viewCellCount = uicontrol(viewEPSC,'Style','text','String','0:',...
    'Units','normalized','Position', [0.001 0.945 0.049 0.03], 'Tag',...
    'viewCellCount','HorizontalAlignment','right');


%Button controls
viewFirstName = uicontrol(viewEPSC,'Style','pushbutton','String','<<',...
    'Units','normalized','Position', [0.28 0.94 0.025 0.04], 'Tag','viewFirstName',...
    'Callback', @viewEPSC_fileChange);
viewPrevName = uicontrol(viewEPSC,'Style','pushbutton','String','<',...
    'Units','normalized','Position', [0.305 0.94 0.025 0.04], 'Tag','viewPrevName',...
    'Callback', @viewEPSC_fileChange);
viewNextName = uicontrol(viewEPSC,'Style','pushbutton','String','>',...
    'Units','normalized','Position', [0.33 0.94 0.025 0.04], 'Tag','viewNextName',...
    'Callback', @viewEPSC_fileChange);
viewLastName = uicontrol(viewEPSC,'Style','pushbutton','String','>>',...
    'Units','normalized','Position', [0.355 0.94 0.025 0.04], 'Tag','viewLastName',...
    'Callback', @viewEPSC_fileChange);

%% Blind interface
% viewBlindText = uicontrol(viewEPSC, 'Style','text','String','Blind data:',...
%     'Units','normalized','Position', [0.385 0.93 0.1 0.04], 'Tag',...
%     'viewBlindText','Enable','off');
viewBlindCheck = uicontrol(viewEPSC,'Style','checkbox','String','Blind data',...
    'Units','normalized','Position', [0.385 0.935 0.1 0.04], 'Tag',...
    'viewBlindCheck','Callback', @viewEPSC_BlindFile,'Value',0,'Enable','on');
% viewBlindDrop = uicontrol(viewEPSC,'Style','popup','String','[No Blinds found]',...
%     'Units','normalized','Position', [0.47 0.88 0.25 0.1], 'Tag',...
%     'viewBlindDrop','Callback', @viewEPSC_BlindFile,'Enable','off');
% viewRevealCheck = uicontrol(viewEPSC,'Style','checkbox','String','Reveal',...
%     'Units','normalized','Position', [0.72 0.94 0.08 0.04], 'Tag',...
%     'viewRevealCheck','Callback', @viewEPSC_BlindFile,'Enable','off');

%% Load and manage data
%viewFrame = uipanel(viewEPSC, 'Units','normalized','Position', [0.81 0.08 0.185 0.915]);
viewLoadFrame = uipanel(viewEPSC, 'Units','normalized','Position', [0.81 0.86 0.185 0.13]);
%Load Data button and format select
viewLoadDrop = uicontrol(viewEPSC,'Style','popup','String',{'EphysDB','ABF','Matlab'},...
    'Units','normalized','Position', [0.9057 0.94 0.0831 0.04], 'Tag','viewLoadDrop',...
    'Value', 2);
viewLoadData = uicontrol(viewEPSC, 'Style','pushbutton','String','Load Data',...
    'Units','normalized','Position', [0.82 0.94 0.0831 0.04], 'Tag',...
    'viewLoadData','Callback', @(src,event)viewEPSC_loadData(viewLoadDrop));

%Application range checkboxes
viewApplyAllText = uicontrol(viewEPSC, 'Style','text','String','Apply to all:',...
    'Units','normalized','Position', [0.82 0.89 0.08 0.04], 'Tag',...
    'viewApplyAllText','HorizontalAlignment','left');
viewApplyAllCheck = uicontrol(viewEPSC,'Style','checkbox',...
    'Units','normalized','Position', [0.95 0.9 0.025 0.03], 'Tag',...
    'viewApplyAllCheck','Value',0,'Callback', @viewEPSC_doubleCheck);

viewApplyProtocolText = uicontrol(viewEPSC, 'Style','text','String','Apply to protocol:',...
    'Units','normalized','Position', [0.82 0.87 0.15 0.03], 'Tag',...
    'viewApplyProtocolText','HorizontalAlignment','left');
viewApplyProtocolCheck = uicontrol(viewEPSC,'Style','checkbox',...
    'Units','normalized','Position', [0.95 0.872 0.025 0.03], 'Tag',...
    'viewApplyProtocolCheck','Value',0,'Callback', @viewEPSC_doubleCheck);

%% EPSC Analysis
%Baseline
viewAnalysisFrame = uipanel(viewEPSC, 'Units','normalized','Position', [0.81 0.66 0.185 0.195]);

viewBaseline = uicontrol(viewEPSC,'Style','pushbutton','String','Correct Baseline',...
    'Units','normalized','Position', [0.82 0.81 0.15 0.04], 'Tag',...
    'viewBaseline','Callback', @viewEPSC_Baseline);
viewBaseCheck = uicontrol(viewEPSC,'Style','checkbox',...
    'Units','normalized','Position', [0.97 0.81 0.02 0.04], 'Tag',...
    'viewBaseCheck','Callback', @viewEPSC_Plot);

%Remove Artifacts
viewArtifacts = uicontrol(viewEPSC,'Style','pushbutton','String','Remove Artifacts',...
    'Units','normalized','Position', [0.82 0.765 0.15 0.04], 'Tag',...
    'viewArtifacts','Callback', @viewEPSC_Artifacts);
viewArtifactsCheck = uicontrol(viewEPSC,'Style','checkbox',...
    'Units','normalized','Position', [0.97 0.765 0.02 0.04], 'Tag',...
    'viewArtifactsCheck','Callback', @viewEPSC_Plot);

%Calculate Amplitude
viewAmplitude = uicontrol(viewEPSC,'Style','pushbutton','String','Amplitude',...
    'Units','normalized','Position', [0.82 0.72 0.15 0.04], 'Tag',...
    'viewAmplitude','Callback', @viewEPSC_Amplitude);
viewAmplitudeCheck = uicontrol(viewEPSC,'Style','checkbox',...
    'Units','normalized','Position', [0.97 0.72 0.02 0.04], 'Tag',...
    'viewAmplitudeCheck','Callback', @viewEPSC_Plot);

%Calculate Charge
viewCharge = uicontrol(viewEPSC,'Style','pushbutton','String','Charge',...
    'Units','normalized','Position', [0.82 0.675 0.15 0.04], 'Tag',...
    'viewCharge','Callback', @viewEPSC_Charge);
viewChargeCheck = uicontrol(viewEPSC,'Style','checkbox',...
    'Units','normalized','Position', [0.97 0.675 0.02 0.04], 'Tag',...
    'viewChargeCheck','Callback', @viewEPSC_Plot);

%% mini Analysis
viewMiniFrame = uipanel(viewEPSC, 'Units','normalized','Position', [0.81 0.592 0.185 0.063]);

viewMiniAnalysis = uicontrol(viewEPSC,'Style','pushbutton','String','Detect mEPSCs',...
    'Units','normalized','Position', [0.82 0.61 0.15 0.04], 'Tag',...
    'viewMiniAnalysis','Callback', @viewEPSC_MiniAnalysis);
viewMiniAnalysisCheck = uicontrol(viewEPSC,'Style','checkbox',...
    'Units','normalized','Position', [0.97 0.61 0.02 0.04], 'Tag',...
    'viewMiniAnalysisCheck');%,'Callback', @viewEPSC_Plot);

%% Discard and remove cell
viewRemoveFrame = uipanel(viewEPSC, 'Units','normalized','Position', [0.81 0.155 0.185 0.13]);
viewDiscardText = uicontrol(viewEPSC, 'Style','text','String','Discard removed:',...
    'Units','normalized','Position', [0.82 0.245 0.12 0.03], 'Tag',...
    'viewDiscardText','HorizontalAlignment','right','Enable','off');
viewDiscardCheck = uicontrol(viewEPSC,'Style','checkbox',...
    'Units','normalized','Position', [0.95 0.245 0.025 0.03], 'Tag',...
    'viewDiscardCheck','Value',0,'Enable','off');
viewRemoveCell = uicontrol(viewEPSC,'Style','pushbutton','String','Remove cell',...
    'Units','normalized','Position', [0.82 0.2 0.166 0.04], 'Tag',...
    'viewRemoveCell','Callback', @viewEPSC_Remove);
viewRemoveAll = uicontrol(viewEPSC,'Style','pushbutton','String','Remove all',...
    'Units','normalized','Position', [0.82 0.16 0.166 0.04], 'Tag',...
    'viewRemoveAll','Callback', @viewEPSC_Remove);

%% Save and Export
viewSaveFrame = uipanel(viewEPSC, 'Units','normalized','Position', [0.81 0.05 0.185 0.1]);
viewSave = uicontrol(viewEPSC,'Style','pushbutton','String','Save Analysis',...
    'Units','normalized','Position', [0.82 0.1 0.166 0.04], 'Tag',...
    'viewSave','Callback', @viewEPSC_Save);
viewExport = uicontrol(viewEPSC,'Style','pushbutton','String','Export to Excel',...
    'Units','normalized','Position', [0.82 0.06 0.166 0.04], 'Tag',...
    'viewExport','Callback', @viewEPSC_Export);

%% Fix axes limits
viewAxesFix = uipanel(viewEPSC, 'Units','normalized','Position', [0.81 0.294 0.185 0.094]);
viewXLimFix = uicontrol(viewEPSC,'Style','checkbox','String','Fix X-limits',...
    'Units','normalized','Position', [0.82 0.34 0.14 0.04], 'Tag',...
    'viewXLimFix','Callback', @viewEPSC_Plot);
viewYLimFix = uicontrol(viewEPSC,'Style','checkbox','String','Fix Y-limits',...
    'Units','normalized','Position', [0.82 0.30 0.14 0.04], 'Tag',...
    'viewYLimFix','Callback', @viewEPSC_Plot);
viewFullLim = uicontrol(viewEPSC,'Style','pushbutton','String','Full view',...
    'Units','normalized','Position', [0.9 0.32 0.085 0.04], 'Tag',...
    'viewFullLim','Callback', @viewEPSC_Plot);

%% Load data if input exists
if ~isempty(ephysFltr)
    viewLoadDrop.Value = 1;
    viewEPSC_loadData(viewLoadDrop,ephysFltr)
end
end


function viewEPSC_fileChange(hObject,Event)
%Get direction
direction = hObject.Tag;
%Get namesDrop
viewNamesDrop = findobj('Tag','viewNamesDrop');
numFiles = numel(viewNamesDrop.String);
curFile = viewNamesDrop.Value;

switch direction
    case 'viewNextName' %next
        if curFile ~= numFiles
            viewNamesDrop.Value = curFile+1;
        else
            viewNamesDrop.Value = 1;
        end
    case 'viewLastName' %end
        viewNamesDrop.Value = numFiles;
    case 'viewPrevName' %previous
        if curFile ~= 1
            viewNamesDrop.Value = curFile-1;
        else
            viewNamesDrop.Value = numFiles;
        end
    case 'viewFirstName' %first
        viewNamesDrop.Value = 1;
end
protCheck = findobj('Tag','viewApplyProtocolCheck');
allCheck = findobj('Tag','viewApplyAllCheck');
protCheck.Value = 0;
allCheck.Value = 0;

drawnow; pause(0.01);
%Update plot
viewEPSC_Plot;
end


function viewEPSC_Plot(hObject,~)
%Get relevant objects
viewEPSC = findobj('Tag', 'viewEPSC');
viewPlot = findobj('Tag', 'viewPlot');
viewNamesDrop = findobj('Tag','viewNamesDrop');
viewArtifactsCheck = findobj('Tag','viewArtifactsCheck');
viewBaseCheck = findobj('Tag','viewBaseCheck');
viewAmplitudeCheck = findobj('Tag','viewAmplitudeCheck');
viewChargeCheck = findobj('Tag','viewChargeCheck');
viewMiniAnalysisCheck = findobj('Tag','viewMiniAnalysisCheck');

viewXLimFix = findobj('Tag','viewXLimFix');
viewYLimFix = findobj('Tag','viewYLimFix');

%Get appdata
plotFltr = getappdata(viewEPSC,'ephysFltr');
if isempty(plotFltr) %nothing to do reset
    %Reset cell counter
    viewPlot.UserData = 0;
    %Delete children if exist
    if ~isempty(viewPlot.Children)
        delete(viewPlot.Children);
    end
    %Uncheck
    viewArtifactsCheck.Value = false;
    viewBaseCheck.Value = false;
    viewAmplitudeCheck.Value = false;
    viewChargeCheck.Value = false;
    return;
end
if ~exist('hObject','var')
    hObject.Tag = '';
end
if strcmp(hObject.Tag, 'viewFullLim')
    xlim(viewPlot,'auto');
    ylim(viewPlot,'auto');
    return;
end
ephysDB = getappdata(viewEPSC,'ephysDB');
dataPath = getappdata(viewEPSC,'dataPath');
dataPath = dataPath{ephysDB(viewNamesDrop.Value)};
oldCell = false;

%Get setting values
baselineValues = getappdata(viewEPSC,'baselineValues');
baselineValue = baselineValues{viewNamesDrop.Value};
artifactSettings = getappdata(viewEPSC,'artifactSettings');
artifactSetting = artifactSettings{viewNamesDrop.Value};
amplitudeSettings = getappdata(viewEPSC,'amplitudeSettings');
amplitudeSetting = amplitudeSettings{viewNamesDrop.Value};
chargeSettings = getappdata(viewEPSC,'chargeSettings');
chargeSetting = chargeSettings{viewNamesDrop.Value};
miniSettings = getappdata(viewEPSC,'miniSettings');
miniSetting = miniSettings{viewNamesDrop.Value};

%Get current data and si
filename = plotFltr{viewNamesDrop.Value,1};
fileData = retrieveEphys(filename,'data',dataPath); fileData = fileData{1}(:,1);
%Assume from abf in microsecond
fileSI = retrieveEphys(filename,'si',dataPath); fileSI = fileSI{1};
%Change stupid si notation
if fileSI>1; fileSI = fileSI*1e-6; end;


%See if we are plotting an old cell
if viewPlot.UserData == viewNamesDrop.Value %we have not changed data file
    oldCell = true;
end

%See if we are fixing zoom
if isempty(regexp(hObject.Tag,'LimFix','ONCE'))
    if viewXLimFix.Value
        oldX = viewPlot.XLim;
        viewXLimFix.UserData = oldX;
    end
    if viewYLimFix.Value
        oldY = viewPlot.YLim;
        viewYLimFix.UserData = oldY;
    end
end

if ~oldCell || strcmp(hObject.Tag,'viewArtifactsCheck')
    
    %Plot data
    dataTrace = plot(viewPlot,(1:numel(fileData))*fileSI,fileData,'Tag','viewDataTrace');
    ylabel(viewPlot,'Current (pA)'); xlabel(viewPlot,'Time (s)');
    xlim(viewPlot,[0,numel(fileData)*fileSI]);
    
    viewPlot.Tag = 'viewPlot';
    viewPlot.UserData = viewNamesDrop.Value;
    
    %Minimum Y limit
    if viewPlot.YLim(2)-viewPlot.YLim(1)<500
        addY = (500-(viewPlot.YLim(2)-viewPlot.YLim(1)))/2;
        viewPlot.YLim(1) = viewPlot.YLim(1)-addY;
        viewPlot.YLim(2) = viewPlot.YLim(2)+addY;
    end
    
    %Set cell counter
    viewCellCount = findobj('Tag','viewCellCount');
    viewCellCount.String = [num2str(viewNamesDrop.Value),':'];
    
    if ~oldCell
        %Check if protocol is available
        viewApplyProtocol{1} = findobj('Tag','viewApplyProtocolText');
        viewApplyProtocol{2} = findobj('Tag','viewApplyProtocolCheck');
        if ephysDB(viewNamesDrop.Value) == 1 &&...
                plotFltr{viewNamesDrop.Value,21} > 0
            set([viewApplyProtocol{:}],'Enable','on');
        else
            set([viewApplyProtocol{:}],'Enable','off');
        end
        
        %Do check marks
        settingCell = {baselineValue,artifactSetting,amplitudeSetting,...
            chargeSetting,miniSetting};
        UICell = {viewBaseCheck,viewArtifactsCheck,viewAmplitudeCheck,...
            viewChargeCheck,viewMiniAnalysisCheck};
        for i = 1:numel(settingCell)
            if isempty(settingCell{i})
                UICell{i}.Value = false;
            elseif i == 1 && nanmean(settingCell{i}{2}(:,1)) <= 0.025
                UICell{i}.Value = false;
            else
                UICell{i}.Value = true;
            end
        end
        
        %Clear tempSettings
        viewArtifactsCheck.UserData = [];
        viewChargeCheck.UserData = [];
        viewAmplitudeCheck.UserData = [];
        viewBaseCheck.UserData = [];
        viewMiniAnalysisCheck.UserData = [];
        
        %Update open windows
        viewAmplitudeGUI = findobj('Tag','viewAmplitudeGUI');
        viewBaselineGUI = findobj('Tag','viewBaselineGUI');
        viewArtifactsGUI = findobj('Tag','viewArtifactsGUI');
        viewChargeGUI = findobj('Tag','viewChargeGUI');
        viewMiniGUI = findobj('Tag','viewMiniGUI');
        
        if ~isempty(viewBaselineGUI)
            status = findobj('Tag','viewBaseStatus');
            viewBase_Update(status);
        end
        if ~isempty(viewArtifactsGUI)
            status = findobj('Tag','viewArtifactStatus');
            viewArt_Update(status);
        end
        if ~isempty(viewAmplitudeGUI)
            status = findobj('Tag','viewAmplitudeStatus');
            viewAmp_Update(status);
        end
        
        if ~isempty(viewChargeGUI)
            status = findobj('Tag','viewChargeStatus');
            viewCharge_Update(status);
        end
        
        if ~isempty(viewMiniGUI)
            status = findobj('Tag','viewMiniStatus');
            viewMini_Update(status);
        end
    end
else
    dataTrace = findobj('Tag','viewDataTrace');
end

%Draw baseline
if viewBaseCheck.Value
    
    
    %Remove old if necessary
    viewBaselinePlot = findobj('Tag','viewBaselinePlot');
    if ~isempty(viewBaselinePlot); delete(viewBaselinePlot); end;
    
    if nanmean(baselineValue{2}(:,1)) > 0.025 %not initial values
        %Calculate Baseline
        cellBaseline = viewCalculateBaseline(baselineValue,fileData,fileSI);
        %And plot
        hold(viewPlot,'on');
        plot(viewPlot,dataTrace.XData,cellBaseline,'r--','Tag',...
            'viewBaselinePlot')
        hold(viewPlot,'off');
    end
else
    viewBaselinePlot = findobj('Tag','viewBaselinePlot');
    if ~isempty(viewBaselinePlot); delete(viewBaselinePlot); end;
end

%Remove artifacts
if viewArtifactsCheck.Value
    
    if ~isempty(artifactSetting)
        %Remove old if present
        viewArtInterpPlot = findobj('Tag','viewArtInterpPlot');
        if ~isempty(viewArtInterpPlot); delete(viewArtInterpPlot); end;
        
        idx = cell(numel(artifactSetting),2);
        for i = 1:numel(artifactSetting)
            [idx{i,1}, idx{i,2}] = viewGetArtifacts(fileData,fileSI,...
                artifactSetting{i});
        end
        allIdx = [vertcat(idx{:,1}),vertcat(idx{:,2})];
        
        %         artInterpY = [];
        %         artInterpX = [];
        %         for i = 1:size(allIdx,1)
        %             artInterpY = [artInterpY,NaN,dataTrace.YData([allIdx(i,1),allIdx(i,2)]),NaN];
        %             artInterpX = [artInterpX,dataTrace.XData([allIdx(i,1)-1,allIdx(i,1),...
        %                 allIdx(i,2),allIdx(i,2)+1])];
        %             dataTrace.YData(allIdx(i,1)+1:allIdx(i,2)-1) = NaN;
        %         end
        %
        %         %plot
        %         hold(viewPlot,'on');
        %         plot(viewPlot,artInterpX,artInterpY,'r-.','Tag',...
        %             'viewArtInterpPlot')
        %         hold(viewPlot,'off');
        
        gapped = fileData;
        artInterp = nan(size(dataTrace.XData));
        for i = 1:numel(artifactSetting)
            [~, emptyTrace, predTrace] = ...
                viewInterpArtifacts([idx{i,1},idx{i,2}],fileData);
            gapped(isnan(emptyTrace)) = NaN;
            artInterp(~isnan(predTrace)) = predTrace(~isnan(predTrace));
        end
        dataTrace.YData = gapped;
        %plot
        hold(viewPlot,'on');
        plot(viewPlot,dataTrace.XData,artInterp,'r-.','Tag',...
            'viewArtInterpPlot')
        hold(viewPlot,'off');
    end
else
    viewArtInterpPlot = findobj('Tag','viewArtInterpPlot');
    if ~isempty(viewArtInterpPlot); delete(viewArtInterpPlot); end;
end
%Fix zoom if necessary
if viewXLimFix.Value && ~isempty(viewXLimFix.UserData)
    viewPlot.XLim = viewXLimFix.UserData;
elseif strcmp(hObject.Tag,'viewXLimFix')
    xlim(viewPlot,'auto');
end
if viewYLimFix.Value && ~isempty(viewYLimFix.UserData)
    viewPlot.YLim = viewYLimFix.UserData;
elseif strcmp(hObject.Tag,'viewYLimFix')
    ylim(viewPlot,'auto');
end

end

function viewEPSC_loadData(viewLoadDrop,inputFltr)
%Get relevant objects
viewEPSC = findobj('Tag', 'viewEPSC');
viewNamesDrop = findobj('Tag','viewNamesDrop');

%Unblind data if necessary
viewBlindCheck = findobj('Tag','viewBlindCheck');
if viewBlindCheck.Value
    viewBlindCheck.Value = false;
    viewEPSC_BlindFile(viewBlindCheck);
end

plotUpdate = false;


%Get variables
ephysFltr = getappdata(viewEPSC,'ephysFltr');
ephysDB = getappdata(viewEPSC,'ephysDB');
baselineValues = getappdata(viewEPSC,'baselineValues');
artifactSettings = getappdata(viewEPSC,'artifactSettings');
amplitudeSettings = getappdata(viewEPSC,'amplitudeSettings');
chargeSettings = getappdata(viewEPSC,'chargeSettings');
miniSettings = getappdata(viewEPSC,'miniSettings');
miniCoords = getappdata(viewEPSC,'miniCoords');
miniFeatures= getappdata(viewEPSC,'miniFeatures');
miniTargets= getappdata(viewEPSC,'miniTargets');

%% Check what type of data loading
if viewLoadDrop.Value == 1
    if ~exist('inputFltr','var')
        cancel = false;
        %Load ephysFltr from workspace
        workVars = evalin('base','who');
        if isempty(workVars); workVars=' '; cancel=true; end;
        %Create listbox
        [s,v] = listdlg('PromptString','Select EphysFltr:',...
            'ListString',workVars,'ListSize', [220 300]);
        drawnow; pause(0.01);
        
        if ~v || cancel %user cancelled or no variables present
            return
        end
        
        inputFltr = [];
        for i = s
            inputFltr = [inputFltr;evalin('base',workVars{i})];
        end
    end
    
    %Secure presence dataPath
    dataPath = getappdata(viewEPSC,'dataPath');
    if isempty(dataPath{1})
        %No global variable ask user
        dataPath{1} = uigetdir('','Select ephysDB folder');
        setappdata(viewEPSC,'dataPath',dataPath);
    end
    %unambiguous dataPath for now
    dataPath = dataPath{1};
    
    %Make sure all data has files
    if any(~([inputFltr{:,17}]))
        inputFltr = inputFltr([inputFltr{:,17}],:);
        disp('Warning, file(s) without data removed')
    end
    
    
else
    %Load data from file
    extList = '*.abf';
    %Flip for matlab
    if viewLoadDrop.Value == 3; extList = '*.mat'; end;
    [filename,pathName] = uigetfile(extList,'Select Data',...
        'MultiSelect', 'on');
    if ~pathName %User cancelled
        return
    end
    if iscell(filename) %multiple files selected
        inputFltr = filename(:);
        filePath = cellfun(@(x) fullfile(pathName,x),filename,...
            'UniformOutput',false);
        
        %Remove extension when present
        extFltr = cellfun(@(x) regexp(x,'.abf|.mat'),filename);
        for i = 1:numel(filename)
            if ~isempty(extFltr(i))
                inputFltr{i} = inputFltr{i}(1:extFltr(i)-1);
            end
        end
    else %only one file added
        extFltr = regexp(filename,'.abf|.mat');
        if isempty(extFltr); extFltr = numel(filename)+1; end;
        inputFltr = {filename(1:extFltr-1)};
        filePath = {fullfile(pathName,filename)};
    end
    
    %Set data directory
    currPath = fileparts(which('viewEPSC_GUI'));
    dataPath = fullfile(currPath,'viewData');
    
    %Store in app data
    allPath = getappdata(viewEPSC,'dataPath');
    allPath{2} = dataPath;
    setappdata(viewEPSC,'dataPath',allPath);
    
    %Check if dir needs to be created
    if ~exist(dataPath,'dir')
        mkdir(dataPath);
        mkdir(fullfile(dataPath,'Data'));
    elseif ~exist(fullfile(dataPath,'Data'),'dir')
        mkdir(fullfile(dataPath,'Data'));
    end
    
    %Load abf files into dir
    if viewLoadDrop.Value == 2
        for i =1:numel(filePath)
            [data,si,header] = abfload(filePath{i});
            save(fullfile(dataPath,'Data', [inputFltr{i},'.mat']),'-v7.3','data','si','header');
        end
    else %Mat file
        %Check if single file
        if strcmp(who('-file',filePath{1}),'dataStruct')
            load(filePath{1});
            
            inputFltr = struct2cell(dataStruct);
            inputFltr = inputFltr(1,1,:);
            inputFltr = inputFltr(:);
            
            %Loop over files
            dataFields = fieldnames(dataStruct);
            dataFields = dataFields(2:end-1);
            for i = 1:numel(dataStruct)
                header = dataStruct(i).header;
                save(fullfile(dataPath,'Data', [inputFltr{i},'.mat']),'-v7.3','header');
                dataFile = matfile(fullfile(dataPath,'Data', [inputFltr{i},'.mat']),'Writable',true);
                for jj = 1:numel(dataFields)
                    dataFile.(dataFields{jj}) = dataStruct(i).(dataFields{jj});
                end
            end
            
            clear('dataStruct');
        else %Just copy files
            for i =1:numel(filePath)
                %Check to make sure source is not destination
                if ~strcmp(filePath{i},fullfile(dataPath,'Data', [inputFltr{i},'.mat']))
                    copyfile(filePath{i},fullfile(dataPath,'Data', [inputFltr{i},'.mat']));
                end
            end
        end
    end
end

%% First data, or add to end
if numel(viewNamesDrop.String) == 1 &&...
        strcmp(viewNamesDrop.String{1},'No data selected')
    %First data overwrite
    viewNamesDrop.String = inputFltr(:,1);
    selectInput = true(size(inputFltr(:,1)));
    plotUpdate = true;
else
    %Added data, add only new entries
    selectInput = ~ismember(inputFltr(:,1),viewNamesDrop.String);
    viewNamesDrop.String = [viewNamesDrop.String;inputFltr(selectInput,1)];
end
inputFltr = inputFltr(selectInput,:); %Remove existing entries for future operations

%Adjust dimensions as needed (empty cell padding)
if ~isempty(ephysFltr)
    if size(ephysFltr,2) > size(inputFltr,2)
        inputFltr(:,size(inputFltr,2)+1:size(ephysFltr,2)) = {[]};
    elseif size(ephysFltr,2) < size(inputFltr,2)
        ephysFltr(:,size(ephysFltr,2)+1:size(inputFltr,2)) = {[]};
    end
end

%% Set changed variables
ephysFltr = [ephysFltr;inputFltr];
ephysDB = [ephysDB;repmat(viewLoadDrop.Value,size(inputFltr,1),1)];
ephysDB(ephysDB ~= 1) = 2;
baselineValues = [baselineValues; repmat({[{'linear'},...
    {[0,0.1;0,0.1;0,0.1;0.1,-0.1; NaN, NaN; NaN, NaN]}]},...
    size(inputFltr(:,1)))];
artifactSettings = [artifactSettings; cell(size(inputFltr(:,1)))];
amplitudeSettings = [amplitudeSettings(:); cell(size(inputFltr(:,1)))];
chargeSettings = [chargeSettings(:); cell(size(inputFltr(:,1)))];
miniSettings = [miniSettings(:); cell(size(inputFltr(:,1)))];
miniCoords = [miniCoords(:); cell(size(inputFltr(:,1)))];
miniFeatures = [miniFeatures(:); cell(size(inputFltr(:,1)))];
miniTargets = [miniTargets(:); cell(size(inputFltr(:,1)))];

if viewLoadDrop.Value ~= 2 %Maybe old settings exist in which case load them
    %Check for existing baseline
    [oldValues, targets] = retrieveEphys( ephysFltr, ...
        {'BaseSetting','ArtSetting','AmpSetting','ChargeSetting',...
        'miniSetting','miniCoords','miniFeatures','miniTargets'},...
        dataPath);
    baselineValues(targets(:,1)) = oldValues(targets(:,1),1);
    artifactSettings(targets(:,2)) = oldValues(targets(:,2),2);
    amplitudeSettings(targets(:,3)) = oldValues(targets(:,3),3);
    chargeSettings(targets(:,4)) = oldValues(targets(:,4),4);
    miniSettings(targets(:,5)) = oldValues(targets(:,5),5);
    miniCoords(targets(:,6)) = oldValues(targets(:,6),6);
    miniFeatures(targets(:,7)) = oldValues(targets(:,7),7);
    miniTargets(targets(:,8)) = oldValues(targets(:,8),8);
end

targetCorr = find(targets(:,6) ~= targets(:,8) & targets(:,6));
brokenCorr = find(cellfun(@(x,y) numel(x)~=numel(y),miniCoords,miniTargets));
targetCorr = unique([targetCorr;brokenCorr]);
if ~isempty(targetCorr)
    for ii = 1:numel(targetCorr)
        %No saved targets every coordinate is real mini
        jj=targetCorr(ii);
        miniTargets{jj} = [true(size(miniCoords{jj},1),1),...
            false(size([miniCoords{jj}],1),1)];
    end
end
%Set variables again
setappdata(viewEPSC,'ephysFltr',ephysFltr);
setappdata(viewEPSC,'ephysDB',ephysDB);
setappdata(viewEPSC,'baselineValues',baselineValues)
setappdata(viewEPSC,'artifactSettings',artifactSettings);
setappdata(viewEPSC,'amplitudeSettings',amplitudeSettings);
setappdata(viewEPSC,'chargeSettings',chargeSettings);
setappdata(viewEPSC,'miniSettings',miniSettings);
setappdata(viewEPSC,'miniCoords',miniCoords);
setappdata(viewEPSC,'miniFeatures',miniFeatures);
setappdata(viewEPSC,'miniTargets',miniTargets);

%Plot if necessary
if plotUpdate
    viewEPSC_Plot
end
end

function viewEPSC_doubleCheck(hObject,Event)
protCheck = findobj('Tag','viewApplyProtocolCheck');
allCheck = findobj('Tag','viewApplyAllCheck');
if hObject.Value
    if strcmp(hObject.Tag,'viewApplyProtocolCheck')
        allCheck.Value = 0;
    else
        protCheck.Value = 0;
    end
end
end

% Analysis GUI functions

function viewEPSC_Baseline(~,~)
%prevent multiple
if ~isempty(findobj('Tag','viewBaselineGUI'))
    figure(findobj('Tag','viewBaselineGUI')) %Make active window
    return
end

%Get
viewEPSC = findobj('Tag', 'viewEPSC');
ephysDB = getappdata(viewEPSC,'ephysDB');
if isempty(ephysDB) % no data loaded just set one dummy variable
    ephysDB =0;
end
viewNamesDrop = findobj('Tag','viewNamesDrop');

%% Draw new window
vSize = 0.84;
viewBaselineGUI = figure('OuterPosition',...
    [viewEPSC.Position(1)+viewEPSC.Position(3)*0.75 viewEPSC.Position(2)*1.1 350 500*vSize],...
    'Tag','viewBaselineGUI','MenuBar','none','Toolbar','none',...
    'Name','Baseline Settings','NumberTitle','off','CloseRequestFcn',@viewBase_Update,...
    'WindowStyle','normal');

%Set defaults
% viewBaseProtocolDefaultCheck = uicontrol(viewBaselineGUI,'Style','checkbox',...
%     'Units','normalized','Position', [0.05 0.93 0.05 0.04/vSize], 'Tag',...
%     'viewBaseProtocolDefaultCheck','Callback', @viewGetProtocol);
viewBaseProtocolDefault = uicontrol(viewBaselineGUI, 'Style','pushButton','String','Set to protocol defaults',...
    'Units','normalized','Position', [0.05 0.924 0.5 0.05/vSize], 'Tag',...
    'viewBaseProtocolDefault','Callback', @viewBase_Update);

%Set baseline points (Description)
viewBaseSetupText = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','Define points and range for baseline calculation:',...
    'Units','normalized','Position', [0.05 0.8645 0.9 0.04/vSize], 'Tag',...
    'viewBaseSetupText','HorizontalAlignment','left');

%Set baseline points (Set drop down, add/remove)
viewBaseSetDrop = uicontrol(viewBaselineGUI,'Style','popup','String',{'Set 1'},...
    'Units','normalized','Position', [0.05 0.8229 0.3 0.04/vSize], 'Tag',...
    'viewBaseSetDrop','Callback', @viewBase_Update);
viewBaseSetAdd = uicontrol(viewBaselineGUI,'Style','pushbutton','String','Add Set',...
    'Units','normalized','Position', [0.36 0.8110 0.25 0.05/vSize], 'Tag','viewBaseSetAdd',...
    'Callback', @viewBase_Update);
viewBaseSetRemove = uicontrol(viewBaselineGUI,'Style','pushbutton','String','Remove Set',...
    'Units','normalized','Position', [0.63 0.8110 0.25 0.05/vSize], 'Tag','viewBaseSetRemove',...
    'Callback', @viewBase_Update);

%% Set baseline points (Numbers and range boxes)
viewBasePointText = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','Baseline Point',...
    'Units','normalized','Position', [0.075 0.7276 0.405 0.04/vSize], 'Tag',...
    'viewBasePointText','HorizontalAlignment','center');
viewBaseRangeText = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','Average Range',...
    'Units','normalized','Position', [0.52 0.7276 0.405 0.04/vSize], 'Tag',...
    'viewBaseRangeText','HorizontalAlignment','center');

viewBaseText1 = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','1:',...
    'Units','normalized','Position', [0.03 0.68 0.04 0.04/vSize], 'Tag',...
    'viewBaseText1','HorizontalAlignment','left');
viewBasePoint1 = uicontrol(viewBaselineGUI, 'Style','edit','String','1',...
    'Units','normalized','Position', [0.075 0.68 0.405 0.04/vSize], 'Tag',...
    'viewBasePoint1','Callback', @viewBase_Update);
viewBaseRange1 = uicontrol(viewBaselineGUI, 'Style','edit','String','1',...
    'Units','normalized','Position', [0.52 0.68 0.405 0.04/vSize], 'Tag',...
    'viewBaseRange1','Callback', @viewBase_Update);

viewBaseText2 = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','2:',...
    'Units','normalized','Position', [0.03 0.62 0.04 0.04/vSize], 'Tag',...
    'viewBaseText2','HorizontalAlignment','left');
viewBasePoint2 = uicontrol(viewBaselineGUI, 'Style','edit','String','1',...
    'Units','normalized','Position', [0.075 0.62 0.405 0.04/vSize], 'Tag',...
    'viewBasePoint2','Callback', @viewBase_Update);
viewBaseRange2 = uicontrol(viewBaselineGUI, 'Style','edit','String','1',...
    'Units','normalized','Position', [0.52 0.62 0.405 0.04/vSize], 'Tag',...
    'viewBaseRange2','Callback', @viewBase_Update);

viewBaseText3 = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','3:',...
    'Units','normalized','Position', [0.03 0.56 0.04 0.04/vSize], 'Tag',...
    'viewBaseText3','HorizontalAlignment','left');
viewBasePoint3 = uicontrol(viewBaselineGUI, 'Style','edit','String','1',...
    'Units','normalized','Position', [0.075 0.56 0.405 0.04/vSize], 'Tag',...
    'viewBasePoint3','Callback', @viewBase_Update);
viewBaseRange3 = uicontrol(viewBaselineGUI, 'Style','edit','String','1',...
    'Units','normalized','Position', [0.52 0.56 0.405 0.04/vSize], 'Tag',...
    'viewBaseRange3','Callback', @viewBase_Update);

viewBaseText4 = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','4:',...
    'Units','normalized','Position', [0.03 0.5 0.04 0.04/vSize], 'Tag',...
    'viewBaseText3','HorizontalAlignment','left');
viewBasePoint4 = uicontrol(viewBaselineGUI, 'Style','edit','String','1',...
    'Units','normalized','Position', [0.075 0.5 0.405 0.04/vSize], 'Tag',...
    'viewBasePoint4','Callback', @viewBase_Update);
viewBaseRange4 = uicontrol(viewBaselineGUI, 'Style','edit','String','1',...
    'Units','normalized','Position', [0.52 0.5 0.405 0.04/vSize], 'Tag',...
    'viewBaseRange4','Callback', @viewBase_Update);

viewBaseText5 = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','5:',...
    'Units','normalized','Position', [0.03 0.44 0.04 0.04/vSize], 'Tag',...
    'viewBaseText5','HorizontalAlignment','left');
viewBasePoint5 = uicontrol(viewBaselineGUI, 'Style','edit','String','NaN',...
    'Units','normalized','Position', [0.075 0.44 0.405 0.04/vSize], 'Tag',...
    'viewBasePoint5','Callback', @viewBase_Update);
viewBaseRange5 = uicontrol(viewBaselineGUI, 'Style','edit','String','NaN',...
    'Units','normalized','Position', [0.52 0.44 0.405 0.04/vSize], 'Tag',...
    'viewBaseRange5','Callback', @viewBase_Update);


viewBaseText6 = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','6:',...
    'Units','normalized','Position', [0.03 0.38 0.04 0.04/vSize], 'Tag',...
    'viewBaseText6','HorizontalAlignment','left');
viewBasePoint6 = uicontrol(viewBaselineGUI, 'Style','edit','String','NaN',...
    'Units','normalized','Position', [0.075 0.38 0.405 0.04/vSize], 'Tag',...
    'viewBasePoint6','Callback', @viewBase_Update);
viewBaseRange6 = uicontrol(viewBaselineGUI, 'Style','edit','String','NaN',...
    'Units','normalized','Position', [0.52 0.38 0.405 0.04/vSize], 'Tag',...
    'viewBaseRange6','Callback', @viewBase_Update);

%% Intepolation method
viewBaseInterpText = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','Interpolation Method:',...
    'Units','normalized','Position', [0.075 0.287 0.4 0.04/vSize], 'Tag',...
    'viewBaseInterpText','HorizontalAlignment','left');
viewBaseInterpDrop = uicontrol(viewBaselineGUI,'Style','popup',...
    'String',{'Linear','Cubic'},...
    'Units','normalized','Position', [0.52 0.299 0.4 0.04/vSize], 'Tag',...
    'viewBaseInterpDrop','Callback', @viewBase_Update);

%Apply and close figure
viewBaseApply = uicontrol(viewBaselineGUI,'Style','pushbutton','String','Apply',...
    'Units','normalized','Position', [0.05 0.18 0.43 0.06/vSize], 'Tag','viewBaseApply',...
    'Callback', @viewBase_Update);
viewBaseCancel = uicontrol(viewBaselineGUI,'Style','pushbutton','String','Cancel',...
    'Units','normalized','Position', [0.52 0.18 0.43 0.06/vSize], 'Tag','viewBaseCancel',...
    'Callback', @viewBase_Update);

%Status update
viewBaseStatus = uicontrol(viewBaselineGUI, 'Style','text',...
    'String','Tip: a minimum of four points is required for Cubic interpolation',...
    'Units','normalized','Position', [0.05 0.06 0.9 0.07/vSize], 'Tag',...
    'viewBaseStatus','HorizontalAlignment','left');

%% Check if we have a protocol
if ephysDB(viewNamesDrop.Value) ~= 1
    %No protocol disable protocol defaults check
    viewBaseProtocolDefault.Enable = 'off';
end

%Initialize figure
viewBase_Update(viewBaseStatus)
end

function viewEPSC_Artifacts(~,~)
%prevent multiple
if ~isempty(findobj('Tag','viewArtifactsGUI'))
    figure(findobj('Tag','viewArtifactsGUI')) %Make active window
    return
end

%Get
viewEPSC = findobj('Tag', 'viewEPSC');
ephysDB = getappdata(viewEPSC,'ephysDB');
if isempty(ephysDB)
    ephysDB = 0;
end
viewNamesDrop = findobj('Tag','viewNamesDrop');

vSize = 0.84;
viewArtifactsGUI = figure('OuterPosition',...
    [viewEPSC.Position(1)+viewEPSC.Position(3)*0.75 viewEPSC.Position(2)*1.1 350 500*vSize],...
    'Tag','viewArtifactsGUI','MenuBar','none','Toolbar','none',...
    'Name','Artifact specifications','NumberTitle','off','CloseRequestFcn',@viewArt_Update,...
    'WindowStyle','normal');

%Set defaults
viewArtifactsProtocolDefault = uicontrol(viewArtifactsGUI, 'Style','pushButton','String','Set to protocol defaults',...
    'Units','normalized','Position', [0.05 0.924 0.5 0.05/vSize], 'Tag',...
    'viewArtifactsProtocolDefault','Callback', @viewArt_Update);

%Set Block drop, add and remove
viewArtifactsSetDrop = uicontrol(viewArtifactsGUI,'Style','popup','String',{'Block 0'},...
    'Units','normalized','Position', [0.05 0.8229 0.3 0.04/vSize], 'Tag',...
    'viewArtifactsSetDrop','Callback', @viewArt_Update,'Enable','off');
viewArtifactsSetAdd = uicontrol(viewArtifactsGUI,'Style','pushbutton','String','Add Block',...
    'Units','normalized','Position', [0.36 0.8110 0.30 0.05/vSize], 'Tag','viewArtifactsSetAdd',...
    'Callback', @viewArt_Update);
viewArtifactsSetRemove = uicontrol(viewArtifactsGUI,'Style','pushbutton','String','Remove Block',...
    'Units','normalized','Position', [0.68 0.8110 0.30 0.05/vSize], 'Tag','viewArtifactsSetRemove',...
    'Callback', @viewArt_Update,'Enable','off');

%fill in boxes
viewArtifactStartText = uicontrol(viewArtifactsGUI, 'Style','text',...
    'String','Train start:',...
    'Units','normalized','Position', [0.1 0.68 0.40 0.04/vSize], 'Tag',...
    'viewArtifactStartText','HorizontalAlignment','center','Enable','off');
viewArtifactSetting(1) = uicontrol(viewArtifactsGUI, 'Style','edit','String','',...
    'Units','normalized','Position', [0.52 0.68 0.35 0.04/vSize], 'Tag',...
    'viewArtifactSetting1','Callback', @viewArt_Update,'Enable','off');

viewArtifactPulseNText = uicontrol(viewArtifactsGUI, 'Style','text',...
    'String','Number of pulses:',...
    'Units','normalized','Position', [0.1 0.62 0.40 0.04/vSize], 'Tag',...
    'viewArtifactPulseNText','HorizontalAlignment','center','Enable','off');
viewArtifactSetting(2) = uicontrol(viewArtifactsGUI, 'Style','edit','String','',...
    'Units','normalized','Position', [0.52 0.62 0.35 0.04/vSize], 'Tag',...
    'viewArtifactSetting2','Callback', @viewArt_Update,'Enable','off');

viewArtifactFrequencyText = uicontrol(viewArtifactsGUI, 'Style','text',...
    'String','Frequency:',...
    'Units','normalized','Position', [0.1 0.56 0.40 0.04/vSize], 'Tag',...
    'viewArtifactFrequencyText','HorizontalAlignment','center','Enable','off');
viewArtifactSetting(3) = uicontrol(viewArtifactsGUI, 'Style','edit','String','',...
    'Units','normalized','Position', [0.52 0.56 0.35 0.04/vSize], 'Tag',...
    'viewArtifactSetting3','Callback', @viewArt_Update,'Enable','off');

viewArtifactFirstWidthText = uicontrol(viewArtifactsGUI, 'Style','text',...
    'String','Width first artifact:',...
    'Units','normalized','Position', [0.1 0.5 0.40 0.04/vSize], 'Tag',...
    'viewArtifactFirstWidthText','HorizontalAlignment','center','Enable','off');
viewArtifactSetting(4) = uicontrol(viewArtifactsGUI, 'Style','edit','String','',...
    'Units','normalized','Position', [0.52 0.5 0.35 0.04/vSize], 'Tag',...
    'viewArtifactSetting4','Callback', @viewArt_Update,'Enable','off');

viewArtifactLastWidthText = uicontrol(viewArtifactsGUI, 'Style','text',...
    'String','Width last artifact:',...
    'Units','normalized','Position', [0.1 0.44 0.40 0.04/vSize], 'Tag',...
    'viewArtifactLastWidthText','HorizontalAlignment','center','Enable','off');
viewArtifactSetting(5) = uicontrol(viewArtifactsGUI, 'Style','edit','String','',...
    'Units','normalized','Position', [0.52 0.44 0.35 0.04/vSize], 'Tag',...
    'viewArtifactSetting5','Callback', @viewArt_Update,'Enable','off');

viewArtifactAutoDropText = uicontrol(viewArtifactsGUI, 'Style','text',...
    'String','Adjust width to slope:',...
    'Units','normalized','Position', [0.1 0.38 0.40 0.04/vSize], 'Tag',...
    'viewArtifactAutoDropText','HorizontalAlignment','center','Enable','off');
viewArtifactSetting(6) = uicontrol(viewArtifactsGUI, 'Style','checkbox',...
    'Units','normalized','Position', [0.52 0.38 0.35 0.04/vSize], 'Tag',...
    'viewArtifactSetting6','Callback', @viewArt_Update,'Enable','off',...
    'Value',true);

%artifact interpolation (implement later)
viewArtifactInterpText = uicontrol(viewArtifactsGUI, 'Style','text',...
    'String','Interpolation Method:',...
    'Units','normalized','Position', [0.075 0.287 0.4 0.04/vSize], 'Tag',...
    'viewArtifactInterpText','HorizontalAlignment','left','Enable','off');
viewArtifactInterpDrop = uicontrol(viewArtifactsGUI,'Style','popup',...
    'String',{'Linear','Cubic'},...
    'Units','normalized','Position', [0.52 0.299 0.4 0.04/vSize], 'Tag',...
    'viewArtifactInterpDrop','Callback', @viewArt_Update,'Enable','off');

%Apply and close figure
viewArtifactApply = uicontrol(viewArtifactsGUI,'Style','pushbutton','String','Apply',...
    'Units','normalized','Position', [0.05 0.18 0.43 0.06/vSize], 'Tag','viewArtifactApply',...
    'Callback', @viewArt_Update,'Enable','off');
viewArtifactCancel = uicontrol(viewArtifactsGUI,'Style','pushbutton','String','Cancel',...
    'Units','normalized','Position', [0.52 0.18 0.43 0.06/vSize], 'Tag','viewArtifactCancel',...
    'Callback', @viewArt_Update);

%Status update
viewArtifactStatus = uicontrol(viewArtifactsGUI, 'Style','text',...
    'String','',...
    'Units','normalized','Position', [0.05 0.06 0.9 0.07/vSize], 'Tag',...
    'viewArtifactStatus','HorizontalAlignment','left');

viewArt_Update(viewArtifactStatus);

end

function viewEPSC_Amplitude(~,~)
%%
%prevent multiple
if ~isempty(findobj('Tag','viewAmplitudeGUI'))
    figure(findobj('Tag','viewAmplitudeGUI')) %Make active window
    return
end

%Get
viewEPSC = findobj('Tag', 'viewEPSC');

%Draw Figure
viewAmplitudeGUI = figure('OuterPosition',...
    [viewEPSC.Position(1)+viewEPSC.Position(3)*0.6 viewEPSC.Position(2)*1.1 450 500],...
    'Tag','viewAmplitudeGUI','MenuBar','none','Toolbar','none',...
    'Name','Amplitude specifications','NumberTitle','off','CloseRequestFcn',@viewAmp_Update,...
    'WindowStyle','normal');

%Block #
viewAmplitudeBlockDrop = uicontrol(viewAmplitudeGUI,'Style','popup','String',...
    {'Block #'},...
    'Units','normalized','Position', [0.02 0.94 0.17 0.04], 'Tag',...
    'viewAmplitudeBlockDrop','Callback', @viewAmp_Update);

%Calculation method
viewAmplitudeMethodText = uicontrol(viewAmplitudeGUI, 'Style','text',...
    'String','Calculation Method:',...
    'Units','normalized','Position', [0.2 0.93 0.27 0.04], 'Tag',...
    'viewAmplitudeMethodText','HorizontalAlignment','center');
viewAmplitudeMethodDrop = uicontrol(viewAmplitudeGUI,'Style','popup','String',...
    {'Artifact','Baseline'},... ,'Paired '},...
    'Units','normalized','Position', [0.46 0.94 0.27 0.04], 'Tag',...
    'viewAmplitudeMethodDrop','Callback', @viewAmp_Update);

%Zoom to pulse check
viewAmplitudeZoomText = uicontrol(viewAmplitudeGUI, 'Style','text',...
    'String','Zoom to pulse:',...
    'Units','normalized','Position', [0.74 0.93 0.2 0.04], 'Tag',...
    'viewAmplitudeZoomText','HorizontalAlignment','center');
viewAmplitudeZoomCheck = uicontrol(viewAmplitudeGUI, 'Style','checkbox',...
    'Units','normalized','Position', [0.94 0.932 0.06 0.04], 'Tag',...
    'viewAmplitudeZoomCheck','Value',false,'Callback', @viewAmp_Update);

%Table with values
viewAmplitudeOverview = uitable(viewAmplitudeGUI,'Units','normalized',...
    'Position',[0.02 0.09 0.96 0.83],'Tag','viewAmplitudeOverview',...
    'ColumnName',{'Block 1'},'CellSelectionCallback',...
    @viewAmp_Update);

%Status
viewAmplitudeStatus = uicontrol(viewAmplitudeGUI, 'Style','text',...
    'String','Something long and boring very very boring preferably two lines or something I dont know',...
    'Units','normalized','Position', [0.02 0.007 0.6 0.07], 'Tag',...
    'viewAmplitudeStatus','HorizontalAlignment','left');

%Apply/Cancel
viewAmplitudeApply = uicontrol(viewAmplitudeGUI,'Style','pushbutton','String','Apply',...
    'Units','normalized','Position', [0.66 0.02 0.15 0.05], 'Tag','viewAmplitudeApply',...
    'Callback', @viewAmp_Update);
viewAmplitudeCancel = uicontrol(viewAmplitudeGUI,'Style','pushbutton','String','Cancel',...
    'Units','normalized','Position', [0.82 0.02 0.15 0.05], 'Tag','viewAmplitudeCancel',...
    'Callback', @viewAmp_Update);

% viewAmplitudeUnits = uicontrol(viewAmplitudeGUI, 'Style','text',...
%     'String','(pA)', 'Units','normalized','Position', [0.04 0.88 0.073 0.0333]);

viewAmp_Update(viewAmplitudeStatus);
end

function viewEPSC_Charge(~,~)
%%
%prevent multiple
if ~isempty(findobj('Tag','viewChargeGUI'))
    figure(findobj('Tag','viewChargeGUI')) %Make active window
    return
end

viewEPSC = findobj('Tag', 'viewEPSC');

%Draw Figure
viewChargeGUI = figure('OuterPosition',...
    [viewEPSC.Position(1)+viewEPSC.Position(3)*0.6 viewEPSC.Position(2)*1.1 500 500],...
    'Tag','viewChargeGUI','MenuBar','none','Toolbar','none',...
    'Name','Charge specifications','NumberTitle','off','CloseRequestFcn',@viewCharge_Update,...
    'WindowStyle','normal');

%Block #
viewChargeBlockDrop = uicontrol(viewChargeGUI,'Style','popup','String',...
    {'Block ##'},...
    'Units','normalized','Position', [0.81 0.94 0.17 0.04], 'Tag',...
    'viewChargeBlockDrop','Callback', @viewCharge_Update);

% %Response start
% viewChargePulseStarts = uibuttongroup(viewChargeGUI,'Title','Pulse start',...
%     'Units','normalized','Position', [0.81 0.75 0.17 0.16], 'Tag',...
%     'viewChargeResponseStarts','SelectionChangedFcn',@viewCharge_Update);
%
% viewChargeStartsAuto = uicontrol(viewChargePulseStarts,'Style',...
%     'radiobutton','Units','normalized','Tag','viewChargeStartsAuto',...
%     'String','Auto',...
%     'Position',[0.05 0.69 0.92 0.35]);
%
% viewChargeStartsPre = uicontrol(viewChargePulseStarts,'Style',...
%     'radiobutton','Units','normalized','Tag','viewChargeStartsPre',...
%     'String','Pre',...
%     'Position',[0.05 0.36 0.92 0.35]);
%
% viewChargeStartsPost = uicontrol(viewChargePulseStarts,'Style',...
%     'radiobutton','Units','normalized','Tag','viewChargeStartsPost',...
%     'String','Post',...
%     'Position',[0.05 0.01 0.92 0.35]);

%Response Width
viewChargePulseWidth = uibuttongroup(viewChargeGUI,'Title','Pulse width',...
    'Units','normalized','Position', [0.81 0.697 0.17 0.213], 'Tag',...
    'viewChargePulseWidth','SelectionChangedFcn',@viewCharge_Update);

viewChargeWidthMax = uicontrol(viewChargePulseWidth,'Style',...
    'radiobutton','Units','normalized','Tag','viewChargeWidthMax',...
    'String','Max',...
    'Position',[0.05 0.78 0.92 0.25]);

viewChargeWidthFixed = uicontrol(viewChargePulseWidth,'Style',...
    'radiobutton','Units','normalized','Tag','viewChargeWidthFixed',...
    'String','Fixed',...
    'Position',[0.05 0.54 0.92 0.25]);

viewChargeWidthCustom = uicontrol(viewChargePulseWidth,'Style',...
    'radiobutton','Units','normalized','Tag','viewChargeWidthCustom',...
    'String','Custom',...
    'Position',[0.05 0.29 0.92 0.25]);

viewChargeWidthEdit = uicontrol(viewChargePulseWidth,'Style',...
    'edit','Units','normalized','Tag','viewChargeWidthEdit',...
    'String','','Enable','off',...
    'Position',[0.07 0.04 0.88 0.22],'Callback', @viewCharge_Update);

%Synchronous pulse width
viewChargeSyncWidth = uibuttongroup(viewChargeGUI,'Title','Sync width',...
    'Units','normalized','Position', [0.81 0.52 0.17 0.18], 'Tag',...
    'viewChargeSyncWidth','SelectionChangedFcn',@viewCharge_Update);
viewChargeSyncMax = uicontrol(viewChargeSyncWidth,'Style',...
    'radiobutton','Units','normalized','Tag','viewChargeSyncMax',...
    'String','Pulse',...
    'Position',[0.05 0.69 0.92 0.25]);
viewChargeSyncCustom = uicontrol(viewChargeSyncWidth,'Style',...
    'radiobutton','Units','normalized','Tag','viewChargeSyncCustom',...
    'String','Custom',...
    'Position',[0.05 0.36 0.92 0.25]);
viewChargeSyncEdit = uicontrol(viewChargeSyncWidth,'Style',...
    'edit','Units','normalized','Tag','viewChargeSyncEdit',...
    'String','','Enable','off',...
    'Position',[0.07 0.04 0.88 0.29],'Callback', @viewCharge_Update);

%Zoom to pulse check
viewChargeZoomText = uicontrol(viewChargeGUI, 'Style','text',...
    'String','Zoom:',...
    'Units','normalized','Position', [0.81 0.47 0.1 0.04], 'Tag',...
    'viewChargeZoomText','HorizontalAlignment','center');
viewChargeZoomCheck = uicontrol(viewChargeGUI, 'Style','checkbox',...
    'Units','normalized','Position', [0.927 0.47 0.07 0.04], 'Tag',...
    'viewChargeZoomCheck','Value',false,'Callback', @viewCharge_Update);


%Table with values
viewChargeOverview = uitable(viewChargeGUI,'Units','normalized',...
    'Position',[0.016 0.124 0.78 0.86],'Tag','viewChargeOverview',...
    'ColumnName',{'Block 1'},'CellSelectionCallback',...
    @viewCharge_Update);
% viewAmplitudeUnits = uicontrol(viewChargeGUI, 'Style','text',...
%     'String','(pC)', 'Units','normalized','Position', [0.022 0.94 0.073 0.0333]);


%Apply/Cancel
viewChargeApply = uicontrol(viewChargeGUI,'Style','pushbutton','String','Apply',...
    'Units','normalized','Position', [0.81 0.073 0.17 0.05], 'Tag','viewChargeApply',...
    'Callback', @viewCharge_Update);
viewChargeCancel = uicontrol(viewChargeGUI,'Style','pushbutton','String','Cancel',...
    'Units','normalized','Position', [0.81 0.02 0.17 0.05], 'Tag','viewChargeCancel',...
    'Callback', @viewCharge_Update);

viewChargeStatus = uicontrol(viewChargeGUI, 'Style','text',...
    'String','I dont know where to put this nor what to say',...
    'Units','normalized','Position', [0.02 0.02 0.75 0.08], 'Tag',...
    'viewChargeStatus','HorizontalAlignment','left');

viewCharge_Update(viewChargeStatus);
end

%miniAnalysis
function viewEPSC_MiniAnalysis(~,~)
%prevent multiple
if ~isempty(findobj('Tag','viewMiniGUI'))
    figure(findobj('Tag','viewMiniGUI')) %Make active window
    return
end

viewEPSC = findobj('Tag', 'viewEPSC');

%Draw figure
viewMiniGUI = figure('OuterPosition',...
    [viewEPSC.Position(1)+viewEPSC.Position(3)*0.6 viewEPSC.Position(2)*1.1 300 340],...
    'Tag','viewMiniGUI','MenuBar','none','Toolbar','none',...
    'Name','Mini specifications','NumberTitle','off',...
    'WindowStyle','normal','CloseRequestFcn',@viewMini_Update);

%Section drop down
viewMiniSetDrop = uicontrol(viewMiniGUI,'Style','popup','String',{'Section 0'},...
    'Units','normalized','Position', [0.05 0.77 0.9 0.09], 'Tag',...
    'viewMiniSetDrop','Callback', @viewMini_Update,'Enable','off');
viewMiniSetAdd = uicontrol(viewMiniGUI,'Style','pushbutton','String','Add Section',...
    'Units','normalized','Position', [0.05 0.88 0.435 0.09], 'Tag','viewMiniSetAdd',...
    'Callback', @viewMini_Update);
viewMiniSetRemove = uicontrol(viewMiniGUI,'Style','pushbutton','String','Remove Section',...
    'Units','normalized','Position', [0.525 0.88 0.435 0.09], 'Tag','viewMiniSetRemove',...
    'Callback', @viewMini_Update,'Enable','off');

%Start and stop
viewMiniStartText = uicontrol(viewMiniGUI,'Style','text','String','Start',...
    'Units','normalized','Position', [0.08 0.68 0.36 0.07], 'Tag','viewMiniStartText');
viewMiniStopText = uicontrol(viewMiniGUI,'Style','text','String','Stop',...
    'Units','normalized','Position', [0.56 0.68 0.36 0.07], 'Tag','viewMiniStopText');

viewMiniStartEdit = uicontrol(viewMiniGUI,'Style','edit','String','0',...
    'Units','normalized','Position', [0.08 0.615 0.36 0.07], 'Tag','viewMiniStartEdit',...
    'Callback', @viewMini_Update);
viewMiniStopEdit = uicontrol(viewMiniGUI,'Style','edit','String','0',...
    'Units','normalized','Position', [0.56 0.615 0.36 0.07], 'Tag','viewMiniStopEdit',...
    'Callback', @viewMini_Update);

%Mini method drop
viewMiniMethodText = uicontrol(viewMiniGUI,'Style','text','String','Detection Method:',...
    'Units','normalized','Position', [0.05 0.52 0.9 0.07], 'Tag','viewMiniMethodText',...
    'HorizontalAlignment','left');
viewMiniMethodDrop = uicontrol(viewMiniGUI,'Style','popup','String',{'Artificial Neural Network'},...
    'Units','normalized','Position', [0.05 0.43 0.9 0.09], 'Tag',...
    'viewMiniMethodDrop');

%Analysis finished
viewMiniDoneCheck = uicontrol(viewMiniGUI,'Style','checkbox','String','Section analyzed',...
    'Units','normalized','Position', [0.05 0.34 0.9 0.07], 'Tag','viewMiniDoneCheck',...
    'Callback', @viewMini_Update);

%Start Analysis button
viewMiniAnalyze = uicontrol(viewMiniGUI,'Style','pushbutton','String','Start Analysis',...
    'Units','normalized','Position', [0.05 0.23 0.9 0.09], 'Tag','viewMiniAnalyze',...
    'Callback', @viewEPSC_MiniANN);

%Apply Cancel buttons
viewMiniApply = uicontrol(viewMiniGUI,'Style','pushbutton','String','Apply',...
    'Units','normalized','Position', [0.05 0.13 0.425 0.09], 'Tag','viewMiniApply',...
    'Callback', @viewMini_Update);
viewMiniCancel = uicontrol(viewMiniGUI,'Style','pushbutton','String','Cancel',...
    'Units','normalized','Position', [0.525 0.13 0.425 0.09], 'Tag','viewMiniCancel',...
    'Callback', @viewMini_Update);
%Status text
viewMiniStatus = uicontrol(viewMiniGUI,'Style','text','String','Mini status',...
    'Units','normalized','Position', [0.05 0.02 0.9 0.07], 'Tag','viewMiniStatus',...
    'HorizontalAlignment','left');

viewMini_Update(viewMiniStatus);
end

function viewEPSC_MiniANN(~,~)
%prevent multiple
if ~isempty(findobj('Tag','viewANNGUI'))
    figure(findobj('Tag','viewANNGUI')) %Make active window
    return
end

viewEPSC = findobj('Tag', 'viewEPSC');
figure(viewEPSC); %Make sure nothing covers the graph

%Draw figure
viewANNGUI = figure('OuterPosition',...
    [viewEPSC.Position(1)+viewEPSC.Position(3)*0.6 viewEPSC.Position(2)*1.1 300 450],...
    'Tag','viewANNGUI','MenuBar','none','Toolbar','none',...
    'Name','Mini Analysis','NumberTitle','off',...
    'WindowStyle','normal','CloseRequestFcn',@viewANN_Update);

%Section drop down
viewANNEventDrop = uicontrol(viewANNGUI,'Style','popup','String',{'0 @ 0s'},...
    'Units','normalized','Position', [0.05 0.89 0.9 0.09], 'Tag',...
    'viewANNEventDrop','Callback', @viewANN_Update);
viewANNZoom = uicontrol(viewANNGUI,'Style','pushbutton','String','Zoom',...
    'Units','normalized','Position', [0.05 0.84 0.425 0.07], 'Tag','viewANNZoom',...
    'Callback', @viewANN_Update,'UserData',false);
viewANNFull = uicontrol(viewANNGUI,'Style','pushbutton','String','Full',...
    'Units','normalized','Position', [0.525 0.84 0.425 0.07], 'Tag','viewANNFull',...
    'Callback', @viewANN_Update);


%Mini method drop
viewANNZoomText = uicontrol(viewANNGUI,'Style','text','String','Zoom window size:',...
    'Units','normalized','Position', [0.05 0.78 0.9 0.05], 'Tag','viewANNZoomText',...
    'HorizontalAlignment','center');


viewANNZoomXText = uicontrol(viewANNGUI,'Style','text','String','(s):',...
    'Units','normalized','Position', [0.05 0.70 0.14 0.05], 'Tag','viewANNZoomXText',...
    'HorizontalAlignment','right');
viewANNZoomYText = uicontrol(viewANNGUI,'Style','text','String','(pA):',...
    'Units','normalized','Position', [0.525 0.70 0.14 0.05], 'Tag','viewANNZoomYText',...
    'HorizontalAlignment','right');

viewANNZoomXEdit = uicontrol(viewANNGUI,'Style','edit','String','0.5',...
    'Units','normalized','Position', [0.19 0.69 0.285 0.07], 'Tag','viewANNZoomXEdit',...
    'Callback', @viewANN_Update);
viewANNZoomYEdit = uicontrol(viewANNGUI,'Style','edit','String','300',...
    'Units','normalized','Position', [0.665 0.69 0.285 0.07], 'Tag','viewANNZoomYEdit',...
    'Callback', @viewANN_Update);

%Confirm Discard buttons
viewANNConfirm = uicontrol(viewANNGUI,'Style','pushbutton','String','Confirm (m)',...
    'Units','normalized','Position', [0.05 0.59 0.425 0.07], 'Tag','viewANNConfirm',...
    'Callback', @viewANN_Update);
viewANNDiscard = uicontrol(viewANNGUI,'Style','pushbutton','String','Discard (c)',...
    'Units','normalized','Position', [0.05 0.52 0.425 0.07], 'Tag','viewANNDiscard',...
    'Callback', @viewANN_Update);

%Baseline New Event buttons
viewANNBaseline = uicontrol(viewANNGUI,'Style','pushbutton','String','Baseline (b)',...
    'Units','normalized','Position', [0.525 0.59 0.425 0.07], 'Tag','viewANNBaseline',...
    'Callback', @viewANN_Update,'Enable','off');
viewANNNewEvent = uicontrol(viewANNGUI,'Style','pushbutton','String','New event (n)',...
    'Units','normalized','Position', [0.525 0.52 0.425 0.07], 'Tag','viewANNNewEvent',...
    'Callback', @viewANN_Update,'Enable','off');


%Preview
viewANNPreviewCheck = uicontrol(viewANNGUI,'Style','checkbox',...
    'String','Preview detection','Units','normalized','Position',...
    [0.05 0.45 0.9 0.05], 'Tag','viewANNPreviewCheck',...
    'Callback', @viewANN_Update);


%Detection threshold
viewANNDetectText = uicontrol(viewANNGUI,'Style','text','String','Detection Threshold:',...
    'Units','normalized','Position', [0.05 0.38 0.56 0.05], 'Tag','viewANNDetectText',...
    'HorizontalAlignment','left');
viewANNDetectEdit = uicontrol(viewANNGUI,'Style','edit','String','2',...
    'Units','normalized','Position', [0.64 0.37 0.18 0.07], 'Tag','viewANNDetectEdit',...
    'Callback', @viewANN_Update);

%Certainty threshold
viewANNCertText = uicontrol(viewANNGUI,'Style','text','String','Certainty Threshold:',...
    'Units','normalized','Position', [0.05 0.30 0.56 0.05], 'Tag','viewANNCertText',...
    'HorizontalAlignment','left');
viewANNCertEdit = uicontrol(viewANNGUI,'Style','edit','String','5',...
    'Units','normalized','Position', [0.64 0.29 0.18 0.07], 'Tag','viewANNCertEdit',...
    'Callback', @viewANN_Update);

%Check from here
viewANNfromHereCheck = uicontrol(viewANNGUI,'Style','checkbox',...
    'Units','normalized','Position',...
    [0.05 0.20 0.07 0.05], 'Tag','viewANNfromHereCheck',...
    'Callback', @viewANN_Update);
viewANNfromHereText = uicontrol(viewANNGUI,'Style','text',...
    'String',sprintf('Detect after selected point'),'Units','normalized','Position',...
    [0.12 0.175 0.38 0.1], 'Tag','viewANNfromHereText');

%Start Redetect button
viewANNAnalyze = uicontrol(viewANNGUI,'Style','pushbutton','String','Auto detect',...
    'Units','normalized','Position', [0.51 0.19 0.44 0.07], 'Tag','viewANNAnalyze',...
    'Callback', @viewANN_Update);

%Apply Cancel buttons
viewANNFinish = uicontrol(viewANNGUI,'Style','pushbutton','String','Finish',...
    'Units','normalized','Position', [0.05 0.10 0.425 0.07], 'Tag','viewANNFinish',...
    'Callback', @viewANN_Update);
viewANNCancel = uicontrol(viewANNGUI,'Style','pushbutton','String','Cancel',...
    'Units','normalized','Position', [0.525 0.10 0.425 0.07], 'Tag','viewANNCancel',...
    'Callback', @viewANN_Update);
%Status text
viewANNStatus = uicontrol(viewANNGUI,'Style','text','String','A-OK!',...
    'Units','normalized','Position', [0.05 0.02 0.9 0.05], 'Tag','viewANNStatus',...
    'HorizontalAlignment','left');
viewANN_Update(viewANNStatus);
end

% Save GUI and Export

function viewEPSC_Save(~,~)
% prevent multiple
if ~isempty(findobj('Tag','viewSaveGUI'))
    figure(findobj('Tag','viewSaveGUI')) %Make active window
    return
end

%Get
viewEPSC = findobj('Tag', 'viewEPSC');
ephysDB = getappdata(viewEPSC,'ephysDB');
dataPath = getappdata(viewEPSC,'dataPath');
viewNamesDrop = findobj('Tag','viewNamesDrop');

if isempty(ephysDB)
    %dummy variable
    ephysDB = 1;
    noData = true;
else
    noData = false;
end

viewSaveGUI = figure('OuterPosition',...
    [viewEPSC.Position(1)+viewEPSC.Position(3)*0.75 viewEPSC.Position(2)*1.1 450 450],...
    'Tag','viewSaveGUI','MenuBar','none','Toolbar','none',...
    'Name','Save settings and analysis','NumberTitle','off',...
    'WindowStyle','normal');
%,'CloseRequestFcn',@viewArt_Update);

%Save Path
viewSavePathEdit = uicontrol(viewSaveGUI,'Style',...
    'edit','Units','normalized','Tag','viewSavePathEdit',...
    'String',fullfile(dataPath{ephysDB(viewNamesDrop.Value)},'Data'),...
    'Position',[0.24 0.94 0.74 0.05],'HorizontalAlignment','left');

viewSavePathSelect = uicontrol(viewSaveGUI,'Style',...
    'pushbutton','Units','normalized','Tag','viewSavePathSelect',...
    'String','Select path',...
    'Position',[0.017 0.94 0.21 0.05],'Callback', @viewSave_Update);

%mEPSCs
viewSaveMini = uicontrol(viewSaveGUI,'Style',...
    'frame','Units','normalized','Tag','viewSaveMini',...
    'Position',[0.04 0.77 0.71 0.15]);
viewSaveMiniText = uicontrol(viewSaveGUI,'Style',...
    'text','Units','normalized','Tag','viewSaveMiniText',...
    'String','mEPSC data:',...
    'Position',[0.05 0.89 0.21 0.04]);

viewSaveMiniCoords = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveMiniCoords',...
    'String','Coordinates','Value',true,...
    'Position',[0.06 0.84 0.31 0.04]);
viewSaveMiniTargets = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveMiniTargets',...
    'String','Targets','Value',true,...
    'Position',[0.06 0.78 0.31 0.04]);
viewSaveMiniFeatures = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveMiniFeatures',...
    'String','Features','Value',true,...
    'Position',[0.31 0.84 0.33 0.04]);
viewSaveMiniReal = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveMiniReal',...
    'String','Only save marked events','Value',false,...
    'Position',[0.31 0.78 0.43 0.04]);

%Options
viewSaveSettings = uicontrol(viewSaveGUI,'Style',...
    'frame','Units','normalized','Tag','viewSaveSettings',...
    'Position',[0.04 0.46 0.42 0.28]);
viewSaveSettingText = uicontrol(viewSaveGUI,'Style',...
    'text','Units','normalized','Tag','viewSaveSettingText',...
    'String','Settings to save:',...
    'Position',[0.05 0.72 0.25 0.04]);

viewSaveBaseSetting = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveBaseSetting',...
    'String','Baseline Settings','Value',true,...
    'Position',[0.08 0.66 0.31 0.04]);
viewSaveArtSetting = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveArtSetting',...
    'String','Artifact Settings','Value',true,...
    'Position',[0.08 0.60 0.31 0.04]);
viewSaveAmpSetting = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveAmpSetting',...
    'String','Amplitude Settings','Value',true,...
    'Position',[0.08 0.54 0.33 0.04]);
viewSaveChargeSetting = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveChargeSetting',...
    'String','Charge Settings','Value',true,...
    'Position',[0.08 0.48 0.31 0.04]);


viewSaveValues = uicontrol(viewSaveGUI,'Style',...
    'frame','Units','normalized','Tag','viewSaveValues',...
    'Position',[0.54 0.46 0.42 0.28]);
viewSaveValueText = uicontrol(viewSaveGUI,'Style',...
    'text','Units','normalized','Tag','viewSaveValueText',...
    'String','Values to save:',...
    'Position',[0.55 0.72 0.24 0.04]);

viewSaveBaseValue = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveBaseValue',...
    'String','Baseline trace','Value',false,...
    'Position',[0.58 0.66 0.31 0.04]);
viewSaveArtValue = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveArtValue',...
    'String','Artifact Positions','Value',false,...
    'Position',[0.58 0.60 0.31 0.04]);
viewSaveAmpValue = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveAmpValue',...
    'String','Amplitude Values','Value',true,...
    'Position',[0.58 0.54 0.33 0.04]);
viewSaveChargeValue = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveChargeValue',...
    'String','Charge Values','Value',true,...
    'Position',[0.58 0.48 0.31 0.04]);

viewSaveTraces = uicontrol(viewSaveGUI,'Style',...
    'frame','Units','normalized','Tag','viewSaveTraces',...
    'Position',[0.04 0.15 0.54 0.28]);
viewSaveTraceText = uicontrol(viewSaveGUI,'Style',...
    'text','Units','normalized','Tag','viewSaveTraceText',...
    'String','Traces to save:',...
    'Position',[0.05 0.41 0.235 0.04]);

viewSaveCorrTrace = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveCorrTrace',...
    'String','Corrected trace','Value',false,...
    'Position',[0.06 0.35 0.5 0.04]);
viewSaveEmptyTrace = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveEmptyTrace',...
    'String','Trace with artifacts removed','Value',false,...
    'Position',[0.06 0.29 0.5 0.04]);
viewSaveInterpTrace = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveInterpTrace',...
    'String','Only Artifact Interpolations','Value',false,...
    'Position',[0.06 0.23 0.5 0.04]);
viewSaveSyncTrace = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveSyncTrace',...
    'String','Synchronous cut-off trace','Value',false,...
    'Position',[0.06 0.17 0.5 0.04]);

viewSaveIndex = uicontrol(viewSaveGUI,'Style',...
    'frame','Units','normalized','Tag','viewSaveIndex',...
    'Position',[0.63 0.25 0.33 0.18]);
viewSaveIndexText = uicontrol(viewSaveGUI,'Style',...
    'text','Units','normalized','Tag','viewSaveIndexText',...
    'String','Save indices:',...
    'Position',[0.64 0.41 0.20 0.04]);

viewSaveAmpIdx = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveAmpIdx',...
    'String','Amplitude index','Value',false,...
    'Position',[0.65 0.35 0.30 0.04]);
viewSaveChargeIdx = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveChargeIdx',...
    'String','Charge index','Value',false,...
    'Position',[0.65 0.29 0.30 0.04]);

viewSaveSingleFile = uicontrol(viewSaveGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSaveSingleFile',...
    'String','Save as single file','Value',false,...
    'Position',[0.61 0.18 0.35 0.04]);

viewSaveSave = uicontrol(viewSaveGUI,'Style',...
    'pushbutton','Units','normalized','Tag','viewSaveSave',...
    'String','Save','Value',false,...
    'Position',[0.79 0.08 0.18 0.05],'Callback', @viewSave_Update);
viewSaveCancel = uicontrol(viewSaveGUI,'Style',...
    'pushbutton','Units','normalized','Tag','viewSaveCancel',...
    'String','Cancel','Value',false,...
    'Position',[0.79 0.017 0.18 0.05],'Callback', @viewSave_Update);

viewSaveStatus = uicontrol(viewSaveGUI,'Style',...
    'text','Units','normalized','Tag','viewSaveStatus',...
    'String','Tip: All parameters can be calculated from the settings, avoid selecting too much to save space.',...
    'Position',[0.03 0.025 0.72 0.08],'HorizontalAlignment','left');
if noData
    viewSaveStatus.String = 'No data loaded. Come back later';
    viewSaveSave.Enable = 'off';
    return;
end

viewSave_Update(viewSaveStatus);
end
%
function viewEPSC_Export(~,~)
%Draw Export window
% prevent multiple
if ~isempty(findobj('Tag','viewExportGUI'))
    figure(findobj('Tag','viewExportGUI')) %Make active window
    return
end

% Get
viewEPSC = findobj('Tag', 'viewEPSC');

viewExportGUI = figure('OuterPosition',...
    [viewEPSC.Position(1)+viewEPSC.Position(3)*0.75 viewEPSC.Position(2)*1.1 600 390],...
    'Tag','viewExportGUI','MenuBar','none','Toolbar','none',...
    'Name','Export Analysis to Excel','NumberTitle','off',...
    'WindowStyle','normal');
%,'CloseRequestFcn',@viewArt_Update);

%Export Path
viewExportPathEdit = uicontrol(viewExportGUI,'Style',...
    'edit','Units','normalized','Tag','viewExportPathEdit',...
    'String','',...
    'Position',[0.2 0.905 0.77 0.06],'HorizontalAlignment','left');

viewExportPathSelect = uicontrol(viewExportGUI,'Style',...
    'pushbutton','Units','normalized','Tag','viewExportPathSelect',...
    'String','Select path',...
    'Position',[0.022 0.90 0.16 0.07],'Callback', @viewExport_Update);

%Options
%Amplitude
viewExportAmplitude = uicontrol(viewExportGUI,'Style',...
    'frame','Units','normalized','Tag','viewExportAmplitude',...
    'Position',[0.016 0.135 0.47 0.36]);
viewExportAmplitudeText = uicontrol(viewExportGUI,'Style',...
    'text','Units','normalized','Tag','viewExportAmplitudeText',...
    'String','Amplitude:',...
    'Position',[0.028 0.455 0.13 0.06]);

viewAmpCorr = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewAmpCorr',...
    'String','Corrected Amplitude Values','Value',true,...
    'Position',[0.04 0.40 0.37 0.06]);
viewAmpNorm = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewAmpNorm',...
    'String','Normalized Amplitude Values','Value',true,...
    'Position',[0.04 0.32 0.37 0.06]);
viewAmpRaw = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewAmpRaw',...
    'String','Raw Amplitude Values','Value',false,...
    'Position',[0.04 0.24 0.37 0.06]);
viewAmpBase = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewAmpBase',...
    'String','Baseline at amplitude index','Value',false,...
    'Position',[0.04 0.16 0.37 0.06]);

%Synchronous charge
viewExportSync = uicontrol(viewExportGUI,'Style',...
    'frame','Units','normalized','Tag','viewExportSync',...
    'Position',[0.016 0.52 0.47 0.30]);
viewExportSyncText = uicontrol(viewExportGUI,'Style',...
    'text','Units','normalized','Tag','viewExportSyncText',...
    'String','Synchronous charge:',...
    'Position',[0.028 0.8 0.26 0.06]);

viewSyncCharge = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSyncCharge',...
    'String','Synchronous charge','Value',true,...
    'Position',[0.04 0.72 0.37 0.06]);
viewSyncNorm = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSyncNorm',...
    'String','Percentage of total','Value',true,...
    'Position',[0.04 0.64 0.37 0.06]);
viewSyncCum = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewSyncCum',...
    'String','Cumulative synchronous charge','Value',false,...
    'Position',[0.04 0.56 0.42 0.06]);

%Asynchronous charge
viewExportAsync = uicontrol(viewExportGUI,'Style',...
    'frame','Units','normalized','Tag','viewExportAsync',...
    'Position',[0.516 0.52 0.47 0.30]);
viewExportAsyncText = uicontrol(viewExportGUI,'Style',...
    'text','Units','normalized','Tag','viewExportAsyncText',...
    'String','Asynchronous charge:',...
    'Position',[0.528 0.8 0.28 0.06]);

viewAsyncCharge = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewAsyncCharge',...
    'String','Asynchronous charge','Value',true,...
    'Position',[0.54 0.72 0.43 0.06]);
viewAsyncNorm = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewAsyncNorm',...
    'String','Percentage of total','Value',true,...
    'Position',[0.54 0.64 0.43 0.06]);
viewAsyncCum = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewAsyncCum',...
    'String','Cumulative asynchronous charge','Value',false,...
    'Position',[0.54 0.56 0.43 0.06]);

%Total charge
viewExportTotal = uicontrol(viewExportGUI,'Style',...
    'frame','Units','normalized','Tag','viewExportTotal',...
    'Position',[0.516 0.195 0.47 0.30]);
viewExportTotalText = uicontrol(viewExportGUI,'Style',...
    'text','Units','normalized','Tag','viewExportTotalText',...
    'String','Total charge:',...
    'Position',[0.528 0.455 0.15 0.06]);

viewTotalCharge = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewTotalCharge',...
    'String','Total charge','Value',true,...
    'Position',[0.54 0.40 0.43 0.06]);
viewTotalNorm = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewTotalNorm',...
    'String','Normalized total charge','Value',true,...
    'Position',[0.54 0.32 0.43 0.06]);
viewTotalCum = uicontrol(viewExportGUI,'Style',...
    'checkbox','Units','normalized','Tag','viewTotalCum',...
    'String','Cumulative total charge','Value',false,...
    'Position',[0.54 0.24 0.43 0.06]);

%Status text
viewExportStatus = uicontrol(viewExportGUI,'Style',...
    'text','Units','normalized','Tag','viewExportStatus',...
    'String','Tip: Every option will have its own sheet.',...
    'Position',[0.03 0.02 0.94 0.1],'HorizontalAlignment','left');

%Export button
viewExportExport = uicontrol(viewExportGUI,'Style',...
    'pushbutton','Units','normalized','Tag','viewExportExport',...
    'String','Export','Value',false,...
    'Position',[0.54 0.12 0.18 0.07],'Callback', @viewExport_Update);
viewExportCancel = uicontrol(viewExportGUI,'Style',...
    'pushbutton','Units','normalized','Tag','viewExportCancel',...
    'String','Cancel','Value',false,...
    'Position',[0.75 0.12 0.18 0.07],'Callback', @viewExport_Update);
end

% Analysis Update Callbacks
function viewBase_Update(hObject,event)
viewEPSC = findobj('Tag', 'viewEPSC');
viewNamesDrop = findobj('Tag','viewNamesDrop');
viewBaselineGUI = findobj('Tag','viewBaselineGUI');
viewBaseCheck = findobj('Tag','viewBaseCheck');

baselineValues = getappdata(viewEPSC,'baselineValues');

%Are we closing?
if strcmp(hObject.Tag,'viewBaseCancel') || strcmp(hObject.Tag,'viewBaselineGUI')
    %Remove scatter
    delete(findobj('Tag','viewBaseScatter'));
    %Reset values
    if ~isempty(baselineValues)
        viewBaseCheck.UserData = baselineValues{viewNamesDrop.Value};
    end
    %Close figure
    delete(viewBaselineGUI);
    return
end

if isempty(baselineValues)
    %No Data loaded just do nothing
    return
end
baselineValue = baselineValues{viewNamesDrop.Value};
tempBaseline = viewBaseCheck.UserData;

if isempty(tempBaseline) || nanmean(tempBaseline{2}(:,1)) < 0.05 %Probably not real values replace
    tempBaseline = baselineValue;
end

cID = viewNamesDrop.Value;
ephysDB = getappdata(viewEPSC,'ephysDB');
baseFltr = getappdata(viewEPSC,'ephysFltr');
dataPath = getappdata(viewEPSC,'dataPath');
updateBoxes = false;
updateBaseDots = false;

%% protocol default
if ephysDB(cID) == 1 && strcmp(hObject.Tag,'viewBaseProtocolDefault')
    %Get standard variables
    ephysFltr = getappdata(viewEPSC,'ephysFltr');
    dataPath = getappdata(viewEPSC,'dataPath');
    
    %Get protMeta
    [~,protMeta] = protRetrieve(ephysFltr{cID,21},ephysFltr,dataPath{1});
    
    %find mEPSC entries
    mEPSCpoints = strcmp('mEPSC',protMeta{1,2}(:,1));
    %Take two points from beginning and end
    minPointIdx = find(mEPSCpoints,1,'first');
    if ~minPointIdx == 1
        minTime(1) = sum([protMeta{1,2}{1:minPointIdx-1,2}])+protMeta{1,2}{minPointIdx,2}/2-0.05;
    else
        minTime(1) = 0;
    end
    minTime(2) = sum([protMeta{1,2}{1:minPointIdx,2}])*0.9;
    
    maxPointIdx = find(mEPSCpoints,1,'last');
    maxTime(1) = sum([protMeta{1,2}{1:maxPointIdx-1,2}])+protMeta{1,2}{maxPointIdx,2}/2-0.05;
    maxTime(2) = sum([protMeta{1,2}{1:maxPointIdx,2}]);
    
    %Reset original baselineValue
    tempBaseline{1} = 'linear';
    tempBaseline{2} = NaN(6,2);
    
    %Fill it in
    tempBaseline{2}(1,:) = [minTime(1), 0.1];
    tempBaseline{2}(2,:) = [minTime(2), -0.1];
    tempBaseline{2}(3,:) = [maxTime(1), 0.1];
    tempBaseline{2}(4,:) = [maxTime(2), -0.1];
    
    %Nothing to report
    viewBaseStatus = findobj('Tag','viewBaseStatus');
    viewBaseStatus.String = '';
    
    %Update base scatters
    updateBaseDots = true;
    %% Add/Remove parameter set
elseif strcmp(hObject.Tag,'viewBaseSetAdd')
    %Get base set drop
    viewBaseSetDrop = findobj('Tag','viewBaseSetDrop');
    idx = numel(viewBaseSetDrop.String);
    viewBaseSetDrop.String{end+1} = ['Set ',num2str(idx+1)];
    
    %Prepare baselineValue
    tempBaseline{2}(1+6*(idx):6*(idx+1),:) = NaN;
    viewBaseSetDrop.Value =  viewBaseSetDrop.Value+1;
    
    updateBoxes = true;
    
elseif strcmp(hObject.Tag,'viewBaseSetRemove')
    %Get base set drop
    viewBaseSetDrop = findobj('Tag','viewBaseSetDrop');
    idx = numel(viewBaseSetDrop.String);
    if idx > 1
        %Generate remain fltrs
        remain = true(size(tempBaseline{2}(:,1)));
        remain(1+6*(viewBaseSetDrop.Value-1):6*(viewBaseSetDrop.Value)) =...
            false;
        viewBaseSetDrop.String = viewBaseSetDrop.String(1:end-1);
        %Prepare baselineValue
        tempBaseline{2} = tempBaseline{2}(remain,:);
        
        updateBoxes = true;
    else
        %Update status
        viewBaseStatus = findobj('Tag','viewBaseStatus');
        viewBaseStatus.String = 'Last set cannot be removed';
        viewBaseStatus.ForegroundColor = [0 0 0];
    end
    
    %See if we need to reset drop position
    if viewBaseSetDrop.Value > idx-1
        viewBaseSetDrop.Value = 1;
    end
    
    %Update base scatters
    updateBaseDots = true;
    %% Save baseline values if necessary
elseif regexp(hObject.Tag,'viewBasePoint|viewBaseRange')
    %Find out which value to change
    %Get column
    if regexp(hObject.Tag,'viewBasePoint') %Point
        c=1;
    else %Range
        c=2;
    end
    %Get row adjusted for set number
    viewBaseSetDrop = findobj('Tag','viewBaseSetDrop');
    r=str2num(hObject.Tag(end))+(viewBaseSetDrop.Value-1)*6;
    
    %Check if empty
    if isempty(hObject.String)
        tempBaseline{2}(r,c) = NaN;
    else
        %Remove illegal characters
        illChar = regexp(hObject.String,'[^0-9\.-]');
        illDots = regexp(hObject.String,'\.');
        illMinus = regexp(hObject.String,'-');
        illMinus = illMinus(illMinus ~= 1);
        if ~isempty(illDots)
            illDots = illDots(2:end);
        end
        if ~isempty(illChar) || ~isempty(illDots) || ~isempty(illMinus)
            %Update status
            viewBaseStatus = findobj('Tag','viewBaseStatus');
            viewBaseStatus.String = 'Warning! Only numeric input is used';
            viewBaseStatus.ForegroundColor = [1 0 0];
            hObject.String([illMinus,illChar,illDots]) = '';
        end
        
        %Check if value is allowed
        rangeStatus = false;
        dataTrace = findobj('Tag','viewDataTrace');
        minValue = min(dataTrace.XData);
        maxValue = max(dataTrace.XData);
        if c==1 %Input is point
            if str2double(hObject.String) < minValue
                hObject.String = num2str(minValue);
                rangeStatus = true;
            elseif str2double(hObject.String) > maxValue
                hObject.String = num2str(maxValue);
                rangeStatus = true;
            end
            if ~isnan(tempBaseline{2}(r,2))
                if str2double(hObject.String)+tempBaseline{2}(r,2) < minValue
                    tempBaseline{2}(r,2) = 0.1;
                    rangeStatus = true;
                    updateBoxes = true;
                elseif str2double(hObject.String)+tempBaseline{2}(r,2) > maxValue
                    tempBaseline{2}(r,2) = -0.1;
                    rangeStatus = true;
                    updateBoxes = true;
                end
            end
        else %Input is range
            if ~isnan(tempBaseline{2}(r,1))
                if str2double(hObject.String)+tempBaseline{2}(r,1) < minValue
                    hObject.String = '0.1';
                    rangeStatus = true;
                elseif str2double(hObject.String)+tempBaseline{2}(r,1) > maxValue
                    hObject.String = '-0.1';
                    rangeStatus = true;
                end
            end
        end
        if rangeStatus
            viewBaseStatus = findobj('Tag','viewBaseStatus');
            viewBaseStatus.String = 'Warning! Baseline should be in trace';
            viewBaseStatus.ForegroundColor = [1 0 0];
        end
        
        %Set Value
        tempBaseline{2}(r,c) = str2double(hObject.String);
    end
    
    
    %Update base scatters
    updateBaseDots = true;
    
    %% Method drop down
elseif strcmp(hObject.Tag,'viewBaseInterpDrop')
    %set baseline method
    if hObject.Value == 1
        tempBaseline{1} = 'linear';
    else
        if sum(~isnan(tempBaseline{2}(:,1))) < 4
            viewBaseStatus = findobj('Tag','viewBaseStatus');
            viewBaseStatus.String = 'Warning! Cubic interpolation requires at least 4 points';
            viewBaseStatus.ForegroundColor = [1 0 0];
        end
        tempBaseline{1} = 'pchip';
    end
    
    
    %% Apply points
elseif strcmp(hObject.Tag,'viewBaseApply')
    %Remove full NaNs
    filledValues = ~any(isnan(tempBaseline{2}),2);
    applyValues = tempBaseline{2}(filledValues,:);
    [~,sortIdx] = sort(applyValues(:,1));
    applyValues = applyValues(sortIdx,:);
    %see how far off we are from 6
    extraValues = 6 - mod(size(applyValues,1),6);
    
    if extraValues < 6
        applyValues = [applyValues;NaN(extraValues,2)];
    end
    
    tempBaseline{2} = applyValues;
    
    if sum(~isnan(applyValues(:,1))) < 4
        tempBaseline{1} = 'linear';
    end
    
    %See if we need to apply to other traces
    applyAll = findobj('Tag','viewApplyAllCheck');
    applyProt = findobj('Tag','viewApplyProtocolCheck');
    
    if applyAll.Value
        applyRange = true(size(baselineValues));
    elseif applyProt.Value
        %Get protnumber and matches
        [~,applyRange] = selectEphys(baseFltr{viewNamesDrop.Value,21},21,baseFltr);
    else %only apply to individual trace
        applyRange = viewNamesDrop.Value;
    end
    
    baselineValues(applyRange) = {tempBaseline};
    
    setappdata(viewEPSC,'baselineValues',baselineValues);
    
    % Do this in seperate function
    %saveEphysData(baselineValues,'baseline',baseFltr,applyRange,dataPath);
    
    
    %Check Baseline
    viewBaseCheck = findobj('Tag','viewBaseCheck');
    viewBaseCheck.Value = 1;
    
    
    %Update base scatters and boxes
    updateBaseDots = true;
    updateBoxes = true;
    viewEPSC_Plot;
end

%% Fill in boxes and method drop
if ~isempty(regexp(hObject.Tag,'viewBaseStatus|viewBaseSetDrop')) ||...
        (ephysDB(cID) == 1 && strcmp(hObject.Tag,'viewBaseProtocolDefault')) ||...
        updateBoxes
    
    %See if protocol defaults can be enabled
    viewBaseProtocolDefault = findobj('Tag','viewBaseProtocolDefault');
    if ephysDB(cID) == 1 && baseFltr{cID,21} > 0
        viewBaseProtocolDefault.Enable = 'on';
    else
        viewBaseProtocolDefault.Enable = 'off';
    end
    
    viewBaseSetDrop = findobj('Tag','viewBaseSetDrop');
    %Initialize sets
    viewBaseSetDrop.String = {};
    for i = 1:floor(size(tempBaseline{2},1)/6)
        viewBaseSetDrop.String{i} = ['Set ',num2str(i)];
    end
    
    %Check which set is visible
    if strcmp(hObject.Tag,'viewBaseStatus')
        setOffset = 0;
        viewBaseSetDrop.Value = 1;
    else
        setOffset = 6*(viewBaseSetDrop.Value-1);
    end
    
    
    %Set first six boxes
    for i =1:6
        %Point
        tempPoint = findobj('Tag',['viewBasePoint',num2str(i)]);
        if ~isnan(tempBaseline{2}(i+setOffset,1))
            tempPoint.String = num2str(tempBaseline{2}(i+setOffset,1));
        else
            tempPoint.String = '';
        end
        %Range
        tempRange = findobj('Tag',['viewBaseRange',num2str(i)]);
        if ~isnan(tempBaseline{2}(i+setOffset,2))
            tempRange.String = num2str(tempBaseline{2}(i+setOffset,2));
        else
            tempRange.String = '';
        end
    end
    %Set method drop
    viewBaseInterpDrop = findobj('Tag','viewBaseInterpDrop');
    if strcmp(tempBaseline{1},'linear')
        viewBaseInterpDrop.Value = 1;
    else
        viewBaseInterpDrop.Value = 2;
    end
end

%%
if updateBaseDots || strcmp(hObject.Tag,'viewBaseStatus')
    %Get axis and trace and remove previous scatters
    viewPlot = findobj('Tag', 'viewPlot');
    dataTrace = findobj('Tag','viewDataTrace');
    prevScatter = findobj('Tag','viewBaseScatter');
    if ~isempty(prevScatter); delete(prevScatter); end;
    
    
    %Get points
    baseX1 = tempBaseline{2}(~isnan(tempBaseline{2}(:,1)),1);
    baseX2 = baseX1+ tempBaseline{2}(~isnan(tempBaseline{2}(:,1)),2);
    
    %Find points in trace
    baseIdx1 = ones(size(baseX1));
    baseIdx2 = baseIdx1;
    for i = 1:numel(baseIdx1)
        idx = find(dataTrace.XData > baseX1(i), 1, 'first');
        if isempty(idx); idx = numel(dataTrace.XData); end;
        baseIdx1(i) = idx;
        idx = find(dataTrace.XData > baseX2(i), 1, 'first');
        if isempty(idx); idx = numel(dataTrace.XData); end;
        baseIdx2(i) = idx;
    end
    
    %Get Real points
    baseX1 = dataTrace.XData(baseIdx1);
    baseX2 = dataTrace.XData(baseIdx2);
    baseY1 = dataTrace.YData(baseIdx1);
    baseY2 = dataTrace.YData(baseIdx2);
    
    hold(viewPlot, 'on')
    scatter(viewPlot,baseX1,baseY1,64,'r','x','Tag','viewBaseScatter');
    scatter(viewPlot,baseX2,baseY2,64,'y','x','Tag','viewBaseScatter');
    hold(viewPlot, 'off')
    
    viewPlot.Tag = 'viewPlot';
    
end



viewBaseCheck.UserData = tempBaseline;
end

function viewArt_Update(hObject,event)
%Manage and draw removing of artifacts
%Get basic stuff
viewEPSC = findobj('Tag', 'viewEPSC');
viewNamesDrop = findobj('Tag','viewNamesDrop');
artFltr = getappdata(viewEPSC,'ephysFltr');

viewArtifactsGUI = findobj('Tag','viewArtifactsGUI');
viewArtifactsCheck = findobj('Tag','viewArtifactsCheck');
viewArtifactStatus = findobj('Tag','viewArtifactStatus');
viewArtifactStatus.String = '';
viewArtifactApply = findobj('Tag','viewArtifactApply');
viewArtifactApply.Enable = 'off'; %We will turn it on if settings are ok
artifactSettings = getappdata(viewEPSC,'artifactSettings');

if strcmp(hObject.Tag,'viewArtifactCancel') || strcmp(hObject.Tag,'viewArtifactsGUI')
    %Remove Artifact trace
    delete(findobj('Tag','viewArtifactTrace'));
    %Reset values
    if ~isempty(artifactSettings)
        viewArtifactsCheck.UserData = artifactSettings{viewNamesDrop.Value};
    end
    %Close figure
    delete(viewArtifactsGUI);
    return
end

if isempty(artFltr)
    %No Data loaded just do nothing
    return
end

dataTrace = findobj('Tag','viewDataTrace');
viewArtifactsSetDrop = findobj('Tag','viewArtifactsSetDrop');


dataPath = getappdata(viewEPSC,'dataPath');
ephysDB = getappdata(viewEPSC,'ephysDB');

if ephysDB(viewNamesDrop.Value) > 1
    dataPath = dataPath{2};
else
    dataPath = dataPath{1};
end


artifactSetting = artifactSettings{viewNamesDrop.Value};

artifactTemp = viewArtifactsCheck.UserData;

%fill in settings if temp is empty
if isempty(artifactTemp) && ~isempty(artifactSetting)
    artifactTemp = artifactSetting;
    viewArtifactsCheck.UserData = artifactTemp;
end


%Update booleans
fillBoxes = false;
enableBoxes = false;
removeArtifacts = false;

if strcmp(hObject.Tag,'viewArtifactStatus')
    viewArtifactStatus.String = ['Tip: Only linear interpolations between'...
        ' artifacts are supported for now... (maybe forever)'];
    %Check if we can set protocol defaults
    viewArtifactsProtocolDefault = findobj('Tag','viewArtifactsProtocolDefault');
    if ephysDB(viewNamesDrop.Value) == 1 &&...
            artFltr{viewNamesDrop.Value,21} > 0
        viewArtifactsProtocolDefault.Enable = 'on';
    else
        viewArtifactsProtocolDefault.Enable = 'off';
    end
    
    %First time plot is opened check if we already have settings
    viewArtifactsSetDrop.Value = 1;
    if ~isempty(artifactTemp)
        %We have parameters fill in some stuff
        if strcmp(viewArtifactsSetDrop.Enable,'off')
            enableBoxes = true;
        end
        fillBoxes = true;
        removeArtifacts = true;
        
        %Prepare drop
        viewArtifactsSetDrop.String = {};
        for i = 1:numel(artifactTemp)
            viewArtifactsSetDrop.String{i} = ['Block ', num2str(i)];
        end
    else %Turn off interface
        
        viewArtifactsSetDrop.String = {'Block 0'};
        viewArtifactsSetDrop.Enable = 'off';
        
        viewArtifactsSetRemove = findobj('Tag','viewArtifactsSetRemove');
        viewArtifactsSetRemove.Enable = 'off';
        
        viewArtifactPulseNText = findobj('Tag','viewArtifactPulseNText');
        viewArtifactPulseNText.Enable = 'off';
        viewArtifactFrequencyText = findobj('Tag','viewArtifactFrequencyText');
        viewArtifactFrequencyText.Enable = 'off';
        viewArtifactFirstWidthText = findobj('Tag','viewArtifactFirstWidthText');
        viewArtifactFirstWidthText.Enable = 'off';
        viewArtifactLastWidthText = findobj('Tag','viewArtifactLastWidthText');
        viewArtifactLastWidthText.Enable = 'off';
        viewArtifactAutoDropText = findobj('Tag','viewArtifactAutoDropText');
        viewArtifactAutoDropText.Enable = 'off';
        viewArtifactStartText = findobj('Tag','viewArtifactStartText');
        viewArtifactStartText.Enable = 'off';
        
        viewArtifactSetting1 = findobj('Tag','viewArtifactSetting1');
        viewArtifactSetting1.Enable = 'off';
        viewArtifactSetting1.String = '';
        viewArtifactSetting2 = findobj('Tag','viewArtifactSetting2');
        viewArtifactSetting2.Enable = 'off';
        viewArtifactSetting2.String = '';
        viewArtifactSetting3 = findobj('Tag','viewArtifactSetting3');
        viewArtifactSetting3.Enable = 'off';
        viewArtifactSetting3.String = '';
        viewArtifactSetting4 = findobj('Tag','viewArtifactSetting4');
        viewArtifactSetting4.Enable = 'off';
        viewArtifactSetting4.String = '';
        viewArtifactSetting5 = findobj('Tag','viewArtifactSetting5');
        viewArtifactSetting5.Enable = 'off';
        viewArtifactSetting5.String = '';
        viewArtifactSetting5 = findobj('Tag','viewArtifactSetting6');
        viewArtifactSetting5.Enable = 'off';
        viewArtifactSetting5.Value = true;
        
        viewArtifactInterpText = findobj('Tag','viewArtifactInterpText');
        viewArtifactInterpText.Enable = 'off';
        
        viewArtifactInterpDrop = findobj('Tag','viewArtifactInterpDrop');
        viewArtifactInterpDrop.Enable = 'off';
        
        return;
    end
elseif strcmp(hObject.Tag,'viewArtifactsProtocolDefault')
    %Get Protocol defaults
    if ephysDB(viewNamesDrop.Value) == 1
        %Get protMeta
        [~,protMeta] = protRetrieve(artFltr{viewNamesDrop.Value,21},...
            artFltr,dataPath);
        
        %Find evokeds
        APs = strcmp('APs',protMeta{1,2}(:,1));
        
        %Reset block drop
        viewArtifactsSetDrop.String = {};
        
        nBlocks = sum(APs);
        APs = find(APs);
        for i =1:nBlocks
            %Get right numbers
            if APs(i) == 1
                artifactTemp{i}(1) = dataTrace.XData(1);
            else
                artifactTemp{i}(1) = sum([protMeta{1,2}{1:APs(i)-1,2}]);
            end
            artifactTemp{i}(2) = round(protMeta{1,2}{APs(i),2}*protMeta{1,2}{APs(i),3});
            artifactTemp{i}(3) = protMeta{1,2}{APs(i),3};
            artifactTemp{i}(4) = 0.005;
            if artifactTemp{i}(3) >= 10
                artifactTemp{i}(5) = 0.005+0.00005*artifactTemp{i}(2);
                if artifactTemp{i}(5) > 0.013
                    artifactTemp{i}(5) = 0.013;
                end
            else
                artifactTemp{i}(5) = 0.005;
            end
            artifactTemp{i}(6) = 1;
            
            viewArtifactsSetDrop.String{i} = ['Block ',num2str(i)];
        end
        
        %Update everything
        fillBoxes = true;
        removeArtifacts = true;
        if strcmp(viewArtifactsSetDrop.Enable,'off')
            enableBoxes = true;
        end
    else
        viewArtifactStatus.String = ['Protocol default only available for ephysDB '...
            'data'];
        return; %We're done
    end
elseif strcmp(hObject.Tag,'viewArtifactsSetAdd')
    %See which block is happening
    if strcmp(viewArtifactsSetDrop.Enable,'on')
        %We already have blocks, add more
        viewArtifactsSetDrop.String{end+1} = ['Block ',...
            num2str(viewArtifactsSetDrop.Value+1)];
        viewArtifactsSetDrop.Value = viewArtifactsSetDrop.Value+1;
        fillBoxes = true;
    else %First block
        viewArtifactsSetDrop.String = {'Block 1'};
        enableBoxes = true;
    end
    %Put in NaN values
    artifactTemp{viewArtifactsSetDrop.Value} = NaN(1,6);
    artifactTemp{viewArtifactsSetDrop.Value}(6) = 1;
    
elseif strcmp(hObject.Tag,'viewArtifactsSetRemove')
    %See how many blocks there are
    if numel(viewArtifactsSetDrop.String) == 1
        %Last box clear and disable
        viewArtifactsSetDrop.Value = 1;
        viewArtifactsSetDrop.String = {'Block 0'};
        
        artifactTemp = {NaN(1,6)};
        artifactTemp{1}(6) = 1;
        enableBoxes = true;
        fillBoxes = true;
        
    else %Remove current block from data and last one from drop
        remains = true(size(artifactTemp));
        remains(viewArtifactsSetDrop.Value) = false;
        artifactTemp = artifactTemp(remains);
        viewArtifactsSetDrop.String = viewArtifactsSetDrop.String(1:end-1);
        %Make sure we don't overshoot drop down
        if viewArtifactsSetDrop.Value > numel(viewArtifactsSetDrop.String)
            viewArtifactsSetDrop.Value = numel(viewArtifactsSetDrop.String);
        end
        fillBoxes = true;
        removeArtifacts = true;
    end
elseif strcmp(hObject.Tag,'viewArtifactsSetDrop')
    fillBoxes = true;
    removeArtifacts = true;
elseif contains(hObject.Tag,'viewArtifactSetting')
    %edit box, make sure input is valid
    if str2double(hObject.Tag(end)) < 6 %Its not the checkbox
        if isempty(hObject.String)
            artifactTemp{viewArtifactsSetDrop.Value}(str2double(hObject.Tag(end)))...
                = NaN;
        else
            %Remove illegal characters
            illChar = regexp(hObject.String,'[^0-9\.]');
            illDots = regexp(hObject.String,'\.');
            if ~isempty(illDots)
                illDots = illDots(2:end);
            end
            if ~isempty(illChar) || ~isempty(illDots)
                %Update status
                viewArtifactStatus.String = 'Warning! Only positive numeric input is used';
                viewArtifactStatus.ForegroundColor = [1 0 0];
                hObject.String([illChar,illDots]) = '';
            end
            %Fill it in
            artifactTemp{viewArtifactsSetDrop.Value}(str2double(hObject.Tag(end)))...
                = str2double(hObject.String);
        end
    else %Its the checkbox
        if hObject.Value
            artifactTemp{viewArtifactsSetDrop.Value}(6) = 1;
        else
            artifactTemp{viewArtifactsSetDrop.Value}(6) = 0;
        end
    end
    
    %Draw (incomplete options will be ignored later)
    removeArtifacts = true;
elseif strcmp(hObject.Tag,'viewArtifactApply')
    %Check validity
    %Loop over blocks
    for i = 1:numel(viewArtifactsSetDrop.String)
        if sum(isnan(artifactTemp{i})) == 0
            %Check if block is valid
            block = artifactTemp{i};
            blockLength = block(1)+(1/block(3)*block(2));
            
            if blockLength > max(dataTrace.XData)
                viewArtifactStatus.String = 'Warning! Specified block longer than trace. Settings not Applied';
                viewArtifactStatus.ForegroundColor = [1 0 0];
                return;
            elseif 1/block(3) < max(block(4:5))
                viewArtifactStatus.String = ['Warning! Artifact may not exceed pulse length. ',...
                    'Typical widths range from 0.005s to 0.01s. Settings not Applied'];
                viewArtifactStatus.ForegroundColor = [1 0 0];
                return;
            end
        else
            viewArtifactStatus.String = 'Warning! Not all blocks are complete. Settings not Applied';
            viewArtifactStatus.ForegroundColor = [1 0 0];
            return;
        end
    end
    
    %See application range
    applyAll = findobj('Tag','viewApplyAllCheck');
    applyProt = findobj('Tag','viewApplyProtocolCheck');
    
    if applyAll.Value
        applyRange = true(size(artifactSettings));
    elseif applyProt.Value
        %Get protnumber and matches
        [~,applyRange] = selectEphys(artFltr{viewNamesDrop.Value,21},21,artFltr);
    else %only apply to individual trace
        applyRange = viewNamesDrop.Value;
    end
    
    %Applying save variables and set checkbox
    artifactSettings(applyRange) = {artifactTemp};
    setappdata(viewEPSC,'artifactSettings',artifactSettings);
    
    viewArtifactsCheck = findobj('Tag','viewArtifactsCheck');
    viewArtifactsCheck.Value = 1;
    
    %Update plot
    viewEPSC_Plot
    
end

if enableBoxes %Turn on/off all the boxes
    toggleList = {'off','on'};
    if strcmp(hObject.Tag, 'viewArtifactCancel') ||...
            strcmp(hObject.Tag, 'viewArtifactsSetRemove')
        toggleList = fliplr(toggleList);
        enableRange = [3:15,17];
    else
        enableRange = 4:17;
    end
    enableObjects= findobj(viewArtifactsGUI,'Enable',toggleList{1});
    
    set(enableObjects(enableRange),'Enable',toggleList{2});
end

if fillBoxes %Set boxes to valid information
    %Get edits
    editBoxes = findobj(viewArtifactsGUI,'Style','edit');
    editBoxes = flipud(editBoxes);
    widthCheck = findobj('Tag','viewArtifactSetting6');
    
    %How many blocks
    if numel(artifactTemp) == 0
        %No blocks back to nothing
        set(editBoxes,'String','');
        widthCheck.Value = 1;
    else %fill in all the things
        for i =1:5
            if isnan(artifactTemp{viewArtifactsSetDrop.Value}(i))
                editBoxes(i).String = '';
            else
                editBoxes(i).String = num2str(...
                    artifactTemp{viewArtifactsSetDrop.Value}(i));
            end
        end
        %Check and fill auto width toggle
        if isnan(artifactTemp{viewArtifactsSetDrop.Value}(6))
            widthCheck.Value = 1;
        else
            widthCheck.Value = logical(...
                artifactTemp{viewArtifactsSetDrop.Value}(6));
        end
    end
    
    
    
    %We did a reset so also remove trace if present
    viewArtifactTrace = findobj('Tag','viewArtifactTrace');
    if ~isempty(viewArtifactTrace); delete(viewArtifactTrace); end
end

if removeArtifacts  %Make block artifacts red
    %See if old version needs to be removed
    viewArtifactTrace = findobj('Tag','viewArtifactTrace');
    if ~isempty(viewArtifactTrace); delete(viewArtifactTrace); end
    
    %See if we have a full set
    if sum(isnan(artifactTemp{viewArtifactsSetDrop.Value})) == 0
        %Check if block is valid
        block = artifactTemp{viewArtifactsSetDrop.Value};
        blockLength = block(1)+(1/block(3)*block(2));
        
        dataTrace = findobj('Tag','viewDataTrace');
        filename = artFltr{viewNamesDrop.Value,1};
        fileData = retrieveEphys(filename,'data',dataPath); fileData = fileData{1}(:,1);
        
        %See if settings are valid
        if blockLength > max(dataTrace.XData)
            viewArtifactStatus.String = 'Warning! Specified block longer than trace';
            viewArtifactStatus.ForegroundColor = [1 0 0];
        elseif 1/block(3) < max(block(4:5))
            viewArtifactStatus.String = ['Warning! Artifact may not exceed pulse length. ',...
                'Typical widths range from 0.005s to 0.01s'];
            viewArtifactStatus.ForegroundColor = [1 0 0];
        else %Block is valid set up for plot
            viewArtifactStatus.String = 'Valid block specified. Make sure to check proper cuts!';
            viewArtifactStatus.ForegroundColor = [0 0 0];
            
            %Get Start stops
            artIdx = zeros(block(2),2);
            [artIdx(:,1), artIdx(:,2)] =...
                viewGetArtifacts(fileData, dataTrace.XData(1), block);
            
            %Create unified vector containing artifacts
            artX = nan(size(dataTrace.XData));
            artY = nan(size(dataTrace.XData));
            for i=1:block(2)
                artX(artIdx(i,1):artIdx(i,2)) = dataTrace.XData(artIdx(i,1):artIdx(i,2));
                artY(artIdx(i,1):artIdx(i,2)) = fileData(artIdx(i,1):artIdx(i,2));
            end
            
            %Plot data in grey
            viewPlot = findobj('Tag','viewPlot');
            hold(viewPlot,'on')
            
            plot(viewPlot,artX,artY,...
                'Color',[0.65 0.65 0.65],'Tag','viewArtifactTrace');
            hold(viewPlot,'off')
            
            %Allow Apply
            viewArtifactApply.Enable = 'on';
        end
    end
end

%Set temp
viewArtifactsCheck.UserData = artifactTemp;
end

function viewAmp_Update(hObject,event)
%Manage and zoom to amplitudes
%Get basic stuff
viewEPSC = findobj('Tag', 'viewEPSC');
viewArtifactsCheck = findobj('Tag','viewBaseCheck');
viewBaseCheck = findobj('Tag','viewArtifactsCheck');
viewAmplitudeGUI = findobj('Tag','viewAmplitudeGUI');
viewAmplitudeStatus = findobj('Tag','viewAmplitudeStatus');
viewAmplitudeCheck = findobj('Tag','viewAmplitudeCheck');
viewNamesDrop = findobj('Tag','viewNamesDrop');
viewPlot = findobj('Tag','viewPlot');

amplitudeSettings = getappdata(viewEPSC, 'amplitudeSettings');

dataTrace = findobj('Tag','viewDataTrace');
ampObjects = findobj(viewAmplitudeGUI);
ampTable = findobj('Tag','viewAmplitudeOverview');
%Are we closing
if strcmp(hObject.Tag, 'viewAmplitudeCancel')...
        || strcmp(hObject.Tag, 'viewAmplitudeGUI')
    
    if ~isempty(amplitudeSettings)
        viewAmplitudeCheck.UserData = amplitudeSettings{viewNamesDrop.Value};
    end
    %Remove old scatters
    prevPeaks = findobj('Tag', 'viewPeakScatter');
    if ~isempty(prevPeaks); delete(prevPeaks); end;
    prevCorrs = findobj('Tag', 'viewCorrPeakScatter');
    if ~isempty(prevCorrs); delete(prevCorrs); end;
    prevSel = findobj('Tag', 'viewSelPeakScatter');
    if ~isempty(prevSel); delete(prevSel); end;
    
    delete(viewAmplitudeGUI);
    if ~isempty(dataTrace)
        viewPlot.XLim = [0,dataTrace.XData(end)];
    end
    return
end

%See if we can proceed
if (~viewArtifactsCheck.Value || ~viewBaseCheck.Value)...
        && (~strcmp(hObject.Tag,'viewAmplitudeGUI') && ~strcmp(hObject.Tag,'viewAmplitudeCancel'))
    
    %Artifacts not removed
    set(ampObjects(2:end),'Enable','off');
    ampTable.Data = [];
    viewAmplitudeStatus.Enable = 'on';
    viewAmplitudeStatus.String = 'Amplitude can only be calculated if artifacts are removed and baseline is set';
    return
else
    set(ampObjects(2:end),'Enable','on');
    
    
    viewAmplitudeOverview = findobj('Tag','viewAmplitudeOverview');
    viewAmplitudeMethodDrop = findobj('Tag','viewAmplitudeMethodDrop');
    viewAmplitudeBlockDrop = findobj('Tag','viewAmplitudeBlockDrop');
    
    
    dataPath = getappdata(viewEPSC,'dataPath');
    ephysDB = getappdata(viewEPSC,'ephysDB');
    ampFltr = getappdata(viewEPSC,'ephysFltr');
    baselineValues = getappdata(viewEPSC, 'baselineValues');
    baselineValue = baselineValues{viewNamesDrop.Value};
    artifactSettings = getappdata(viewEPSC, 'artifactSettings');
    artifactSetting = artifactSettings{viewNamesDrop.Value};
    
    amplitudeSetting = amplitudeSettings{viewNamesDrop.Value};
    
    filename = ampFltr{viewNamesDrop.Value,1};
    fileData = retrieveEphys(filename,'data',...
        dataPath{ephysDB(viewNamesDrop.Value)});
    fileData = fileData{1}(:,1);
    
    amplitudeTemp = viewAmplitudeCheck.UserData;
    
    if isempty(amplitudeTemp)
        amplitudeTemp = amplitudeSetting;
    end
    
    updateTable = false;
    markPulse = false;
    
    if strcmp(hObject.Tag, 'viewAmplitudeStatus')
        %first Initialize block and set settings
        nBlocks = numel(artifactSetting);
        
        viewAmplitudeStatus.String = '';
        
        if isempty(amplitudeTemp)
            amplitudeTemp = ones(nBlocks,1);
        end
        
        %Create drop and columns
        viewAmplitudeOverview.ColumnName = {};
        viewAmplitudeBlockDrop.String = {};
        for i = 1:nBlocks
            viewAmplitudeOverview.ColumnName(i) = {['Block ', num2str(i)]};
            viewAmplitudeBlockDrop.String(i) = {['Block ', num2str(i)]};
        end
        
        updateTable = true;
        
    elseif strcmp(hObject.Tag, 'viewAmplitudeBlockDrop')
        
        viewAmplitudeMethodDrop.Value = amplitudeTemp(hObject.Value);
        
    elseif strcmp(hObject.Tag, 'viewAmplitudeMethodDrop')
        
        amplitudeTemp(viewAmplitudeBlockDrop.Value) = viewAmplitudeMethodDrop.Value;
        updateTable = true;
        
    elseif strcmp(hObject.Tag, 'viewAmplitudeApply')
        %See application range
        applyAll = findobj('Tag','viewApplyAllCheck');
        applyProt = findobj('Tag','viewApplyProtocolCheck');
        
        if applyAll.Value
            applyRange = true(size(amplitudeSettings));
        elseif applyProt.Value
            %Get protnumber and matches
            [~,applyRange] = selectEphys(ampFltr{viewNamesDrop.Value,21},21,ampFltr);
        else %only apply to individual trace
            applyRange = viewNamesDrop.Value;
        end
        
        %Applying save variables and set checkbox
        amplitudeSettings(applyRange) = {amplitudeTemp};
        setappdata(viewEPSC,'amplitudeSettings',amplitudeSettings);
        
        viewAmplitudeCheck = findobj('Tag','viewAmplitudeCheck');
        viewAmplitudeCheck.Value = 1;
        
    elseif strcmp(hObject.Tag, 'viewAmplitudeOverview') %Mark Pulse
        markPulse = true;
        updateTable = true;
    elseif strcmp(hObject.Tag, 'viewAmplitudeZoomCheck') %Mark Pulse
        if ~hObject.Value
            viewPlot.XLim = [0,dataTrace.XData(end)];
            return
        end
    end
    
    if updateTable
        %Remove old scatters
        prevPeaks = findobj('Tag', 'viewPeakScatter');
        if ~isempty(prevPeaks); delete(prevPeaks); end;
        prevCorrs = findobj('Tag', 'viewCorrPeakScatter');
        if ~isempty(prevCorrs); delete(prevCorrs); end;
        prevSel = findobj('Tag', 'viewSelPeakScatter');
        if ~isempty(prevSel); delete(prevSel); end;
        
        peaks = viewGetAmplitude(fileData,dataTrace.XData(1),artifactSetting);
        
        %Create peak point scatter
        hold(viewPlot,'on')
        peakScat = scatter(viewPlot,dataTrace.XData(vertcat(peaks{:,2})),...
            vertcat(peaks{:,1}),'g','^','Tag','viewPeakScatter');
        hold(viewPlot,'off')
        
        %Get corrections
        for c = 1:numel(artifactSetting)
            settings = {artifactSetting{c}, baselineValue,[]};
            [corrPeaks{c}, corrValues{c}] = viewCorrectAmplitude(peaks{c,2},amplitudeTemp(c),...
                settings{amplitudeTemp(c)},fileData,dataTrace.XData(1));
        end
        
        %Create correction point scatter
        hold(viewPlot,'on')
        corrScat = scatter(viewPlot,dataTrace.XData(vertcat(peaks{:,2})),...
            vertcat(corrValues{:})','k','v','Tag','viewCorrPeakScatter');
        hold(viewPlot,'off')
        
        %Update Table
        tableData = cell(max(cellfun(@numel,corrPeaks)),numel(corrPeaks));
        for t = 1:numel(corrPeaks)
            tableData(1:numel(corrPeaks{t}),t) = num2cell(corrPeaks{t});
        end
        viewAmplitudeOverview.Data = tableData;
        
        if markPulse
            %Get pulse
            selectedPulse = event.Indices;
            
            %Make sure selected pulse is in range
            if ~isempty(selectedPulse) && selectedPulse(2) <= numel(corrPeaks) &&...
                    selectedPulse(1) <= numel(corrPeaks{selectedPulse(2)})
                
                selectedPulse = selectedPulse(1,:); %proceed only with first selected
                
                hold(viewPlot,'on')
                selScatUp = scatter(viewPlot,...
                    dataTrace.XData(peaks{selectedPulse(2),2}(selectedPulse(1))),...
                    corrValues{selectedPulse(2)}(selectedPulse(1)),...
                    'r','v','Tag','viewSelPeakScatter');
                selScatDown = scatter(viewPlot,...
                    dataTrace.XData(peaks{selectedPulse(2),2}(selectedPulse(1))),...
                    peaks{selectedPulse(2),1}(selectedPulse(1)),...
                    'r','^','Tag','viewSelPeakScatter');
                hold(viewPlot,'off')
                
                viewAmplitudeZoomCheck = findobj('Tag','viewAmplitudeZoomCheck');
                if viewAmplitudeZoomCheck.Value
                    [strts, stops] = viewGetArtifacts(fileData,dataTrace.XData(1),...
                        artifactSetting{selectedPulse(2)});
                    strts = strts*dataTrace.XData(1);
                    stops = stops*dataTrace.XData(1);
                    
                    if numel(stops) > 1
                        xOffset = diff(strts(1:2));
                        if xOffset < 0.15
                            xOffset = xOffset + (0.15-xOffset)*0.5;
                        elseif xOffset > 0.3
                            xOffset = 0.3;
                        end
                    else
                        xOffset = 0.15;
                    end
                    
                    viewPlot.XLim = [strts(selectedPulse(1))-xOffset*0.1,...
                        strts(selectedPulse(1))+xOffset];
                    ylim(viewPlot,'auto');
                end
            end
        end
    end
    
    viewAmplitudeCheck.UserData = amplitudeTemp;
end
end

function viewCharge_Update(hObject,event)
%Manage and zoom to charge
%Get basic stuff
viewEPSC = findobj('Tag', 'viewEPSC');
viewArtifactsCheck = findobj('Tag','viewBaseCheck');
viewBaseCheck = findobj('Tag','viewArtifactsCheck');
viewChargeGUI = findobj('Tag','viewChargeGUI');
viewChargeStatus = findobj('Tag','viewChargeStatus');
viewNamesDrop = findobj('Tag','viewNamesDrop');
viewChargeCheck = findobj('Tag','viewChargeCheck');
viewPlot = findobj('Tag','viewPlot');

chargeSettings = getappdata(viewEPSC, 'chargeSettings');
chargeObjects = findobj(viewChargeGUI,'Type','UIControl');
chargeTable = findobj('Tag','viewChargeOverview');
dataTrace = findobj('Tag','viewDataTrace');

%Are we closing
if strcmp(hObject.Tag, 'viewChargeCancel')...
        || strcmp(hObject.Tag, 'viewChargeGUI')
    
    if ~isempty(chargeSettings)
        viewChargeCheck.UserData = chargeSettings{viewNamesDrop.Value};
    end
    %Remove old scatters
    viewSyncPlot = findobj('Tag','viewSyncPlot');
    if ~isempty(viewSyncPlot); delete(viewSyncPlot); end;
    
    delete(viewChargeGUI);
    if ~isempty(dataTrace)
        viewPlot.XLim = [0,dataTrace.XData(end)];
    end
    return;
end
%Proceed
if (~viewArtifactsCheck.Value || ~viewBaseCheck.Value)...
        && (~strcmp(hObject.Tag,'viewChargeGUI') && ~strcmp(hObject.Tag,'viewChargeCancel'))
    %Artifacts not removed
    set(chargeTable,'Data',[]);
    set(chargeObjects,'Enable','off'); set(chargeTable,'Enable','off');
    viewChargeStatus.Enable = 'on';
    viewChargeStatus.String = 'Charge can only be calculated if artifacts are removed and baseline is set';
    return
else
    set(chargeObjects,'Enable','on'); set(chargeTable,'Enable','on');
    
    %Get more stuff
    
    viewChargeOverview = findobj('Tag','viewChargeOverview');
    viewChargeBlockDrop = findobj('Tag','viewChargeBlockDrop');
    
    
    
    ephysDB = getappdata(viewEPSC,'ephysDB');
    dataPath = getappdata(viewEPSC,'dataPath');
    dataPath = dataPath{ephysDB(viewNamesDrop.Value)};
    chargeFltr = getappdata(viewEPSC,'ephysFltr');
    baselineValues = getappdata(viewEPSC, 'baselineValues');
    baselineValue = baselineValues{viewNamesDrop.Value};
    artifactSettings = getappdata(viewEPSC, 'artifactSettings');
    artifactSetting = artifactSettings{viewNamesDrop.Value};
    
    chargeSetting = chargeSettings{viewNamesDrop.Value};
    
    filename = chargeFltr{viewNamesDrop.Value,1};
    %     fileData = retrieveEphys(filename,'data',...
    %         dataPath);
    %     fileData = fileData{1}(:,1);
    
    chargeTemp = viewChargeCheck.UserData;
    
    if isempty(chargeTemp)
        chargeTemp = chargeSetting;
    end
    
    updateTable = false;
    setBoxes = false;
    chargePlot = false;
    markPulse = false;
    
    if strcmp(hObject.Tag, 'viewChargeStatus')
        %Initialize everything
        nBlocks = numel(artifactSetting);
        viewChargeBlockDrop.Value = 1;
        
        if isempty(chargeTemp)
            chargeTemp = ones(2,nBlocks);
        end
        
        
        hObject.String = '';
        
        
        %Create drop and columns
        viewChargeOverview.ColumnName = {'Sync','Async','Total'};
        viewChargeBlockDrop.String = {};
        for i = 1:nBlocks
            viewChargeBlockDrop.String(i) = {['Block ', num2str(i)]};
        end
        
        setBoxes = true;
        updateTable = true;
    elseif strcmp(hObject.Tag, 'viewChargeBlockDrop')
        %Set boxes and table
        setBoxes = true;
        updateTable = true;
        
    elseif strcmp(hObject.Tag, 'viewChargePulseWidth')
        %Start with edit off
        viewChargeWidthEdit = findobj('Tag','viewChargeWidthEdit');
        viewChargeWidthEdit.Enable = 'off';
        
        %Did we come from fixed?
        if strcmp(event.OldValue.Tag,'viewChargeWidthFixed')
            %Get pulse width
            allSettings = vertcat(artifactSetting{:});
            minPulse = min(1./allSettings(:,3));
            %find and change real fixed values to customs
            chargeTemp(2,chargeTemp(2,:) == 2) = 3 + minPulse;
        end
        %Which scenario is true
        switch event.NewValue.Tag
            case 'viewChargeWidthMax'
                chargeTemp(2,viewChargeBlockDrop.Value) = 1;
            case 'viewChargeWidthFixed'
                chargeTemp(2,viewChargeBlockDrop.Value) = 2;
            case 'viewChargeWidthCustom'
                viewChargeWidthEdit.Enable = 'on';
                if isnan(str2double(viewChargeWidthEdit.String))
                    chargeTemp(2,viewChargeBlockDrop.Value) = 3;
                else
                    chargeTemp(2,viewChargeBlockDrop.Value) = 3+...
                        str2double(viewChargeWidthEdit.String);
                end
        end
        
        updateTable = true;
    elseif strcmp(hObject.Tag, 'viewChargeWidthEdit')
        viewChargeWidthEdit = hObject;
        if isempty(viewChargeWidthEdit.String)
            chargeTemp(2,viewChargeBlockDrop.Value) = 3;
        else
            %Remove illegal characters
            illChar = regexp(viewChargeWidthEdit.String,'[^0-9\.]');
            illDots = regexp(viewChargeWidthEdit.String,'\.');
            if ~isempty(illDots)
                illDots = illDots(2:end);
            end
            if ~isempty(illChar) || ~isempty(illDots)
                %Update status
                viewChargeStatus.String = 'Warning! Only positive numeric input is used';
                viewChargeStatus.ForegroundColor = [1 0 0];
                viewChargeWidthEdit.String([illChar,illDots]) = '';
            end
            %Fill it in
            chargeTemp(2,viewChargeBlockDrop.Value) = 3+...
                str2double(viewChargeWidthEdit.String);
        end
        
        updateTable = true;
    elseif strcmp(hObject.Tag, 'viewChargeSyncWidth')
        %Start with edit off
        viewChargeSyncEdit = findobj('Tag','viewChargeSyncEdit');
        viewChargeSyncEdit.Enable = 'off';
        
        %which event is true
        switch event.NewValue.Tag
            case 'viewChargeSyncMax'
                chargeTemp(1,viewChargeBlockDrop.Value) = 1;
            case 'viewChargeSyncCustom'
                viewChargeSyncEdit.Enable = 'on';
                if isnan(str2double(viewChargeSyncEdit.String))
                    chargeTemp(1,viewChargeBlockDrop.Value) = 2;
                else
                    chargeTemp(1,viewChargeBlockDrop.Value) = 2+...
                        str2double(viewChargeSyncEdit.String);
                end
        end
        
    elseif strcmp(hObject.Tag, 'viewChargeSyncEdit')
        viewChargeSyncEdit = hObject;
        syncWidth = sscanf(viewChargeSyncEdit.String,'%g');
        
        if isempty(syncWidth) %No value
            chargeTemp(1,viewChargeBlockDrop.Value) = 2;
            viewChargeSyncEdit.String = '';
        else
            %Fill it in
            chargeTemp(1,viewChargeBlockDrop.Value) = 2+abs(syncWidth);
            viewChargeSyncEdit.String = num2str(abs(syncWidth));
        end
        
        updateTable = true;
    elseif strcmp(hObject.Tag, 'viewChargeApply')
        %Check fixed
        if any(chargeTemp(2,:) == 2)
            chargeTemp(2,:) = 2;
        end
        
        %See application range
        applyAll = findobj('Tag','viewApplyAllCheck');
        applyProt = findobj('Tag','viewApplyProtocolCheck');
        
        if applyAll.Value
            applyRange = true(size(chargeSettings));
        elseif applyProt.Value
            %Get protnumber and matches
            [~,applyRange] = selectEphys(chargeFltr{viewNamesDrop.Value,21},21,chargeFltr);
        else %only apply to individual trace
            applyRange = viewNamesDrop.Value;
        end
        
        %Applying save variables and set checkbox
        chargeSettings(applyRange) = {chargeTemp};
        setappdata(viewEPSC,'chargeSettings',chargeSettings);
        
        viewChargeCheck.Value = 1;
        
    elseif strcmp(hObject.Tag, 'viewChargeOverview') %Mark Pulse
        updateTable = true;
        markPulse = true;
    elseif strcmp(hObject.Tag, 'viewChargeZoomCheck')
        if ~hObject.Value
            viewPlot.XLim = [0,dataTrace.XData(end)];
        end
    end
    
    if setBoxes
        %We need to set boxes
        blck = viewChargeBlockDrop.Value;
        %         viewChargeResponseStarts = findobj('Tag','viewChargeResponseStarts');
        %         startButtons = findobj(viewChargeResponseStarts);
        %         viewChargeResponseStarts.SelectedObject =...
        %             startButtons(4-chargeTemp(1,blck)+1);
        
        
        viewChargePulseWidth = findobj('Tag','viewChargePulseWidth');
        widthButtons = findobj(viewChargePulseWidth);
        if any(chargeTemp(2,:) == 2)
            %Fixed mark as fixed
            viewChargePulseWidth.SelectedObject = widthButtons(4);
            widthButtons(2).String = '';
        else
            if chargeTemp(2,blck) >= 3
                butNum = 3;
                editNum = num2str(chargeTemp(2,blck)-3);
                widthButtons(2).Enable = 'on';
            else
                butNum = chargeTemp(2,blck);
                editNum = '';
                widthButtons(2).Enable = 'off';
            end
            viewChargePulseWidth.SelectedObject =...
                widthButtons(4-butNum+2);
            widthButtons(2).String = editNum;
        end
        
        %Sync width
        viewChargeSyncWidth = findobj('Tag','viewChargeSyncWidth');
        syncButtons = findobj(viewChargeSyncWidth);
        if chargeTemp(1,blck) == 1
            butNum = 4;
            editNum = '';
            syncButtons(2).Enable = 'off';
        else
            butNum = 3;
            editNum = num2str(chargeTemp(1,blck)-2);
            syncButtons(2).Enable = 'on';
        end
        viewChargeSyncWidth.SelectedObject = syncButtons(butNum);
        syncButtons(2).String = editNum;
        
    end
    
    if updateTable
        %         %Get pulse widths
        %         pWidths = zeros(size(artifactSetting));
        %         i=1;
        %         while i <= numel(artifactSetting)
        %             if chargeTemp(2,i) >= 3
        %                 pWidths(i) = chargeTemp(2,i)-3;
        %                 if pWidths(i) > 1/artifactSetting{i}(3)
        %                     pWidths(i) = 1/artifactSetting{i}(3);
        %                     viewChargeStatus.String = 'Warning! Custom width too large. Maximum used for calculation';
        %                     chargeTemp(2,i) =  pWidths(i) + 3;
        %                     viewChargeWidthEdit = findobj('Tag','viewChargeWidthEdit');
        %                     viewChargeWidthEdit.String = num2str(pWidths(i));
        %                 end
        %             elseif chargeTemp(2,i) == 2
        %                 allSettings = vertcat(artifactSetting{:});
        %                 pWidths(:) = min(1./allSettings(:,3));
        %                 i= numel(artifactSetting);
        %             elseif chargeTemp(2,i) == 1
        %                 pWidths(i) = 1/artifactSetting{i}(3);
        %             end
        %             i=i+1;
        %         end
        %
        %         %See if we start Pre or Post
        %         pulseStart = zeros(size(artifactSetting));
        % %         for i = 1:numel(artifactSetting)
        % %             if chargeTemp(1,i) > 1
        % %                 pulseStart(i) = chargeTemp(1,i)-2;
        % %             else %Auto calculate best one
        % %                 pulseStart(i) = viewAutoResponseStarts(artifactSetting{i}, fileData, dataTrace.XData(1));
        % %             end
        % %         end
        % %
        %         %Calculate Charge
        %         blck = viewChargeBlockDrop.Value;
        %         %Get artifacts
        %         [strt, stop] = viewGetArtifacts(fileData,...
        %             dataTrace.XData(1), artifactSetting{blck});
        %         %Get baseline
        %         cellBaseline = viewCalculateBaseline(baselineValue,fileData,...
        %             dataTrace.XData(1));
        %         %Get Charge
        %         [pulseCharge,syncTrace,syncIdx] = viewGetResponseCharge(...
        %             pulseStart(blck),pWidths(blck),...
        %             [strt, stop],cellBaseline, fileData, dataTrace.XData(1));
        
        %Unified Response charge calculation function
        [pulseCharge,syncTrace,syncIdx] = viewGetResponseCharge2(filename,...
            chargeTemp, artifactSetting, baselineValue, dataPath);
        
        %Only this block
        pulseCharge = pulseCharge{1}{viewChargeBlockDrop.Value};
        syncTrace = syncTrace{1}{viewChargeBlockDrop.Value};
        syncIdx = syncIdx{1}{viewChargeBlockDrop.Value};
        
        chargePlot = true;
        
        %Set the table
        viewChargeOverview.Data = pulseCharge;
        
        
    end
end

if chargePlot
    %We have syncTrace and syncIdx create plot
    
    %Delete old if necessary
    viewSyncPlot = findobj('Tag','viewSyncPlot');
    if ~isempty(viewSyncPlot); delete(viewSyncPlot); end;
    
    hold(viewPlot,'on')
    plot(viewPlot,dataTrace.XData,syncTrace,'g--','Tag','viewSyncPlot');
    scatter(viewPlot,syncIdx(:,1).*dataTrace.XData(1),syncIdx(:,2),'ks',...
        'Tag','viewSyncPlot')
    hold(viewPlot,'off')
    
    if markPulse
        %Get pulse
        selectedPulse = event.Indices;
        
        %Make sure selected pulse is in range
        if ~isempty(selectedPulse) && ...
                selectedPulse(1) <= size(hObject.Data,1)
            selectedPulse = selectedPulse(1);
            
            hold(viewPlot,'on')
            selScatFront = scatter(viewPlot,...
                syncIdx(selectedPulse,1).*dataTrace.XData(1),...
                syncIdx(selectedPulse,2),...
                'rs','Tag','viewSyncPlot');
            selScatBack = scatter(viewPlot,...
                syncIdx(selectedPulse+size(syncIdx,1)/3,1).*dataTrace.XData(1),...
                syncIdx(selectedPulse+size(syncIdx,1)/3,2),...
                'rs','Tag','viewSyncPlot');
            hold(viewPlot,'off')
            
            viewChargeZoomCheck = findobj('Tag','viewChargeZoomCheck');
            if viewChargeZoomCheck.Value
                
                if size(syncIdx,1) > 2
                    xOffset = diff(syncIdx(1:2,1).*dataTrace.XData(1));
                    if xOffset > 0.3
                        xOffset = diff([syncIdx(selectedPulse,1),...
                            syncIdx(selectedPulse+size(syncIdx,1)/3,1)]);
                        xOffset = xOffset.*dataTrace.XData(1);
                    end
                    if xOffset < 0.15
                        xOffset = xOffset + (0.15-xOffset)*0.5;
                    end
                else
                    xOffset = 0.15;
                end
                
                viewPlot.XLim = [syncIdx(selectedPulse,1).*dataTrace.XData(1)-xOffset*0.1,...
                    syncIdx(selectedPulse,1).*dataTrace.XData(1)+xOffset];
                ylim(viewPlot,'auto');
            end
        else
            viewPlot.XLim = [0,dataTrace.XData(end)];
        end
    end
    
end


%Force disable response starts
% disableTags = {'Post','Pre','Auto'};
% for i = 1:numel(disableTags)
%     disObject = findobj('Tag',['viewChargeStarts',disableTags{i}]);
%     disObject.Enable = 'off';
% end

%Disable custom Edit if not selected
viewChargeCustom{1} = findobj('Tag','viewChargeWidthCustom');
viewChargeCustom{2} = findobj('Tag','viewChargeSyncCustom');
custEdits = {'viewChargeWidthEdit','viewChargeSyncEdit'};

for cust = 1:numel(viewChargeCustom)
    if ~viewChargeCustom{cust}.Value
        viewChargeEdit = findobj('Tag',custEdits{cust});
        viewChargeEdit.Enable = 'off';
    end
end

viewChargeCheck.UserData = chargeTemp;
end

%Mini update callbacks
function viewMini_Update(hObject,event)
%Get objects
viewEPSC = findobj('Tag', 'viewEPSC');
viewNamesDrop = findobj('Tag','viewNamesDrop');
viewMiniAnalysisCheck = findobj('Tag','viewMiniAnalysisCheck');

%Get dataTrace
viewDataTrace = findobj('Tag','viewDataTrace');

viewMiniGUI = findobj('Tag','viewMiniGUI');
viewMiniSetDrop = findobj('Tag','viewMiniSetDrop');
viewMiniDoneCheck = findobj('Tag','viewMiniDoneCheck');
viewMiniStatus = findobj('Tag','viewMiniStatus');

viewMiniStartEdit = findobj('Tag','viewMiniStartEdit');
viewMiniStopEdit = findobj('Tag','viewMiniStopEdit');

miniSettings  = getappdata(viewEPSC,'miniSettings');
miniCoords  = getappdata(viewEPSC,'miniCoords');
miniTargets  = getappdata(viewEPSC,'miniTargets');
miniFeatures  = getappdata(viewEPSC,'miniFeatures');

miniCoord = miniCoords{viewNamesDrop.Value};
miniTarget = miniTargets{viewNamesDrop.Value};
miniFeature = miniFeatures{viewNamesDrop.Value};
miniSetting   = miniSettings{viewNamesDrop.Value};
miniTemp = viewMiniAnalysisCheck.UserData;

if size(miniTemp,2) == 0
    miniTemp = miniSetting;
end

%Remove temp events when switching cells
if isempty(viewMiniDoneCheck.UserData) || strcmp(hObject.Tag,'viewMiniStatus')
    viewMiniDoneCheck.UserData = {miniCoord,miniTarget,miniFeature};
    tempCoord = miniCoord;
    tempTarget = miniTarget;
    tempFeature = miniFeature;
else
    tempCoord = viewMiniDoneCheck.UserData{1};
    tempTarget = viewMiniDoneCheck.UserData{2};
    tempFeature = viewMiniDoneCheck.UserData{3};
end

%Update booleans
plotMinis = false;
closeWindow = false;

%Perform button operations
switch hObject.Tag
    case 'viewMiniStatus'
        hObject.String = 'Status OK!';
        %Reset everything to defaults
        viewMiniSetDrop.Value = 1;
        viewMiniSetDrop.String = {'Section 0'};
        viewMiniDoneCheck.Value = false;
        viewMiniStartEdit.String = '';
        viewMiniStopEdit.String = '';
        
        plotMinis = true;
    case 'viewMiniSetAdd'
        %Set drop string and Value
        dropN = size(miniTemp,1);
        viewMiniSetDrop.String(dropN+1) = {['Section ',num2str(dropN+1)]};
        viewMiniSetDrop.Value = dropN+1;
        
        %Set initial values
        if dropN == 0
            %No other sections, whole of the trace
            miniTemp(1,1) = viewDataTrace.XData(1);
        else %Start at the end of the other section
            miniTemp(dropN+1,1) = max(miniTemp(:,2));
        end
        miniTemp(dropN+1,2) = viewDataTrace.XData(end);
        miniTemp(dropN+1,3) = false;
    case 'viewMiniSetRemove'
        %Remove section
        dropN = size(miniTemp,1);
        
        %Remove one section
        remSec = true(size(miniTemp,1),1);
        remSec(viewMiniSetDrop.Value) = false;
        miniTemp = miniTemp(remSec,:);
        viewMiniSetDrop.Value = min([viewMiniSetDrop.Value,dropN-1]);
        viewMiniSetDrop.String = viewMiniSetDrop.String(1:end-1);
        
        if dropN<=1
            %Removing last section reset
            viewMiniSetDrop.String = {'Section 0'};
            viewMiniSetDrop.Value = 1;
        end
        
        %Update minis
        plotMinis = true;
    case 'viewMiniStartEdit'
        %Get number
        startNum = sscanf(hObject.String,'%g');
        startNum = round(startNum,numel(num2str(1/viewDataTrace.XData(1)))-1);
        
        %make sure its valid
        startNum = max([startNum,viewDataTrace.XData(1)]);
        startNum = min([startNum,viewDataTrace.XData(end)]);
        
        if ismember(startNum,miniTemp(:,1))
            hObject.String = num2str(miniTemp(viewMiniSetDrop.Value,1));
            viewMiniStatus = 'Duplicate start times are not allowed';
            return;
        end
        
        %Check if we are making section larger
        if startNum < miniTemp(viewMiniSetDrop.Value,1)
            %Definitely not analyzed
            viewMiniDoneCheck.Value = false;
            miniTemp(viewMiniSetDrop.Value,3) = 0;
        else
            plotMinis = true;
        end
        
        %fill it in
        miniTemp(viewMiniSetDrop.Value,1) = startNum;
        hObject.String = num2str(startNum);
    case 'viewMiniStopEdit'
        %Get number and round to si
        stopNum = sscanf(hObject.String,'%g');
        stopNum = round(stopNum,numel(num2str(1/viewDataTrace.XData(1)))-1);
        
        %make sure its valid
        stopNum = max([stopNum,viewDataTrace.XData(1)]);
        stopNum = min([stopNum,viewDataTrace.XData(end)]);
        
        %Check if we are making section larger
        if stopNum > miniTemp(viewMiniSetDrop.Value,2)
            %Definitely not analyzed
            viewMiniDoneCheck.Value = false;
            miniTemp(viewMiniSetDrop.Value,3) = 0;
        else
            plotMinis = true;
        end
        
        %fill it in
        miniTemp(viewMiniSetDrop.Value,2) = stopNum;
        hObject.String = num2str(stopNum);
    case 'viewMiniApply'
        %Sanitize found miniEvents and Sections
        if ~isempty(miniTemp)
            %Select only analyzed and sort
            [~,miniSort] = sort(miniTemp(logical(miniTemp(:,3)),1),1);
            miniTemp = miniTemp(miniSort,:);
            %Unoverlap
            saneCoord = [];
            saneTarget = [];
            saneFeature = [];
            i=1;
            while i <= size(miniTemp,1)
                if i ~= size(miniTemp,1) && miniTemp(i,2)>miniTemp(i+1,1)
                    %edit if Stop is beyond next start
                    if miniTemp(i,2)>miniTemp(i+1,2) %Next section is contained in this one, just remove it
                        miniFltr = true(size(miniTemp,1),1);
                        miniFltr(i+1) = false;
                        %Remove from settings and drop downs
                        miniTemp = miniTemp(miniFltr,:);
                        viewMiniSetDrop.Value = min([viewMiniSetDrop.Value,size(miniTemp,1)]);
                        viewMiniSetDrop.String = viewMiniSetDrop.String(1:end-1);
                    else
                        miniTemp(i,2) = miniTemp(i+1,1)-viewDataTrace.XData(1);
                    end
                end
                miniFltr = tempCoord(:,1)*viewDataTrace.XData(1) > miniTemp(i,1)...
                    & tempCoord(:,1)*viewDataTrace.XData(1) < miniTemp(i,2);
                saneCoord = [saneCoord; tempCoord(miniFltr,:)];
                saneTarget = [saneTarget; tempTarget(miniFltr,:)];
                saneFeature = [saneFeature; tempFeature(miniFltr,:)];
                
                i=i+1;
            end
            %Save changes
            miniCoords{viewNamesDrop.Value} = saneCoord;
            miniTargets{viewNamesDrop.Value} = logical(saneTarget);
            miniFeatures{viewNamesDrop.Value} = saneFeature;
            
            setappdata(viewEPSC,'miniCoords',miniCoords);
            setappdata(viewEPSC,'miniTargets',miniTargets);
            setappdata(viewEPSC,'miniFeatures',miniFeatures);
            
            %Check analysis
            viewMiniAnalysisCheck.Value = true;
        else
            %Save changes
            miniCoords{viewNamesDrop.Value} = [];
            miniTargets{viewNamesDrop.Value} = [];
            miniFeatures{viewNamesDrop.Value} = [];
            
            setappdata(viewEPSC,'miniCoords',miniCoords);
            setappdata(viewEPSC,'miniTargets',miniTargets);
            setappdata(viewEPSC,'miniFeatures',miniFeatures);
            
            %Check analysis
            viewMiniAnalysisCheck.Value = false;
        end
        miniSettings{viewNamesDrop.Value} = miniTemp;
        setappdata(viewEPSC,'miniSettings',miniSettings);
    case 'viewMiniCancel'
        viewMiniAnalysisCheck.UserData = miniSetting;
        closeWindow = true;
    case 'viewMiniGUI'
        closeWindow = true;
end

if closeWindow
    %Remove plot
    viewMiniScatGreen = findobj('Tag','viewMiniScatGreen');
    if ~isempty(viewMiniScatGreen); delete(viewMiniScatGreen); end
    
    viewMiniAnalysisCheck.UserData = miniSettings{viewNamesDrop.Value};
    delete(viewMiniGUI);
    return;
    
end
%See if we need elements to be on
if size(miniTemp,1) < 1
    %We dont have setttings disable the elements
    set(viewMiniGUI.Children,'Enable','off');
    set(viewMiniGUI.Children([1,2,3,13]),'Enable','on');
    fillBoxes = false;
else
    set(viewMiniGUI.Children,'Enable','on');
    fillBoxes = true;
end
% inactivate done check
set(viewMiniGUI.Children(5),'Enable','inactive');
% viewMiniGUI.Children(5).Value = false;

%fillBoxes
if fillBoxes
    
    viewMiniStartEdit.String = num2str(miniTemp(viewMiniSetDrop.Value,1));
    viewMiniStopEdit.String = num2str(miniTemp(viewMiniSetDrop.Value,2));
    viewMiniDoneCheck.Value = miniTemp(viewMiniSetDrop.Value,3);
    
    SecNums = cellfun(@num2str,num2cell(1:size(miniTemp,1)),'UniformOutput',false);
    viewMiniSetDrop.String = strcat('Section',{' '},SecNums);
end

%Plot minis
if plotMinis && ~isempty(tempCoord)
    viewPlot = findobj('Tag','viewPlot');
    fileSI = viewDataTrace.XData(1);
    hold(viewPlot,'on')
    %Remove old
    viewMiniScatGreen = findobj('Tag','viewMiniScatGreen');
    if ~isempty(viewMiniScatGreen); delete(viewMiniScatGreen); end
    %Scatter Confirmed
    scatter(viewPlot,tempCoord(tempTarget(:,1),1)*fileSI,tempCoord(tempTarget(:,1),2),...
        'MarkerEdgeColor','g','MarkerFaceColor','g',...
        'Tag','viewMiniScatGreen');
    hold(viewPlot,'off')
end

%Store temp
viewMiniAnalysisCheck.UserData = miniTemp;
end

%Mini analysis function
function viewANN_Update(hObject,event)
%Get main objects
viewEPSC = findobj('Tag','viewEPSC');
viewNamesDrop = findobj('Tag','viewNamesDrop');
viewPlot = findobj('Tag','viewPlot');

viewMiniGUI = findobj('Tag','viewMiniGUI');
viewMiniAnalysisCheck = findobj('Tag','viewMiniAnalysisCheck');
viewMiniSetDrop = findobj('Tag','viewMiniSetDrop');
viewMiniDoneCheck = findobj('Tag','viewMiniDoneCheck');

viewANNGUI = findobj('Tag','viewANNGUI');
viewANNEventDrop = findobj('Tag','viewANNEventDrop');
viewANNZoom = findobj('Tag','viewANNZoom');
viewANNStatus = findobj('Tag','viewANNStatus');
viewANNPreviewCheck = findobj('Tag','viewANNPreviewCheck');

%Common variables
miniSetting = viewMiniAnalysisCheck.UserData;

% miniCoords = getappdata(viewEPSC,'miniCoords');
% miniFeatures= getappdata(viewEPSC,'miniFeatures');
% miniTargets= getappdata(viewEPSC,'miniTargets');

if isempty(viewANNGUI.UserData)
    miniCoord = viewMiniDoneCheck.UserData{1};
    miniTarget = viewMiniDoneCheck.UserData{2};
    miniFeature = viewMiniDoneCheck.UserData{3};
else
    miniCoord = viewANNGUI.UserData{1};
    miniTarget = viewANNGUI.UserData{2};
    miniFeature = viewANNGUI.UserData{3};
end




%Current position
[miniCurrIdx,~,~,next] = sscanf(viewANNEventDrop.String{viewANNEventDrop.Value},'%g');
miniCurrX = sscanf(viewANNEventDrop.String{viewANNEventDrop.Value}(next+1:end),'%g');

%Section limits
%Get section parts
viewMiniStartEdit = findobj('Tag','viewMiniStartEdit');
viewMiniStopEdit = findobj('Tag','viewMiniStopEdit');

xStart = miniSetting(viewMiniSetDrop.Value,1);
xStop = miniSetting(viewMiniSetDrop.Value,2);

%Mini settings
viewANNZoomXEdit = findobj('Tag','viewANNZoomXEdit');
viewANNZoomYEdit = findobj('Tag','viewANNZoomYEdit');
viewANNDetectEdit = findobj('Tag','viewANNDetectEdit');
viewANNCertEdit = findobj('Tag','viewANNCertEdit');

%filedata
ephysDB = getappdata(viewEPSC,'ephysDB');
dataPath = getappdata(viewEPSC,'dataPath');
dataPath = dataPath{ephysDB(viewNamesDrop.Value)};
miniFltr = getappdata(viewEPSC,'ephysFltr');
filename = miniFltr{viewNamesDrop.Value,1};
fileData = retrieveEphys(filename,{'data','si'},...
    dataPath);
fileSI = fileData{2};
if fileSI>1; fileSI = fileSI/1e6; end;
fileData = fileData{1}(:,1);

%Fix partial saved parameters
if ~isempty(miniTarget) && all(miniTarget(:,1))
    ampThres = sscanf(viewANNDetectEdit.String,'%g');
    %detect peaks
    [roughX,roughY,roughFeatures] = roughMiniDetect(...
        fileData(round(xStart/fileSI):round(xStop/fileSI)),ampThres);
    %Resize features
    roughLarge = NaN(size(roughFeatures,1),10);
    roughLarge(:,1:size(roughFeatures,2)) = roughFeatures;
    
    %Generate Targets
    roughCoords = [roughX,roughY];
    roughTargets = false(size(roughCoords));
    roughTargets(:,2) = true;
    
    %Remove potential double coords
    maxD = round(0.002/fileSI);
    for ii = 1:size(miniCoord,1)
        selVec = ~(roughCoords(:,1)>miniCoord(ii,1)-maxD &...
            roughCoords(:,1)<miniCoord(ii,1)+maxD);
        
        roughCoords = roughCoords(selVec,:);
        roughTargets = roughTargets(selVec,:);
        roughLarge = roughLarge(selVec,:);
    end
    
    %Combine
    miniCoord = [roughCoords;miniCoord];
    miniTarget = [roughTargets;miniTarget];
    miniFeature = [roughLarge;miniFeature];
    %Sort
    [~,sortVec] = sort(miniCoord(:,1));
    miniCoord = miniCoord(sortVec,:);
    miniTarget = miniTarget(sortVec,:);
    miniFeature = miniFeature(sortVec,:);
    
%     %Save
%     viewMiniDoneCheck.UserData{1} = miniCoord;
%     viewMiniDoneCheck.UserData{3} = miniFeature;
%     viewMiniDoneCheck.UserData{2} = miniTarget;

end

%Update booleans
updateScat = false;
freshDetect = false;
eventDropUpdate = false;
updateLims = false;
previewDetect = false;
closeWindow = false;
updateRatio = false;

switch hObject.Tag
    case 'viewANNStatus'
        %Disable all other functionality %Get all view- related windows except the ANN one
        window = sort(findobj('-regexp','Tag','view[^(ANN)]','Type','Figure'));
        
        enableSettings = cell(size(window));
        
        % Store Enable and set to inactive
        for i=1:numel(window)
            UIObjects = sort(findobj(window(i),'Type','UIControl'));
            enableSettings{i} = get(UIObjects,'Enable');
            set(UIObjects,'Enable','inactive');
        end
        hObject.UserData = enableSettings;
        
        %Prevent closing miniAnalysis
        viewMiniGUI.CloseRequestFcn = '';
        
        %Activated graph click function
        viewPlot.ButtonDownFcn = @viewANN_click;
        set(viewPlot.Children,'HitTest','off');
        
        %Unblock UI modes
        %         hManager = uigetmodemanager(viewEPSC);
        %         try
        %             [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2
        %         catch
        %             set(hManager.WindowListenerHandles, 'Enable', 'off');  % HG1
        %         end
        %Get rid of all uimodes for now
        zoom(viewEPSC,'off')
        pan(viewEPSC,'off')
        datacursormode(viewEPSC,'off')
        viewEPSC.ToolBar = 'none';
        
        viewEPSC.WindowKeyPressFcn = @viewANN_pressKey;
        viewEPSC.WindowScrollWheelFcn = @viewANN_pressKey;
        
        %Set XLim to selected section
        updateLims = true;
        
        %Check if we should set default settings
        viewPath = fileparts(which('viewEPSC_GUI'));
        if exist(fullfile(viewPath,'viewMiniSettings.mat'),'file') == 2
            load(fullfile(viewPath,'viewMiniSettings.mat'));
            
            %Set settings
            viewANNZoomXEdit.String = num2str(viewMiniSettings(1));
            viewANNZoomYEdit.String = num2str(viewMiniSettings(2));
            viewANNDetectEdit.String = num2str(viewMiniSettings(3));
            viewANNCertEdit.String = num2str(viewMiniSettings(4));
        else
            %Make with current settings
            viewMiniSettings = [];
            viewMiniSettings(1) = sscanf(viewANNZoomXEdit.String,'%g');
            viewMiniSettings(2) = sscanf(viewANNZoomYEdit.String,'%g');
            viewMiniSettings(3) = sscanf(viewANNDetectEdit.String,'%g');
            viewMiniSettings(4) = sscanf(viewANNCertEdit.String,'%g');
            
            save(fullfile(viewPath,'viewMiniSettings.mat'),'viewMiniSettings');
        end
        
        %Perform detection
        %         if isempty(miniCoord)
        %             dThres = viewMiniSettings(3);
        %             cThres = viewMiniSettings(4);
        %
        %             [ miniCoord, miniFeature, miniTarget ] = viewANNDetectMinis(dThres,cThres,...
        %                 fileData,fileSI,[xStart, xStop]);
        %
        %             %Update drop
        %             eventDropUpdate = true;
        %         elseif xStart/fileSI > miniCoord(end,1) || xStop/fileSI < miniCoord(1,1)
        %             %No events in this section, probably no analysis yet
        %             freshDetect = true;
        %         end
        
        if isempty(miniCoord) || xStart/fileSI > miniCoord(end,1)...
                || xStop/fileSI < miniCoord(1,1)
            freshDetect = true;
        else
            eventDropUpdate = true;
        end
        
        %Update plot
        updateScat = true;
        
        
    case 'viewANNZoom'
        viewANNZoom.UserData = true;
        updateLims = true;
    case 'viewANNFull'
        viewANNZoom.UserData = false;
        updateLims = true;
    case 'viewANNZoomXEdit'
        if viewANNZoom.UserData; updateLims = true; end
    case 'viewANNZoomYEdit'
        updateLims = true;
    case 'viewANNEventDrop'
        updateLims = true;
    case 'viewANNConfirm'
        %Mark current event
        miniTarget(miniCurrIdx,:) = [1 0];
        
        %Get surrounding events
        currCoord = miniCoord(miniCurrIdx,1);
        markCoord = miniCoord(miniTarget(:,1),:);
        markFeature = miniFeature(miniTarget(:,1),:);
        markCurrIdx = find(currCoord==markCoord(:,1));
        %See if they should be marked as double
        rangeEvents = unique([max([1,markCurrIdx-1]),...
            min([size(markCoord,1),markCurrIdx+1])]);
        doubleEvents = diff(markCoord(sort([rangeEvents,markCurrIdx]),1))*fileSI < 0.03;
        doubleIdx = rangeEvents(doubleEvents);
        %mark them as double
        for i=doubleIdx
            markFeature(i,9) = true;
        end
        markFeature(markCurrIdx,9) = true;
        
        %         for i=1:numel(rangeEvents)
        %             if doubleEvents(i)
        %                 markFeature(rangeEvents(i),9) = true;
        %             end
        %         end
        %
        %Calculate parameters
        for i=[doubleIdx,markCurrIdx]
            bDouble=markFeature(i,9);
            
            
            pre = max([1, markCoord(i,1)-0.03/fileSI+1]);
            post = min([numel(fileData), pre-1+0.07/fileSI]);
            
            if i+1 > size(markCoord,1)
                distance = diff([markCoord(i,1),xStop/fileSI]);
                preDistance = diff(markCoord(i-1:i,1));
            elseif i==1
                distance = diff(markCoord(i:i+1,1));
                preDistance = diff([xStart/fileSI,markCoord(i,1)]);
            else
                distance = diff(markCoord(i:i+1,1));
                preDistance = diff(markCoord(i-1:i,1));
            end
            
            %Features
            %1:Amplitude; 2:rise time, 3:baseline, 4:decayTau, 5:50%X, 6:50%Y,
            %7:fit area, 8:sum Area, 9:double?
            [newCoord, newFeature] = ...
                viewGetMiniParameters(fileData(pre:post),fileSI,bDouble,...
                distance,preDistance);
            
            %Set new coordinates
            markCoord(i,1) = markCoord(i,1)+newCoord(1,1);
            markCoord(i,2) = newCoord(1,2);
            
            %set features
            markFeature(i,:) = newFeature;
            
        end
        %Save new features
        miniCoord(miniTarget(:,1),:) = markCoord;
        miniFeature(miniTarget(:,1),:) = markFeature;
        
        %         bDouble= any(doubleEvents);
        %
        %         pre = max([1, currCoord(1,1)-0.03/fileSI+1]);
        %         post = min([numel(fileData), pre-1+0.07/fileSI]);
        %
        %         if markCurrIdx+1 > size(markCoord,1)
        %             distance = diff([currCoord(1,1),xStop/fileSI]);
        %             preDistance = diff([markCoord(rangeEvents(1),1),currCoord(1,1)]);
        %         elseif markCurrIdx==1
        %             distance = diff([currCoord(1,1),markCoord(rangeEvents(end),1)]);
        %             preDistance = diff([xStart/fileSI,currCoord(1,1)]);
        %         else
        %             distance = diff([currCoord(1,1),markCoord(rangeEvents(end),1)]);
        %             preDistance = diff([markCoord(rangeEvents(1),1),currCoord(1,1)]);
        %         end
        %         %Features
        %         %1:Amplitude; 2:rise time, 3:baseline, 4:decayTau, 5:50%X, 6:50%Y,
        %         %7:fit area, 8:sum Area, 9:double?
        %         [newCoord, newFeature] = ...
        %             viewGetMiniParameters(fileData(pre:post),fileSI,bDouble,...
        %             distance,preDistance);
        %         %Set new coordinates
        %         miniCoord(miniCurrIdx,1) = miniCoord(miniCurrIdx,1)+newCoord(1,1);
        %         miniCoord(miniCurrIdx,2) = newCoord(1,2);
        %
        %         %set features
        %         miniFeature(miniCurrIdx,:) = newFeature;
        
        %Advance position unless its the last one
        miniCurrIdx = min([miniCurrIdx+1,numel(viewANNEventDrop.String)]);
        viewANNEventDrop.Value = miniCurrIdx;
        
        viewANNCertEdit.UserData = viewANNCertEdit.UserData-1;
        updateRatio= true;
        updateScat = true;
    case 'viewANNDiscard'
        miniTarget(miniCurrIdx,:) = [0 1];
        
        %Check if double event
        if ~isnan(miniFeature(miniCurrIdx,9)) && miniFeature(miniCurrIdx,9)
            %Get surrounding events
            currCoord = miniCoord(miniCurrIdx,1);
            markCoord = miniCoord(miniTarget(:,1),:);
            markFeature = miniFeature(miniTarget(:,1),:);
            rangeEvents = find(currCoord>markCoord(:,1),1,'last');
            rangeEvents = [rangeEvents, find(currCoord<markCoord(:,1),1,'first')];
            
            %Check for doubles
            if ~isempty(rangeEvents)
                calcRange = false(size(rangeEvents));
                doubleEvents = diff(markCoord(unique(...
                    [max([1,rangeEvents(1)-1]),rangeEvents,...
                    min([size(markCoord,1),rangeEvents(end)+1])]),1))...
                    *fileSI < 0.03;
                %correct for wrong number of double events
                if numel(doubleEvents) < numel(rangeEvents)+1
                    if rangeEvents(1) == 1
                        doubleEvents = [false; doubleEvents];
                    else
                        doubleEvents = [doubleEvents; false];
                    end
                end
                
                if numel(doubleEvents) == 1
                    markFeature(rangeEvents(1),9) = doubleEvents;
                else
                    for i=1:numel(rangeEvents)
                        if any(doubleEvents(i:i+1))
                            markFeature(rangeEvents(i),9) = true;
                            calcRange(i) = true;
                        else
                            calcRange(i) = markFeature(rangeEvents(i),9);
                            markFeature(rangeEvents(i),9) = false;
                        end
                    end
                end
                
                %Select only double or changed events
                rangeEvents = rangeEvents(logical(calcRange));
                
                %Calculate parameters
                for i=rangeEvents
                    bDouble=markFeature(i,9);
                    
                    
                    pre = max([1, markCoord(i,1)-0.03/fileSI+1]);
                    post = min([numel(fileData), pre-1+0.07/fileSI]);
                    
                    if i+1 > size(markCoord,1)
                        distance = diff([markCoord(i,1),xStop/fileSI]);
                        preDistance = diff(markCoord(i-1:i,1));
                    elseif i==1
                        distance = diff(markCoord(i:i+1,1));
                        preDistance = diff([xStart/fileSI,markCoord(i,1)]);
                    else
                        distance = diff(markCoord(i:i+1,1));
                        preDistance = diff(markCoord(i-1:i,1));
                    end
                    
                    %Features
                    %1:Amplitude; 2:rise time, 3:baseline, 4:decayTau, 5:50%X, 6:50%Y,
                    %7:fit area, 8:sum Area, 9:double?
                    [newCoord, newFeature] = ...
                        viewGetMiniParameters(fileData(pre:post),fileSI,bDouble,...
                        distance,preDistance);
                    
                    %Set new coordinates
                    markCoord(i,1) = markCoord(i,1)+newCoord(1,1);
                    markCoord(i,2) = newCoord(1,2);
                    
                    %set features
                    markFeature(i,:) = newFeature;
                    
                end
                %Save new features
                miniCoord(miniTarget(:,1),:) = markCoord;
                miniFeature(miniTarget(:,1),:) = markFeature;
            end
        end
        %Advance position unless its the last one
        miniCurrIdx = min([miniCurrIdx+1,numel(viewANNEventDrop.String)]);
        viewANNEventDrop.Value = miniCurrIdx;
        
        viewANNCertEdit.UserData = viewANNCertEdit.UserData+1;
        updateRatio= true;
        updateScat = true;
    case 'viewANNCertEdit'
        %Check if we need to preview
        if viewANNPreviewCheck.Value
            if viewANNZoom.UserData
                previewDetect = true;
            else
                viewANNStatus.String = 'Preview only works when zoomed in';
                viewANNPreviewCheck.Value = false;
            end
        else %nothing to do for now
            return
        end
    case 'viewANNDetectEdit'
        %Check if we need to preview
        if viewANNPreviewCheck.Value
            if viewANNZoom.UserData
                previewDetect = true;
            else
                viewANNStatus.String = 'Preview only works when zoomed in';
                viewANNPreviewCheck.Value = false;
            end
        else %nothing to do for now
            return
        end
    case 'viewANNPreviewCheck'
        %Check if we need to preview
        if viewANNPreviewCheck.Value
            if viewANNZoom.UserData
                previewDetect = true;
                viewANNStatus.String = 'Preview freezes event selection';
            else
                viewANNStatus.String = 'Preview only works when zoomed in';
                viewANNPreviewCheck.Value = false;
            end
        else %preview switch off, update plot to normal
            updateScat = true;
        end
    case 'viewANNAnalyze'
        %Check if we need to adjust starting point
        viewANNfromHereCheck = findobj('Tag','viewANNfromHereCheck');
        if viewANNfromHereCheck.Value
            %make sure event is in window
            if miniCurrX < viewPlot.XLim(1) || miniCurrX > viewPlot.XLim(2)
                %Not in view ask if we should continue
                doItAnyway = questdlg(['Warning! Selected point is not in',...
                    ' current view. Proceed anyway?'], 'Warning!','Proceed',...
                    'Cancel','Cancel');
                if ~strcmp(doItAnyway,'Proceed')
                    %Don't do anything
                    viewANNStatus.String = 'Hint: Press Zoom to focus on event';
                    return
                end
            end
            %Update xStart
            xStart = miniCurrX;
        end
        
        %Detect events
        freshDetect = true;
    case 'viewANNFinish' %Save events and go back to mini specifications
        %Save
        viewMiniDoneCheck.UserData{1} = miniCoord;
        viewMiniDoneCheck.UserData{3} = miniFeature;
        viewMiniDoneCheck.UserData{2} = miniTarget;
        
        %Set mini settings to analyzed
        viewMiniAnalysisCheck.UserData(viewMiniSetDrop.Value,3) = 1;
        viewMiniDoneCheck.Value = true;
        
        %Keep settings for next time
        viewMiniSettings = [];
        viewMiniSettings(1) = sscanf(viewANNZoomXEdit.String,'%g');
        viewMiniSettings(2) = sscanf(viewANNZoomYEdit.String,'%g');
        viewMiniSettings(3) = sscanf(viewANNDetectEdit.String,'%g');
        viewMiniSettings(4) = sscanf(viewANNCertEdit.String,'%g');
        
        viewPath = fileparts(which('viewEPSC_GUI'));
        save(fullfile(viewPath,'viewMiniSettings.mat'),'viewMiniSettings');
        
        %Close window
        closeWindow = true;
    case 'viewANNCancel'
        closeWindow = true;
    case 'viewANNGUI'
        closeWindow = true;
end

%Perform detection only on this window and plot here
if previewDetect
    %Change start and stop of detect
    xStart = max([xStart,viewPlot.XLim(1)]);
    xStop = min([xStop,viewPlot.XLim(2)]);
    
    freshDetect = true;
end

%No events in this section, probably no analysis yet
if freshDetect
    viewANNStatus.String = 'Waiting for detection to finish...';
    drawnow;
    
    dThres = sscanf(viewANNDetectEdit.String,'%g');
    cThres = sscanf(viewANNCertEdit.String,'%g');
    
    [ coord, feature, target ] = viewANNDetectMinis(dThres,cThres,...
        fileData,fileSI,[xStart, xStop]);
    
    %Resize features
    largeFeatures = NaN(size(feature,1),10);
    largeFeatures(:,1:size(feature,2)) = feature;
    
    %Correct parameters
    markCoord = coord(target(:,1),:);
    markFeature = largeFeatures(target(:,1),:);
    markTarget = target;
    coordDistance = diff([markCoord(:,1)*fileSI;xStop]);
    leadingDouble = false;
    
    for i=1:size(markCoord,1)
        %is event part of a double?
        bDouble= coordDistance(i) < 0.03 | leadingDouble;
        leadingDouble = coordDistance(i) < 0.03; %Make sure next event will be marked double also
        
        pre = round(max([1, markCoord(i,1)-0.03/fileSI+1]));
        post = round(min([numel(fileData), pre-1+0.07/fileSI]));
        
        %Features
        %1:Amplitude; 2:rise time, 3:baseline, 4:decayTau, 5:50%X, 6:50%Y,
        %7:fit area, 8:sum Area, 9:double?
        [newCoord, newFeature] = ...
            viewGetMiniParameters(fileData(pre:post),fileSI,bDouble,...
            coordDistance(i)/fileSI,coordDistance(max([1,i-1]))/fileSI);
        %Set new coordinates
        markCoord(i,1) = markCoord(i,1)+newCoord(1,1);
        markCoord(i,2) = newCoord(1,2);
        
        %set features
        markFeature(i,:) = newFeature;
        
        %mark bad fits
        if newFeature(10)
            targetIdx = find(target(:,1),i);
            markTarget(targetIdx(end),:) = [0 0]; %unmarked
        end
        viewANNStatus.String = ['Calculating parameters. (',...
            num2str(i),'/',num2str(size(markCoord,1)),')'];
    end
    
    coord(target(:,1),:) = markCoord;
    largeFeatures(target(:,1),:) = markFeature;
    feature = largeFeatures;
    target = markTarget;
    %Make sure we don't have duplicates
    uniqueCoord = false(size(coord,1),1);
    [~,unqIdx] = unique(coord(:,1));
    uniqueCoord(unqIdx) = true;
    
    %Remove first of non-uniques
    coord = coord([uniqueCoord(2:end);true],:);
    feature = feature([uniqueCoord(2:end);true],:);
    target = target([uniqueCoord(2:end);true],:);
    
    if ~isempty(miniCoord)
        %find overlapping variables and remove from originals
        overlapFltr = miniCoord(:,1)*fileSI >= xStart &...
            miniCoord(:,1)*fileSI <= xStop;
        miniCoord = miniCoord(~overlapFltr,:);
        miniFeature = miniFeature(~overlapFltr,:);
        miniTarget = miniTarget(~overlapFltr,:);
        
        %Concatenate
        miniCoord = [miniCoord; coord];
        miniFeature = [miniFeature; feature];
        miniTarget = [miniTarget; target];
        
        %Sort
        [~,miniIdx] = sort(miniCoord(:,1));
        miniCoord = miniCoord(miniIdx,:);
        miniFeature = miniFeature(miniIdx,:);
        miniTarget = miniTarget(miniIdx,:);
    else
        miniCoord = coord;
        miniFeature = feature;
        miniTarget = target;
    end
    
    %Update plot
    updateScat = true;
    
    %Update drop
    if ~previewDetect
        eventDropUpdate = true;
        viewANNCertEdit.UserData = 0;
        updateRatio = true;
    end
    
    %Update status
    viewANNStatus.String = 'Detection finished';
    
end



%Update the drop
if eventDropUpdate
    %Set number of events and current event
    miniEventStrings = num2cell(1:size(miniCoord,1));
    miniEventStrings = cellfun(@num2str, miniEventStrings,...
        'UniformOutput', false);
    miniCoordString = num2cell(miniCoord(:,1)*fileSI);
    miniCoordString = cellfun(@num2str, miniCoordString,...
        'UniformOutput', false);
    miniFullString = cellfun(@(x,y) [x,' @ ',y,'s'],miniEventStrings',...
        miniCoordString, 'UniformOutput', false);
    viewANNEventDrop.String = miniFullString;
end

%%% needs to be before updateScat to fix possible preview scatters
if updateLims
    if viewANNPreviewCheck.Value
        updateScat = true;
        viewANNPreviewCheck.Value = false;
    end
    %Get zoom window
    xLength = sscanf(viewANNZoomXEdit.String,'%g');
    yLength = sscanf(viewANNZoomYEdit.String,'%g');
    
    if isempty(xLength)
        xLength = 0.5;
        viewANNZoomXEdit.String = '0.5';
    end
    if isempty(yLength)
        yLength = 300;
        viewANNZoomYEdit.String = '300';
    end
    
    %Is zoom selected?
    if viewANNZoom.UserData
        %Get current index
        if miniCurrX == 0
            miniX = xStart+xLength*0.15;
        else
            miniX = miniCurrX;
        end
        
        %Are we moving
        if exist('event','var') && ischar(event) %Pagedown pressed skip to nec
            if strcmp(event,'next')
                x1 = viewPlot.XLim(1)+xLength*0.7;
                x2 = viewPlot.XLim(2)+xLength*0.7;
                %Decay manual ratio
                viewANNCertEdit.UserData = viewANNCertEdit.UserData*0.8;
            elseif strcmp(event, 'prev')
                x1 = viewPlot.XLim(1)-xLength*0.7;
                x2 = viewPlot.XLim(2)-xLength*0.7;
                %Undecay manual ratio
                viewANNCertEdit.UserData = viewANNCertEdit.UserData/0.8;
            end
            %Change currIdx
            newIdx = find(miniCoord(:,1)>(x1+xLength*0.15)/fileSI);
            if isempty(newIdx) %Nothing found just take last event
                miniCurrIdx = numel(miniCoord(:,1));
                miniX = miniCoord(miniCurrIdx,1);
            else
                miniCurrIdx = newIdx(1);
                miniX = miniCoord(miniCurrIdx,1);
            end
            viewANNEventDrop.Value = miniCurrIdx;
            updateRatio = true;
        else
            %Set currIdx 20% from start
            x1 = miniX-xLength*0.15;
            x2 = miniX+xLength*0.85;
        end
        
        %Make sure we don't exceed trace
        if x1 < numel(fileData)*fileSI && x2 > 0
            xlim(viewPlot,[x1,x2]);
            
            %Set baseline 20% from the top
            b1 = max([1,round(x1/fileSI)]);
            b2 = min([numel(fileData),round(x2/fileSI)]);
            
            miniBase = mean(fileData(b1:b2));
            
            y1 = ceil(miniBase-yLength*0.8);
            y2 = ceil(miniBase+yLength*0.2);
            ylim(viewPlot,[y1,y2]);
        end
        
        
        
    else %Just draw to section limits
        viewPlot.XLim = [xStart, xStop];
        %Set baseline 20% from the top
        miniBase = mean(fileData(round(xStart/fileSI):round(xStop/fileSI)));
        
        y1 = ceil(miniBase-yLength*0.8);
        y2 = ceil(miniBase+yLength*0.2);
        ylim(viewPlot,[y1,y2]);
    end
    
    %Set scatter
    viewCurrScat = findobj('Tag','viewMiniScatYellow');
    if ~isempty(viewCurrScat); delete(viewCurrScat);end
    if miniCurrIdx > 0
        hold(viewPlot,'on')
        scatter(viewPlot,miniCoord(miniCurrIdx,1)*fileSI,miniCoord(miniCurrIdx,2),...
            'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
            'Tag','viewMiniScatYellow')
        if miniTarget(miniCurrIdx,1)
            %Also fill baseline
            baseX1 = miniCoord(miniCurrIdx,1)*fileSI-miniFeature(miniCurrIdx,2);
            baseY1 = miniFeature(miniCurrIdx,3);
            scatter(viewPlot,baseX1,baseY1,'>',...
                'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                'Tag','viewMiniScatYellow')
            if ~miniFeature(miniCurrIdx,10)
                %Also fill decay
                decayX = miniCoord(miniCurrIdx,1)*fileSI+miniFeature(miniCurrIdx,5);
                decayY = miniFeature(miniCurrIdx,6)+miniFeature(miniCurrIdx,3);
                scatter(viewPlot,decayX,decayY,'<',...
                    'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                    'Tag','viewMiniScatYellow')
            end
        end
        hold(viewPlot,'off')
    end
end

if updateScat
    %Remove old versions if available
    viewMiniScat{1} = findobj('Tag','viewMiniScatRed');
    viewMiniScat{2} = findobj('Tag','viewMiniScatGreen');
    viewMiniScat{3} = findobj('Tag','viewMiniScatYellow');
    viewMiniScat{4} = findobj('Tag','viewMiniScatBase');
    viewMiniScat{5} = findobj('Tag','viewMiniScatDecay');
    for i = 1:numel(viewMiniScat)
        if ~isempty(viewMiniScat{i})
            delete(viewMiniScat{i});
        end
    end
    
    %Time to make a scatter plot...
    hold(viewPlot, 'on')
    %Scatter Baseline
    baseX = miniCoord(miniTarget(:,1),1)*fileSI-miniFeature(miniTarget(:,1),2);
    baseY = miniFeature(miniTarget(:,1),3);
    scatter(viewPlot,baseX,baseY,'>',...
        'MarkerEdgeColor','k','HitTest','off',...
        'Tag','viewMiniScatBase')
    
    %Scatter Decay
    decayX = miniCoord(miniTarget(:,1),1)*fileSI+miniFeature(miniTarget(:,1),5);
    decayY = miniFeature(miniTarget(:,1),6)+miniFeature(miniTarget(:,1),3);
    %Remove bad fits
    badFits = miniFeature(miniTarget(:,1),10);
    decayX = decayX(~badFits); decayY = decayY(~badFits);
    scatter(viewPlot,decayX,decayY,'<',...
        'MarkerEdgeColor',[0.5 0 0.5],'HitTest','off',...
        'Tag','viewMiniScatDecay')
    
    %Scatter Confirmed
    scatter(viewPlot,miniCoord(miniTarget(:,1),1)*fileSI,miniCoord(miniTarget(:,1),2),...
        'MarkerEdgeColor','g','MarkerFaceColor','g','HitTest','off',...
        'Tag','viewMiniScatGreen')
    
    %Scatter of not targeted
    scatter(viewPlot,miniCoord(~any(miniTarget,2),1)*fileSI,miniCoord(~any(miniTarget,2),2),...
        'MarkerEdgeColor','r','HitTest','off','Tag','viewMiniScatRed');
    
    if miniCurrIdx > 0 && ~previewDetect
        scatter(viewPlot,miniCoord(miniCurrIdx,1)*fileSI,miniCoord(miniCurrIdx,2),...
            'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
            'Tag','viewMiniScatYellow')
        if miniTarget(miniCurrIdx,1)
            %Also fill baseline
            baseX1 = miniCoord(miniCurrIdx,1)*fileSI-miniFeature(miniCurrIdx,2);
            baseY1 = miniFeature(miniCurrIdx,3);
            scatter(viewPlot,baseX1,baseY1,'>',...
                'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                'Tag','viewMiniScatYellow')
            if ~miniFeature(miniCurrIdx,10)
                %Also fill decay
                decayX = miniCoord(miniCurrIdx,1)*fileSI+miniFeature(miniCurrIdx,5);
                decayY = miniFeature(miniCurrIdx,6)+miniFeature(miniCurrIdx,3);
                scatter(viewPlot,decayX,decayY,'<',...
                    'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                    'Tag','viewMiniScatYellow')
            end
        end
    end
    
    hold(viewPlot, 'off')
    
end
%Display ratio
if updateRatio
   ratioNum = viewANNCertEdit.UserData/7;
   viewANNStatus.String = ['Manual ratio: ',num2str(ratioNum)];
end
if closeWindow
    %Remove functions
    viewPlot.ButtonDownFcn = '';
    set(viewPlot.Children,'HitTest','on');
    
    viewEPSC.WindowKeyPressFcn = '';
    viewEPSC.WindowScrollWheelFcn = '';
    viewEPSC.ToolBar = 'figure';
    
    %Allow mini to close
    viewMiniGUI.CloseRequestFcn = @viewMini_Update;
    
    %Re do the Axes
    viewPlot.XLim = [0,numel(fileData)*fileSI];
    ylim(viewPlot, 'auto');
    %Minimum Y limit
    if viewPlot.YLim(2)-viewPlot.YLim(1)<500
        addY = (500-(viewPlot.YLim(2)-viewPlot.YLim(1)))/2;
        viewPlot.YLim(1) = viewPlot.YLim(1)-addY;
        viewPlot.YLim(2) = viewPlot.YLim(2)+addY;
    end
    %Remove old scats if available
    viewMiniScat{1} = findobj('Tag','viewMiniScatRed');
    viewMiniScat{2} = findobj('Tag','viewMiniScatYellow');
    viewMiniScat{3} = findobj('Tag','viewMiniScatBase');
    viewMiniScat{4} = findobj('Tag','viewMiniScatDecay');
    for i = 1:numel(viewMiniScat)
        if ~isempty(viewMiniScat{i})
            delete(viewMiniScat{i});
        end
    end
    
    %replot (This messes up the current temporary miniSettings)
    %     viewPlot.UserData = [];
    %     viewEPSC_Plot;
    
    %Re-enable functionality
    window = sort(findobj('-regexp','Tag','view[^(ANN)]','Type','Figure'));
    enableSettings = viewANNStatus.UserData;
    for i=1:numel(window)
        UIObjects = sort(findobj(window(i),'Type','UIControl'));
        for j = 1:numel(enableSettings{i})
            set(UIObjects(j),'Enable',enableSettings{i}{j});
        end
    end
    %Auto apply on finish
    if strcmp(hObject.Tag,'viewANNFinish')
        viewMini_Update(findobj('Tag','viewMiniApply'),[]);
    end
    %Delete figure and finish
    delete(viewANNGUI);
    return
end

%Store events if not previewing
if ~previewDetect
    viewANNGUI.UserData = {miniCoord,miniTarget,miniFeature};
end
end

function viewANN_click(hObject, event)
viewANNPreviewCheck = findobj('Tag','viewANNPreviewCheck');
if viewANNPreviewCheck.Value
    %preview dont do anything
    return;
end
viewANNGUI = findobj('Tag','viewANNGUI');
viewANNEventDrop = findobj('Tag','viewANNEventDrop');
viewDataTrace = findobj('Tag','viewDataTrace');
fileSI = viewDataTrace.XData(1);
viewPlot = hObject;

%Get X coordinate of click
xCorr = event.IntersectionPoint(1);
%Get peak data
miniCoord = viewANNGUI.UserData{1};
miniTarget = viewANNGUI.UserData{2};
miniFeature = viewANNGUI.UserData{3};

%find closest peak
[~, xClose] = min(abs(miniCoord(:,1)-xCorr/fileSI));

%Set currIdx
viewANNEventDrop.Value = xClose;

%Plot CurrIdx point
viewCurrScat = findobj('Tag','viewMiniScatYellow');
if ~isempty(viewCurrScat); delete(viewCurrScat);end

if xClose > 0
    hold(viewPlot,'on')
    scatter(viewPlot,miniCoord(xClose,1)*fileSI,miniCoord(xClose,2),...
        'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
        'Tag','viewMiniScatYellow')
    
    if miniTarget(xClose,1)
        %Also fill baseline
        baseX1 = miniCoord(xClose,1)*fileSI-miniFeature(xClose,2);
        baseY1 = miniFeature(xClose,3);
        scatter(viewPlot,baseX1,baseY1,'>',...
            'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
            'Tag','viewMiniScatYellow')
        if ~miniFeature(xClose,10)
            %Also fill decay
            decayX = miniCoord(xClose,1)*fileSI+miniFeature(xClose,5);
            decayY = miniFeature(xClose,6)+miniFeature(xClose,3);
            scatter(viewPlot,decayX,decayY,'<',...
                'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                'Tag','viewMiniScatYellow')
        end
    end
    hold(viewPlot,'off')
end

end

function viewANN_pressKey(hObject,event)
if strcmp(event.EventName, 'WindowScrollWheel')
    if event.VerticalScrollCount > 0
        keyPressed = 'pagedown';
    else
        keyPressed = 'pageup';
    end
else
    keyPressed = event.Key;
end
if strcmp(keyPressed,'l'); keyPressed = 'rightarrow'; end;
if strcmp(keyPressed,'j'); keyPressed = 'leftarrow'; end;
switch keyPressed
    case 'm'
        viewANN_Update(findobj('Tag','viewANNConfirm'))
    case 'c'
        viewANN_Update(findobj('Tag','viewANNDiscard'))
    case 'rightarrow'
        viewANNPreviewCheck = findobj('Tag','viewANNPreviewCheck');
        if viewANNPreviewCheck.Value
            %preview dont do anything
            return;
        end
        viewANNGUI = findobj('Tag','viewANNGUI');
        viewANNEventDrop = findobj('Tag','viewANNEventDrop');
        viewPlot = findobj('Tag','viewPlot');
        viewANNZoomXEdit = findobj('Tag','viewANNZoomXEdit');
        viewDataTrace = findobj('Tag','viewDataTrace');
        fileSI = viewDataTrace.XData(1);
        
        currIdx = viewANNEventDrop.Value;
        if currIdx+1 <= numel(viewANNEventDrop.String)
            viewANNEventDrop.Value = currIdx+1;
            
            miniCoord = viewANNGUI.UserData{1};
            miniTarget = viewANNGUI.UserData{2};
            miniFeature = viewANNGUI.UserData{3};
            
            %See if we need to move the window
            xLength = sscanf(viewANNZoomXEdit.String,'%g');
            
            if miniCoord(currIdx+1,1)*fileSI > (viewPlot.XLim(1)+xLength*0.85)
                viewANN_Update(viewANNEventDrop);
            else
                %Mark next point
                viewCurrScat = findobj('Tag','viewMiniScatYellow');
                if ~isempty(viewCurrScat); delete(viewCurrScat);end
                
                hold(viewPlot,'on')
                scatter(viewPlot,miniCoord(currIdx+1,1)*fileSI,miniCoord(currIdx+1,2),...
                    'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                    'Tag','viewMiniScatYellow')
                if miniTarget(currIdx+1,1)
                    %Also fill baseline
                    baseX1 = miniCoord(currIdx+1,1)*fileSI-miniFeature(currIdx+1,2);
                    baseY1 = miniFeature(currIdx+1,3);
                    scatter(viewPlot,baseX1,baseY1,'>',...
                        'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                        'Tag','viewMiniScatYellow')
                    if ~miniFeature(currIdx+1,10)
                        %Also fill decay
                        decayX = miniCoord(currIdx+1,1)*fileSI+miniFeature(currIdx+1,5);
                        decayY = miniFeature(currIdx+1,6)+miniFeature(currIdx+1,3);
                        scatter(viewPlot,decayX,decayY,'<',...
                            'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                            'Tag','viewMiniScatYellow')
                    end
                end
                hold(viewPlot,'off')
                
            end
            
        end
    case 'leftarrow'
        viewANNPreviewCheck = findobj('Tag','viewANNPreviewCheck');
        if viewANNPreviewCheck.Value
            %preview dont do anything
            return;
        end
        viewANNGUI = findobj('Tag','viewANNGUI');
        viewANNEventDrop = findobj('Tag','viewANNEventDrop');
        viewPlot = findobj('Tag','viewPlot');
        viewANNZoomXEdit = findobj('Tag','viewANNZoomXEdit');
        viewDataTrace = findobj('Tag','viewDataTrace');
        fileSI = viewDataTrace.XData(1);
        
        currIdx = viewANNEventDrop.Value;
        if currIdx-1 > 0
            viewANNEventDrop.Value = currIdx-1;
            
            miniCoord = viewANNGUI.UserData{1};
            miniTarget = viewANNGUI.UserData{2};
            miniFeature = viewANNGUI.UserData{3};
            
            %See if we need to move the window
            xLength = sscanf(viewANNZoomXEdit.String,'%g');
            
            if miniCoord(currIdx-1,1)*fileSI < (viewPlot.XLim(1)+xLength*0.15)
                viewANN_Update(viewANNEventDrop,'prev');
            else
                %Mark next point
                viewCurrScat = findobj('Tag','viewMiniScatYellow');
                if ~isempty(viewCurrScat); delete(viewCurrScat);end
                
                hold(viewPlot,'on')
                scatter(viewPlot,miniCoord(currIdx-1,1)*fileSI,miniCoord(currIdx-1,2),...
                    'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                    'Tag','viewMiniScatYellow')
                if miniTarget(currIdx-1,1)
                    %Also fill baseline
                    baseX1 = miniCoord(currIdx-1,1)*fileSI-miniFeature(currIdx-1,2);
                    baseY1 = miniFeature(currIdx-1,3);
                    scatter(viewPlot,baseX1,baseY1,'>',...
                        'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                        'Tag','viewMiniScatYellow')
                    if ~miniFeature(currIdx-1,10)
                        %Also fill decay
                        decayX = miniCoord(currIdx-1,1)*fileSI+miniFeature(currIdx-1,5);
                        decayY = miniFeature(currIdx-1,6)+miniFeature(currIdx-1,3);
                        scatter(viewPlot,decayX,decayY,'<',...
                            'MarkerEdgeColor','none','MarkerFaceColor','y','HitTest','off',...
                            'Tag','viewMiniScatYellow')
                    end
                end
                hold(viewPlot,'off')
                
            end
        end
        
    case 'home'
        viewANNEventDrop = findobj('Tag','viewANNEventDrop');
        viewANNEventDrop.Value = 1;
        viewANN_Update(viewANNEventDrop)
    case 'end'
        viewANNEventDrop = findobj('Tag','viewANNEventDrop');
        viewANNEventDrop.Value = numel(viewANNEventDrop.String);
        viewANN_Update(viewANNEventDrop)
    case 'pagedown'
        viewANNEventDrop = findobj('Tag','viewANNEventDrop');
        viewANN_Update(viewANNEventDrop,'next')
    case 'pageup'
        viewANNEventDrop = findobj('Tag','viewANNEventDrop');
        viewANN_Update(viewANNEventDrop,'prev')
end
end

%Remove Cell Callback
function viewEPSC_Remove(hObject,event)
%Get Objects
viewEPSC = findobj('Tag', 'viewEPSC');
viewPlot = findobj('Tag','viewPlot');
viewNamesDrop = findobj('Tag','viewNamesDrop');
viewCellCount  =findobj('Tag','viewCellCount');
viewBlindCheck  =findobj('Tag','viewBlindCheck');

reBlind = false;
%unblind if necessary
if viewBlindCheck.Value
    viewBlindCheck.Value = false;
    viewEPSC_BlindFile(viewBlindCheck)
    reBlind = true;
end
%Get all appdata except dataPath
allAppdata = getappdata(viewEPSC);
appNames = fieldnames(allAppdata);
appNames = appNames(~strcmp(appNames,'dataPath'));
appNames = appNames(~strcmp(appNames,'ScribeAddAnnotationStateData'));
appNames = appNames(~strcmp(appNames,'ZoomOnState'));

%Get appdata %Old method
%1) Method, 2) Points and range
% baselineValues = getappdata(viewEPSC,'baselineValues');
% artifactSettings = getappdata(viewEPSC,'artifactSettings');
% amplitudeSettings = getappdata(viewEPSC, 'amplitudeSettings');
% chargeSettings = getappdata(viewEPSC, 'chargeSettings');
% ephysFltr = getappdata(viewEPSC,'ephysFltr');
% ephysDB = getappdata(viewEPSC,'ephysDB');

%Remove all or single
removeIdx = false(size(viewNamesDrop.String));
if strcmp(hObject.Tag,'viewRemoveCell')
    %Remove single get cell ID
    removeIdx(viewNamesDrop.Value) = true;
elseif strcmp(hObject.Tag,'viewRemoveAll')
    %Remove all
    yes = questdlg('Remove all cells?');
    if ~strcmp(yes,'Yes')
        return
    end
    removeIdx(:) = true;
    reBlind = false;
end
%Remove idx
for i = 1:numel(appNames)
    setappdata(viewEPSC,appNames{i},allAppdata.(appNames{i})(~removeIdx,:));
end
viewNamesDrop.String = viewNamesDrop.String(~removeIdx,:);

%Old method
% viewNamesDrop.String = viewNamesDrop.String(~removeIdx,:);
% baselineValues = baselineValues(~removeIdx,:);
% artifactSettings = artifactSettings(~removeIdx,:);
% amplitudeSettings = amplitudeSettings(~removeIdx,:);
% chargeSettings = chargeSettings(~removeIdx,:);
% ephysFltr = ephysFltr(~removeIdx,:);
% ephysDB = ephysDB(~removeIdx,:);

%if empty now set string to preinit
if isempty(viewNamesDrop.String)
    viewNamesDrop.Value = 1;
    viewNamesDrop.String = {'No data selected'};
    viewCellCount.String = '0:';
elseif viewNamesDrop.Value > numel(viewNamesDrop.String)
    %Make sure we are at an existing value
    viewNamesDrop.Value = numel(viewNamesDrop.String);
    viewCellCount.String = [num2str(viewNamesDrop.Value),':'];
end

%Old method
%Store changes
% setappdata(viewEPSC,'ephysFltr',ephysFltr);
% setappdata(viewEPSC,'ephysDB',ephysDB);
% setappdata(viewEPSC,'baselineValues',baselineValues)
% setappdata(viewEPSC,'artifactSettings',artifactSettings);
% setappdata(viewEPSC,'amplitudeSettings',amplitudeSettings);
% setappdata(viewEPSC,'chargeSettings',chargeSettings);

%Update plot as new cell
viewPlot.UserData = [];
viewEPSC_Plot;

if reBlind
    viewBlindCheck.Value = true;
    viewEPSC_BlindFile(viewBlindCheck)
end
end

%Save and export GUIs
function viewSave_Update(hObject,event)
%Manage and execute saving
%Get
viewSaveGUI = findobj('Tag','viewSaveGUI');
allChecks = findobj(viewSaveGUI,'Style','checkbox');
viewEPSC = findobj('Tag', 'viewEPSC');
ephysDB = getappdata(viewEPSC,'ephysDB');
saveFltr = getappdata(viewEPSC,'ephysFltr');
dataPath = getappdata(viewEPSC,'dataPath');
viewNamesDrop = findobj('Tag','viewNamesDrop');
viewSaveStatus = findobj('Tag','viewSaveStatus');

if strcmp(hObject.Tag,'viewSaveStatus')
    %Just opened check if we have setting files, otherwise make one
    viewPath = fileparts(which('viewEPSC_GUI'));
    if exist(fullfile(viewPath,'viewSaveSettings.mat'),'file') == 2
        load(fullfile(viewPath,'viewSaveSettings.mat'));
    else
        %Make with current settings
        saveChecks = get(allChecks,'Value');
        save(fullfile(viewPath,'viewSaveSettings.mat'),'saveChecks');
    end
    if numel(saveChecks) < numel(allChecks)
        %Old make with current settings
        saveChecks = get(allChecks,'Value');
        save(fullfile(viewPath,'viewSaveSettings.mat'),'saveChecks');
    end
    %Set checks
    for i = 1:numel(saveChecks)
        allChecks(i).Value = saveChecks{i};
    end
elseif strcmp(hObject.Tag,'viewSavePathSelect')
    %Get edit box
    viewSavePathEdit = findobj('Tag','viewSavePathEdit');
    
    %Get Path
    viewSavePathEdit.String...
        = uigetdir(viewSavePathEdit.String,...
        'Select save folder');
elseif strcmp(hObject.Tag,'viewSaveCancel')
    %Nothing special just delete
    delete(viewSaveGUI);
    return;
elseif strcmp(hObject.Tag,'viewSaveSave')
    %Saving all selected items
    saveChecks = get(allChecks,'Value');
    
    if ~any([saveChecks{2:end}])
        %Nothing selected return
        
        viewSaveStatus.String = 'Please select at least one item to save';
        return
    end
    %Retrieve setting files
    baselineValues = getappdata(viewEPSC,'baselineValues');
    artifactSettings = getappdata(viewEPSC,'artifactSettings');
    amplitudeSettings = getappdata(viewEPSC, 'amplitudeSettings');
    chargeSettings = getappdata(viewEPSC, 'chargeSettings');
    miniSettings = getappdata(viewEPSC, 'miniSettings');
    miniCoords = getappdata(viewEPSC, 'miniCoords');
    miniTargets = getappdata(viewEPSC, 'miniTargets');
    miniFeatures = getappdata(viewEPSC, 'miniFeatures');
    
    viewSavePathEdit = findobj('Tag','viewSavePathEdit');
    
    %See if we're making a file or saving to mat-files
    if saveChecks{1} %Single file yes ask  for name and set it up
        singleFile = true;
        slash = '';
        if isempty(regexp(viewSavePathEdit.String(end),'/|\','ONCE'))
            if isunix
                slash = '/';
            else
                slash = '\';
            end
        end
        [FileName,PathName] = uiputfile('*.mat',...
            'Save Analyzed As',...
            [viewSavePathEdit.String,slash]);
        dataStruct = struct();
        dataStruct.filename = {};
        
        %Create necessary structs
        if saveChecks{2}; dataStruct.ChargeIdx = {}; end;
        if saveChecks{3}; dataStruct.AmpIdx = {}; end;
        if saveChecks{4}; dataStruct.SyncTrace = {}; end;
        if saveChecks{5}; dataStruct.InterpTrace = {}; end;
        if saveChecks{6}; dataStruct.EmptyTrace = {}; end;
        if saveChecks{7}; dataStruct.CorrTrace = {}; end;
        if saveChecks{8}; dataStruct.ChargeValue = {}; end;
        if saveChecks{9}; dataStruct.AmpValue = {}; end;
        if saveChecks{10}; dataStruct.ArtIdx = {}; end;
        if saveChecks{11}; dataStruct.Baseline = {}; end;
        if saveChecks{12}; dataStruct.ChargeSetting = {}; end;
        if saveChecks{13}; dataStruct.AmpSetting = {}; end;
        if saveChecks{14}; dataStruct.ArtSetting = {}; end;
        if saveChecks{15}; dataStruct.BaseSetting = {}; end;
        if any([saveChecks{17:19}]); dataStruct.miniSetting = {}; end;
        if saveChecks{17}; dataStruct.miniFeatures = {}; end;
        if saveChecks{18}; dataStruct.miniTargets = {}; end;
        if saveChecks{19}; dataStruct.miniCoords = {}; end;
    else
        singleFile = false;
    end
    
    unAnalyzed = [];
    
    %Loop over cells
    for i=1:numel(viewNamesDrop.String)
        %Update status
        viewSaveStatus.String = ['Saving file:',num2str(i)];
        drawnow;
        %Get dataFile
        dataFile = matfile(...
            fullfile(dataPath{ephysDB(i)},'Data', [saveFltr{i,1},'.mat']),'Writable',true);
        dataTrace = dataFile.data; dataTrace = dataTrace(:,1);
        si = dataFile.si;
        if si>1; si = si*1e-6; end;
        
        if singleFile
            allFields = fieldnames(dataFile);
            dataStruct(i).filename = saveFltr{i,1};
            dataStruct(i).data = dataTrace;
            dataStruct(i).si = dataFile.si;
            if any(strcmp(allFields,'header'))
                dataStruct(i).header = dataFile.header;
            end
        else %See if we need to copy any files
            if ~isempty(regexp(viewSavePathEdit.String(end),'/|\','ONCE'))
                savePath = viewSavePathEdit.String(1:end-1);
            else
                savePath = viewSavePathEdit.String;
            end
            if ~strcmp(fullfile(dataPath{ephysDB(i)},'Data'),savePath)
                copyfile(fullfile(dataPath{ephysDB(i)},'Data', [saveFltr{i,1},'.mat']),...
                    fullfile(savePath, [saveFltr{i,1},'.mat']));
                dataFile = matfile(...
                    fullfile(savePath, [saveFltr{i,1},'.mat']),'Writable',true);
            end
        end
        %%
        %Check if we have to save mini things
        if any([saveChecks{17:19}])
            if ~isempty(miniSettings{i})
                %We have values continue
                if ~singleFile
                    dataFile.miniSetting = miniSettings{i};
                else
                    dataStruct(i).miniSetting = miniSettings{i};
                end
            end
        end
        if saveChecks{19} %Mini Coordinates
            if ~isempty(miniSettings{i})
                %Are we saving all or just marked
                if saveChecks{16}
                    %Just marked
                    saveCoords = miniCoords{i}(miniTargets{i}(:,1),:);
                else %Save all
                    saveCoords = miniCoords{i};
                end
                %We have values continue
                if ~singleFile
                    dataFile.miniCoords = saveCoords;
                else
                    dataStruct(i).miniCoords = saveCoords;
                end
                
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        %Check if we have to save Targets
        if saveChecks{18} %Mini Targets
            if ~isempty(miniSettings{i})
                %Are we saving all or just marked
                if saveChecks{16}
                    %Just marked
                    saveTargets = miniTargets{i}(miniTargets{i}(:,1),:);
                else %Save all
                    saveTargets = miniTargets{i};
                end
                %We have values continue
                if ~singleFile
                    dataFile.miniTargets = saveTargets;
                else
                    dataStruct(i).miniTargets = saveTargets;
                end
                
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        %Check if we have to save Features
        if saveChecks{17} %Mini Features
            if ~isempty(miniSettings{i})
                %Are we saving all or just marked
                if saveChecks{16}
                    %Just marked
                    saveFeatures = miniFeatures{i}(miniTargets{i}(:,1),:);
                else %Save all
                    saveFeatures = miniFeatures{i};
                end
                %We have values continue
                if ~singleFile
                    dataFile.miniFeatures = saveFeatures;
                else
                    dataStruct(i).miniFeatures = saveFeatures;
                end
                
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        %Check if we have to save Baseline
        if saveChecks{15} %Base settings
            if ~isempty(baselineValues{i}) &&...
                    nanmean(baselineValues{i}{2}(:,1)) > 0.025
                %We have values continue
                if ~singleFile
                    dataFile.BaseSetting = baselineValues{i};
                else
                    dataStruct(i).BaseSetting = baselineValues{i};
                end
                
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        %Check if we have artifacts
        if saveChecks{14}
            if ~isempty(artifactSettings{i})
                %We have values continue
                if ~singleFile
                    dataFile.ArtSetting = artifactSettings{i};
                else
                    dataStruct(i).ArtSetting = artifactSettings{i};
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        %Check if we have amplitude settings
        if saveChecks{13}
            if ~isempty(amplitudeSettings{i})
                %We have values continue
                if ~singleFile
                    dataFile.AmpSetting = amplitudeSettings{i};
                else
                    dataStruct(i).AmpSetting = amplitudeSettings{i};
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        %Check if we have charge settings
        if saveChecks{12}
            if ~isempty(chargeSettings{i})
                %We have values continue
                if ~singleFile
                    dataFile.ChargeSetting = chargeSettings{i};
                else
                    dataStruct(i).ChargeSetting = chargeSettings{i};
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        if saveChecks{11} %Actual baseline
            if ~isempty(baselineValues{i}) &&...
                    nanmean(baselineValues{i}{2}(:,1)) > 0.025
                %We have values continue
                baseline = viewCalculateBaseline...
                    (baselineValues{i},dataTrace,si);
                if ~singleFile
                    dataFile.Baseline = baseline;
                else
                    dataStruct(i).Baseline = baseline;
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        
        if saveChecks{10} %Start stops
            if ~isempty(artifactSettings{i})
                %We have values continue
                artIdx = cell(size(artifactSettings{i}));
                for v = 1:numel(artIdx)
                    [strts, stops] = viewGetArtifacts(dataTrace, si, artifactSettings{i}{v});
                    artIdx{v} = [strts, stops];
                end
                if ~singleFile
                    dataFile.ArtIdx = artIdx;
                else
                    dataStruct(i).ArtIdx = artIdx;
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        if saveChecks{9} %Amplitude Values
            if ~isempty(amplitudeSettings{i}) &&...
                    ~isempty(artifactSettings{i}) &&...
                    ~isempty(baselineValues{i})
                %We have values continue
                peaks = viewGetAmplitude(dataTrace, si, artifactSettings{i});
                
                corrPeaks = cell(1,size(peaks,1));
                for v = 1:size(peaks,1)
                    settings = {artifactSettings{i}{v},baselineValues{i}};
                    corrPeaks{v} = viewCorrectAmplitude(peaks{v,2},...
                        amplitudeSettings{i}(v),...
                        settings{amplitudeSettings{i}(v)},...
                        dataTrace, si);
                end
                
                if ~singleFile
                    dataFile.AmpValue = corrPeaks;
                else
                    dataStruct(i).AmpValue = corrPeaks;
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        if saveChecks{8} %Charge Values
            if ~isempty(chargeSettings{i}) &&...
                    ~isempty(artifactSettings{i}) &&...
                    ~isempty(baselineValues{i})
                %We have values continue
                artIdx = cell(size(artifactSettings{i}));
                for v = 1:numel(artIdx)
                    [strts, stops] = viewGetArtifacts(dataTrace, si, artifactSettings{i}{v});
                    artIdx{v} = [strts, stops];
                end
                baseline = viewCalculateBaseline...
                    (baselineValues{i},dataTrace,si);
                
                %Get pulse Widths
                pWidths = zeros(size(artifactSettings{i}));
                p=1;
                while p <= numel(artifactSettings{i})
                    if chargeSettings{i}(2,p) >= 3
                        pWidths(p) = chargeSettings{i}(2,p)-3;
                        if pWidths(p) > 1/artifactSettings{i}{p}(3)
                            pWidths(p) = 1/artifactSettings{i}{p}(3);
                        end
                    elseif chargeSettings{i}(2,p) == 2
                        allSettings = vertcat(artifactSettings{i}{:});
                        pWidths(:) = min(1./allSettings(:,3));
                        p= numel(artifactSettings{i});
                    elseif chargeSettings{i}(2,p) == 1
                        pWidths(p) = 1/artifactSettings{i}{p}(3);
                    end
                    p=p+1;
                end
                
                pulseCharge = cell(1,size(chargeSettings{i},2));
                for v = 1:numel(pWidths)
                    pulseCharge{v} = viewGetResponseCharge(...
                        chargeSettings{i}(1,v),pWidths(v),...
                        artIdx{v}, baseline, dataTrace, si);
                end
                
                if ~singleFile
                    dataFile.ChargeValue = pulseCharge;
                else
                    dataStruct(i).ChargeValue = pulseCharge;
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        if saveChecks{7} %Corrected trace
            if ~isempty(artifactSettings{i})
                %We have values continue
                artIdx = cell(size(artifactSettings{i}));
                for v = 1:numel(artIdx)
                    [strts, stops] = viewGetArtifacts(dataTrace, si, artifactSettings{i}{v});
                    artIdx{v} = [strts, stops];
                end
                
                corrTrace = viewInterpArtifacts(artIdx,dataTrace);
                
                if ~singleFile
                    dataFile.CorrTrace = corrTrace;
                else
                    dataStruct(i).CorrTrace = corrTrace;
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        if saveChecks{6} %Empty trace
            if ~isempty(artifactSettings{i})
                %We have values continue
                artIdx = cell(size(artifactSettings{i}));
                for v = 1:numel(artIdx)
                    [strts, stops] = viewGetArtifacts(dataTrace, si, artifactSettings{i}{v});
                    artIdx{v} = [strts, stops];
                end
                
                [~,emptyTrace] = viewInterpArtifacts(artIdx,dataTrace);
                
                if ~singleFile
                    dataFile.EmptyTrace = emptyTrace;
                else
                    dataStruct(i).EmptyTrace = emptyTrace;
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        if saveChecks{5} %Pred trace
            if ~isempty(artifactSettings{i})
                %We have values continue
                artIdx = cell(size(artifactSettings{i}));
                for v = 1:numel(artIdx)
                    [strts, stops] = viewGetArtifacts(dataTrace, si, artifactSettings{i}{v});
                    artIdx{v} = [strts, stops];
                end
                
                [~,~,predTrace] = viewInterpArtifacts(artIdx,dataTrace);
                
                if ~singleFile
                    dataFile.InterpTrace = predTrace;
                else
                    dataStruct(i).InterpTrace = predTrace;
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        if saveChecks{4} %Sync trace
            if ~isempty(chargeSettings{i}) &&...
                    ~isempty(artifactSettings{i}) &&...
                    ~isempty(baselineValues{i})
                %We have values continue
                artIdx = cell(size(artifactSettings{i}));
                for v = 1:numel(artIdx)
                    [strts, stops] = viewGetArtifacts(dataTrace, si, artifactSettings{i}{v});
                    artIdx{v} = [strts, stops];
                end
                baseline = viewCalculateBaseline...
                    (baselineValues{i},dataTrace,si);
                
                %Get pulse Widths
                pWidths = zeros(size(artifactSettings{i}));
                p=1;
                while p <= numel(artifactSettings{i})
                    if chargeSettings{i}(2,p) >= 3
                        pWidths(p) = chargeSettings{i}(2,p)-3;
                        if pWidths(p) > 1/artifactSettings{i}{p}(3)
                            pWidths(p) = 1/artifactSettings{i}{p}(3);
                        end
                    elseif chargeSettings{i}(2,p) == 2
                        allSettings = vertcat(artifactSettings{i}{:});
                        pWidths(:) = min(1./allSettings(:,3));
                        p= numel(artifactSettings{i});
                    elseif chargeSettings{i}(2,p) == 1
                        pWidths(p) = 1/artifactSettings{i}{p}(3);
                    end
                    p=p+1;
                end
                
                syncTrace = nan(size(dataTrace));
                for v = 1:numel(pWidths)
                    [~,tempTrace] = viewGetResponseCharge(...
                        chargeSettings{i}(1,v),pWidths(v),...
                        artIdx{v}, baseline, dataTrace, si);
                    syncTrace(~isnan(tempTrace)) = tempTrace(~isnan(tempTrace));
                end
                
                if ~singleFile
                    dataFile.SyncTrace = syncTrace;
                else
                    dataStruct(i).SyncTrace = syncTrace;
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        if saveChecks{3} %Raw amplitudes and index
            if ~isempty(artifactSettings{i})
                %We have values continue
                peaks = viewGetAmplitude(dataTrace, si, artifactSettings{i});
                
                if ~singleFile
                    dataFile.AmpIdx = peaks;
                else
                    dataStruct(i).AmpIdx = peaks;
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
        if saveChecks{2} %Charge Idx
            if ~isempty(chargeSettings{i}) &&...
                    ~isempty(artifactSettings{i}) &&...
                    ~isempty(baselineValues{i})
                %We have values continue
                artIdx = cell(size(artifactSettings{i}));
                for v = 1:numel(artIdx)
                    [strts, stops] = viewGetArtifacts(dataTrace, si, artifactSettings{i}{v});
                    artIdx{v} = [strts, stops];
                end
                baseline = viewCalculateBaseline...
                    (baselineValues{i},dataTrace,si);
                
                %Get pulse Widths
                pWidths = zeros(size(artifactSettings{i}));
                p=1;
                while p <= numel(artifactSettings{i})
                    if chargeSettings{i}(2,p) >= 3
                        pWidths(p) = chargeSettings{i}(2,p)-3;
                        if pWidths(p) > 1/artifactSettings{i}{p}(3)
                            pWidths(p) = 1/artifactSettings{i}{p}(3);
                        end
                    elseif chargeSettings{i}(2,p) == 2
                        allSettings = vertcat(artifactSettings{i}{:});
                        pWidths(:) = min(1./allSettings(:,3));
                        p= numel(artifactSettings{i});
                    elseif chargeSettings{i}(2,p) == 1
                        pWidths(p) = 1/artifactSettings{i}{p}(3);
                    end
                    p=p+1;
                end
                
                syncIdx = cell(size(pWidths));
                for v = 1:numel(pWidths)
                    [~,~,syncIdx{v}] = viewGetResponseCharge(...
                        chargeSettings{i}(1,v),pWidths(v),...
                        artIdx{v}, baseline, dataTrace, si);
                end
                
                if ~singleFile
                    dataFile.ChargeIdx = syncIdx;
                else
                    dataStruct(i).ChargeIdx = syncIdx;
                end
            else
                unAnalyzed(end+1) = i;
            end
        end
        
    end
    %%
    if singleFile
        save(fullfile(PathName,FileName),'dataStruct');
    end
    %Done
    if ~isempty(unAnalyzed)
        viewSaveStatus.String = 'Some unanalyzed files were not saved';
    else
        viewSaveStatus.String = 'Finished saving files';
    end
    %Save checks with current settings
    viewPath = fileparts(which('viewEPSC_GUI'));
    saveChecks = get(allChecks,'Value');
    save(fullfile(viewPath,'viewSaveSettings.mat'),'saveChecks');
end
end

function viewExport_Update(hObject,event)
%Get Objects
viewEPSC = findobj('Tag', 'viewEPSC');
viewNamesDrop = findobj('Tag','viewNamesDrop');
viewExportGUI = findobj('Tag','viewExportGUI');
viewExportPathEdit = findobj('Tag','viewExportPathEdit');
viewExportStatus = findobj('Tag','viewExportStatus');
allChecks = findobj(viewExportGUI,'Style','checkbox');
exportChecks = get(allChecks,'Value');
viewBlindCheck  =findobj('Tag','viewBlindCheck');

reBlind = false;
%unblind if necessary
if viewBlindCheck.Value
    viewBlindCheck.Value = false;
    viewEPSC_BlindFile(viewBlindCheck)
    reBlind = true;
end

%Get and set path
if strcmp(hObject.Tag,'viewExportPathSelect')
    %Set file
    [FileName, PathName]...
        = uiputfile('*.xlsx',...
        'Save Excel as...',viewExportPathEdit.String);
    if ~FileName
        %User canceled return
        return;
    else
        viewExportPathEdit.String = fullfile(PathName,FileName);
    end
elseif strcmp(hObject.Tag,'viewExportStatus') %First opened
    %Just opened check if we have setting files, otherwise make one
    viewPath = fileparts(which('viewEPSC_GUI'));
    if exist(fullfile(viewPath,'viewExportSettings.mat'),'file') == 2
        load(fullfile(viewPath,'viewExportSettings.mat'));
    else
        %Make with current settings
        save(fullfile(viewPath,'viewExportSettings.mat'),'exportChecks');
    end
    if numel(exportChecks) < numel(allChecks)
        %Old make with current settings
        save(fullfile(viewPath,'viewExportSettings.mat'),'exportChecks');
    end
    %Set checks
    for i = 1:numel(exportChecks)
        allChecks(i).Value = exportChecks{i};
    end
    
elseif strcmp(hObject.Tag,'viewExportCancel')
    %Nothing special this exit
    delete(viewExportGUI);
    return;
elseif strcmp(hObject.Tag,'viewExportExport')
    %% Perform Export:
    %Check if we have a path, if not get one
    if isempty(viewExportPathEdit.String)
        %Set file
        [FileName, PathName]...
            = uiputfile('*.xlsx',...
            'Save Excel as...',viewExportPathEdit.String);
        if ~FileName
            %User canceled return
            return;
        else
            viewExportPathEdit.String = fullfile(PathName,FileName);
        end
    end
    
    if ~any([exportChecks{:}])
        %Nothing selected return
        viewExportStatus.String = 'Please select at least one item to export';
        return
    end
    
    %Save current checks
    viewPath = fileparts(which('viewEPSC_GUI'));
    save(fullfile(viewPath,'viewExportSettings.mat'),'exportChecks');
    
    
    %Retrieve setting files
    baselineValues = getappdata(viewEPSC,'baselineValues');
    artifactSettings = getappdata(viewEPSC,'artifactSettings');
    amplitudeSettings = getappdata(viewEPSC, 'amplitudeSettings');
    chargeSettings = getappdata(viewEPSC, 'chargeSettings');
    ephysDB = getappdata(viewEPSC, 'ephysDB');
    dataPath = getappdata(viewEPSC, 'dataPath');
    
    %Initialize ExcelData
    excelData = {};
    excelSheet = {};
    
    flippedChecks = flipud(vertcat(exportChecks{:}));
    %Go through all the checks
    
    %Get sheet dimension
    pulseNum = cellfun(@(x) vertcat(x{:}),artifactSettings,...
        'UniformOutput', false);
    blockNum = cellfun(@(x) size(x,1),pulseNum);
    %Get max number of pulses in trace +2 empty spaces per extra
    %block
    pulseMax = [];
    for blck = 1:max(blockNum)
        pulseMax(end+1) = max(cellfun(@(x) x(blck,2),pulseNum(blockNum >= blck)));
    end
    %pulseMax = max(cellfun(@(x) sum(x(:,2))+2*(size(x,1)-1),pulseNum));
    
    %Generate pulse strings
    pText = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,1);
    idx = 2;
    for blck = 1:numel(pulseMax)
        bText = ['b',num2str(blck)];
        for p = 1:pulseMax(blck)
            pText(idx+p-1) = {[bText,'p',num2str(p)]};
        end
        idx = idx+sum(pulseMax(1:blck))+2*blck;
    end
    
    viewExportStatus.String = 'Retrieving data'; drawnow;
    %% CorrAmplitude
    if any(flippedChecks(1:4))
        %Get amplitude stuff
        [peakRaw, peakIdx, peakCorr] = viewGetAmplitude2(...
            viewNamesDrop.String, artifactSettings, amplitudeSettings,...
            baselineValues, dataPath, ephysDB);
        if flippedChecks(1)
            %Save corrected Peaks
            excelSheet(end+1) = {'Corrected Amplitude (pA)'};
            peakCorrX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            peakCorrX(1,2:end) = viewNamesDrop.String;
            peakCorrX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(peakCorr)
                idx = 2;
                for blck = 1:numel(peakCorr{c})
                    peakCorrX(idx:idx+numel(peakCorr{c}{blck})-1,c+1) =...
                        num2cell(peakCorr{c}{blck}(:));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {peakCorrX};
        end
        %% NormAmplitude
        if flippedChecks(2)
            %Save corrected Peaks
            excelSheet(end+1) = {'Normalized Amplitude'};
            peakNormX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            peakNormX(1,2:end) = viewNamesDrop.String;
            peakNormX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(peakCorr)
                idx = 2;
                for blck = 1:numel(peakCorr{c})
                    peakNormX(idx:idx+numel(peakCorr{c}{blck})-1,c+1) =...
                        num2cell(peakCorr{c}{blck}(:)/peakCorr{c}{1}(1));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {peakNormX};
        end
        %% RawAmplitude
        if flippedChecks(3)
            %Save corrected Peaks
            excelSheet(end+1) = {'Raw Amplitude (pA)'};
            peakRawX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            peakRawX(1,2:end) = viewNamesDrop.String;
            peakRawX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(peakCorr)
                idx = 2;
                for blck = 1:numel(peakCorr{c})
                    peakRawX(idx:idx+numel(peakRaw{c}{blck})-1,c+1) =...
                        num2cell(peakRaw{c}{blck}(:));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {peakRawX};
        end
        
        %% BaseAmplitude
        if flippedChecks(4)
            %Save corrected Peaks
            excelSheet(end+1) = {'Baseline at peak (pA)'};
            peakBaseX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            peakBaseX(1,2:end) = viewNamesDrop.String;
            peakBaseX(1:end,1) = pText;
            idx = 2;
            
            for c = 1:numel(peakCorr)
                filename = viewNamesDrop.String{c};
                cellPath = dataPath{ephysDB(c)};
                %Get data and si
                fileData = retrieveEphys(filename,'data',cellPath); fileData = fileData{1}(:,1);
                fileSI = retrieveEphys(filename,'si',cellPath); fileSI = fileSI{1};
                if fileSI > 1; fileSI = fileSI{1}*1e-6; end;
                cellBaseline = viewCalculateBaseline(...
                    baselineValues{c},fileData,fileSI);
                
                idx = 2;
                for blck = 1:numel(peakCorr{c})
                    peakBaseX(idx:idx+numel(peakRaw{c}{blck})-1,c+1) =...
                        num2cell(cellBaseline(peakIdx{c}{blck}(:)));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {peakBaseX};
        end
    end
    
    %% Charge
    if any(flippedChecks(5:end))
        %Get Charge
        pulseCharge = viewGetResponseCharge2(...
            viewNamesDrop.String, chargeSettings, artifactSettings,...
            baselineValues, dataPath, ephysDB);
        %% Sync
        if flippedChecks(5)
            %Save SynchronousCharge
            excelSheet(end+1) = {'Synchronous Charge (pC)'};
            syncChargeX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            syncChargeX(1,2:end) = viewNamesDrop.String;
            syncChargeX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(pulseCharge)
                idx = 2;
                for blck = 1:numel(pulseCharge{c})
                    syncChargeX(idx:idx+size(pulseCharge{c}{blck},1)-1,c+1) =...
                        num2cell(pulseCharge{c}{blck}(:,1));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {syncChargeX};
        end
        %% Sync percentage
        if flippedChecks(6)
            %Save SynchronousCharge
            excelSheet(end+1) = {'Synchronous (%)'};
            syncNormX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            syncNormX(1,2:end) = viewNamesDrop.String;
            syncNormX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(pulseCharge)
                idx = 2;
                for blck = 1:numel(pulseCharge{c})
                    syncNormX(idx:idx+size(pulseCharge{c}{blck},1)-1,c+1) =...
                        num2cell(pulseCharge{c}{blck}(:,1)./pulseCharge{c}{blck}(:,3)*100);
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {syncNormX};
        end
        %% Sync cumulative
        if flippedChecks(7)
            %Save SynchronousCharge
            excelSheet(end+1) = {'Cumulative Synchronous (pC)'};
            syncCumX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            syncCumX(1,2:end) = viewNamesDrop.String;
            syncCumX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(pulseCharge)
                idx = 2;
                for blck = 1:numel(pulseCharge{c})
                    syncCumX(idx:idx+size(pulseCharge{c}{blck},1)-1,c+1) =...
                        num2cell(cumsum(pulseCharge{c}{blck}(:,1)));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {syncCumX};
        end
        %% Async
        if flippedChecks(8)
            %Save ASynchronousCharge
            excelSheet(end+1) = {'Asynchronous Charge (pC)'};
            asyncChargeX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            asyncChargeX(1,2:end) = viewNamesDrop.String;
            asyncChargeX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(pulseCharge)
                idx = 2;
                for blck = 1:numel(pulseCharge{c})
                    asyncChargeX(idx:idx+size(pulseCharge{c}{blck},1)-1,c+1) =...
                        num2cell(pulseCharge{c}{blck}(:,2));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {asyncChargeX};
        end
        %% async percentage
        if flippedChecks(9)
            %Save asynchronousCharge
            excelSheet(end+1) = {'Asynchronous (%)'};
            asyncNormX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            asyncNormX(1,2:end) = viewNamesDrop.String;
            asyncNormX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(pulseCharge)
                idx = 2;
                for blck = 1:numel(pulseCharge{c})
                    asyncNormX(idx:idx+size(pulseCharge{c}{blck},1)-1,c+1) =...
                        num2cell(pulseCharge{c}{blck}(:,2)./pulseCharge{c}{blck}(:,3)*100);
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {asyncNormX};
        end
        %% async cumulative
        if flippedChecks(10)
            %Save asynchronousCharge
            excelSheet(end+1) = {'Cumulative Asynchronous (pC)'};
            asyncCumX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            asyncCumX(1,2:end) = viewNamesDrop.String;
            asyncCumX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(pulseCharge)
                idx = 2;
                for blck = 1:numel(pulseCharge{c})
                    asyncCumX(idx:idx+size(pulseCharge{c}{blck},1)-1,c+1) =...
                        num2cell(cumsum(pulseCharge{c}{blck}(:,2)));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {asyncCumX};
        end
        
        %% Total
        if flippedChecks(11)
            %Save TotalCharge
            excelSheet(end+1) = {'Total Charge (pC)'};
            totalChargeX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            totalChargeX(1,2:end) = viewNamesDrop.String;
            totalChargeX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(pulseCharge)
                idx = 2;
                for blck = 1:numel(pulseCharge{c})
                    totalChargeX(idx:idx+size(pulseCharge{c}{blck},1)-1,c+1) =...
                        num2cell(pulseCharge{c}{blck}(:,3));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {totalChargeX};
        end
        %% total normalized
        if flippedChecks(12)
            %Save TotalCharge
            excelSheet(end+1) = {'Normalized total Charge'};
            totalNormX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            totalNormX(1,2:end) = viewNamesDrop.String;
            totalNormX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(pulseCharge)
                idx = 2;
                for blck = 1:numel(pulseCharge{c})
                    totalNormX(idx:idx+size(pulseCharge{c}{blck},1)-1,c+1) =...
                        num2cell(pulseCharge{c}{blck}(:,3)./pulseCharge{c}{1}(1,3));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {totalNormX};
        end
        %% total cumulative
        if flippedChecks(13)
            %Save TotalCharge
            excelSheet(end+1) = {'Cumulative Total (pC)'};
            totalCumX = cell(sum(pulseMax)+2*(numel(pulseMax)-1)+1,...
                numel(artifactSettings)+1);
            %Initialize sheet
            totalCumX(1,2:end) = viewNamesDrop.String;
            totalCumX(1:end,1) = pText;
            idx = 2;
            for c = 1:numel(pulseCharge)
                idx = 2;
                for blck = 1:numel(pulseCharge{c})
                    totalCumX(idx:idx+size(pulseCharge{c}{blck},1)-1,c+1) =...
                        num2cell(cumsum(pulseCharge{c}{blck}(:,3)));
                    idx = 2+sum(pulseMax(1:blck))+2*blck;
                end
            end
            excelData(end+1) = {totalCumX};
        end
    end
    
    %% Export Excel
    for sheet = 1:numel(excelData)
        viewExportStatus.String = ['Writing sheet: ',num2str(sheet)]; drawnow;
        
        xlswrite(viewExportPathEdit.String,excelData{sheet},excelSheet{sheet});
    end
    viewExportStatus.String = 'Finished writing Excel sheet';
end

if reBlind
    viewBlindCheck.Value = true;
    viewEPSC_BlindFile(viewBlindCheck)
end
end

%Blind cells
function viewEPSC_BlindFile(hObject,event)
viewEPSC = findobj('Tag', 'viewEPSC');
viewNamesDrop = findobj('Tag','viewNamesDrop');
dataFltr = getappdata(viewEPSC,'ephysFltr');
ephysDB = getappdata(viewEPSC,'ephysDB');


if hObject.Value
    %Blind files
    if isempty(hObject.UserData) ||...
            numel(hObject.UserData{1}) ~= numel(viewNamesDrop.String)
        %New blind or n files changed
        blindOrder = randperm(numel(viewNamesDrop.String));
        [~,unblindOrder] = sort(blindOrder);
        hObject.UserData{1} = blindOrder;
        hObject.UserData{2} = unblindOrder;
    else
        blindOrder = hObject.UserData{1};
        unblindOrder = hObject.UserData{2};
    end
    hObject.UserData{3} = viewNamesDrop.String;
    
    baselineValues = getappdata(viewEPSC,'baselineValues');
    baselineValue = baselineValues{viewNamesDrop.Value};
    artifactSettings = getappdata(viewEPSC,'artifactSettings');
    artifactSetting = artifactSettings{viewNamesDrop.Value};
    amplitudeSettings = getappdata(viewEPSC,'amplitudeSettings');
    amplitudeSetting = amplitudeSettings{viewNamesDrop.Value};
    chargeSettings = getappdata(viewEPSC,'chargeSettings');
    chargeSetting = chargeSettings{viewNamesDrop.Value};
    miniSettings = getappdata(viewEPSC,'miniSettings');
    miniSetting = miniSettings{viewNamesDrop.Value};
    
    %Sort data
    dataObj = {'ephysFltr','ephysDB','baselineValues','artifactSettings',...
        'amplitudeSettings','amplitudeSettings','chargeSettings','miniSettings',...
        'miniCoords','miniFeatures','miniTargets'};
    for ii = 1:numel(dataObj)
        sortObj = getappdata(viewEPSC,dataObj{ii});
        sortObj = sortObj(blindOrder,:);
        setappdata(viewEPSC,dataObj{ii},sortObj);
    end
    viewNamesDrop.String = cellfun(@num2str,...
        num2cell(1:numel(viewNamesDrop.String)),'UniformOutput',false);
    viewNamesDrop.Value = unblindOrder(viewNamesDrop.Value);
    
else
    %unblind files
    blindOrder = hObject.UserData{1};
    unblindOrder = hObject.UserData{2};
    
    %Sort data
    dataObj = {'ephysFltr','ephysDB','baselineValues','artifactSettings',...
        'amplitudeSettings','amplitudeSettings','chargeSettings','miniSettings',...
        'miniCoords','miniFeatures','miniTargets'};
    for ii = 1:numel(dataObj)
        sortObj = getappdata(viewEPSC,dataObj{ii});
        sortObj = sortObj(unblindOrder,:);
        setappdata(viewEPSC,dataObj{ii},sortObj);
    end
    
    viewNamesDrop.String = hObject.UserData{3};
    viewNamesDrop.Value = blindOrder(viewNamesDrop.Value);
end
if nargin == 2
    viewEPSC_Plot;
end
end

function viewCloseRequest(hObject,event)
yes = questdlg('Quit viewEPSC? Did you save everything?');
if strcmp(yes,'Yes')
    %Close all subsidiary windows first
    window = {};
    window{end+1} = findobj('Tag','viewAmplitudeGUI');
    window{end+1} = findobj('Tag','viewBaselineGUI');
    window{end+1} = findobj('Tag','viewArtifactsGUI');
    window{end+1} = findobj('Tag','viewChargeGUI');
    window{end+1} = findobj('Tag','viewSaveGUI');
    window{end+1} = findobj('Tag','viewMiniGUI');
    window{end+1} = findobj('Tag','viewANNGUI');
    window{end+1} = findobj('Tag','viewEPSC');
    
    for i = 1:numel(window)
        if ~isempty(window{i})
            delete(window{i});
        end
    end
    munlock; clear;
end
end
