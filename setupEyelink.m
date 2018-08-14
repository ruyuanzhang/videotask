function setupEyelink(win,eyetempfile)
if exist('var','win')||isempty(win)
    win = firstel(Screen('Windows'));
end
if exist('var','eyetempfile')||isempty(eyetempfile)
    temp = regexp(datestr(now),'.+ (\d+):(\d+):(\d+)','tokens');  % HHMMSS    [or datestr(now,'HHMMSS') !]
    eyetempfile = sprintf('%s.edf',cat(2,temp{1}{:}));
end

assert(EyelinkInit()==1);
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