skip = [5 42 43 45 53 87 88 94];
heart = [];
% Make sure biosig installed (installer does not conflict with existing matlab files, but adding manually does
run('/Users/Bowen/Documents/MATLAB/Toolboxes/biosig4octmat-2.93/biosig_installer.m'); 

for x = 1:120
    if ismember(x,skip)
        continue
    end
    fprintf('Loading participant %.0f.\n',x);
    try
        %[heart(x,1), heart(x,2)] = hrv(x,'pt');
        [X{x},HRV(x,1),RRI(x,1)] = hrv2(x);
    catch
        fprintf('Problem occur...\n');
        continue;
    end
end

%% If using Biosig
for x = 1:120
    if ismember(x,skip)
        continue
    end
    try
    id(x,1) = x;
    meanNN(x,1) = X{x}.meanNN;
    SDNN(x,1) = X{x}.SDNN;
    RMSSD(x,1) = X{x}.RMSSD;
    VLF(x,1) = X{x}.FFT.VLF;
    LF(x,1) = X{x}.FFT.LF;
    HF(x,1) = X{x}.FFT.HF;
    ratio(x,1) = X{x}.FFT.LFHFratio;
    catch
        fprintf('Something wrong with subject %.0f...\n',x);
        continue;
    end
end
heartData = table(id,meanNN,SDNN,RMSSD,VLF,LF,HF);
