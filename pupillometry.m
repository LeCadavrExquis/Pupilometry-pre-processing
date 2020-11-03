%%epoch cutting conditions
clues = {  'CS_Minus' 'to_win_CS_Plus_Cash' 'to_lose_CS_Plus_Cash' 'to_lose_CS_Plus_Porn'    'to_win_CS_Plus_Porn'  };
rewards = {'NoUCsm' 'plan_No_UCSp_cash' 'plan_UCSp_porn' 'unpl_No_UCSp_porn'};
%% loading file tree
home = 'C:\Users\01140724\Documents\Kajetany\pupillometry-pre-processing';%%home directory
addpath(genpath(home))
cd (home)
sub_list = dir([home '/dane']);

%%delating "." and ".." directory
sub_list(1:2) = [];

%%loading eeglab
eeglab

%%loading data into EEGLAB   

for k = 1 : length(sub_list)
    
    eeg = loadEegSet(sub_list(k));
    eeg = eeg_checkset( eeg );
    
    eeg1 = eeg;
    eeg1 = pop_epoch( eeg1, clues, [-3  8], 'epochinfo', 'yes');
    eeg1.setname = eeg1.setname(1: end - 7);
    eeg1.setname = strcat(eeg1.setname, '_clues');
    eeg1.condition = 'clues';
    eeg1 = pop_rmbase( eeg1, [-300    0]); %rmbase_qb zmienia na procentowy baseline (divisive as opposed to substractive)
    eeg1 = addEpochInfo(eeg1);
    eeg1 = eeg_checkset( eeg1 );
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, eeg1);
    
    eeg = pop_epoch( eeg, rewards, [-3  8], 'epochinfo', 'yes');
    eeg.setname = eeg.setname(1: end - 7);
    eeg.setname = strcat(eeg.setname, '_rewards');
    eeg.condition = 'rewards';
    eeg = pop_rmbase( eeg, [-300    0]); %rmbase_qb zmienia na procentowy baseline (divisive as opposed to substractive)
    eeg = addEpochInfo(eeg);
    eeg = eeg_checkset( eeg );
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, eeg);
end



eeglab redraw
%%
%WARNING: function works with the assumption that data(5,:) corresond to
%intervals_A and 6 correspond to intervals_B
function eeg = addEpochInfo(eeg)
    %%eeg.epoch.intervals_A
    for i = 1 : length(eeg.epoch)
        j = 1;
        eeg.epoch(i).intervals_A = [];
        while(j <= eeg.pnts)
            if(eeg.data(5, j, i) == 1)
                startJ = j;
                while(eeg.data(5, j, i) == 1)
                    if(j >= eeg.pnts)
                        break;
                    end
                    j = j + 1;
                end
                eeg.epoch(i).intervals_A = [eeg.epoch(i).intervals_A; startJ, j];
            end
            j = j + 1;
        end
    end
    
    %%eeg.epoch.intervals_B
    for i = 1 : length(eeg.epoch)
        j = 1;
        eeg.epoch(i).intervals_B = [];
        while(j <= eeg.pnts)
            if(eeg.data(6, j, i) == 1)
                startJ = j;
                while(eeg.data(6, j, i) == 1)
                    if(j >= eeg.pnts)
                        break;
                    end
                    j = j + 1;
                end
                eeg.epoch(i).intervals_B = [eeg.epoch(i).intervals_B; startJ, j];
            end
            j = j + 1;
        end
    end
    
    %%matlab is just stupid, to remove pos 5 and 6 we need to remove 5 2
    %%times xd
    eeg.data(5,:) = [];
    eeg.data(5,:) = [];
end
%%
function tmpIntervalsData = writeTempIntervalData(intervals, pnts)
    tmpIntervalsData = zeros(1, pnts);
    if (isempty(intervals))
        return;
    end
    
    [rows, ~] = size(intervals);
    for i = 1 : rows-1
        tmpIntervalsData(intervals(i, 1) : intervals(i, 2)) = 1;
    end
end
%%
function interpolatedData = interpolateIntervals(data, intervals)
    MEAN_RANGE = 3;
    interpolatedData = [];
    counter = 1;
    [intervalsRows,~] = size(intervals);
    stop = intervals(counter,1);
    if (stop <= MEAN_RANGE + 1)
        %TODO
        stop = MEAN_RANGE + 1 + 1;
    end
    if(intervals(end, 2) >= length(data) - MEAN_RANGE - 1)
        intervals(end,2) = length(data) - MEAN_RANGE - 1;
    end
    i = 1;
    while(i <= length(data))
        if(i == stop)
            interpolatedData = [interpolatedData,...
                linspace(mean(data(stop - MEAN_RANGE - 1 : stop - 1)),...
                         mean(data(intervals(counter, 2) + 1 : intervals(counter, 2) + 1 + MEAN_RANGE)), ...
                         (intervals(counter, 2) - stop + 1))]; %#ok<AGROW>
            
           i = intervals(counter,2) + 1; 
           counter = counter + 1;
           if(counter < intervalsRows)
                stop = intervals(counter,1);
           end
        end
        interpolatedData(i) = data(i);  %#ok<AGROW>
        i = i + 1;
    end
end
%%
function intervals = getIntervals(M)
    intervals = [];
    w2h_UPPER_THRESHOLD = 1.2;
    w2h_LOWER_THRESHOLD = 0.8;
    tmp = NaN;
    for i = 1 : length(M)
        if(M(i) > w2h_UPPER_THRESHOLD || M(i) < w2h_LOWER_THRESHOLD)
            if(isnan(tmp))
                tmp = i;
            end
        else
            if(~isnan(tmp))
                intervals = [intervals; tmp, i]; %#ok<AGROW>
                tmp = NaN;
            end
        end
    end
    
    if(isnan(tmp))
       intervals = [intervals; tmp, length(M)]; %#ok<AGROW>
    end    
    %% suming close intervals
    MIN_INTERVAL_DISTANCE = 10;
    [rows, ~] = size(intervals);
    garbbage = [];
    for i = 1 : rows-1
        if(intervals(i, 2) + MIN_INTERVAL_DISTANCE > intervals(i+1, 1))
            intervals(i+1, 1) = intervals(i, 1);
            garbbage = [garbbage; i];
        end
    end
    
    intervals(rows, 1) = intervals(rows-1,1);
    garbbage = [garbbage; rows-1];
    
    intervals(garbbage,:) = [];
    
end
%%
function eeg = loadEegSet(file)
    DEBUG_PLOT = true;

    eeg = eeg_emptyset();
    
    %% loading some study infromation
    eeg.setname = file.name(1 : end-4);
    eeg.trials = 1;
    eeg.srate = 60;
    underscoresIndexes = strfind(eeg.setname,'_');
    eeg.subject = file.name(1 : underscoresIndexes(1) - 1);
    
    underscoresData = eeg.setname((underscoresIndexes(1) + 1) : end);
    
    if(length(underscoresData) == 1)
        eeg.group = 1;
        eeg.session = str2num(underscoresData(1));
    elseif (length(underscoresData) == 3)
         eeg.group = 2;
         eeg.session = str2num(underscoresData(3));
    else
        eeg.group = 0;
        eeg.session = 0;
    end
    
    %% loading raw data
    filename = [file.folder '/' file.name];
    formatSpec = '%f%f%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%s%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fopen(filename,'r'), formatSpec,...
        'Delimiter', '\t', 'TextType', 'string', 'EmptyValue', NaN,...
        'HeaderLines' ,44-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    fclose(fileID);
    t = table(dataArray{1:end-1}, 'VariableNames', {'ev_index','TotalTime','DeltaTime','A_X_Gaze','A_Y_Gaze','VarName6','VarName7','VarName8','A_PupilWidth',...
        'A_PupilHeight','VarName11','VarName12','VarName13','VarName14','B_X_Gaze','B_Y_Gaze','VarName17','VarName18','VarName19','B_PupilWidth','B_PupilHeight',...
        'VarName22','VarName23','VarName24','VarName25','VarName26','Count','Markers'});
    clearvars formatSpec fileID dataArray ;

    t = removevars(t, {'VarName6','VarName7','VarName8','VarName11','VarName12','VarName13','VarName14','VarName17','VarName18','VarName19','VarName22',...
        'VarName23','VarName24','VarName25','VarName26','A_X_Gaze','A_Y_Gaze','B_X_Gaze','B_Y_Gaze'});

    s = table2struct(t);
    clear t    
    
    %% loading events
    events = [];
    for i = 1:length(s)
        if s(i).ev_index == 12
            events = [events, s(i)]; %#ok<AGROW>
        end
    end
    %deleting marker record
    s = s(~isnan([s.A_PupilWidth]));   

    %% calculating PupilDiam and w2h
    w2h_B = zeros(1,length(s));
    w2h_A = zeros(1,length(s));
    for ii = 1:length(s)

        s(ii).B_PupilDiam = mean([s(ii).B_PupilHeight s(ii).B_PupilWidth]);
        s(ii).A_PupilDiam = mean([s(ii).A_PupilHeight s(ii).A_PupilWidth]);
        w2h_B(ii) = (s(ii).B_PupilWidth / s(ii).B_PupilHeight);
        w2h_A(ii) = (s(ii).A_PupilWidth / s(ii).A_PupilHeight);

    end  
    
    %% adding event info
    gg=1;
    eeg.event(1:end) = [];
    for ii = 1:length(events)
        if contains(events(ii).DeltaTime, 'CS_') || contains(events(ii).DeltaTime, 'UC')
            eeg.event(gg).latency = (events(ii).TotalTime*1000)/16.66;
            eeg.event(gg).type = events(ii).DeltaTime;
            eeg.event(gg).code = events(ii).DeltaTime;
            eeg.event(gg).bvmknum = ii;
            eeg.event(gg).duration = 1;
            eeg.event(gg).channel = 0;
            eeg.event(gg).bvtime = 1;
            gg=gg+1;
        end
    end

    %% setting data   
    eeg.pnts = length([s(:).TotalTime]);
    eeg.times(1,:) = [s(:).TotalTime];
    
    eeg.intervals_A = getIntervals(w2h_A);
    eeg.intervals_B = getIntervals(w2h_B);
     
    eeg.data(1,:) = interpolateIntervals([s(:).A_PupilDiam], eeg.intervals_A);
    eeg.data(2,:) = interpolateIntervals([s(:).B_PupilDiam], eeg.intervals_B);
    %chan 3 and 4 DEBUG
    eeg.data(3,:) = [s(:).A_PupilDiam];
    eeg.data(4,:) = [s(:).B_PupilDiam];
    %chan 5 and 6 temp (will be removed after cuting into epoch)
    eeg.data(5,:) = writeTempIntervalData(eeg.intervals_A, eeg.pnts);
    eeg.data(6,:) = writeTempIntervalData(eeg.intervals_B, eeg.pnts);
    
    if(DEBUG_PLOT)
        figure(11);
        plot([s(:).TotalTime], [s(:).A_PupilDiam], [s(:).TotalTime], eeg.data(1,:));
    end
    
    clear s;
    

end
