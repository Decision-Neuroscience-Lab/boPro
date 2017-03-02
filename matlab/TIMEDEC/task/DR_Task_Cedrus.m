function [DATA timematrix] = DR_Task_Cedrus(sbj, ioObj, address, h, window, width, height, INTERVALS, NUM_REPEATS, participants_cond)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%DR Task%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Triggers
% 20 = experiment on
% 21 = experiment off
% 22 = TD task on
% 23 = TD task off
% 24/25/26/27/28/29 = DR task on (each cond)
% 30 = DR task off
% 31 = DR partcipant response on
% 32 = DR participant response off


%% Try Catch
try
    %%%%%%%%%%%%%%%%%%%%%%%%%PRESENTATION%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Set Screen
    %     myScreen = max(Screen('Screens'));
    %     Screen('Preference','SkipSyncTests', 0);
    %     [window, winRect] = Screen(myScreen,'OpenWindow');
    %     [width, height] = RectSize(winRect);
    %     rect = Screen('rect', window);
    %     [width, height] = RectSize(rect);
    ifi = Screen('GetFlipInterval', window);
    HideCursor;
    ListenChar(2);
    WaitSecs(0.05);
    
    
    if ismac
        defaultFont = 'Helvetica';
        fontSize = 30;
    else
        defaultFont = 'Arial';
        Screen('TextStyle',window,0);
        fontSize = 30;
    end
    
    
    num_trials = NUM_REPEATS * numel(INTERVALS);
    ninterv = size(INTERVALS,2);
    
    intervals = repmat(INTERVALS,1,NUM_REPEATS);
    intervals = Shuffle(intervals);
    
    DATA = zeros(num_trials, 7)
    timematrix = zeros(num_trials + 2, 4) 
    
    %Ready Screen
    
    %     Screen('TextSize',window, fontSize);
    %     readytext = 'Press a button when you''re ready to begin';
    %     Screen(window, 'FillRect', [128 128 128]);
    %     Screen('DrawText', window, readytext, width/2-450, height/2, fontSize, [0 0 0]);
    %
    %     feedback_onset = Screen(window, 'Flip');
    %     WaitSecs(0.5);
    %
    %     CedrusResponseBox('FlushEvents', h);
    %     CedrusResponseBox('WaitButtons',h);
    
    %Trigger experiment on
    io32(ioObj,address, 20);
    time_of_trigger = GetSecs;
    WaitSecs(0.01);
    io32(ioObj,address,0);
    timematrix(1,1) = time_of_trigger;
    
    
    i = 1;
    for t = 1:num_trials
        
        %Build Fixation
        Screen(window, 'FillRect', [128 128 128]);
        Screen('DrawLine', window, [0 0 0], width/2, height/2-12, width/2, height/2+12,5);
        Screen('DrawLine', window, [0 0 0], width/2-12, height/2, width/2+12, height/2,5);
        
        %Screen Flip
        fix_onset = Screen(window, 'Flip');
        
        %Build Stimulus Presentation
        Screen(window, 'FillRect', [128 128 128]);
        Screen('FillRect', window, [20 20 20], [width/2-30, height/2-30, width/2+30, height/2+30]);
        
        randjitter = randi(3);
        
        interval = intervals(t);
        DATA(t,1) = interval;
        
        %Trigger condition on
        switch DATA(t,1)
            case INTERVALS(1)
                stim_trigger = 24;
            case INTERVALS(2)
                stim_trigger = 25;
            case INTERVALS(3)
                stim_trigger = 26;
            case INTERVALS(4)
                stim_trigger = 27;
            case INTERVALS(5)
                stim_trigger = 28;
            case INTERVALS(6)
                stim_trigger = 29;
        end
        
        %Screen Flip
        presentation_onset = Screen(window, 'Flip', fix_onset + floor(randjitter/ifi) * ifi);
        tstart = tic;
        
        io32(ioObj,address, stim_trigger);
        time_of_trigger = GetSecs;
        WaitSecs(0.01);
        io32(ioObj,address,0);
        DATA(t,2) = stim_trigger;
        DATA(t,3) = time_of_trigger;
        timematrix(t+1,2) = time_of_trigger;
   
        
        %Build Fixation 2
        
        Screen(window, 'FillRect', [128 128 128]);
        Screen('DrawLine', window, [255 255 255], width/2, height/2-12, width/2, height/2+12,5);
        Screen('DrawLine', window, [255 255 255], width/2-12, height/2, width/2+12, height/2,5);
        
        %Screen Flip
        CedrusResponseBox('FlushEvents', h);
        fix2_onset = Screen(window, 'Flip', presentation_onset + floor(interval/ifi) * ifi);
        toc(tstart)
        WaitSecs(0.05);
        
        %%%%%%%%%%%%%%%%%%%%%%REPRODUCTION%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Build Fixation 4
        Screen(window, 'FillRect', [128 128 128]);
        Screen('DrawLine', window, [255 255 255], width/2, height/2-12, width/2, height/2+12,5);
        Screen('DrawLine', window, [255 255 255], width/2-12, height/2, width/2+12, height/2,5);
        
        %Screen Flip
        fix4_onset = Screen(window, 'Flip');
        
        
        %% Record Response
        
        %Check for buttons
        buttons = 1;
    while any(buttons(1,:))
      buttons = CedrusResponseBox('FlushEvents',h);
    end
        
        %Set up response loop
        
        check = 1;
        CedrusResponseBox('FlushEvents', h);
        while check == 1
            
            evt = CedrusResponseBox('GetButtons', h);
            
            if ~isempty(evt) && evt.action == 1
                
                evt = CedrusResponseBox('GetBaseTimer', h);
                
                %Trigger DR participant response on
                io32(ioObj,address, 31);
                time_of_trigger = GetSecs;
                WaitSecs(0.01);
                io32(ioObj,address,0);
                timematrix(t+1,3) = time_of_trigger;
                
                %Record time according to Cedrus
                if DATA(t,4) == 0
                    DATA(t,4) = evt.basetimer;
                end
                
                % Build Reproduction Stimulus Presentation
                Screen(window, 'FillRect', [128 128 128]);
                Screen('FillRect', window, [20 20 20], [width/2-30, height/2-30, width/2+30, height/2+30]);
                %Screen Flip
                reproduction_onset = Screen(window, 'Flip');
                
            elseif ~isempty(evt) && evt.action == 0
                
                 evt = CedrusResponseBox('GetBaseTimer', h);
                
                %Trigger DR participant response off
                io32(ioObj,address, 32);
                time_of_trigger = GetSecs;
                WaitSecs(0.01);
                io32(ioObj,address,0); 
                timematrix(t+1,4) = time_of_trigger;
                
                %Record time according to Cedrus
                if DATA(t,5) == 0
                    DATA(t,5) = evt.basetimer;
                end   
                
                clear evt
                check = 0;
            end
        end
        
        DATA(t,6) = (DATA(t,5)) - (DATA(t,4));
        DATA(t,7) = (DATA(t,6)) - (DATA(t,1));
        CedrusResponseBox('FlushEvents', h);
        
        %Build Fixation 5
        Screen(window, 'FillRect', [128 128 128]);
        Screen('DrawLine', window, [0 0 0], width/2, height/2-12, width/2, height/2+12,5);
        Screen('DrawLine', window, [0 0 0], width/2-12, height/2, width/2+12, height/2,5);
        
        %Screen Flip
        fix5_onset = Screen(window, 'Flip');
        WaitSecs(0.05);
        
        
        WaitSecs(0.01);
        io32(ioObj,address,0);   %reset TTL to 0
        
        %Build Fixation 5
        Screen(window, 'FillRect', [128 128 128]);
        Screen('DrawLine', window, [0 0 0], width/2, height/2-12, width/2, height/2+12,5);
        Screen('DrawLine', window, [0 0 0], width/2-12, height/2, width/2+12, height/2,5);
        
        %Screen Flip
        fix5_onset = Screen(window, 'Flip');
        WaitSecs(0.05);
        
    end
    
    %Trigger DR off
    io32(ioObj,address, 30);
    time_of_trigger = GetSecs;
    WaitSecs(0.01);
    io32(ioObj,address,0);
    timematrix(num_trials+2,1) = time_of_trigger;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% Build Feedback
   
    feedback{1}='Your reponse accuracy was above average \n\nPress any button to continue';
    feedback{2}='Your response accuracy was below average - you thought the square appeared for longer than it really did \n\nPress any button to continue';
    feedback{3}='Your response accuracy was below average - you thought the square appeared for shorter than it really did \n\nPress any button to continue';
    
    processingtext = 'Processing results';
    processingtext1 = 'Processing results.';
    processingtext2 = 'Processing results..';
    processingtext3 = 'Processing results...';
    
    %Processing

    if participants_cond(sbj,2) ~= 4
       
        for processingtime = 0:2
            
            Screen('TextSize',window, fontSize);
            Screen(window, 'FillRect', [128 128 128]);
            Screen('DrawText', window, processingtext, width/2-225, height/2, fontSize, [0 0 0]);
            
            feedback_onset = Screen(window, 'Flip');
            WaitSecs(0.5);
            
            Screen('TextSize',window, fontSize);
            Screen(window, 'FillRect', [128 128 128]);
            Screen('DrawText', window, processingtext1, width/2-225, height/2, fontSize, [0 0 0]);
            
            feedback_onset = Screen(window, 'Flip');
            WaitSecs(0.5);
            
            Screen('TextSize',window, fontSize);
            Screen(window, 'FillRect', [128 128 128]);
            Screen('DrawText', window, processingtext2, width/2-225, height/2, fontSize, [0 0 0]);
            
            feedback_onset = Screen(window, 'Flip');
            WaitSecs(0.5);
            
            Screen('TextSize',window, fontSize);
            Screen(window, 'FillRect', [128 128 128]);
            Screen('DrawText', window, processingtext3, width/2-225, height/2, fontSize, [0 0 0]);
            
            feedback_onset = Screen(window, 'Flip');
            WaitSecs(0.5);
            
        end
        
        %Feedback
        Screen('TextSize',window, fontSize);
        Screen(window, 'FillRect', [128 128 128]);
        
        feed_disp = feedback{participants_cond(sbj,2)};
        DrawFormattedText(window, feed_disp, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
        
        CedrusResponseBox('FlushEvents', h);
        feedback_onset = Screen(window, 'Flip');
        WaitSecs(2*pi);
        CedrusResponseBox('WaitButtons',h);
    end

    Screen('TextSize',window, fontSize);
    Screen(window, 'FillRect', [128 128 128]);
    DrawFormattedText(window, 'Please see the experimenter now', 'center', 'center',  [0 0 0], 35);
    
    feedback_onset = Screen(window, 'Flip');
    WaitSecs(10);
    CedrusResponseBox('FlushEvents', h);
    CedrusResponseBox('WaitButtons',h);
    
    %Trigger experiment off
    io32(ioObj,address, 21);
    time_of_trigger = GetSecs;
    WaitSecs(0.01);
    io32(ioObj,address,0);
    
    %Close Screen
    %     ShowCursor;
    %     ListenChar(1);
    %     Screen('CloseAll');
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
end

%% Save to file

%save(['DurRepTask_log_sbj' num2str(sbj) '_' datestr(now,'yyyymmddHHMMSS') '.mat'],'DATA')