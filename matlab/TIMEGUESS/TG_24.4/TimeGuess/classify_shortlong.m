part = 


longer = part(:,1) < part(:,2);
longer = part(longer,:);
shorter = part(:,1) > part(:,2);
shorter = part(shorter,:);

same = part(:,1) == part(:,2);
same = part(same,:);
