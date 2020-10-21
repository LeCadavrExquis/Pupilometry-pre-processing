%% loading file tree
home = 'C:\Users\01140724\Documents\Kajetany\pupillometry-pre-processing';
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
    eeg = pop_epoch( eeg, {  'CS_Minus' 'to_win_CS_Plus_Cash' 'to_lose_CS_Plus_Cash' 'to_lose_CS_Plus_Porn'    'to_win_CS_Plus_Porn'  }, [-3  8], 'epochinfo', 'yes');
    eeg = pop_rmbase( eeg, [-300    0]); %rmbase_qb zmienia na procentowy baseline (divisive as opposed to substractive)
    
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, eeg);
    

end

eeglab redraw
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
            
           i = intervals(counter,2) + 1; %#ok<FXSET>
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
    %% loading raw data
    eeg = eeg_emptyset();

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

    %% setting some eeg atributes 
    eeg.setname = file.name;
    eeg.trials = 1;
    eeg.srate = 60;  
    eeg.pnts = length([s(:).TotalTime]);
    eeg.times(1,:) = [s(:).TotalTime];
     
    eeg.data(1,:) = interpolateIntervals([s(:).A_PupilDiam], getIntervals(w2h_A));
    eeg.data(2,:) = interpolateIntervals([s(:).B_PupilDiam], getIntervals(w2h_B));
    eeg.data(3,:) = [s(:).A_PupilDiam];
    eeg.data(4,:) = [s(:).B_PupilDiam];
    
    if(DEBUG_PLOT)
        figure(11);
        plot([s(:).TotalTime], [s(:).A_PupilDiam], [s(:).TotalTime], eeg.data(1,:));
    end
    
    clear s;
    

end