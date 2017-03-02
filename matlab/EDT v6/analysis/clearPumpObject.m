function clearPumpObject(id,place)

for x = id
    oldcd = cd(place);
    name = sprintf('%.0f_1_*', x);
    loadname = dir(name);
    load(loadname.name);
    
    
    data.params.pump = [];
    
    save(loadname.name,'data');
    cd(oldcd);
    if x ~= 4
    oldcd = cd(place);
    name = sprintf('%.0f_3_*', x);
    loadname = dir(name);
    load(loadname.name);
    
    
    data.params.pump = [];
    
    save(loadname.name,'data');
    cd(oldcd);
    end
    fprintf('%.0f cleared.\n',x);
end