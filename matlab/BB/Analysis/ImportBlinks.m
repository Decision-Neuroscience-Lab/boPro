function ImportBlinks(participants)

refChan = 65;
rawDir = 'Q:\DATA\BB\raw\EOG\';
processedDir = 'Q:\DATA\BB\data\EOG\';
startEvent = 192; 
endEvent = 160;




[ALLEEG, EEG, CURRENTSET] = eeglab;
for p = participants
    
    pString = ['p' num2str(p)];
    pFile = [rawDir pString '.edf'];

    EEG = pop_biosig(pFile, 'importannot','off','ref',refChan);
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');  
    
    
end

counter = 0;
for p = participants
   
    counter= counter + 1;
    pString = ['p' num2str(p)];
    pFile = [pString '.set'];
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',counter,'study',0);
    
    startDataIndex = find([EEG.event.type] == startEvent);
    endDataIndex = find([EEG.event.type] == endEvent);
    
    startPoint = EEG.event(startDataIndex).latency;
    endPoint = EEG.event(endDataIndex).latency;   
    EEG = pop_select( EEG,'point',[startPoint endPoint] );
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'overwrite','on','gui','off'); 
    EEG = pop_saveset( EEG, 'filename',pFile,'filepath',processedDir);

    
end

fprintf('All done.\n')