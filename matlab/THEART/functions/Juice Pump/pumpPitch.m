function pumpPitch(base, increment)


base = 10
while 1
squirtMaker(pump,1,base);
WaitSecs(0.3);
base = base + increment
if base > 145
    break;
end
end

N = [85 115 145 145 115 85 85 115 145 115];

for p = 1:length(N)
    if p == length(N)
        squirtMaker(pump,2,N(p));
    else
squirtMaker(pump,1,N(p));
WaitSecs(0.3);
    end
end