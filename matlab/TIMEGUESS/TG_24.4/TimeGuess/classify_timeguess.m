function [partresponse partblocks frequency] = classify_timeguess(numparts)

loadpath = 'C:\Users\bowenf\Documents\MATLAB\TG_11.4\TimeGuess\data';
skip = [];
num = 6;
numparts = 5;
response_scale = 7;

for x = 1:numparts;
    if ~ismember(num,skip)
        disp(num)
        
        %% Load associated files
        cd(loadpath);
        stringfordir = sprintf('%.0f_*', num);
        loadname = dir(stringfordir);
        load(loadname.name);
      
        %% Index responses
        numblocks = 3;
        allblocks = [];
        for z = 1:numblocks
            allblocks = cat(1,TG{z},allblocks);
        end
        allblocks = sortrows(allblocks);
        
        two = allblocks(:,1) == 2;
        four = allblocks(:,1) == 4;
        six = allblocks(:,1) == 6;
        eight = allblocks(:,1) == 8;
        ten = allblocks(:,1) == 10;
        twelve = allblocks(:,1) == 12;
        fourteen = allblocks(:,1) == 14;
              
        allresponses = zeros(18,7);
        
        allresponses(:,1) = allblocks(two,4);
        allresponses(:,2) = allblocks(four,4);
        allresponses(:,3) = allblocks(six,4);
        allresponses(:,4) = allblocks(eight,4);
        allresponses(:,5) = allblocks(ten,4);
        allresponses(:,6) = allblocks(twelve,4);
        allresponses(:,7) = allblocks(fourteen,4);
             
        partresponse{x} = allresponses;
        partblocks{x} = allblocks;   
        
    end
 num = num+1;
end

%% Frequency of each response to each interval
blocks = [];
for x = 1:numparts
blocks = cat(1,partblocks{1,x}, blocks);
end
blocks = sortrows(blocks);

response = [];
for x = 1:numparts
response = cat(1,partresponse{1,x}, response);
end


two = blocks(:,1) == 2;
four = blocks(:,1) == 4;
six = blocks(:,1) == 6;
eight = blocks(:,1) == 8;
ten = blocks(:,1) == 10;
twelve = blocks(:,1) == 12;
fourteen = blocks(:,1) == 14;

for y = 1:response_scale
frequency(1,y) = sum(blocks(two,4) == y);
frequency(2,y) = sum(blocks(four,4) == y);
frequency(3,y) = sum(blocks(six,4) == y);
frequency(4,y) = sum(blocks(eight,4) == y);
frequency(5,y) = sum(blocks(ten,4) == y);
frequency(6,y) = sum(blocks(twelve,4) == y);
frequency(7,y) = sum(blocks(fourteen,4) == y);
end 
