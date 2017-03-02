function [trialLog params] = PracticeBandit
%% initialise parameters
clear all; close all; clc;
PsychJavaTrouble;

% Set Random Number Generator Seed
s = RandStream.create('mt19937ar','seed',sum(100*clock));
RandStream.setDefaultStream(s);
params.seed = s;

params.nTrials = 260; % number of trials
params.practiceTrials = 10;
params.nBandits = 4; % number of bandits
params.pointBounds = [0 100]; %upper and lower bounds on bandit payouts
params.payoutSD = 4; %gaussian noise around mean in payout
params.backgroundColour = [0 0 0]; %colour of background
params.windowLength = 1.5; %length of window in which to accept responses (sec)
params.feedbackDelay = 2; %length of time between response and feedback
params.breakAfter = 130; %take a break after how many trials?
params.itiMean = 1; %mean of poisson distribution from which to draw inter trial interval
params.speed = -2; %speed of voice. negative is slower, positive is faster. integers only.
params.saveDir = 'C:\Users\dbennett1\Documents\BLINKBANDIT\Code\';

% fixation cross parameters
params.fixationColour = [255 255 255];
params.fixationSize = 10; % in pixels
params.fixationPenWidth = 2; % line width in pixels

trialLog.choice = [];
trialLog.payout = [];

%% Make beep sounds
[sPress, sfPress] = MakeBeep;
[sInit, sfInit] = MakeBeep(1000, 0.3);

%% Initialise Cedrus Box
[h] = Initialise_Cedrus_Within; 

%% get acceptable bandit walks

params.banditWalks = []; %initialise as empty

while isempty(params.banditWalks)    
   
    tempWalks = BlinkyWalk(params.nTrials, params.nBandits, params.pointBounds);
    h = figure;
    plot(tempWalks');
    
    reply = input('Are you happy with this pattern? (enter ''y'' or ''n'') >> ', 's');    
    if strcmpi(reply, 'y')
        params.banditWalks = tempWalks;
    end    
    close(h)  
end

%% trial loop
try
PTB = InitialisePTB; % Set up Psych Toolbox


% Draw background
Screen('FillRect',PTB.window,params.backgroundColour);
Screen('DrawLine', PTB.window, params.fixationColour, PTB.centrex, PTB.centrey - params.fixationSize,  PTB.centrex, PTB.centrey + params.fixationSize, params.fixationPenWidth);
Screen('DrawLine', PTB.window, params.fixationColour, PTB.centrex - params.fixationSize, PTB.centrey, PTB.centrex + params.fixationSize, PTB.centrey, params.fixationPenWidth);
Screen('Flip', PTB.window);

for trial = 1:params.practiceTrials
    
    if trial == 1
        tts('After the tone, press a button to pick an option.', params.speed);
    elseif trial == params.breakAfter + 1
        tts('OK, take a break.', params.speed);
        tts('You can press any button to continue when you are ready.', params.speed);
        CedrusResponseBox('FlushEvents', h);
        CedrusResponseBox('WaitButtonPress', h);
        tts('Press a button after the tone to choose.', params.speed);
    end
       
    %wait for buttons to be released
    buttons = 1;
    while any(buttons(1,:))
        buttons = CedrusResponseBox('FlushEvents', h);
    end   
    
    %clear java heap
    jheapcl;
    
    %play trial-initial tone
    sound(sInit,sfInit);
    startTime = GetSecs;
    
    responseContainer = [];
    while isempty(responseContainer) && GetSecs < (startTime + params.windowLength)
        responseContainer = CedrusResponseBox('GetButtons', h);
        if ~isempty(responseContainer) && strcmp(responseContainer.buttonID, 'middle') %ignore if middle button
            responseContainer = [];
        end
    end
    
    if ~isempty(responseContainer)
        rt = GetSecs - startTime;
        sound(sPress, sfPress);
               
        switch responseContainer.buttonID
           case 'top'
               choice = 1;
           case 'right'
               choice = 2;
           case 'bottom'
               choice = 3;
           case 'left'
               choice = 4;
        end
        
        choiceMean = params.banditWalks(choice, trial);
        payout = SpinBandit(choiceMean, params.payoutSD);
        payout = min(payout, max(params.pointBounds)); %ensure the payout is less than the maximum
        payout = max(payout, min(params.pointBounds)); %ensure the payout is more than the minimum
        
        % give feedback
        WaitSecs(params.feedbackDelay);
        talkText = MakeTalkText(payout);      
        tts(talkText, params.speed);
        
        % assign choice info to container
        trialLog(trial).choice = choice;
        trialLog(trial).payout = payout;
        trialLog(trial).rt = rt;
  
    else
        trialLog(trial).choice = NaN;
        trialLog(trial).payout = NaN;
        trialLog(trial).rt = NaN;
        
        talkText = 'No response. Please try to be faster.';
        tts(talkText, params.speed);
    end
    
    % add variable jitter from poisson distribution
    iti = poissrnd(params.itiMean);
    trialLog(trial).iti = iti;
    WaitSecs(iti);
        
end


%% Close PsychToolbox
ClosePTB;
catch
    ClosePTB;
    psychrethrow(psychlasterror);
end



    function [h] = Initialise_Cedrus_Within


    %%% open connection to button box (Lumina)
    fprintf('\nOpening connection to button box...\n')

    if IsOSX
        devs = dir('/dev/cu.usbserial*');
    elseif IsWin
    % Ok, no way of really enumerating what's there, so we simply predifne
    % the first 7 hard-coded port names:
        devs = {'COM0', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7'};
    else
        error('Perceptual_Calibration_fMRI: Cannot find port to which button box is connected.\n');
    end    

    % Let user choose if there are multiple potential candidates:
    if length(devs) > 1
        fprintf('Following devices are potentially Cedrus RB devices: Choose one.\n\n');
        for i=1:length(devs)
            fprintf('%i: %s\n', i, char(devs(i)));
        end
        fprintf('\n');

        while 1
            devidxs = input('Type the number + ENTER of your response pad device: ', 's');
            devid = str2double(devidxs);

            if isempty(devid)
                fprintf('Type the number please, not something else!\n');
            end

            if ~isnumeric(devid)
                fprintf('Type the number please, not something else!\n');
            end

            if devid < 1 || devid > length(devs) || ~isfinite(devid)
                fprintf('Type one of the listed numbers please!\n');
            else
                break;
            end
        end

        if ~IsWin
            port = ['/dev/' char(devs(devid))];
        else
            port = char(devs(devid));
        end
    else
        % Only one candidate: Choose it.
        if ~IsWin
            port = ['/dev/' char(devs(1).name)];
        else
            port = char(devs(1));
        end
    end

    fprintf('\nOpening response box port...\n')
    h = CedrusResponseBox('Open', port, 0, 1);
    % calibrates timers and resets RTT - the latter sets
    % devinfo.baseToPtbOffset to hostime (current PTB time)
    fprintf('Done.\n')

    fprintf('Computing slope between PTB clock and button box clock...\n')
    resetTime = CedrusResponseBox('ResetRTTimer', h);
    devinfo = CedrusResponseBox('GetDeviceInfo', h); %#ok<NOPRT,NASGU>
    offset0 = devinfo.baseToPtbOffset;    
    slope0 = CedrusResponseBox('GetBoxTimerSlope', h);
    slope0 = [GetSecs offset0 slope0];
    roundtrip = CedrusResponseBox('RoundTripTest',h);
    fprintf('Done.\n')

    end

    function [talkText] = MakeTalkText(payout)
        
        switch payout
            
            case 1 
                talkText = 'You got one point';
            case 34
                talkText = 'You got thirtyfore points';
            case 54
                talkText = 'You got fiftyfore points';
            case 64
                talkText = 'You got sixtyfore points';
            case 74
                talkText = 'You got seventeefore points';                
            case 84
                talkText = 'You got ateyfour points';
            case 94
                talkText = 'You got ninetyfore points';
            otherwise              
                talkText = sprintf('You got %.0f points.\n', payout);
        
        end
     
        
    end

    function [X] = BlinkyWalk(nSteps, nBandits, pointBounds)
    %random walk - one dimensional with decaying gaussian

    pointMin = min(pointBounds);
    pointMax = max(pointBounds);
    X = zeros(nBandits, nSteps); % container variable

    % random walk parameters
    lambda = 0.9836; %decay parameter
    theta = 50; %decay centre
    sigmaD = 2.8; %standard deviation of gaussian noise

    % initialise starting points

    startingPoints = rand([1,nBandits]) * 100;
    X(:,1) = startingPoints';

    % random walk
    for step = 2:nSteps

        stepDone = 0;

        while ~stepDone

            lastStep = X(:, step - 1); %get last steps for all bandits

            stepNoise = sigmaD.*randn(nBandits,1); %independently get noise for all bandits
            thisStep = (lambda .* lastStep) + ( ( 1 - lambda ) .* theta ) + stepNoise; %calculate next step for all bandits

            if all(thisStep > pointMin & thisStep < pointMax)   %make sure all values are within permissable range
                X(:, step) = thisStep;
                stepDone = 1;
            end
        end
    end


    end

    function [payout] = SpinBandit(banditMean, banditSD) 

    unroundedPayout = banditMean + banditSD .* randn; %gaussian noise
%     unroundedPayout = banditMean + banditSD .* tan(pi * rand(1) - pi/2);   % noise from cauchy distribution (fat-tailed) 
    payout = round(unroundedPayout);

    end

    function wav = tts(txt,voice,pace,fs)
    %TTS text to speech.
    %   TTS (TXT) synthesizes speech from string TXT, and speaks it. The audio
    %   format is mono, 16 bit, 16k Hz by default.
    %   
    %   WAV = TTS(TXT) does not vocalize but output to the variable WAV.
    %
    %   TTS(TXT,VOICE) uses the specific voice. Use TTS('','List') to see a
    %   list of availble voices. Default is the first voice.
    %
    %   TTS(...,PACE) set the pace of speech to PACE. PACE ranges from 
    %   -10 (slowest) to 10 (fastest). Default 0.
    %
    %   TTS(...,FS) set the sampling rate of the speech to FS kHz. FS must be
    %   one of the following: 8000, 11025, 12000, 16000, 22050, 24000, 32000,
    %       44100, 48000. Default 16.
    %   
    %   This function requires the Microsoft Win32 Speech API (SAPI).
    %
    %   Examples:
    %       % Speak the text;
    %       tts('I can speak.');
    %       % List availble voices;
    %       tts('I can speak.','List');
    %       % Do not speak out, store the speech in a variable;
    %       w = tts('I can speak.',[],-4,44100);
    %       wavplay(w,44100);
    %
    %   See also WAVREAD, WAVWRITE, WAVPLAY.

    % Written by Siyi Deng; 12-21-2007;

    if ~ispc, error('Microsoft Win32 SAPI is required.'); end
    if ~ischar(txt), error('First input must be string.'); end

    SV = actxserver('SAPI.SpVoice');
    TK = invoke(SV,'GetVoices');

    if nargin > 1
        % Select voice;
        for k = 0:TK.Count-1
            if strcmpi(voice,TK.Item(k).GetDescription)
                SV.Voice = TK.Item(k);
                break;
            elseif strcmpi(voice,'list')
                disp(TK.Item(k).GetDescription);
            end
        end
        % Set pace;
        if nargin > 2
            if isempty(pace), pace = 0; end
            if abs(pace) > 10, pace = sign(pace)*10; end        
            SV.Rate = pace;
        end
    end

    if nargin < 4 || ~ismember(fs,[8000,11025,12000,16000,22050,24000,32000,...
            44100,48000]), fs = 16000; end

    if nargout > 0
       % Output variable;
       MS = actxserver('SAPI.SpMemoryStream');
       MS.Format.Type = sprintf('SAFT%dkHz16BitMono',fix(fs/1000));
       SV.AudioOutputStream = MS;  
    end

    invoke(SV,'Speak',txt);

    if nargout > 0
        % Convert uint8 to double precision;
        wav = reshape(double(invoke(MS,'GetData')),2,[])';
        wav = (wav(:,2)*256+wav(:,1))/32768;
        wav(wav >= 1) = wav(wav >= 1)-2;
        delete(MS);
        clear MS;
    end

    delete(SV); 
    clear SV TK;
    pause(0.2);

    end % TTS;


    function [s sf] = MakeBeep(varargin)

    cf = 1500; %auditory frequency (/pitch)
    sf = 22050; %sampling frequency
    d = 0.1; %duration (seconds)
    scale = 0.4; %volume scaling factor

    if numel(varargin) == 2
        cf = varargin{1};
        d = varargin{2};
    end



    n = sf * d;
    s = (1:n)/sf;
    s = scale * sin(2*pi*cf*s);

    end
end