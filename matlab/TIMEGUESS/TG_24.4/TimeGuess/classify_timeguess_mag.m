function [response blocks frequency] = classify_timeguess_mag(numparts)

loadpath = 'C:\Users\bowenf\Desktop\TG_15.4\TimeGuess\data';
skip = [];
num = 12;
numparts = 15;
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
             
        responses{x} = allresponses;
        blocks{x} = allblocks;   
        
    end
 num = num+1;
end

%% Divide into intervals by participant

for z = 1:numparts
    clear two
    clear four
    clear six
    clear eight
    clear ten
    clear twelve
    clear fourteen
two = blocks{z}(:,1) == 2;
four = blocks{z}(:,1) == 4;
six = blocks{z}(:,1) == 6;
eight = blocks{z}(:,1) == 8;
ten = blocks{z}(:,1) == 10;
twelve = blocks{z}(:,1) == 12;
fourteen = blocks{z}(:,1) == 14;

int{1,z} = blocks{z}(two,[1 3:4]);
int{2,z} = blocks{z}(four,[1 3:4]);
int{3,z} = blocks{z}(six,[1 3:4]);
int{4,z} = blocks{z}(eight,[1 3:4]);
int{5,z} = blocks{z}(ten,[1 3:4]);
int{6,z} = blocks{z}(twelve,[1 3:4]);
int{7,z} = blocks{z}(fourteen,[1 3:4]);
end

%% Small/large means by interval, by participant
for k = 1:numparts
    for j = 1:7        
    i0 = int{j,k}(:,3) == 0;
    i1 = int{j,k}(:,3) == 1;
    i2 = int{j,k}(:,3) == 2;
    i3 = int{j,k}(:,3) == 3;
    i4 = int{j,k}(:,3) == 4;
    
    smallrespint{j,k} = mean(cat(1, int{j,k}(i1,2), int{j,k}(i2,2)));
    largerespint{j,k} = mean(cat(1, int{j,k}(i3,2), int{j,k}(i4,2)));
    nomag{j,k} = int{j,k}(i0,2);
    
    
    split{j,k} = cat(2, smallrespint{j,k}, largerespint{j,k});  
    
    end
end

for k = 1 : numparts
    for j = 1 : 7 
anova1(split{j,k})
mean(nomag{j,k})
    end
end

%% Small/large responses by interval (all participants)

allpartint{1} = cat(1, int{1,1:numparts});
allpartint{2} = cat(1, int{2,1:numparts});
allpartint{3} = cat(1, int{3,1:numparts});
allpartint{4} = cat(1, int{4,1:numparts});
allpartint{5} = cat(1, int{5,1:numparts});
allpartint{6} = cat(1, int{6,1:numparts});
allpartint{7} = cat(1, int{7,1:numparts});

% Count invalid responses
invalid = 0;
for j = 1:7
    response0 = allpartint{j}(:,2) == 0;
    invalid = invalid + sum(response0);
end

for j = 1:7
    allintresp(:,j) = allpartint{j}(:,2)
end

for j = 1:7
    i0 = allpartint{j}(:,3) == 0;
    i1 = allpartint{j}(:,3) == 1;
    i2 = allpartint{j}(:,3) == 2;
    i3 = allpartint{j}(:,3) == 3;
    i4 = allpartint{j}(:,3) == 4;
    
    smallresp{j} = cat(1, allpartint{j}(i1,2), allpartint{j}(i2,2));
    largeresp{j} = cat(1, allpartint{j}(i3,2), allpartint{j}(i4,2));
    nomag{j} = allpartint{j}(i0,2);
    
    split{j} = cat(2, smallresp{j}, largeresp{j});  
end

for j = 1 : 7
means(j,1:2) = mean(split{1,j})
means(j,3) = mean(nomag{j})
end
%% Frequency of each response to each interval
for y = 1:response_scale
frequency(1,y) = sum(blocks(two,3) == y);
frequency(2,y) = sum(blocks(four,3) == y);
frequency(3,y) = sum(blocks(six,3) == y);
frequency(4,y) = sum(blocks(eight,3) == y);
frequency(5,y) = sum(blocks(ten,3) == y);
frequency(6,y) = sum(blocks(twelve,3) == y);
frequency(7,y) = sum(blocks(fourteen,3) == y);
end 

%% Break up small/large magnitude responses (by participant, all intervals)

for w = 1:numparts
i1 = blocks{w}(:,4) == 1;
i2 = blocks{w}(:,4) == 2;
i3 = blocks{w}(:,4) == 3;
i4 = blocks{w}(:,4) == 4;

smallresp = cat(1, blocks{w}(i1, 3), blocks{w}(i2, 3));
largeresp = cat(1, blocks{w}(i3, 3), blocks{w}(i4, 3));

split{w} = cat(2, smallresp, largeresp);

mean(split{w})
end
%% All participants, all intervals
blocks = cat(1,blocks{1:numparts});
blocks = sortrows(blocks);

i1 = blocks(:,4) == 1;
i2 = blocks(:,4) == 2;
i3 = blocks(:,4) == 3;
i4 = blocks(:,4) == 4;

smallresp = cat(1, blocks(i1, 3), blocks(i2, 3));
largeresp = cat(1, blocks(i3, 3), blocks(i4, 3));

split = cat(2, smallresp, largeresp);

mean(split)