function get_ready(window, width, height)
    
Screen(window, 'FillRect', [128 128 128]);
text0 = 'Get ready for next block.\nPress any button to proceed.';
DrawFormattedText(window, text0, 'center', 'center',  [0 0 0], 35, 0, 0, 2);
Screen(window, 'Flip');

WaitSecs(2);
KbWait; 

return