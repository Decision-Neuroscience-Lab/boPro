% Figure out optimal choice options
% Effect acts on delay as well as ITI

figure;
c = 1;
for g = 1:2
    for p = 1:15
        for a = 1
            if g == 1
            data = simulateForaging(2,[0,0.5,2.3,],[0,2,8],[0,0.05,0.09,0.1]);
            else
            data = simulateForaging(2,[0,0.5,2.3,],[0,2,8],[0,0,0,0]);
            end
            choices(a) = mean(data(:,8)) - 1;
            fprintf('%.0f simulation complete for participant %.0f, group %.0f.\n',a,p,g);
        end
    output(p,g) = mean(choices);
    end
        c = c + 1;
   % plot(0:0.1:2,prop);hold on;
end
disp(output);
[h,p] = ttest2(output(:,1),output(:,2))

xlabel('Effect size (underestimation)');
ylabel('Proportion of ''accept'' choices');
legend(labels{1:end});