%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RC-TD task (returns discount rates)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [TRIALS timematrixtd] = td_rc_calib_v0 (TRIALS, window, width, height, ioObj, address, h)

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
    fontSize = 30;
else
    defaultFont = 'Arial';
    Screen('TextStyle',window,0);
    fontSize = 30;
end

Screen('TextFont',window, defaultFont);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set some task parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MAX_NUM_TRIALS = size(TRIALS.response, 2);
THRESHOLDS = unique([TRIALS.options.quantile]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up FAST algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% faststruc = fastFull(0, ...
%     'funcHyperbolic', ...
%     'psyLogistic', ...
%     {[.001 1], [0.001 1]}, ...
%     {[0 1], [0 1]});
% faststruc = fastFull(0, ...
%               'funcHyperbolic',...
%               'psyLogistic', ...
%                {[0.001 1], [0.001 1]}, ...
%                {[1 12], [0 1]});
faststruc = fastFull(0, ...
    'funcHyperbolic',...
    'psyLogistic', ...
    {[1 -1.4 0.25], [0.001 1]}, ...
    {[0 1], [0 1]});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% trial loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
task_onset = GetSecs;
post_fix_onset = task_onset;

TRIALS.datetime = GetSecs;

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
    fix_duration = TRIALS.prefix(t).duration;
    
    Screen(window, 'FillRect', grey);
    Screen('DrawLine', window, [0 0 0], width/2, height/2-12, width/2, height/2+12,5);
    Screen('DrawLine', window, [0 0 0], width/2-12, height/2, width/2+12, height/2,5);
    
    fix_onset = Screen(window, 'Flip', post_fix_onset + floor( 1 / ifi ) * ifi - slack);
    trial_onset = fix_onset;
    
    TRIALS.trial(t).onset = trial_onset - task_onset;
    TRIALS.prefix(t).onset = fix_onset - task_onset;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % compute trial parameters
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % parameters for FAST
    d = TRIALS.options(t).delay;
    p = TRIALS.options(t).quantile;
    
    % compute placement
    df = fastChooseYp(faststruc, d, p);
    ai = round( (20 + 10 * rand(1,1)) * 10 ) / 10;
    ad = round( ai / df * 10 ) / 10;
    df = ai / ad;
    
    % record trial params
    TRIALS.options(t).vn = ai;
    TRIALS.options(t).vd = ad;
    TRIALS.options(t).y = df;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% red fixation cross 500ms before end of fixation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen(window, 'FillRect', grey);
    Screen('DrawLine', window, [255 255 255], width/2, height/2-12, width/2, height/2+12,5);
    Screen('DrawLine', window, [255 255 255], width/2-12, height/2, width/2+12, height/2,5);
    white_onset = Screen(window, 'Flip', fix_onset + floor( (fix_duration - .5) / ifi ) * ifi - slack);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% choice options (black fix cross), T/B
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    options_duration = TRIALS.options(t).duration;
    top = TRIALS.options(t).lltop;
    
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
    TRIALS.options(t).onset = options_onset - task_onset;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% choice (green fix cross), L/R
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    response_duration = TRIALS.response(t).duration;
    right = TRIALS.response(t).llright;
    
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
    TRIALS.response(t).onset = response_onset - task_onset;
    
    %Get onset time according to Cedrus
    evt = CedrusResponseBox('GetBaseTimer', h);
    GBTbase = evt.basetimer;
    
    CedrusResponseBox('FlushEvents', h);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% response
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % wait for input
    pressed = 0; key = -1; response = -1; rt = -1;
    
    check = 1;
    firstevt = [];
    
    timerbase = GetSecs;
 
        while isempty(firstevt) && GetSecs < timerbase + 2

            evt = CedrusResponseBox('GetButtons', h);
            if ~isempty(evt)    
                firstevt = evt;
                evt = CedrusResponseBox('GetBaseTimer', h);
                GBT_button = evt.basetimer;
            end %fill firstevt when evt happens
        end %make sure firstevt is empty
   
   
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % wait till end of response window
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    post_fix_duration = TRIALS.postfix(t).duration;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % fixation cross at end of trial (while updating FAST)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen(window, 'FillRect', grey);
    Screen('DrawLine', window, [0 0 0], width/2, height/2-12, width/2, height/2+12,5);
    Screen('DrawLine', window, [0 0 0], width/2-12, height/2, width/2+12, height/2,5);
    post_fix_onset = Screen(window, 'Flip', response_onset + floor(response_duration / ifi) * ifi - slack);
    
    TRIALS.postfix(t).onset = post_fix_onset - task_onset;
    
    if ~isempty(firstevt) && strcmp(firstevt.buttonID, 'left')
        key = 'left';
        response = right == 0;
    elseif ~isempty(firstevt) && strcmp(firstevt.buttonID, 'right')
        key = 'right';
        response = right == 1;
    end
    rt = GBT_button - GBTbase;
    
    
    TRIALS.response(t).key = key;
    TRIALS.response(t).choice = response;
    TRIALS.response(t).rt = rt;
    
    choice = 1 - response;
    
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
            (estimate.marg.sd(1) < 0.1) % or decay rate is constrained
        go = 0;
    end
    
    th_est = [ estimate.interp.quantiles{1}' estimate.interp.quantiles{2}' ];
    
    if ~isempty(th_est)
        TRIALS.fast(t).k25 = th_est(1);
        TRIALS.fast(t).k50 = th_est(2);
        TRIALS.fast(t).k75 = th_est(3);
        TRIALS.fast(t).s25 = th_est(4);
        TRIALS.fast(t).s50 = th_est(5);
        TRIALS.fast(t).s75 = th_est(6);
    end
    
    TRIALS.fast(t).struct = faststruc;
    TRIALS.fast(t).estimate = estimate;
    
    TRIALS.trial(t).end = GetSecs - task_onset;
    timematrixtd(t,1) = fix_onset;
    timematrixtd(t,2) = white_onset;
    timematrixtd(t,3) = options_onset;
    timematrixtd(t,4) = response_onset;
    timematrixtd(t,5) = post_fix_onset;
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
    
    save('data/td_rc_calib_8a_log.mat','TRIALS');
    
end %trials loop

% write number of last trial to structure
TRIALS.lasttrial = t;
