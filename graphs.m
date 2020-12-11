mkdir 2;
cd 2;
subjects = keys(mapObj);
histogramData = [];
figure();
for i = 1 : length(subjects)
    subject = subjects{i};
    mkdir(subject);
    cd(subject);
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
%             %collecting events names
%             for k = 1 : length(ALLEEG(j).event)
%                 events(k) = convertCharsToStrings(ALLEEG(j).event(k).type);
%             end
%             events = unique(events);
%                         
%             for k = 1 : length(events)
%                 tmpData = [];
%                 for l = 1 : size(ALLEEG(j).data,3)
%                     if(strcmp(events(k), convertCharsToStrings(ALLEEG(j).epoch(l).eventtype)))
%                         if(strcmp(convertCharsToStrings(ALLEEG(j).condition), "rewards"))
%                             if(raport(ceil(j/2)).epochPercentRewards_A(l) < ...
%                                     raport(ceil(j/2)).epochPercentRewards_B(l))
%                                 tmpData = [tmpData; ALLEEG(j).data(1,:,l)];
%                             else
%                                 tmpData = [tmpData; ALLEEG(j).data(2,:,l)];
%                             end
%                         else
%                             if(raport(ceil(j/2)).epochPercentClues_A(l) < ...
%                                     raport(ceil(j/2)).epochPercentClues_B(l))
%                                 tmpData = [tmpData; ALLEEG(j).data(1,:,l)];
%                             else
%                                 tmpData = [tmpData; ALLEEG(j).data(2,:,l)];
%                             end
%                         end
%                     end
% 
%                 end
%                 
%                 %ploting
%                 if(isempty(tmpData))
%                     disp(sonversubject"")
%                 end
%                 for l = 1 : size(tmpData,1)
%                     subplot(2, ceil((size(tmpData,1)+1)/2), l);
%                     plot(ALLEEG(j).times, tmpData(l,:));
%                     xline(0);
%                     ylim([-0.1,0.1]);
%                 end
%                 subplot(2, ceil((size(tmpData,1)+1)/2), (l+1));
%                 plot(ALLEEG(j).times, mean(tmpData));
%                 xline(0);
%                 ylim([-0.1,0.1]);
%                 title("mean");
%                 sgtitle(subject + " | run:" + string(ALLEEG(j).session) + " | session:" + string(ALLEEG(j).group)...
%                     + " | " + events(k) + "[" + convertCharsToStrings(ALLEEG(j).condition) + "]");
%                 saveas(gcf,events(k) + ".fig");
%             end
        end
    end
    if(~isempty(tmpSession1))
        histogramData = [histogramData, mean(tmpSession1)];
    end
    if(~isempty(tmpSession2))
        histogramData = [histogramData, mean(tmpSession2)];
    end
    cd ..;
end
histogram(histogramData,10);
xlabel('%');
ylabel('Count');
title("Histogram of % interpolation Sessions(" + ...
    length(histogramData) + ") - [better eye]");
xline(20);
legend(moreThan20(histogramData) + "% epochs are interpolated more than 20%");
saveas(gcf, "hist.fig");

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