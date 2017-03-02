function Initialise_RTBox

fprintf('Computing slope between PTB clock and button box clock...\n')
RTBox('ClockRatio');
fprintf('Done.\n')

RTBox('clear'); % Open RT box if hasn't
RTBox('ButtonNames',{'1' '2' '3' '4'});

end
