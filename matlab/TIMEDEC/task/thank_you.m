function thank_you(window, width, height)

centerx = width/2;
centery = height/2;    
ifi = Screen('GetFlipInterval', window);
slack = ifi/2;
grey = [128 128 128]; %pixel value for grey
defaultFont = 'Helvetica';
fontSize = 40;
Screen('TextFont',window, defaultFont);

Screen(window, 'FillRect', grey);
Screen('TextSize',window, fontSize);
text0 = 'Thank you for participating!';
textbox0 = Screen('TextBounds', window, text0);
Screen('DrawText', window, text0, centerx - textbox0(3)/2, centery - textbox0(4), [0 63 124]);

Screen(window, 'Flip');

KbWait;
