% Clear the workspace
sca;
close all;
clearvars;

%Specify directories
cd('C:\Users\Richy\Desktop\PTB\Memieeg')
cf = pwd;
save_data = fullfile(cf,'data','behav_data');
block_data = fullfile(cf,'data','sub_lists');
face_folder = fullfile(cf,'stimuli','faces');
object_folder = fullfile(cf,'stimuli','objects');

%% Specify time intervals in seconds

encoding_time = 1.5;
elaborate_time = 3;

rest_time = 5;

fc_time = 4;
retrieval_time = 4;

% fixation cross limits
low_lim = 0.5;
upp_lim = 0.75;
%% Specify Image Dimensions

% Image Size
[s1, s2, s3, s4] = deal(300);

% Scale the images if needed to fit within the screen
scaleFactor = 1; % no scaling
s1 = s1 * scaleFactor;
s2 = s2 * scaleFactor;
s3 = s3 * scaleFactor;
s4 = s4 * scaleFactor;

% Gap between the images
gap = 200;

% Define rectangles for the images
rect1 = [0 0 s2 s1];
rect2 = [0 0 s4 s3];

%% Request Subject information

prompt = {'Enter Subject ID (should be: 01,02,03, etc.)','Enter Block Number (should be: 00 (practice),01,02,03,etc.)'};
defInput = {'001','1'};
answer = inputdlg(prompt, 'Subject Info', [1 50], defInput);
if isempty(answer)
    return;
end
subID = answer{1};
subID = ['S' subID];
blockID = answer{2};

% Make Folder to store subjects data
sub_folder = fullfile(save_data,subID);
if ~exist(sub_folder)
    mkdir(sub_folder)
end

%Chek if data for that block exist, if the data exist throw an error message
name2save = [subID '_Block_' blockID '.csv'];
name2save = fullfile(sub_folder,name2save);

if isfile(name2save)
    error('Data for that block alredy exists',':^(');
end

%% Load block order from csv file

block_file = fullfile(block_data,subID, [subID '_' blockID '.csv']);
[~,~,csv] = xlsread(block_file);
dim_names = {csv(1,:)};
csv = cell2struct(csv,dim_names{1, 1},2);
csv = csv(2:end);
trial_type = {csv(:).trial_type};
% Trial numbers
n_encoding = sum(~cellfun('isempty', strfind(trial_type, 'Encoding')));
n_retrieval = sum(~cellfun('isempty', strfind(trial_type, 'Retrieval')));
n_trials = n_encoding + n_retrieval;

%% Extract stimuli order from csv file
% Encoding
enc_face_order = {csv(:).target};
enc_face_order = enc_face_order(1:n_encoding)';

enc_object_order = {csv(:).object};
enc_object_order = enc_object_order(1:n_encoding)';

enc_baseline_order = {csv(:).baseline};
enc_baseline_order = cell2mat(enc_baseline_order(1:n_encoding)');

% Retrieval order
ret_face_order = {csv(:).target};
ret_face_order = ret_face_order((n_encoding + 1):end)';

ret_object_order = {csv(:).object};
ret_object_order = ret_object_order((n_encoding + 1):end)';

ret_lure1_order = {csv(:).lure1};
ret_lure1_order = ret_lure1_order((n_encoding + 1):end)';

ret_lure2_order = {csv(:).lure2};
ret_lure2_order = ret_lure2_order((n_encoding + 1):end)';

ret_type_order = {csv(:).retrieval_type};
ret_type_order = ret_type_order((n_encoding + 1):end)';

ret_baseline_order = {csv(:).baseline};
ret_baseline_order = cell2mat(ret_baseline_order((n_encoding + 1):end)');

%% Add fields to the csv to store the data

csv(1).encoding_onset =  [];
csv(1).encoding_end =  [];
csv(1).elaborate_onset=  [];
csv(1).elaborate_end =  [];
csv(1).elaborate_response =  [];
csv(1).elaborate_rt =  [];
csv(1).fc_onset =  [];
csv(1).fc_end =  [];
csv(1).fc_response =  [];
csv(1).fc_rt =  [];
csv(1).recall_onset=  [];
csv(1).recall_end =  [];
csv(1).recall_response =  [];
csv(1).recall_rt =  [];

%% Start PTB
% Set Screen Parameters
%make sure computer has correct psychtoolbox for task
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1); % <-remove me?
%select external screen if possible
screens = Screen('Screens');
dispScreen = max(screens);
%dispScreen = 1; %% DELETE LATER

% Define black and white
black = BlackIndex(dispScreen);
white = WhiteIndex(dispScreen);

%open screen and get size parameters
[windowPtr, rect] = Screen('OpenWindow',dispScreen,[255 255 255]); % [%[0,0,1024,768]
Screen('BlendFunction', windowPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Get the size of the on screen window in pixels
[maxWidth, maxHeight] = Screen('WindowSize', windowPtr);

%get flip interval
ifi = Screen('GetFlipInterval', windowPtr);

% Get the centre coordinate of the window in pixels
[xCenter, yCenter] = RectCenter(rect);

%Set Defaults
fontDefault = 40;
Screen('TextSize',windowPtr,fontDefault);
Screen('TextFont',windowPtr,'Arial');

%cursor and keypress stuff
%HideCursor;
ListenChar(1);

% see http://psychtoolbox.org/docs/MaxPriority. This was coded on mac osx
Priority(MaxPriority(windowPtr));

%Prepare key press listeners
KbName('UnifyKeyNames');
num_1 = KbName('1');
num_2 = KbName('2');
num_3 = KbName('3');
num_4 = KbName('4');
escape = KbName('ESCAPE'); %escape key (to exit experiment)
RestrictKeysForKbCheck([]); %ensure all keypresses are tracked


%% Specify circle for photodiode
baseCircleDiam = 75;
baseCircle = [0 0 baseCircleDiam baseCircleDiam];
centeredCircle = CenterRectOnPointd(baseCircle, maxWidth-0.5*baseCircleDiam, 1+0.5*baseCircleDiam); %
circleColor1 = [white white white]; % white
circleColor2 = [black black black]; % black

%% Start Task
% Set up the experiment
c = clock; %Current date and time as date vector. [year month day hour minute seconds]
time = strcat(num2str(c(1)),'_',num2str(c(2)),'_',num2str(c(3)),'_',num2str(c(4)),'_',num2str(c(5))); %makes unique filename
taskStartTime = GetSecs; % time experiment starts

%% Set Trial (remove after generate the loop)
trial_idx = 1;

%% Encoding Loop
%Read Stimuli
trial_face = imread(fullfile(face_folder, [enc_face_order{trial_idx,1} '.png']));
face_name = enc_face_order{trial_idx,1};
trial_face = Screen('MakeTexture', windowPtr, trial_face);
trial_object = imread(fullfile(object_folder, [enc_object_order{trial_idx,1} '_exemplar1.jpg']));
trial_object = Screen('MakeTexture', windowPtr, trial_object);

% Calculate positions for the images
xPos1 = (maxWidth - s2 - s4 - gap) / 2;
xPos2 = xPos1 + s2 + gap;
yPos = (maxHeight - s1) / 2;
yPositionLabel = yPos + s3 / 2 + 210; % Position below the right image

% Center the rectangles on the calculated positions
dstRect1 = CenterRectOnPointd(rect1, xPos1 + s2 / 2, yPos + s1 / 2);
dstRect2 = CenterRectOnPointd(rect2, xPos2 + s4 / 2, yPos + s3 / 2);

% Baseline White Screen
baseline_time =enc_baseline_order(trial_idx,1);
stimFlipFrames = round(baseline_time/ifi);
frameCount = 1;

while frameCount <= stimFlipFrames
    Screen('Flip', windowPtr);
    frameCount = frameCount + 1;
end


% Encoding Period
stimFlipFrames = round(encoding_time/ifi);
flipTimes = zeros(1,stimFlipFrames);
frameCount = 1;

while frameCount <= stimFlipFrames
    Screen('DrawTexture', windowPtr, trial_object, [], dstRect1);
    Screen('DrawTexture', windowPtr, trial_face, [], dstRect2);
    DrawFormattedText(windowPtr, face_name, 'center', yPositionLabel, black, [], [], [], [], [], dstRect2);
    if frameCount <= 3
        Screen('FillOval', windowPtr, circleColor2, centeredCircle, baseCircleDiam);
    end
    frameCount = frameCount + 1;
    flipTimes(1,frameCount) = Screen('Flip',windowPtr);
end

encoding_Onset = flipTimes(1) - taskStartTime;
encoding_End = flipTimes(end) - taskStartTime;

% Fixation Cross
fix_duration = round( low_lim + (upp_lim - low_lim) * rand,2);
stimFlipFrames = round(fix_duration/ifi);
frameCount = 1;

while frameCount <= stimFlipFrames
    %DrawFormattedText(windowPtr, '+', 'center', 'center', black);
    Screen('Flip', windowPtr);
    frameCount = frameCount + 1;
end

% Elaborate Phase
stimFlipFrames = round(elaborate_time/ifi);
flipTimes = zeros(1,stimFlipFrames);
frameCount = 1;
keyPressed = 0;
responses = zeros(stimFlipFrames,3);

while frameCount <= stimFlipFrames
    DrawFormattedText(windowPtr, 'Imagine', 'center', maxHeight * 0.2, black);
    DrawFormattedText(windowPtr, '+', 'center', 'center', black);
    
    if frameCount <= 3
        Screen('FillOval', windowPtr, circleColor2, centeredCircle, baseCircleDiam);
    end
    
    numbers = {'1', '2', '3', '4'};
    label = {{{'No'} {'Image'}} {{'Low'} {'Vivid'}}  {{'Mid'} {'Vivid'}}  {{'High'} {'Vivid'}}};
    spacing = maxWidth / 5;
    yPositionNumbers = maxHeight * 2 / 2.5;
    yPositionLabels = yPositionNumbers + 50;
    
    for i = 1:length(numbers)
        xPosition = i * spacing;
        DrawFormattedText(windowPtr, numbers{i}, xPosition, yPositionNumbers, black);
        DrawFormattedText(windowPtr, [label{i}{1}{1} newline  label{i}{2}{1}], xPosition, yPositionLabels, black);
    end
    
    
    [keyPressed,respOnset,keyCode] = KbCheck;
    
    if keyPressed
        responses(frameCount,:) = [keyPressed,respOnset,find(keyCode)];
    end
    
    frameCount = frameCount + 1;
    flipTimes(1,frameCount) = Screen('Flip',windowPtr);
    
end


elaborate_Onset = flipTimes(1) - taskStartTime;
elaborate_End = flipTimes(end) - taskStartTime;

%Save response and RT
[row,col] = find(responses,1,'last');
choice = KbName(responses(row,3));
response_time = responses(row,2) - taskStartTime;

% save data
csv(trial_idx).encoding_onset =  encoding_Onset;
csv(trial_idx).encoding_end =  encoding_End;
csv(trial_idx).elaborate_onset=  elaborate_Onset;
csv(trial_idx).elaborate_end =  elaborate_End;
csv(trial_idx).elaborate_response =  choice;
csv(trial_idx).elaborate_rt =  response_time;


%% Rest Between Phases

stimFlipFrames = round(rest_time/ifi);
second = round(1/ifi);
frameCount = 1;

while frameCount <= stimFlipFrames
    curr_frames = stimFlipFrames - frameCount;
    curr_time = round(curr_frames/second);
    DrawFormattedText(windowPtr, ['You can take a short rest.' newline newline 'The memory task will start in: ' num2str(curr_time) ' seconds'], 'center', 'center', black);
    Screen('Flip', windowPtr);
    frameCount = frameCount + 1;
end

%% Retrieval Trial

%Read Stimuli
row_iterator = trial_idx + n_encoding;
retrieval_type = ret_type_order{trial_idx,1};
trial_object = imread(fullfile(object_folder, [ret_object_order{trial_idx,1} '_exemplar1.jpg']));
trial_object = Screen('MakeTexture', windowPtr, trial_object);

trial_target = ret_face_order{trial_idx,1};
trial_lure1 = ret_lure1_order{trial_idx,1};
trial_lure2 = ret_lure2_order{trial_idx,1};
options = {trial_target trial_lure1 trial_lure2};
options = options(randperm(length(options)));

if strcmp(retrieval_type,'Retrieval')
    corr_resp = find(contains(options,trial_target));
elseif strcmp(retrieval_type,'Lure')
    corr_resp = 4;
end

for i = 1:length(options)
    word = options{i} ;
    spaceIndex = strfind(word, ' ');
    beforeSpace = word(1:spaceIndex-1);
    afterSpace = word(spaceIndex+1:end);
    options{i} = {beforeSpace afterSpace};
end

options{1,4} = {'New', ''};

% Calculate positions for the images
xPos1 = (maxWidth - s2 - s4 - gap) / 2;
xPos2 = xPos1 + s2 + gap;
yPos = (maxHeight - s1) / 2;
% Center the rectangles on the calculated positions
dstRect1 = CenterRectOnPointd(rect1, xPos1 + s2 / 2, yPos + s1 / 2);

% Baseline White Screen
baseline_time =ret_baseline_order(trial_idx,1);
stimFlipFrames = round(baseline_time/ifi);
frameCount = 1;

while frameCount <= stimFlipFrames
    Screen('Flip', windowPtr);
    frameCount = frameCount + 1;
end


% Force Choice

% Present the numbers 1, 2, 3, and 4 below the images with 'number' below each number
space_breaks = 4;
numbers = {'  1', '  2', '  3', '  4'};
spacing = (maxWidth / space_breaks);
yPositionNumbers = yPos + s1 / 2 + 220;
yPositionLabels = yPositionNumbers + 75;

stimFlipFrames = round(fc_time/ifi);
flipTimes = zeros(1,stimFlipFrames);
frameCount = 1;
keyPressed = 0;
responses = zeros(stimFlipFrames,3);


while frameCount <= stimFlipFrames
    
    if frameCount <= 3
        Screen('FillOval', windowPtr, circleColor2, centeredCircle, baseCircleDiam);
    end
    
    for i = 1:length(numbers)
        xPosition = (i * spacing) - spacing/1.5;
        DrawFormattedText(windowPtr, numbers{i}, xPosition, yPositionNumbers, black);
        DrawFormattedText(windowPtr, [options{i}{1} newline  options{i}{2}], xPosition, yPositionLabels, black);
    end
    
    
    % Draw the textures on the screen
    Screen('DrawTexture', windowPtr, trial_object, [], dstRect1);
    
    [keyPressed,respOnset,keyCode] = KbCheck;
    
    if keyPressed
        responses(frameCount,:) = [keyPressed,respOnset,find(keyCode)];
    end
    
    frameCount = frameCount + 1;
    flipTimes(1,frameCount) = Screen('Flip',windowPtr);
end

fc_Onset = flipTimes(1) - taskStartTime;
fc_End = flipTimes(end) - taskStartTime;

% save force choice response
[row,col] = find(responses,1,'last');
fc_choice = KbName(responses(row,3));
fc_response_time = responses(row,2) - taskStartTime;

csv(row_iterator).fc_onset =  fc_Onset;
csv(row_iterator).fc_end =  fc_End;
csv(row_iterator).fc_response =  fc_choice;
csv(row_iterator).fc_rt =  fc_response_time;

% Fixation Cross
fix_duration = round( low_lim + (upp_lim - low_lim) * rand,2);
stimFlipFrames = round(fix_duration/ifi);
frameCount = 1;

while frameCount <= stimFlipFrames
    %DrawFormattedText(windowPtr, '+', 'center', 'center', black);
    Screen('Flip', windowPtr);
    frameCount = frameCount + 1;
end

% Remember Phase
stimFlipFrames = round(retrieval_time/ifi);
flipTimes = zeros(1,stimFlipFrames);
frameCount = 1;
keyPressed = 0;
responses = zeros(stimFlipFrames,3);
keyPressed = 0;

numbers = {'1', '2', '3', '4'};
label = {{{'No'} {'Image'}} {{'Low'} {'Vivid'}}  {{'Mid'} {'Vivid'}}  {{'High'} {'Vivid'}}};
spacing = maxWidth / 5;
yPositionNumbers = maxHeight * 2 / 2.5;
yPositionLabels = yPositionNumbers + 50;

while frameCount <= stimFlipFrames
    
    if frameCount <= 3
        Screen('FillOval', windowPtr, circleColor2, centeredCircle, baseCircleDiam);
    end
    
    % Second part
    DrawFormattedText(windowPtr, 'Recall', 'center', maxHeight * 0.2, black);
    DrawFormattedText(windowPtr, '+', 'center', 'center', black);
    
    for i = 1:length(numbers)
        xPosition = i * spacing;
        DrawFormattedText(windowPtr, numbers{i}, xPosition, yPositionNumbers, black);
        DrawFormattedText(windowPtr, [label{i}{1}{1} newline  label{i}{2}{1}], xPosition, yPositionLabels, black);
    end
    
    [keyPressed,respOnset,keyCode] = KbCheck;
    
    if keyPressed
        responses(frameCount,:) = [keyPressed,respOnset,find(keyCode)];
    end
    
    frameCount = frameCount + 1;
    flipTimes(1,frameCount) = Screen('Flip',windowPtr);
    
    
end

recall_Onset = flipTimes(1) - taskStartTime;
recall_End = flipTimes(end) - taskStartTime;

% Save recall responses
[row,col] = find(responses,1,'last');
recall_choice = KbName(responses(row,3));
recall_response_time = responses(row,2) - taskStartTime;

% save data

csv(row_iterator).recall_onset=  recall_Onset;
csv(row_iterator).recall_end =  recall_End;
csv(row_iterator).recall_response =  recall_choice;
csv(row_iterator).recall_rt =  recall_response_time;


%% Loop End (here the loop ends, before saving the data
csv = struct2table(csv);
writetable(csv,name2save);
Screen('CloseAll');
%%









