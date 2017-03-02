%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RC-TD task (returns discount rates)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TRIALS = td_rc_v8a (TRIALS, window, width, height)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set some PTB parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
centerx = width/2;
centery = height/2;
ifi = Screen('GetFlipInterval', window);
slack = ifi/2;
grey = [128 128 128]; %pixel value for grey
KbName('UnifyKeyNames'); % Unify key names
fKey = KbName('f');
jKey = KbName('j');
cKey = KbName('c');
escapeKey = KbName('ESCAPE');

if ismac
    defaultFont = 'Helvetica';
    fontSize = 35;
else
    defaultFont = 'Arial';
    Screen('TextStyle',window,0);
    fontSize = 35;
end

Screen('TextFont',window, defaultFont);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set some task parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MAX_NUM_TRIALS = size(TRIALS,1);
THRESHOLDS = unique(TRIALS(:,8));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up FAST algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
faststruc = fastFull(0, ...
    'funcHyperbolic', ...
    'psyLogistic', ...
    {[.001 1], [0.001 1]}, ...
    {[0 1], [0 1]});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% trial loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
task_onset = GetSecs;
post_fix_onset = task_onset;

t = 0;
go = 1;
while go
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Increment trial counter
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    t = t + 1;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% fixation cross
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fix_duration = TRIALS(t,3);
    
    Screen(window, 'FillRect', grey);
    Screen('DrawLine', window, [0 0 0], width/2, height/2-12, width/2, height/2+12,5);
    Screen('DrawLine', window, [0 0 0], width/2-12, height/2, width/2+12, height/2,5);
    
    fix_onset = Screen(window, 'Flip', post_fix_onset + floor( .5 / ifi ) * ifi - slack);
    trial_onset = fix_onset;
    
    TRIALS(t,2) = trial_onset - task_onset;
    TRIALS(t,4) = fix_onset - task_onset;
    
    imageArray = Screen('GetImage', window);
    imwrite(imageArray, ['~/Downloads/screenshot_td_rv_v7a_' datestr(now,'YYYYmmDDHHMMSSFFF') '.jpg'])
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % compute trial parameters
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % parameters for FAST
    d = TRIALS(t,7);
    p = TRIALS(t,8);
    
    % compute placement
    df = fastChooseYp(faststruc, d, p);
    ai = round( (20 + 10 * rand(1,1)) * 10 ) / 10;
    ad = round( ai / df * 10 ) / 10;
    df = ai / ad;
    
    % record trial params
    TRIALS(t,9:11) = [ ai ad df ];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% red fixation cross 500ms before end of fixation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen(window, 'FillRect', grey);
    Screen('DrawLine', window, [255 0 0], width/2, height/2-12, width/2, height/2+12,5);
    Screen('DrawLine', window, [255 0 0], width/2-12, height/2, width/2+12, height/2,5);
    red_onset = Screen(window, 'Flip', fix_onset + floor( (fix_duration - .5) / ifi ) * ifi - slack);
    
    imageArray = Screen('GetImage', window);
    imwrite(imageArray, ['~/Downloads/screenshot_td_rv_v7a_' datestr(now,'YYYYmmDDHHMMSSFFF') '.jpg'])
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% choice options (black fix cross), T/B
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    options_duration = TRIALS(t,5);
    top = TRIALS(t,6);
    
    % fix cross
    Screen('TextSize',window, fontSize);
    Screen(window, 'FillRect', grey);
    Screen('DrawLine', window, [0 0 0], width/2, height/2-12, width/2, height/2+12,5);
    Screen('DrawLine', window, [0 0 0], width/2-12, height/2, width/2+12, height/2,5);
    
    % SS option
    text0 = ['$' sprintf('%2.2f',ai)];
    textbox0 = Screen('TextBounds', window, text0);
    Screen('DrawText', window, text0, centerx - textbox0(3)/2, centery + top * .75 * fontSize - (1-top) * 3.00 * fontSize, [0, 0, 0]);
    text1 = 'today';
    textbox1 = Screen('TextBounds', window, text1);
    Screen('DrawText', window, text1, centerx - textbox1(3)/2, centery + top * 2.00 * fontSize - (1-top) * 1.75 * fontSize, [0, 0, 0]);
    % LL option
    text2 = ['$' sprintf('%2.2f',ad)];
    textbox2 = Screen('TextBounds', window, text2);
    Screen('DrawText', window, text2, centerx - textbox2(3)/2, centery + (1-top) * .75 * fontSize - top * 3.00 * fontSize, [0, 0, 0]);
    text3 = ['in ' num2str(d) ' month' (d>1)*'s'];
    textbox3 = Screen('TextBounds', window, text3);
    Screen('DrawText', window, text3, centerx - textbox3(3)/2, centery + (1-top) * 2.00 * fontSize - top * 1.75 * fontSize, [0, 0, 0]);
    
    % Flip
    options_onset = Screen(window, 'Flip', fix_onset + floor(fix_duration/ifi)*ifi - slack);
    TRIALS(t,12) = options_onset - task_onset;
    
    imageArray = Screen('GetImage', window);
    imwrite(imageArray, ['~/Downloads/screenshot_td_rv_v7a_' datestr(now,'YYYYmmDDHHMMSSFFF') '.jpg'])
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% choice (green fix cross), L/R
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    response_duration = TRIALS(t,13);
    right = TRIALS(t,14);
    
    % fix cross
    Screen('TextSize',window, fontSize);
    Screen(window, 'FillRect', grey);
    Screen('DrawLine', window, [32 149 16], width/2, height/2-12, width/2, height/2+12,5);
    Screen('DrawLine', window, [32 149 16], width/2-12, height/2, width/2+12, height/2,5);
    
    testbox0 = Screen('TextBounds', window, ['$' sprintf('%2.2f',ai)]);
    testbox1 = Screen('TextBounds', window, 'in 4 months');
    % SS option
    text0 = ['$' sprintf('%2.2f',ai)];
    textbox0 = Screen('TextBounds', window, text0);
    Screen('DrawText', window, text0, centerx - right * (25 + testbox0(3)/2 + textbox0(3)/2) + (1-right) * (25 + testbox0(3)/2 - textbox0(3)/2), ...
        centery - 1.12 * fontSize, [0, 0, 0]);
    text1 = 'today';
    textbox1 = Screen('TextBounds', window, text1);
    Screen('DrawText', window, text1, centerx - right * (25 + testbox0(3)/2 + textbox1(3)/2) + (1-right) * (25 + testbox0(3)/2 - textbox1(3)/2), ...
        centery + .13 * fontSize, [0, 0, 0]);
    % LL option
    text2 = ['$' sprintf('%2.2f',ad)];
    textbox2 = Screen('TextBounds', window, text2);
    Screen('DrawText', window, text2, centerx - (1-right) * (25 + testbox1(3)/2 + textbox2(3)/2) + right * (25 + testbox1(3)/2 - textbox2(3)/2), ...
        centery - 1.12 * fontSize, [0, 0, 0]);
    text3 = ['in ' num2str(d) ' month' (d>1)*'s'];
    textbox3 = Screen('TextBounds', window, text3);
    Screen('DrawText', window, text3, centerx - (1-right) * (25 + testbox1(3)/2 + textbox3(3)/2) + right * (25 + testbox1(3)/2 - textbox3(3)/2), ...
        centery + .13 * fontSize, [0, 0, 0]);
    
    % Flip
    response_onset = Screen(window, 'Flip', options_onset + floor(options_duration/ifi)*ifi - slack);
    TRIALS(t,15) = response_onset - task_onset;
    
    imageArray = Screen('GetImage', window);
    imwrite(imageArray, ['~/Downloads/screenshot_td_rv_v7a_' datestr(now,'YYYYmmDDHHMMSSFFF') '.jpg'])
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% response
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % wait for input
    pressed = 0; key = -1; response = -1; rt = -1;
    
    % Set up the timer
    startTime = now;
    durationInMiliseconds = ( response_duration - .100 ) * 1000;
    numberOfMilisecondsRemaining = durationInMiliseconds;
    
    % Make sure Kb queue is empty
    while KbCheck; end
    CedrusResponseBox('FlushEvents', h);
    
    check = 1;
    while check == 1 && numberOfMilisecondsRemaining > 0
        numberOfMilisecondsElapsed = round((now - startTime) * 10^8 );
        numberOfMilisecondsRemaining = durationInMiliseconds - numberOfMilisecondsElapsed;
        
        CedrusResponseBox('FlushEvents', h);
        evt = CedrusResponseBox('GetButtons', h);
        
        if ~isempty(evt) && strcmp(evt.buttonID, 'left')
            key = 'left';
            check = 0;
            rt = numberOfMilisecondsElapsed;
            response = right == 0;
        elseif ~isempty(evt) && strcmp(evt.buttonID, 'right')
            key = 'right';
            check = 0;
            rt = numberOfMilisecondsElapsed;
            response = right == 1;
        end
        
    end
    
    WaitSecs(numberOfMilisecondsRemaining/1000);
    
    TRIALS.response(t).key = key;
    TRIALS.response(t).choice = response;
    TRIALS.response(t).rt = rt;
    
    choice = 1 - response;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % wait till end of response window
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    post_fix_duration = TRIALS(t,19);

%     durationInMiliseconds = RUNSHEET(t,13) * 1000;
%     numberOfMilisecondsRemaining = durationInMiliseconds;
%     while numberOfMilisecondsRemaining > 0
%         numberOfMilisecondsElapsed = round((now - startTime) * 10^8 );
%         numberOfMilisecondsRemaining = durationInMiliseconds - numberOfMilisecondsElapsed;
%     end
%     

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % fixation cross at end of trial (while updating FAST)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen(window, 'FillRect', grey);
    Screen('DrawLine', window, [0 0 0], width/2, height/2-12, width/2, height/2+12,5);
    Screen('DrawLine', window, [0 0 0], width/2-12, height/2, width/2+12, height/2,5);
    post_fix_onset = Screen(window, 'Flip', response_onset + floor(response_duration / ifi) * ifi - slack);
    TRIALS(t,20) = post_fix_onset - task_onset;
    
    imageArray = Screen('GetImage', window);
    imwrite(imageArray, ['~/Downloads/screenshot_td_rv_v7a_' datestr(now,'YYYYmmDDHHMMSSFFF') '.jpg'])
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % update FAST structure
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if choice < 2 % participant responded
        [faststruc resample] = fastUpdate(faststruc, [d df choice]);
        if resample
            faststruc = fastResample(faststruc);
        end
    end
    
    % custom stopping rule:
    estimate = fastEstimate(faststruc, THRESHOLDS, 0, 0);
    if (t > MAX_NUM_TRIALS - 1) || ... % either have run through 200 trials...
            (estimate.marg.sd(2) < 0.1) % or decay rate is constrained
        go = 0;
    end
    
    th_est = [ estimate.interp.quantiles{1}' estimate.interp.quantiles{2}' ];
    
    if ~isempty(th_est)
        TRIALS(t, 21:21+numel(th_est)-1) = th_est;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % close open windows
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('Close')
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Break
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     if RUNSHEET(t,1)<max(RUNSHEET(:,1)) && mod(t,96)==0
    %         take_break(window, width, height);
    %     end
    
    save('data/td_rc_7a_log.mat','RUNSHEET');
    
end %trials loop

% cut off unused trial parameters
TRIALS = TRIALS(1:t, :);
