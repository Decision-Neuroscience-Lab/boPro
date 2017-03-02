function drawQuitStim(params, totalReward, time, matured, pressed)

circColour = params.c; % Set to correspond to distribution
responseColour = params.colours{4};
timeColour = params.cPrime;

% Position parameters
textHeightTotal = params.height.*(6/8);
textThick = 3;
rectHeight = params.height.*(4/5);
rectWidth = params.width.*(4/5) - params.width.*(1/5) - (2*textThick);
rectWidth1 = params.width.*(1/5);
rectWidth2 = params.width.*(4/5);
rectDepth = 40;

Screen(params.window, 'FillRect', [128 128 128]); % Draw background
% Display current reward
Screen('FillArc',params.window, circColour,...
    [(params.width/2)-100, (params.height/2)-115, (params.width/2)+100, (params.height/2)+85], 0, 360);
if pressed == 1
    Screen('FrameArc',params.window, responseColour,...
        [(params.width/2)-100, (params.height/2)-115, (params.width/2)+100, (params.height/2)+85], 0, 360,3);
end
if matured == 1
    delay_text = sprintf('$%.2f', params.largeReward);
else
    delay_text = sprintf('$%.2f', params.smallReward);
end
DrawFormattedText(params.window, delay_text, 'center','center', [0 0 0], 50, 0, 0, 2);
% Display total reward
total = sprintf('($%.2f total)', totalReward);
DrawFormattedText(params.window, total, 'center', textHeightTotal, [0 0 0], 40, 0, 0, 2);
% Display total time
Screen('FrameRect', params.window, [0 0 0],...
    [rectWidth1, rectHeight, rectWidth2, rectHeight + rectDepth], textThick);
Screen('FillRect', params.window, timeColour,...
    [rectWidth1 + textThick, rectHeight + textThick,...
    (rectWidth1 + textThick) + (rectWidth*(time/params.blockTime)),... % Fraction of remaining time
    rectHeight + rectDepth - textThick]);