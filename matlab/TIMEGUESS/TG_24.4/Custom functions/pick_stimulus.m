function pick_stimulus(window, width, height, pos, trialpos)

inside = pos.incolour;
outside = pos.outcolour;

red = [255 30 30];
green = [30 255 30];
blue = [30 30 255];
cyan = [30 255 255];
magenta = [255 30 255];
yellow = [255 255 30];
orange = [255 128 30];

        switch trialpos
            case 1
                Screen('FillRect', window, outside, pos.leftscreen);
                Screen('FillArc', window, inside, pos.inleft, 0, 360);
                Screen('FillRect', window, outside, pos.upscreen);
                Screen('FillRect', window, inside, pos.inup);
                Screen('FillRect', window, outside, pos.downscreen);
                Screen('FillRect', window, inside, pos.indown);
                Screen('FillRect', window, outside, pos.rightscreen);
                Screen('FillRect', window, inside, pos.inright);
            case 2
                Screen('FillRect', window, outside, pos.leftscreen);
                Screen('FillRect', window, inside, pos.inleft);
                Screen('FillRect', window, outside, pos.upscreen);
                Screen('FillArc', window, inside, pos.inup, 0, 360);
                Screen('FillRect', window, outside, pos.downscreen);
                Screen('FillRect', window, inside, pos.indown);
                Screen('FillRect', window, outside, pos.rightscreen);
                Screen('FillRect', window, inside, pos.inright);
            case 3
                Screen('FillRect', window, outside, pos.leftscreen);
                Screen('FillRect', window, inside, pos.inleft);
                Screen('FillRect', window, outside, pos.upscreen);
                Screen('FillRect', window, inside, pos.inup);
                Screen('FillRect', window, outside, pos.downscreen);
                Screen('FillArc', window, inside, pos.indown, 0, 360);
                Screen('FillRect', window, outside, pos.rightscreen);
                Screen('FillRect', window, inside, pos.inright);
            case 4
                Screen('FillRect', window, outside, pos.leftscreen);
                Screen('FillRect', window, inside, pos.inleft);
                Screen('FillRect', window, outside, pos.upscreen);
                Screen('FillRect', window, inside, pos.inup);
                Screen('FillRect', window, outside, pos.downscreen);
                Screen('FillRect', window, inside, pos.indown);
                Screen('FillRect', window, outside, pos.rightscreen);
                Screen('FillArc', window, inside, pos.inright, 0, 360);
        end