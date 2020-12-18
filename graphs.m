mkdir spongeBob;
cd spongeBob;
subjects = keys(mapObj);
histData = [];
histSession1 = [];
histSession2 = [];
figure();
for i = 1 : length(subjects)
    if(i <= 47)
        continue;
    end
    subject = subjects{i};
%     mkdir(subject);
%     cd(subject);
    %%histogramData
    tmpSession1 = [];
    tmpSession2 = [];
    for j = 1 : length(ALLEEG)
        if(strcmp(string(ALLEEG(j).subject), string(subject)))
            if(ALLEEG(j).group == 1)
                tmpSession1 = horzcat(tmpSession1, getBetterEye(...
                    raport(ceil(j/2)).epochPercentClues_A,...
                    raport(ceil(j/2)).epochPercentClues_B));
            elseif(ALLEEG(j).group == 2)
                tmpSession2 = horzcat(tmpSession2, getBetterEye(...
                    raport(ceil(j/2)).epochPercentRewards_A,...
                    raport(ceil(j/2)).epochPercentRewards_B));
            end
            %collecting events names
            for k = 1 : length(ALLEEG(j).event)
                events(k) = convertCharsToStrings(ALLEEG(j).event(k).type);
            end
            %redundant ??
            events = unique(events);
            
            tmpEvents = mergeEvents(events);
            
            merged_events = unique(tmpEvents);      
                        
            for k = 1 : length(merged_events)
                tmpData = [];
                for l = 1 : size(ALLEEG(j).data,3)
                    if(contains(convertCharsToStrings(ALLEEG(j).epoch(l).eventtype), merged_events(k)))
                        if(strcmp(convertCharsToStrings(ALLEEG(j).condition), "rewards"))
                            if(raport(ceil(j/2)).epochPercentRewards_A(l) < ...
                                    raport(ceil(j/2)).epochPercentRewards_B(l))
                                tmpData = [tmpData; ALLEEG(j).data(1,:,l)];
                            else
                                tmpData = [tmpData; ALLEEG(j).data(2,:,l)];
                            end
                        else
                            if(raport(ceil(j/2)).epochPercentClues_A(l) < ...
                                    raport(ceil(j/2)).epochPercentClues_B(l))
                                tmpData = [tmpData; ALLEEG(j).data(1,:,l)];
                            else
                                tmpData = [tmpData; ALLEEG(j).data(2,:,l)];
                            end
                        end
                    end

                end
                
                %ploting
                if(isempty(tmpData))
                    disp("!.!.!")
                    continue;
                end
                clf;
                for l = 1 : size(tmpData,1)
                    if(l == 15)
                        continue;
                    end
                    subplot(3, 5, l);
                    plot(ALLEEG(j).times, tmpData(l,:));
                    xline(0);
                    ylim([-0.05,0.05]);
                end
                subplot(3, 5, (l+1));
                plot(ALLEEG(j).times, mean(tmpData));
                xline(0);
                ylim([-0.05,0.05]);
                title("mean");
                sgtitle(subject + " | run:" + string(ALLEEG(j).session) + " | session:" + string(ALLEEG(j).group)...
                    + " | " + strrep(merged_events(k),'_',' ') + " [" + convertCharsToStrings(ALLEEG(j).condition) + "]");
                saveas(gcf,subject + "_" + string(ALLEEG(j).session) + "_" + string(ALLEEG(j).group) +...
                    "_" + convertCharsToStrings(ALLEEG(j).condition) + "_" + merged_events(k) + ".fig");
                saveas(gcf,subject + "_" + string(ALLEEG(j).session) + "_" + string(ALLEEG(j).group) +...
                    "_" + convertCharsToStrings(ALLEEG(j).condition) + "_" + merged_events(k) + ".jpg")
            end
        end
    end
    if(~isempty(tmpSession1))
        histData = [histData, mean(tmpSession1)];
        histSession1 = [histSession1; mean(tmpSession1)];
    end
    if(~isempty(tmpSession2))
        histData = [histData, mean(tmpSession2)];
        histSession2 = [histSession2; mean(tmpSession2)];
    end
%     cd ..;
end
histogram(histData,20);
xlabel('%');
ylabel('Count');
title("Histogram (all) of % interpolation Sessions(" + ...
    length(histData) + ") - [better eye]");
xline(20);
legend(moreThan20(histData) + "% epochs are interpolated more than 20%");
saveas(gcf, "hist_all.fig");
saveas(gcf, "hist_all.jpg");

histogram(histSession1,20);
xlabel('%');
ylabel('Count');
title("Histogram (run 1 and 2) of % interpolation Sessions(" + ...
    length(histSession1) + ") - [better eye]");
xline(20);
legend(moreThan20(histSession1) + "% epochs are interpolated more than 20%");
saveas(gcf, "hist_r12.fig");
saveas(gcf, "hist_r12.jpg");

histogram(histSession2,20);
xlabel('%');
ylabel('Count');
title("Histogram (run 3 and 4) of % interpolation Sessions(" + ...
    length(histSession2) + ") - [better eye]");
xline(20);
legend(moreThan20(histSession2) + "% epochs are interpolated more than 20%");
saveas(gcf, "hist_r34.fig");
saveas(gcf, "hist_r34.jpg");

function z = mergeEvents(events)
    z = [];
    for i = 1 : length(events)
        %%cues
        if(contains(events(i),"CS_Minus"))
            z = [z; "CS_Minus"];
        elseif(contains(events(i),"CS_Plus_Cash"))
            z = [z; "CS_Plus_Cash"];
        elseif(contains(events(i),"CS_Plus_Porn"))
            z = [z; "CS_Plus_Porn"];
        %%rewards
        elseif(contains(events(i),"NoUCsm"))
            z = [z; "NoUCsm"];
        elseif(contains(events(i),"No_UCSp_cash"))
            z = [z; "No_UCSp_cash"];
        elseif(contains(events(i),"No_UCSp_porn"))
            z = [z; "No_UCSp_porn"];
        elseif(contains(events(i),"UCSp_porn"))
            z = [z; "UCSp_porn"];
        elseif(contains(events(i),"UCSp_cash"))
            z = [z; "UCSp_cash"];
        end
    end
end

function x = getBetterEye(A, B)
    x = zeros(1,length(A));
    for i = 1 : length(x)
        if(A(i) < B(i))
            x(i) = B(i);
        else
            x(i) = A(i);
        end
    end
end

function y = moreThan20(data)
    y = 0;
    for i = 1 : length(data)
        if(data(i) > 20)
            y = y + 1;
        end
    end
    
    y = 100 * (y/length(data));
end