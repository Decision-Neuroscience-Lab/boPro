function [blinkRate, returnThreshold, threshold] = GetBlinks(EEG, plotSwitch)
% gets blink rate from an EEG structure
%
% Usage: blinkRate = GetBlinks(EEG, plotSwitch)
% where
%       EEG is an eeglab data structure
%       plotSwitch is a binary toggle (1/0) determining whether data is
%       plotted for visual inspection or not.
%
% other parameters are hardcoded at the start of the script.

%% hardcoded parameters
returnThreshold = -60;
threshold = -100;
windowWidth_points = 20;
stepWidth = 10000;
blinkChannel = 65;

%% Loop until parameters are good

finished = 1;
while finished
    
    returnThreshold = input('Input a baseline return threshold:');
    threshold = input('Input an amplitude threshold:');
    
    %% derived parameters and containers
    counter = 0;
    container = [];
    lastEntry = 1;
    Sf = EEG.srate;
    channelData = EEG.data(blinkChannel,:);
    nSteps = ceil(numel(channelData)./stepWidth);
    startPoint = windowWidth_points/2 + 1;
    endPoint = numel(channelData) - windowWidth_points/2;
    
    %% identify blinks
    
    for i = startPoint:endPoint
        cond1 = channelData(i) <= threshold;
        cond2 = channelData(i) < channelData(i - windowWidth_points/2);
        cond3 = channelData(i) > channelData(i+windowWidth_points/2);
        cond4 = any(channelData(lastEntry:i) >=  returnThreshold);
        cond5 = i > lastEntry + windowWidth_points;
        if cond1 && cond2 && cond3 && cond4 && cond5
            counter = counter + 1;
            container(counter) = i;
            lastEntry = i;
        end
    end
    
    lengthData = size(channelData, 2) / Sf;
    blinkRate = counter / lengthData * 60;
    
    %%
    if plotSwitch
        for step = 1:nSteps-1
            
            XLim = [(step - 1) * stepWidth + 1, step * stepWidth];
            scrsz = get(0,'ScreenSize');
            
            h = figure('Position', [1 1 1920 540]);
            
            plot(min(XLim):max(XLim),channelData(min(XLim):max(XLim)));
            ylim = min(channelData(min(XLim):max(XLim)));
            set(gca, 'ylim', [ylim -ylim]);
            hold on
            
            modifiedContainer = container(container > min(XLim) & container < max(XLim));
            
            for i = 1:numel(modifiedContainer)
                
                plot([modifiedContainer(i) modifiedContainer(i)], [ylim -ylim], 'r:')
                
            end
            
            set(gca, 'xlim', XLim)
            
            theInput = input('Hit enter to continue or q to discountinue checking.', 's');
            close(h)
            if strcmpi(theInput, 'q')
                break
            end
           
        end
    end
    happy = input('Are you happy with these parameters? y or n:', 's');
    if strcmpi(happy, 'y')
     finished = 0;
    end
end
end