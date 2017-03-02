function drawText(window, text)
% Screen('TextFont', window, 'Helvetica');
Screen('TextSize', window, 30);
Screen(window, 'FillRect', [128 128 128]);
DrawFormattedText(window, text, 'center', 'center',  [0 0 0], 90, 0, 0, 2);
Screen(window, 'Flip');
KbWait([], 2); 