function drawFixationColour(window, width, height, colour)


Screen('DrawLine', window, colour, width/2, height/2-(height/90), width/2, height/2+(height/90), 3);
Screen('DrawLine', window, colour, width/2-(height/90), height/2, width/2+(height/90), height/2, 3);
return