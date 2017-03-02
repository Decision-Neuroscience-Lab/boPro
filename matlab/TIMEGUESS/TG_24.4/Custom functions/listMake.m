function list = listMake(size)

sorted = 0;

while ~sorted
    list = ones(1,size);
    for i = 1:numel(list)
        
        randNum = rand;
        if randNum < 0.5
            list(i) = 2;   
        end
    end
    
    numOnes = sum(list == 1);
    numTwos = sum(list == 2);
    
    if numOnes == numTwos
        sorted = 1;
    end
end
