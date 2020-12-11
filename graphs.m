% %%betterEyeClues
% for i = 1 : length(raport)
%     for j = 1 : length(raport(i).epochPercentClues_A)
%         betterEyeClues.name = raport(i).name;
%         if(raport(i).epochPercentClues_A(j) < raport(i).epochPercentClues_A(j))
%             betterEyeClues.betterEye = 'A';
%         else
%             betterEyeClues.betterEye = 'B';
%         end
%     end
% end
% 
% %%betterEyeRewards
% for i = 1 : length(raport)
%     for j = 1 : length(raport(i).epochPercentRewards_A)
%         betterEyeRewards(i).name = raport(i).name;
%         if(raport(i).epochPercentRewards_B(j) < raport(i).epochPercentRewards_A(j))
%             betterEyeRewards(i).betterEye = 'A';
%         else
%             betterEyeRewards(i).betterEye = 'B';
%         end
%     end
% end

%%histogram
subjects = keys(mapObj);
histogramData = [];
for i = 1 : length(subjects)
    tmpSession1 = [];
    tmpSession2 = [];
    subject = subjects{i};
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
        end
    end
    if(~isempty(tmpSession1))
        histogramData = [histogramData, mean(tmpSession1)];
    end
    if(~isempty(tmpSession2))
        histogramData = [histogramData, mean(tmpSession2)];
    end

end
figure();
histogram(histogramData,10);
xlabel('%');
ylabel('Count');
title("Histogram of % interpolation Sessions(" + ...
    length(histogramData) + ") - [better eye]");
xline(20);
legend(moreThan20(histogramData) + "% epochs are interpolated more than 20%");
% 
% 
% clues = {'CS_Minus' 'to_win_CS_Plus_Cash' 'to_lose_CS_Plus_Cash' 'to_lose_CS_Plus_Porn' 'to_win_CS_Plus_Porn'};
% rewards = {'NoUCsm' 'plan_No_UCSp_cash' 'plan_No_UCSp_porn' 'plan_UCSp_porn' 'plan_UCSp_cash' 'unpl_No_UCSp_porn' 'unpl_No_UCSp_cash' 'unpl_UCSp_cash' 'unpl_UCSp_porn' };
% 
% sampleEEG = ALLEEG(1);
% 
% figure();
% %for i = 1 : length(clues)
%     epochIndexes = searchEpoch(sampleEEG.epoch, 'CS_Minus');
%     
%     sum = 0;
%     for j = 1 : length(epochIndexes)
%         sum = sum + sampleEEG.data(1,:,epochIndexes(j));
%         
%         subplot(2, ceil(length(epochIndexes)/2), j);
%         plot(sampleEEG.times, sampleEEG.data(1,:,epochIndexes(j)));
%         title("epoch " + string(j));
%         xline(0);
%     end
%     
%     meanVector = sum/length(epochIndexes);
%     
%     subplot(2, ceil(length(epochIndexes)/2), j);
%     plot(sampleEEG.times, meanVector);
%     title("mean");
%     xline(0);
%     sgtitle('CS_Minus');
%     saveas(gcf,'Barchart.png')
% 
% %end



function epochIndexes = searchEpoch(data, eventName)
    epochIndexes = [];
    for i = 1 : length(data)
        if(strcmp(string(data(i).eventtype), string(eventName)))
            epochIndexes = [epochIndexes, i];
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