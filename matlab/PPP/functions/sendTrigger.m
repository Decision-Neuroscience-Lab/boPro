function sendTrigger(params, trigger)
if params.testing ~= 1
    io32(params.ioObj,params.address,trigger);
    WaitSecs(0.01);
    io32(params.ioObj,params.address,0);
else
   return
end
    
return