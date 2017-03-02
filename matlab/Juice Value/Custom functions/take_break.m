function take_break(window, width, height)

Screen(window, 'FillRect', [128 128 128]);
text0 = 'Take a break.\nPress any button to proceed.';
DrawFormattedText(window, text0, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
Screen(window, 'Flip');

WaitSecs(0.2);
KbWait([], 2); 