function DR_prac(ioObj, address, h, window, width, height, INTERVALS, NUM_REPEATS, participants_cond)




%% Try Catch
try
    %%%%%%%%%%%%%%%%%%%%%%%%%PRESENTATION%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    
    
    num_trials = 4;
    ninterv = size(INTERVALS,2);
    
    intervals = repmat(INTERVALS,1,NUM_REPEATS);
    intervals = Shuffle(intervals);
    
    DATA = zeros(num_trials, 6)
    
    %Ready Screen
    
    Screen('TextSize',window, fontSize);
    readytext = 'Press a button when you''re ready to begin the practice';
    Screen(window, 'FillRect', [128 128 128]);
    Screen('DrawText', window, readytext, width/2-450, height/2, fontSize, [0 0 0]);
    
    feedback_onset = Screen(window, 'Flip');
    WaitSecs(0.5);
    
    CedrusResponseBox('FlushEvents', h);
    CedrusResponseBox('WaitButtons',h);

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
       
        %Screen Flip
        presentation_onset = Screen(window, 'Flip', fix_onset + floor(randjitter/ifi) * ifi);
        tstart = tic;
        
        
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
        
        
        % Set up response loop
        
        check = 1;
        
        while check == 1
            CedrusResponseBox('FlushEvents', h);
            WaitSecs(0.1);
            evt = CedrusResponseBox('GetButtons', h);
            
            if ~isempty(evt) && evt.action == 1
          
                % Build Reproduction Stimulus Presentation
                Screen(window, 'FillRect', [128 128 128]);
                Screen('FillRect', window, [20 20 20], [width/2-30, height/2-30, width/2+30, height/2+30]);
                %                 Screen Flip
                reproduction_onset = Screen(window, 'Flip');
                
            elseif ~isempty(evt) && evt.action == 0
                
                clear evt
                check = 0;
            end
        end
        

        CedrusResponseBox('FlushEvents', h);
        
        %Build Fixation 5
        Screen(window, 'FillRect', [128 128 128]);
        Screen('DrawLine', window, [0 0 0], width/2, height/2-12, width/2, height/2+12,5);
        Screen('DrawLine', window, [0 0 0], width/2-12, height/2, width/2+12, height/2,5);
        
        %Screen Flip
        fix5_onset = Screen(window, 'Flip');
        WaitSecs(0.05);
    
        WaitSecs(0.01);
        
        %Build Fixation 5
        Screen(window, 'FillRect', [128 128 128]);
        Screen('DrawLine', window, [0 0 0], width/2, height/2-12, width/2, height/2+12,5);
        Screen('DrawLine', window, [0 0 0], width/2-12, height/2, width/2+12, height/2,5);
        
        %Screen Flip
        fix5_onset = Screen(window, 'Flip');
        WaitSecs(0.05);
        
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
catch
    ShowCursor;
    ListenChar(1);
    Screen('CloseAll');
    psychrethrow(psychlasterror)
end
