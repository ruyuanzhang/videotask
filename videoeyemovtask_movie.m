% This is the experiment program for the video task on intracranial patients . This
% project is conducted by Ruyuan Zhang (RZ). Ben Hayden and Ruyuan Zhang conceptualize and
% design the experiment.
%
% The basic idea is to record patient's eye movement during a movie
%
% History:
%   20180804 RZ created


%% 
clear all; close all; clc;

sp.subj = 99;  % 99 test,
sp.runNo = 3;  % 

addpath(genpath('./utils'));

%% debug purpose
sp.wanteyelink = 'test.edf'; % use eyeTracking if not empty;
sp.psylab = 1;
%sp.videoFile = '/Users/ruyuan/Documents/Code_git/samplevideo/Interstellar - Ending Scene 1080p HD.mp4'; % the path of the video, we can read
if sp.psylab 
    sp.videoFile = '/Users/psphuser/Desktop/RuyuanZhang/samplevideo/Interstellar - Ending Scene 1080p HD.mp4'; % the path of the video, we can read
    mp = getmonitorparams('cmrrpsphlab');
    sp.deviceNum = 3; % devicenumber to record input
else
    sp.videoFile = '/Users/ruyuan/Documents/Code_git/samplevideo/Interstellar - Ending Scene 1080p HD.mp4'; % the path of the video, we can read
    mp = getmonitorparams('uminnmacpro');
    sp.deviceNum = 1; % devicenumber to record input
end

%mp = getmonitorparams('uminn7tpsboldscreen');
%mp = getmonitorparams('uminnofficedesk');
sp.respKeys = {'1!','2@'};

%% monitor parameter (mp)
%mp = getmonitorparams('uminn7tpsboldscreen');
mp.monitorRect = [0 0 mp.resolution(1) mp.resolution(2)];

%% stimulus parameters (sp)
sp.expName = 'videoeyemov';
sp.nFrames = 2400; % how many total movie frames
sp.frameRate = 24; % how many image frame to play per Secs, note this is not monitor refresh_rate
sp.windowSizeDeg = [10, 8]; % visual deg for width, height

sp.COLOR_GRAY = 127;
sp.COLOR_BLACK = 0;
sp.COLOR_WHITE = 254;
% do some calculation
sp.windowSizePix = round(sp.windowSizeDeg*mp.pixPerDeg(1));
sp.movieRect = CenterRect([0, 0, sp.windowSizePix(1), sp.windowSizePix(1)], mp.monitorRect);
sp.secsPerFrame = 1/sp.frameRate; % secs per image frame
mp.monitorRect = [0 0 mp.resolution(1) mp.resolution(2)];
% make a random movie
%% MRI related preparation
% some auxillary variables
sp.timeKeys = {};
sp.triggerKey = '5'; % the key to start the experiment
sp.timeFrames=zeros(1,sp.nFrames);
sp.allowedKeys = zeros(1, 256);
sp.allowedKeys([20 41 30:34 89:93 79:80]) = 1;  %20,'q';41,'esc';89-93,'1'-'5';30-34, mackeyboard 1-5; 79-80, right/left keys
getOutEarly = 0;
when = 0;
glitchcnt = 0;
%kbQueuecheck setup
KbQueueCreate(sp.deviceNum,sp.allowedKeys);

%% open the window get information about the PT setup
oldclut = pton([],[],[],1);
win = firstel(Screen('Windows'));
winRect = Screen('Rect',win);
Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
mfi = Screen('GetFlipInterval',win);  % re-use what was found upon initialization!

%% wait for a key press to start, start to show stimulus
Screen('FillRect',win,sp.COLOR_BLACK,winRect);
Screen('TextSize',win,30);Screen('TextFont',win,'Arial');
Screen('DrawText', win, 'Press 5 to start, can press ESC to exit during the movie ...',winRect(3)/2-550, winRect(4)/2-50, 127);
Screen('Flip',win);
fprintf('Press the trigger key to begin the movie. (make sure to turn off network, energy saver, spotlight, software updates! mirror mode on!)\n');
safemode = 0;
tic;
while 1
  [secs,keyCode,deltaSecs] = KbWait(-3, 2);
  temp = KbName(keyCode);
  if isequal(temp(1),'=')
    if safemode
      safemode = 0;
      fprintf('SAFE MODE OFF (the scan can start now).\n');
    else
      safemode = 1;
      fprintf('SAFE MODE ON (the scan will not start).\n');
    end
  else
    if safemode
    else
      if isempty(sp.triggerKey) || isequal(temp(1),sp.triggerKey)
        break;
      end
    end
  end
end
fprintf('Experiment starts!\n');
Screen('Flip',win);
% issue the trigger and record it

%% initialize, setup, calibrate, and start eyelink
if sp.wanteyelink
  assert(EyelinkInit()==1);
  win = firstel(Screen('Windows'));
  el = EyelinkInitDefaults(win);
  [wwidth,wheight] = Screen('WindowSize',win);  % returns in pixels
  fprintf('Pixel size of window is width: %d, height: %d.\n',wwidth,wheight);
  Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld',0,0,wwidth-1,wheight-1);
  Eyelink('message','DISPLAY_COORDS %ld %ld %ld %ld',0,0,wwidth-1,wheight-1);
  Eyelink('command','calibration_type = HV5');
  Eyelink('command','active_eye = LEFT');
  Eyelink('command','automatic_calibration_pacing=1500');
    % what events (columns) are recorded in EDF:
  Eyelink('command','file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    % what samples (columns) are recorded in EDF:
  Eyelink('command','file_sample_data = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');
    % events available for real time:
  Eyelink('command','link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    % samples available for real time:
  Eyelink('command','link_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');
  temp = regexp(datestr(now),'.+ (\d+):(\d+):(\d+)','tokens');  % HHMMSS    [or datestr(now,'HHMMSS') !]
  eyetempfile = sprintf('%s.edf',cat(2,temp{1}{:}));
  fprintf('Saving eyetracking data to %s.\n',eyetempfile);
  Eyelink('Openfile',eyetempfile);  % NOTE THIS TEMPORARY FILENAME. REMEMBER THAT EYELINK REQUIRES SHORT FILENAME!
  fprintf('Please perform calibration. When done, the subject should press a button in order to proceed.\n');
  EyelinkDoTrackerSetup(el);
%  EyelinkDoDriftCorrection(el);
  fprintf('Button detected from subject. Starting recording of eyetracking data. Proceeding to stimulus setup.\n');
  Eyelink('StartRecording');
  % note that we expect that something should probably issue the command:
  %   Eyelink('Message','SYNCTIME');
  % before we close out the eyelink.
end
Screen('FillRect',win,sp.COLOR_BLACK,winRect);
Screen('Flip',win);
%% now run the experiment
% get trigger
KbQueueStart(sp.deviceNum);
%%
% open the movie
[moviePtr,dur,fps,width,height,count,aspectRatio] = Screen('OpenMovie',win, sp.videoFile);

% now play the movie
tic
% send the trigger Here!
Screen('PlayMovie',moviePtr, 1);
% send the trigger Here!

% Playback loop: Runs until end of movie or keypress:
while 1
    if getOutEarly
       break;
    end
    [keyIsDown,secs] = KbQueueCheck(sp.deviceNum);  % only check 'q','esc'
    if keyIsDown
        % get the name of the key and record it
        kn = KbName(secs);
        sp.timeKeys = [sp.timeKeys; {secs(find(secs)) kn}];
        % check if ESCAPE was pressed
        if isequal(kn,'ESCAPE')
            fprintf('Escape key detected.  Exiting prematurely.\n');
            getOutEarly = 1;
            break;
        end
        
    end
    
    % Wait for next movie frame, retrieve texture handle to it
    tex = Screen('GetMovieImage', win, moviePtr);
    
    % Valid texture returned? A negative value means end of movie reached:
    if tex<=0
        % We're done, break out of loop:
        break;
    end
    
    % Draw the new texture immediately to screen:
    Screen('DrawTexture', win, tex);
    
    % Update display:
    Screen('Flip', win);
    
    % Release texture:
    Screen('Close', tex);
end
toc

% Stop playback:
Screen('PlayMovie', moviePtr, 0);

% now close the movie
Screen('CloseMovie', moviePtr);


%% clean up and save data
c = fix(clock);
filename=sprintf('%d%02d%02d%02d%02d%02d_exp%s_subj%02d_run%02d',c(1),c(2),c(3),c(4),c(5),c(6),sp.expName,sp.subj,sp.runNo);
%% close out eyelink
if sp.wanteyelink)
  Eyelink('StopRecording');
  Eyelink('CloseFile');
  Eyelink('ReceiveFile');
  Eyelink('ShutDown');
  movefile(eyetempfile,[filename,'edf']);  % RENAME DOWNLOADED FILE TO THE FINAL FILENAME
end
ptoff(oldclut);

%% clean up and save data
rmpath(genpath('./utils'));  % remove the utils path
save(filename); % save everything to the file;
