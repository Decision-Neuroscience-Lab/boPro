function [s sf] = MakeBeep

cf = 2000;
sf = 22050;
d = 0.05;
n = sf * d;
s = (1:n)/sf;
s = sin(2*pi*cf*s);

end