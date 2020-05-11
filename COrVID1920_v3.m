%COrVID1920_v3.m
%
%Some MATLAB stuff for downloading and plotting U.S. COVID-19 data for 
%various customized areas, down to the county level.
%
%See 'READ_ME.txt' for info about files, conventions, inputs and such.  
%See 'InputVars.m' to modify input parameters.  See 'CustomAreas.m' and 
%'CustomMetros.m' to add and/or modify custom areas and metros for which 
%to calculate & plot data from state and county-level source data.
%
%Carl Andersen
%University of Alaska Fairbanks
%csandersen@alaska.edu

clear

disp(' ')
disp('COrVID1920 plotting tool.')
disp('Most current version available at: www.github.com/COrVID1920')
disp(' ')

%Download NYT data from Github at user prompt, else use local files.
%https://github.com/nytimes/covid-19-data

options = weboptions('Timeout',Inf);

download = 0;
download  = input('Download NYT U.S. state-level data? Yes, enter "1" - Use local file, enter "0":  ');
if download == 1
    url = ['https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv'];
    filename1 = 'us-states.csv';
    TS_st_filename = websave(filename1,url);
end

download = 0;
download  = input('Download NYT U.S. county-level data? Yes, enter "1" - Use local file, enter "0":  ');
if download == 1
    url = ['https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv'];
    filename2 = 'us-counties.csv';
    TS_cty_filename = websave(filename2,url);
end

%Get Covid Tracking Project data on testing & hospitalization.
%https://covidtracking.com/ 
%and/or
%https://github.com/COVID19Tracking/covid-tracking-data
download = 0;
download  = input('Download CovidTracking testing/hospital data? Yes, enter "1" - Use local file, enter "0":  ');
if download == 1
    %US data
    url = ['https://raw.githubusercontent.com/COVID19Tracking/covid-tracking-data/master/data/us_daily.csv'];
    filename3 = 'testingUS.csv';
    HT_us_filename = websave(filename3,url);
    %State data
    url = ['https://raw.githubusercontent.com/COVID19Tracking/covid-tracking-data/master/data/states_daily_4pm_et.csv'];
    filename4 = 'testingST.csv';
    HT_st_filename = websave(filename4,url);
end

%Ask if user wants to write plots to .png in current local directory.
write_png = 0;
write_png = input('Write plots as .png in current local directory? Yes, enter "1" - No, enter "0":  ');
disp(' ')
%%
%Check if data was downloaded, else set local filenames.
if exist('TS_st_filename')
   disp('Personal Space.')
else
   TS_st_filename = 'us-states.csv';
end

if exist('TS_cty_filename')
   disp('Hey, Personal Space.')
else
   TS_cty_filename = 'us-counties.csv';
end

if exist('HT_us_filename')
   disp('Personal Space.')
else
    HT_us_filename = 'testingUS.csv';
end

if exist('HT_st_filename')
   disp('Staaaaay Outta That Personal Space...')
else
    HT_st_filename = 'testingST.csv';
end

%Import NYT time series in table form.
TS_st_table = readtable(TS_st_filename);
TS_cty_table = readtable(TS_cty_filename);

%Import CovidTracking testing/hospital time series in table form.
HT_us_table = readtable(HT_us_filename);
HT_st_table = readtable(HT_st_filename);

%Import FIPS (2 & 5 digit), Census division & region code data.
fipscode_5 = readtable('fips-county-codes.csv');
fipscode_2 = readtable('fips-codes.csv');
divcode = readtable('division-codes.csv');
regcode = readtable('region-codes.csv');

%Run InputVars.m to get plotting parameters for later.
run('InputVars.m')

H_TS = height(TS_st_table);
H_HT = height(HT_us_table);
H_TS_C = height(TS_cty_table);
H_HT_S = height(HT_st_table);

%Define and fill 2D array from NYT t.s. state table.
TS_st = zeros(H_TS,4);
TS_st(:,1) = datenum(TS_st_table.date);
TS_st(:,2) = TS_st_table.cases;
TS_st(:,3) = TS_st_table.deaths;
TS_st(:,4) = TS_st_table.fips;

%Start/end dates and days elapsed (H_M) in serial date numbers.
startdate = TS_st(1,1);
enddate = TS_st(H_TS,1);
H_M = enddate - startdate+1;


%%
%NYT state-level data:
%
%Allocate 3D array for state-level data - Master_st(row, column, page)
%row - individual state dates -> H_M elements
%column - date, cases, deaths at each date -> 3 elements
%page - state FIPS code -> 78 elements
Master_st = zeros(H_M, 3, 78);

%Populate Master_st
for i = 1:H_TS
    f_fips = TS_st(i,4);
    date = TS_st(i,1);
    date_index = date-startdate+1;
    cases = TS_st(i,2);
    deaths = TS_st(i,3);
    Master_st(date_index,1,f_fips) = date;
    Master_st(date_index,2,f_fips) = cases;
    Master_st(date_index,3,f_fips) = deaths;   
end

%Fill in data for states on days with no report
for i = 1:78
    f_fips = i;
    date = Master_st(1,1,f_fips);
    
    if date == 0
        Master_st(1,1,f_fips) = startdate;
    end
    
    for j = 2:H_M
        date = Master_st(j,1,f_fips);        
  
        if date == 0
            Master_st(j,1,f_fips) = Master_st(j-1,1,f_fips)+1;
            Master_st(j,2,f_fips) = Master_st(j-1,2,f_fips);
            Master_st(j,3,f_fips) = Master_st(j-1,3,f_fips);
        end
            
    end
end

%Sum up data for all US in one 2D array  - All_st()
All_st = sum(Master_st,3);
datenum_vec = All_st(:,1)/78;
All_st(:,1) = datenum_vec;

%%
%Sum up data for U.S. Census Divisions & Regions

%Allocate 3D array for division-level data - Division_st(row, column, page)
%row - individual div. dates -> H_M elements
%column - date, cases, deaths at each date -> 3 elements
%page - division # -> 9 elements
Division_st = zeros(H_M,3,9);

%New England
Division_st(:,:,1) = Master_st(:,:,9) + Master_st(:,:,23) + ...
    Master_st(:,:,25) + Master_st(:,:,33) + Master_st(:,:,44) ...
    + Master_st(:,:,50);
Division_st(:,1,1) = datenum_vec;

%Mid-Atlantic
Division_st(:,:,2) = Master_st(:,:,34) + Master_st(:,:,36) ...
    + Master_st(:,:,42);
Division_st(:,1,2) = datenum_vec;

%East North Central
Division_st(:,:,3) = Master_st(:,:,17) + Master_st(:,:,18) ...
    + Master_st(:,:,26) + Master_st(:,:,39) + Master_st(:,:,55);
Division_st(:,1,3) = datenum_vec;

%West North Central
Division_st(:,:,4) = Master_st(:,:,19) + Master_st(:,:,20) + ...
    Master_st(:,:,27) + Master_st(:,:,29) + Master_st(:,:,31) + ...
    Master_st(:,:,38) + Master_st(:,:,31);
Division_st(:,1,4) = datenum_vec;

%West North Central
Division_st(:,:,5) = Master_st(:,:,10) + Master_st(:,:,11) + ...
    Master_st(:,:,12) + Master_st(:,:,13) + Master_st(:,:,24) + ...
    Master_st(:,:,37) + Master_st(:,:,45) + Master_st(:,:,51) + ...
    Master_st(:,:,54);
Division_st(:,1,5) = datenum_vec;

%East South Central
Division_st(:,:,6) = Master_st(:,:,1) + Master_st(:,:,21) + ...
    Master_st(:,:,28) + Master_st(:,:,47);
Division_st(:,1,6) = datenum_vec;

%West South Central
Division_st(:,:,7) = Master_st(:,:,5) + Master_st(:,:,22) + ...
    Master_st(:,:,40) + Master_st(:,:,48);
Division_st(:,1,7) = datenum_vec;

%Mountain
Division_st(:,:,8) = Master_st(:,:,4) + Master_st(:,:,8) + ...
    Master_st(:,:,16) + Master_st(:,:,30) + Master_st(:,:,32) + ...
    Master_st(:,:,35) + Master_st(:,:,49) + Master_st(:,:,56);
Division_st(:,1,8) = datenum_vec;

%Pacific
Division_st(:,:,9) = Master_st(:,:,2) + Master_st(:,:,6) + ...
    Master_st(:,:,15) + Master_st(:,:,41) + Master_st(:,:,53);
Division_st(:,1,9) = datenum_vec;


%Allocate 3D array for region-level data - Region_st(row, column, page)
%row - individual reg. dates -> H_M elements
%column - date, cases, deaths at each date -> 3 elements
%page - region # -> 4 elements
Region_st = zeros(H_M,3,4);

%Northeast
Region_st(:,:,1) = Division_st(:,:,1) + Division_st(:,:,2);
Region_st(:,1,1) = datenum_vec;

%Midwest
Region_st(:,:,2) = Division_st(:,:,3) + Division_st(:,:,4);
Region_st(:,1,2) = datenum_vec;

%South
Region_st(:,:,3) = Division_st(:,:,5) + Division_st(:,:,6) + Division_st(:,:,7);
Region_st(:,1,3) = datenum_vec;

%West
Region_st(:,:,4) = Division_st(:,:,8) + Division_st(:,:,9);
Region_st(:,1,4) = datenum_vec;

%%
%Sum up specified state-level data for custom areas.  Parameters defining 
%these areas come from 'CustomAreas.m'which should have already been run 
%by 'InputVars.m' if necessary.  Go there for details.

%Allocate 3D array for summed area data - Areas_st(row, column, page)
%row - individual area dates -> H_M elements
%column - date, cases, deaths at each date -> 3 elements
%page - custom area # -> n_areas elements
Areas_st = zeros(H_M,3,n_areas);

%Sum up each custom area
for i = 1:n_areas
    area_temp = zeros(H_M,3);
    for j = 1:78
        if areas_states(i,j) ~= 0
            fips_temp = areas_states(i,j);
            area_temp = area_temp + Master_st(:,:,fips_temp);
        end
        Areas_st(:,:,i) = area_temp;
        Areas_st(:,1,i) = datenum_vec;
    end
end

%%
%NYT county-level data:

disp('                                                                 ');
disp('      ¯\_(ツ)_/¯            ¯\_(ツ)_/¯            ¯\_(ツ)_/¯      ');
disp('                                                                 ');

%Define and fill 2D array from NYT t.s. county table, then import 
%county-level data
TS_cty = zeros(H_TS_C,4);
TS_cty(:,1) = datenum(TS_cty_table.date);
TS_cty(:,2) = TS_cty_table.cases;
TS_cty(:,3) = TS_cty_table.deaths;
TS_cty(:,4) = TS_cty_table.fips;

%Start/end dates and days elapsed (H_M_C) in serial date numbers
startdate_c = TS_cty(1,1);
enddate_c = TS_cty(H_TS_C,1);
H_M_C = enddate_c - startdate_c+1;

%Allocate 3D array for county-level data Master_cty(row, column, page)
%row - individ. county date -> H_M_C elements
%column - date, cases, deaths -> 3 elements
%page - county, indexed by 5-digit FIPS code
Master_cty = zeros(H_M, 3, 57000);

%Note that many entries in 'us-counties.csv' have blank entries for 
%5-digit FIPS code.  Disregard these for now.

%Populate Master_cty
for i = 1:H_TS_C
    f_fips = TS_cty(i,4);
    fips_nan = isnan(f_fips);
    date = TS_cty(i,1);
    date_index = date-startdate_c+1;
    cases = TS_cty(i,2);
    deaths = TS_cty(i,3);
    if fips_nan == 0  
        Master_cty(date_index,1,f_fips) = date;
        Master_cty(date_index,2,f_fips) = cases;
        Master_cty(date_index,3,f_fips) = deaths;
    end
    
    %Special case for this data set, page 57000 goes to NYC
    name_temp = string(TS_cty_table{i,2});
    is_nyc = strcmp(name_temp,"New York City");
    if is_nyc == 1
        Master_cty(date_index,1,57000) = date;
        Master_cty(date_index,2,57000) = cases;
        Master_cty(date_index,3,57000) = deaths;
    end
  
end

%Fill in data for counties with no report that day
for i = 1:57000
    f_fips = i;
    date = Master_cty(1,1,f_fips);
    
    if date == 0
        Master_cty(1,1,f_fips) = startdate_c;
    end
    
    for j = 2:H_M
        date = Master_cty(j,1,f_fips);        
  
        if date == 0
            Master_cty(j,1,f_fips) = Master_cty(j-1,1,f_fips)+1;
            Master_cty(j,2,f_fips) = Master_cty(j-1,2,f_fips);
            Master_cty(j,3,f_fips) = Master_cty(j-1,3,f_fips);
        end
            
    end
end

%%
%Sum up county-level data to generate data for custom metro areas.  Some 
%parameters come from 'CustomMetros.m' which should have already been run 
%by 'InputVars.m' if necessary.  Go there for details.

%Allocate array for summed county data, 1 page for each custom area
Metro_cty = zeros(H_M,3,n_metro);

%sum up each custom area
for i = 1:n_metro
    area_temp = zeros(H_M,3);
    cty_n_temp = 0;
    for j = 1:254
        if metro_counties(i,j) ~= 0
            fips_temp = metro_counties(i,j);
            area_temp = area_temp + Master_cty(:,:,fips_temp);
            cty_n_temp = cty_n_temp + 1;
        end
        Metro_cty(:,:,i) = area_temp;
        date_temp = Metro_cty(:,1,i)/cty_n_temp;
        Metro_cty(:,1,i) = date_temp;
    end
end

%%Sum up county data into custom metro areas

%%
%Sort and store some of testing/hospital data at U.S. level(see descriptions)

Testing_us = zeros(H_HT,9);
Testing_us(:,2) = HT_us_table.states;
Testing_us(:,3) = HT_us_table.positive;
Testing_us(:,4) = HT_us_table.negative;
Testing_us(:,5) = HT_us_table.posNeg;
Testing_us(:,6) = HT_us_table.pending;
Testing_us(:,7) = HT_us_table.hospitalized;
Testing_us(:,8) = HT_us_table.death;
Testing_us(:,9) = HT_us_table.total;

%flip array up/down & fill date column starting at datenum for 1/22/20
%note that older iterations of this data set have used different startdates
T_temp = flipud(Testing_us);
Testing_us = T_temp;
for i = 1:H_HT
    Testing_us(i,1) = 737811+i;
end

for i = 1:H_HT    
    %replace any NaN values in columns 4-10 with 0
    for j = 4:9
      is_nan_tmp = isnan(Testing_us(i,j));
      if is_nan_tmp == 1
          Testing_us(i,j) = 0;
      end
    end
end

%%
%Sort and store some of testing/hospital data for state level.
%Also calculate per capita stats for state and national level


H_HT_S = height(HT_st_table);

%Allocate and populate 2D state test/hosp array for sorting
Testing_st_2D = zeros(H_HT_S,10);
Testing_st_2D(:,1) = HT_st_table.date;
Testing_st_2D(:,4) = HT_st_table.positive;
Testing_st_2D(:,5) = HT_st_table.negative;
Testing_st_2D(:,6) = HT_st_table.posNeg;
Testing_st_2D(:,7) = HT_st_table.pending;
Testing_st_2D(:,8) = HT_st_table.hospitalized;
Testing_st_2D(:,9) = HT_st_table.death;
Testing_st_2D(:,10) = HT_st_table.total;

%1-date(yyyymmdd), 2-datenum, 3-FIPS, 4-pos, 5-neg, 6-pos+neg, 7-pending, 
%8-hosp, 9-death, 10-total
%fips_2

%st_index_table = readtable('state-index.csv');
%fips_2_lookup = strings(fipscode_2.ABR);

fips_2_lookup = strings(78,1);
Testing_st_abr = strings(H_HT_S,1);
Testing_st_abr = string(HT_st_table.state);

for i =1:H_HT_S
    date_str = string(Testing_st_2D(i,1));
    Testing_st_2D(i,2) = datenum(date_str,'yyyymmdd');
end

for i = 1:78
    fips_2_lookup(i) = fipscode_2.ABR{i};
end

for i = 1:H_HT_S    
    %replace any NaN values in columns 4-10 with 0
    for j = 4:10
      is_nan_tmp = isnan(Testing_st_2D(i,j));
      if is_nan_tmp == 1
          Testing_st_2D(i,j) = 0;
      end
    end
    
    %write FIPS-2 identifier
    for j = 1:78
        ABR_1 = Testing_st_abr(i);
        ABR_2 = fips_2_lookup(j);
        if ABR_1 == ABR_2
           Testing_st_2D(i,3) = j;
        end
    end
end

startdate_T_st = Testing_st_2D(H_HT_S,2) - 1;
enddate_T_st = Testing_st_2D(1,2);

%individual state time series heights H_HT_SI
H_HT_SI = enddate_T_st - startdate_T_st;

%Allocate 3D array for state-level testing/hospital data
% --> Testing_st_3D(row, column, page)
%row -> individual state dates -> H_HT_SI elements
%column -> 10 elements -> 1-date(yyyymmdd), 2-datenum, 3-FIPS, 4-pos, 
%5-neg, 6-pos+neg, 7-pending, 8-hosp, 9-death, 10-total
%page -> state FIPS code -> 78 elements
Testing_st_3D = zeros(H_HT_SI,10,78);

for i = 1:H_HT_S
    date = Testing_st_2D(i,2);
    t_fips = Testing_st_2D(i,3);
    date_index = date - startdate;
    Testing_st_3D(date_index,:,t_fips) = Testing_st_2D(i,:);
end

%fill in any zeros in datenum columns
for i = 1:H_HT_SI
    for j = 1:78
        if Testing_st_3D(i,2,j) == 0
            Testing_st_3D(i,2,j) = startdate + i;
        end
    end
end

%read in state demographics
demogph_st_table = readtable('state-demographics.csv');

Per_Capita_us = zeros(H_HT_SI,8);

Per_Capita_us(:,1) = Testing_us(:,1);
US_Pop = demogph_st_table.Pop(80);
Per_Capita_us(:,2) = Testing_us(:,3)./US_Pop;
Per_Capita_us(:,3) = Testing_us(:,4)./US_Pop;
Per_Capita_us(:,4) = Testing_us(:,5)./US_Pop;
Per_Capita_us(:,5) = Testing_us(:,6)./US_Pop;
Per_Capita_us(:,6) = Testing_us(:,7)./US_Pop;
Per_Capita_us(:,7) = Testing_us(:,8)./US_Pop;
Per_Capita_us(:,8) = Testing_us(:,9)./US_Pop;


%create and fill 3-D state-level array for per capita stats
%1-datenum, 2-pos tests/cases per, 3-neg tests per, 4-Pos+Neg per,
%5-pending per, 6-hosp per, 7-death per, 8-total per  
Per_Capita_st = zeros(H_HT_SI,8,78);

%Per_Capita(row, column, page) stats by FIPS (page). Column -->
%1-datenum, 2-pos, 3-neg, 4-pos+neg, 5-pending, 6-hosp, 7-death, 8-total

for i = 1:78
    Per_Capita_st(:,1,i) = Testing_st_3D(:,2,i);
    Pop_temp = demogph_st_table.Pop(i);
    Per_Capita_st(:,2,i) = Testing_st_3D(:,4,i)./Pop_temp;
    Per_Capita_st(:,3,i) = Testing_st_3D(:,5,i)./Pop_temp;
    Per_Capita_st(:,4,i) = Testing_st_3D(:,6,i)./Pop_temp;
    Per_Capita_st(:,5,i) = Testing_st_3D(:,7,i)./Pop_temp;
    Per_Capita_st(:,6,i) = Testing_st_3D(:,8,i)./Pop_temp;
    Per_Capita_st(:,7,i) = Testing_st_3D(:,9,i)./Pop_temp;
    Per_Capita_st(:,8,i) = Testing_st_3D(:,10,i)./Pop_temp;   
end


%%
%Calculate doubling times
%US on
DTime_states = [02 46 35];
DTime_divisions = [];
DTime_regions = [];
DTime_areas = [];
DTime_metros = [3 4 14 1 9 2 21];

dbl_t_us = zeros(H_M, 2);
dbl_start_us = [0 0];
ln_2 = log(2);
dbl_t_win = 7;
dbl_t_us(:,1) = All_st(:,1);

%US doubling times
for i = dbl_t_win+1:H_M
    if All_st(i,2) ~= 0
        if dbl_start_us(1) == 0
            dbl_start_us(1) = All_st(i,1);
        end
    end
    
    if All_st(i,3) ~= 0
        if dbl_start_us(2) == 0
            dbl_start_us(2) = All_st(i,1);
        end
    end
    
    dbl_temp = All_st(i,2)/All_st(i - dbl_t_win,2);
    if dbl_temp ~= 0    
        dbl_t_us(i,2) = (dbl_t_win*ln_2)/log(dbl_temp);
    end
    
    dbl_temp = All_st(i,3)/All_st(i - dbl_t_win,3);    
    if dbl_temp ~= 0    
        dbl_t_us(i,3) = (dbl_t_win*ln_2)/log(dbl_temp);
    end
end


%State doubling times
dbl_t_state = zeros(H_M, 2, 78);
dbl_start_state = zeros(78,2);
for s = 1:78 
    dbl_t_state(:,1,s) = Master_st(:,1,s);
    for i = dbl_t_win+1:H_M
        if Master_st(i,2,s) ~= 0
            if dbl_start_state(s,1) == 0
                dbl_start_state(s,1) = Master_st(i,1,s);
            end
        end
    
        if Master_st(i,3,s) ~= 0
            if dbl_start_state(s,2) == 0
                dbl_start_state(s,2) = Master_st(i,1,s);
            end
        end
    
        dbl_temp = Master_st(i,2,s)/Master_st(i - dbl_t_win,2,s);
        if dbl_temp ~= 0    
            dbl_t_state(i,2,s) = (dbl_t_win*ln_2)/log(dbl_temp);
        end
    
        dbl_temp = Master_st(i,3,s)/Master_st(i - dbl_t_win,3,s);    
        if dbl_temp ~= 0    
            dbl_t_state(i,3,s) = (dbl_t_win*ln_2)/log(dbl_temp);
        end
    end
end

%division doubling times
dbl_t_div = zeros(H_M, 2, 9);
dbl_start_div = zeros(9,2);
for d = 1:9
    dbl_t_div(:,1,d) = Division_st(:,1,d);
    for i = dbl_t_win+1:H_M
        if Division_st(i,2,d) ~= 0
            if dbl_start_div(d,1) == 0
                dbl_start_div(d,1) = Division_st(i,1,d);
            end
        end
    
        if Division_st(i,3,d) ~= 0
            if dbl_start_div(d,2) == 0
                dbl_start_div(d,2) = Division_st(i,1,d);
            end
        end
    
        dbl_temp = Division_st(i,2,d)/Division_st(i - dbl_t_win,2,d);
        if dbl_temp ~= 0    
            dbl_t_div(i,2,d) = (dbl_t_win*ln_2)/log(dbl_temp);
        end
    
        dbl_temp = Division_st(i,3,d)/Division_st(i - dbl_t_win,3,d);    
        if dbl_temp ~= 0    
            dbl_t_div(i,3,d) = (dbl_t_win*ln_2)/log(dbl_temp);
        end
    end
end
  
%region doubling times
dbl_t_reg = zeros(H_M, 2, 4);
dbl_start_reg = zeros(4,2);

for r = 1:4
    dbl_t_reg(:,1,r) = Region_st(:,1,r);
    for i = dbl_t_win+1:H_M
        if Region_st(i,2,r) ~= 0
            if dbl_start_reg(r,1) == 0
                dbl_start_reg(r,1) = Region_st(i,1,r);
            end
        end
    
        if Region_st(i,3,r) ~= 0
            if dbl_start_reg(r,2) == 0
                dbl_start_reg(r,2) = Region_st(i,1,r);
            end
        end
    
        dbl_temp = Region_st(i,2,r)/Region_st(i - dbl_t_win,2,r);
        if dbl_temp ~= 0    
            dbl_t_reg(i,2,r) = (dbl_t_win*ln_2)/log(dbl_temp);
        end
    
        dbl_temp = Region_st(i,3,r)/Region_st(i - dbl_t_win,3,r);    
        if dbl_temp ~= 0    
            dbl_t_reg(i,3,r) = (dbl_t_win*ln_2)/log(dbl_temp);
        end
    end
end

%Area doubling times
dbl_t_area = zeros(H_M, 2, n_areas);
dbl_start_areas = zeros(n_areas,2);
for a = 1:n_areas
    dbl_t_area(:,1,a) = Areas_st(:,1,a);
    for i = dbl_t_win+1:H_M
        if Areas_st(i,2,a) ~= 0
            if dbl_start_areas(a,1) == 0
                dbl_start_areas(a,1) = Areas_st(i,1,a);
            end
        end
    
        if Region_st(i,3,a) ~= 0
            if dbl_start_areas(a,2) == 0
                dbl_start_areas(a,2) = Areas_st(i,1,a);
            end
        end
    
        dbl_temp = Areas_st(i,2,a)/Areas_st(i - dbl_t_win,2,a);
        if dbl_temp ~= 0    
            dbl_t_area(i,2,a) = (dbl_t_win*ln_2)/log(dbl_temp);
        end
    
        dbl_temp = Areas_st(i,3,a)/Areas_st(i - dbl_t_win,3,a);    
        if dbl_temp ~= 0    
            dbl_t_area(i,3,a) = (dbl_t_win*ln_2)/log(dbl_temp);
        end
    end
end


%Metro doubling times
dbl_t_metro = zeros(H_M, 2, n_metro);
dbl_start_metro = zeros(n_metro,2);
for m = 1:n_metro
    dbl_t_metro(:,1,m) = Metro_cty(:,1,m);
    for i = dbl_t_win+1:H_M
        if Metro_cty(i,2,m) ~= 0
            if dbl_start_metro(m,1) == 0
                dbl_start_metro(m,1) = Metro_cty(i,1,m);
            end
        end
    
        if Metro_cty(i,3,m) ~= 0
            if dbl_start_metro(m,2) == 0
                dbl_start_metro(m,2) = Metro_cty(i,1,m);
            end
        end
    
        dbl_temp = Metro_cty(i,2,m)/Metro_cty(i - dbl_t_win,2,m);
        if dbl_temp ~= 0    
            dbl_t_metro(i,2,m) = (dbl_t_win*ln_2)/log(dbl_temp);
        end
    
        dbl_temp = Metro_cty(i,3,m)/Metro_cty(i - dbl_t_win,3,m);    
        if dbl_temp ~= 0    
            dbl_t_metro(i,3,m) = (dbl_t_win*ln_2)/log(dbl_temp);
        end
    end
end


%%
%See 'READ_ME.txt' & 'InputVars.m' for details on previously obtained plot
%parameters

%adjust plot window to even integer datetime, if using custom ticks
if cust_tick_on == 1    
    plot_win_us = (enddate + t_pad_us(2)) - (startdate + t_pad_us(1));
    if mod(plot_win_us,2) == 1
        t_pad_us(2) = t_pad_us(2) + 1;
    end    
    plot_win_sdr = (enddate + t_pad_sdr(2)) - (startdate + t_pad_sdr(1));
    if mod(plot_win_sdr,2) == 1
        t_pad_sdr(2) = t_pad_sdr(2) + 1;
    end    
    plot_win_cst = (enddate + t_pad_cst(2)) - (startdate + t_pad_cst(1));
    if mod(plot_win_cst,2) == 1
        t_pad_cst(2) = t_pad_cst(2) + 1;
    end   
    plot_win_dbl = (enddate + t_pad_dbl(2)) - (startdate + t_pad_dbl(1));
    if mod(plot_win_dbl,2) == 1
        t_pad_dbl(2) = t_pad_dbl(2) + 1;
    end
end
        
%US plot
if US_plot_on == 1             
    if semilog_US_on == 1
        figure('Renderer', 'painters', 'Position', fig_size_1)
        if US_cases_on == 1
            semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Positive Cases'])
            hold on
        end
        if US_deaths_on == 1
            semilogy(All_st(:,1),All_st(:,3),'DisplayName',['Deaths'])
            hold on
        end
        if US_tests_on == 1
            semilogy(Testing_us(:,1),Testing_us(:,5),'DisplayName',...
                ['All Test Results (Pos. + Neg.)'])
            hold on
        end
        if US_hosp_on == 1
            semilogy(Testing_us(:,1),Testing_us(:,7),'DisplayName',['Hospitalized'])
        end
        
        xlim([(startdate+t_pad_us(1)) (enddate+t_pad_us(2))])
        ylim(y_lmt_us)
        title('COrVID1920 - U.S. Data');
        xlabel('Date');
        ylabel('Known Number to Date');
        legend('Location','northwest','FontSize',lgd_font)   
        if cust_tick_on == 1    
            tick1=startdate+t_pad_us(1);
            tick2=enddate+t_pad_us(2);
            grid on
            grid minor
            xticks(tick1:tk_spc_maj:tick2);
            axe = gca;
            %axe.XAxis.MinorTick = 'on'; 
            axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
            datetick('x',6,'keepticks','keeplimits')
        else 
            grid on
            grid minor
            datetick('x',6,'keepticks','keeplimits')
        end
    end   
    if semilog_US_on == 0
        figure
        if US_cases_on == 1
            plot(All_st(:,1),All_st(:,2),'DisplayName',['Cases'])
            hold on
        end
        if US_deaths_on == 1
            plot(All_st(:,1),All_st(:,3),'DisplayName',['Deaths'])
            hold on
        end
        if US_tests_on == 1
            plot(Testing_us(:,1),Testing_us(:,5),'DisplayName',...
                ['All Test Results (Pos. + Neg.)'])
            hold on
        end
        if US_hosp_on == 1
            plot(Testing_us(:,1),Testing_us(:,7),'DisplayName',['Hospitalized'])
        end
        datetick('x',6,'keepticks','keeplimits')
        xlim([(startdate+t_pad_us(1)) (enddate+t_pad_us(2))])
        ylim(y_lmt_us)
        title('COrVID1920 - U.S. Data');
        xlabel('Date');
        ylabel('Known Number to Date');
        legend({'Positive Cases','Deaths'}, 'Location','northwest')
        grid on
        grid minor
    end
    if semilog_US_on == 2
        figure('Renderer', 'painters', 'Position', [10 10 1250 500])
        %plot semilog on left of fig, linear on right
        subplot1 = subplot(1,2,1);
        if US_cases_on == 1
            semilogy(subplot1,All_st(:,1),All_st(:,2),'DisplayName',['Cases'])
            hold on
        end
        if US_deaths_on == 1
            semilogy(subplot1,All_st(:,1),All_st(:,3),'DisplayName',['Deaths'])
            hold on
        end
        if US_tests_on == 1
            semilogy(subplot1,Testing_us(:,1),Testing_us(:,5),'DisplayName',...
                ['All Test Results (Pos. + Neg.)'])
            hold on
        end
        if US_hosp_on == 1
            semilogy(subplot1,Testing_us(:,1),Testing_us(:,7),'DisplayName',['Hospitalized'])
            hold on
        end
        datetick(subplot1,'x','keepticks','keeplimits')
        grid on
        grid minor
        xlim(subplot1,[(startdate+t_pad_us(1)) (enddate+t_pad_us(2))])
        title(subplot1,'COrVID1920 - U.S. Data');
        xlabel(subplot1,'Date');
        ylabel(subplot1,'Known Number to Date');
        legend(subplot1,'Location','northwest')
        subplot2 = subplot(1,2,2);
        if US_cases_on == 1
            plot(subplot2,All_st(:,1),All_st(:,2),'DisplayName',['Cases'])
            hold on
        end
        if US_deaths_on == 1
            plot(subplot2,All_st(:,1),All_st(:,3),'DisplayName',['Deaths'])
            hold on
        end
        if US_tests_on == 1
            plot(subplot2,Testing_us(:,1),Testing_us(:,5),'DisplayName',...
                ['All Test Results (Pos. + Neg.)'])
            hold on
        end
        if US_hosp_on == 1
            plot(subplot2,Testing_us(:,1),Testing_us(:,7),'DisplayName',['Hospitalized'])
            hold on
        end
        datetick(subplot2,'x',6,'keepticks','keeplimits')
        xlim(subplot2,[(startdate+t_pad_us(1)) (enddate+t_pad_us(2))])
        title(subplot2,'COrVID1920 - U.S. Data');
        xlabel(subplot2,'Date');
        ylabel(subplot1,'Known Number to Date');
        ylabel(subplot2,'Known Number to Date');
        legend(subplot2,'Location','northwest');
        grid on
        grid minor
    end
    
    %plot lines of constant doubling time, tau, in days
    %see dbl_lines_t in 'InputVars.m'
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_us(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"];
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end

    if write_png == 1
        saveas(gcf,'01_US.png')
    end
    hold off
end

%%
%State plots
if ST_plot_on == 1
    %find states to plot
    n_plot = size(state_plots,2);
    figure('Renderer', 'painters', 'Position', fig_size_1)

    %plot US cases
    if ST_include_US == 1;        
        if semilog_ST_on == 1
            semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        end
        if semilog_ST_on == 0
            plot(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        end
        hold on
    end
     
    %plot division, if applicable
    if ST_include_DIV == 1;
        if semilog_ST_on == 1
            semilogy(Division_st(:,1,state_div),Division_st(:,2,state_div),...
                'DisplayName',['New England'])
        end
        if semilog_ST_on == 0
            plot(Division_st(:,1,state_div),Division_st(:,2,state_div),...
                'DisplayName',['Total U.S.'])
        end
        hold on
    end
    %state plots
    for i = 1:n_plot
        fips = state_plots(i);
        if semilog_ST_on == 1
            hold on
            ST_name = string(fipscode_2.ABR(fips));
            semilogy(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',[ST_name])
        end
        if semilog_ST_on == 0
            hold on
            ST_name = string(fipscode_2.ABR(fips));
            plot(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',[ST_name])
        end
    end

    if semilog_RG_on == 1
        ylim(y_lmt_sdr)
    end
    xlim([(startdate+t_pad_sdr(1)) (enddate+t_pad_sdr(2))])
    title('COrVID1920 - State Data');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    
    if cust_tick_on == 1    
        tick1=startdate+t_pad_sdr(1);
        tick2=enddate+t_pad_sdr(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end

    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_sdr(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    hold off
    
    if write_png == 1
        saveas(gcf,'04_State.png')
    end
end
%%
%Division plots
if DV_plot_on == 1
    %find divisions to plot
    n_plot = size(div_plots,2);
    figure('Renderer', 'painters', 'Position', fig_size_1)

    %plot US cases
    if DV_include_US == 1;        
        if semilog_DV_on == 1
            semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        end
        if semilog_DV_on == 0
            plot(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        end
    end
     
    %division plots
    for i = 1:n_plot
        div = div_plots(i);
        if semilog_DV_on == 1
            hold on
            DV_name = string(divcode.Name(div));
            if i ~= 9
                if i ~= 8
                    semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',[DV_name])
                end
            end
            if i == 8
                semilogy(Division_st(:,1,div),Division_st(:,2,div),'g','DisplayName',[DV_name])
            end
            if i == 9
                semilogy(Division_st(:,1,div),Division_st(:,2,div),'k','DisplayName',[DV_name])
            end
        end
        if semilog_DV_on == 0
            hold on
            DV_name = string(divcode.ABR(div));
            plot(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',[DV_name])
        end
    end

    if semilog_RG_on == 1
        ylim(y_lmt_sdr)
    end
    xlim([(startdate+t_pad_sdr(1)) (enddate+t_pad_sdr(2))])
    title('COrVID1920 - Census Division Data');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    
    if cust_tick_on == 1    
        tick1=startdate+t_pad_sdr(1);
        tick2=enddate+t_pad_sdr(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_sdr(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"];
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end    
    hold off
    
    if write_png == 1
        saveas(gcf,'06_Div.png')
    end
end

%%
%Region plots
if RG_plot_on == 1
    %find regions to plot
    n_plot = size(reg_plots,2);
    figure('Renderer', 'painters', 'Position', fig_size_1)

    %plot US cases
    if RG_include_US == 1;        
        if semilog_RG_on == 1
            semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        end
        if semilog_RG_on == 0
            plot(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        end
    end
     
    %region plots
    for i = 1:n_plot
        reg = reg_plots(i);
        if semilog_RG_on == 1
            hold on
            RG_name = string(regcode.Name(reg));
            semilogy(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',[RG_name])
        end
        if semilog_RG_on == 0
            hold on
            RG_name = string(regcode.ABR(reg));
            plot(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',[RG_name])
        end
    end
    
    if semilog_RG_on == 1
        ylim(y_lmt_sdr)
    end
    xlim([(startdate+t_pad_sdr(1)) (enddate+t_pad_sdr(2))])
    title('COrVID1920 - Region Data');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    
    if cust_tick_on == 1    
        tick1=startdate+t_pad_sdr(1);
        tick2=enddate+t_pad_sdr(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end

    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_sdr(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    hold off
    
    if write_png == 1
        saveas(gcf,'05_Reg.png')
    end
end

%%
%Custom areas plots
if CST_plot_on == 1
    figure('Renderer', 'painters', 'Position', fig_size_1)

    %plot US cases
    if CST_include_US == 1;        
        if semilog_CST_on == 1
            semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
            hold on
        end
        if semilog_CST_on == 0
            plot(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
            hold on
        end
    end
     
    %custom area plots
    for i = 1:n_areas
        area = i;
        if semilog_CST_on == 1
            hold on
            CST_name = areas_name(i);
            semilogy(Areas_st(:,1,i),Areas_st(:,2,i),'DisplayName',[CST_name])
        end
        if semilog_CST_on == 0
            hold on
            CST_name = areas_name(i);
            plot(Areas_st(:,1,i),Areas_st(:,2,i),'DisplayName',[CST_name])
        end       
        %datetick('x',6,'keepticks','keeplimits')
        %xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    end
    
    if semilog_CST_on == 1
        ylim(y_lmt_cst)
    end
    xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    title('COrVID1920 - Custom Areas');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    
    if cust_tick_on == 1    
        tick1=startdate+t_pad_cst(1);
        tick2=enddate+t_pad_cst(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end

    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_cst(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    hold off
    
    if write_png == 1
        saveas(gcf,'03_Areas.png')
    end
end

%%
%Custom Metro Plots. Copy/pase main if statement multiple times for more
%plots

%CCTY plot 1, NYC Metro Area
if CCTY_plots_on(1) == 1
    figure('Renderer', 'painters', 'Position', fig_size_1)
    %plot US cases
    if CCTY_include_us(1) == 1;        
        semilogy(All_st(:,1),All_st(:,2),'b','DisplayName',['U.S. Cases'])
        hold on
        semilogy(All_st(:,1),All_st(:,3),'-.b','DisplayName',['U.S. Deaths'])
        hold on
    end
    if CCTY_include_reg(1) == 1;
        reg = 1;
        semilogy(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',...
            ['Northeast Cases'])
        hold on
    end
    if CCTY_include_div(1) == 1;
        div = 2;
        semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',...
            ['Mid-Atlantic Cases'])
        hold on
    end
    if CCTY_include_st(1) == 1;
        fips = 36;
        semilogy(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',...
            ['NY State Cases'])
        hold on
    end
    if CCTY_include_area(1) == 1;
        area = 2;
        semilogy(Areas_st(:,1,area),Areas_st(:,2,area),'r','DisplayName',...
            ['NY Tri-State Cases'])
        hold on
        semilogy(Areas_st(:,1,area),Areas_st(:,3,area),'-.r','DisplayName',...
            ['NY Tri-State Deaths'])
        hold on
    end

    semilogy(Metro_cty(:,1,1),Metro_cty(:,2,1),'g','DisplayName',...
        ['NYC Metro Cases'])
    hold on
    semilogy(Metro_cty(:,1,1),Metro_cty(:,3,1),'-.g','DisplayName',...
        ['NYC Metro Deaths'])
    
    xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    ylim(y_lmt_cst)
    title('COrVID1920 - Greater NYC');
    xlabel('Date');
    ylabel('Known Number to Date');
    legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_cst(1);
        tick2=enddate+t_pad_cst(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    
    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_cst(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    hold off  
    
    if write_png == 1
        saveas(gcf,'02_NYC.png')
    end
end

%CCTY plot 2, Pacific NW
if CCTY_plots_on(2) == 1
    figure('Renderer', 'painters', 'Position', fig_size_1)
    %plot US cases
    if CCTY_include_us(2) == 1;        
        semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        hold on
    end
    if CCTY_include_reg(2) == 1;
        reg = 4;
        semilogy(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',...
            ['West U.S.'])
        hold on
    end
    if CCTY_include_div(2) == 1;
        div = 9;
        semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',...
            ['Pacific'])
        hold on
    end
    if CCTY_include_st(2) == 1;
        fips = 53;
        semilogy(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',...
            ['Washington'])
        hold on
    end
    if CCTY_include_area(2) == 1;
        area = 1;
        semilogy(Areas_st(:,1,area),Areas_st(:,2,area),'DisplayName',...
            ['Pacific NW'])
        hold on
    end
    %CST_name = areas_name(i);
    %Seatac
    MET_name = metro_name(3);
    semilogy(Metro_cty(:,1,3),Metro_cty(:,2,3),'DisplayName',[MET_name])
    hold on
    %Portland, OR
    MET_name = metro_name(4);
    semilogy(Metro_cty(:,1,4),Metro_cty(:,2,4),'DisplayName',[MET_name])
    hold on
    %Corvallis/Albany/Salem
    MET_name = metro_name(8);
    semilogy(Metro_cty(:,1,8),Metro_cty(:,2,8),'DisplayName',[MET_name])
    hold on
    %Fairbanks/Interior
    MET_name = metro_name(6);
    semilogy(Metro_cty(:,1,6),Metro_cty(:,2,6),'DisplayName',[MET_name]);
    hold on
    %Anchorage/Southcentral
    MET_name = metro_name(5);
    semilogy(Metro_cty(:,1,5),Metro_cty(:,2,5),'DisplayName',[MET_name])
    hold on
    %Juneau/Southeast
    MET_name = metro_name(7);
    semilogy(Metro_cty(:,1,7),Metro_cty(:,2,7),'g','DisplayName',[MET_name]);
    hold on
    
    xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    ylim(y_lmt_cst)
    title('COrVID1920 - Pacific NW Metros');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_cst(1);
        tick2=enddate+t_pad_cst(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    
    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_cst(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
        uistack(t_ann,'top');
    end
    
    hold off   
    if write_png == 1
        saveas(gcf,'07_PacNW.png')
    end
end

%CCTY plot 3, Northeast Metros
if CCTY_plots_on(3) == 1
    figure('Renderer', 'painters', 'Position', fig_size_1)
    %plot US cases
    if CCTY_include_us(3) == 1;        
        semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        hold on
    end
    if CCTY_include_reg(3) == 1;
        reg = 1;
        semilogy(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',['NE U.S.'])
        hold on
    end
    if CCTY_include_div(3) == 1;
        div = 1;
        semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',['New England'])
        hold on
        div = 2;
        semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',['Mid-Atlantic'])
        hold on
    end
    if CCTY_include_st(3) == 1;
        fips = 36;
        semilogy(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',...
            ['N.Y.S.'])
        hold on
    end
    if CCTY_include_area(3) == 1;
        area = 2;
        semilogy(Areas_st(:,1,area),Areas_st(:,2,area),'DisplayName',['NY Tri-State'])
        hold on
    end
    %Boston
    MET_name = metro_name(2);
    semilogy(Metro_cty(:,1,2),Metro_cty(:,2,2),'DisplayName',[MET_name])
    hold on
    %Providence/New Beige
    MET_name = metro_name(9);
    semilogy(Metro_cty(:,1,9),Metro_cty(:,2,9),'DisplayName',[MET_name])
    hold on
    %Hartford
    MET_name = metro_name(10);
    semilogy(Metro_cty(:,1,10),Metro_cty(:,2,10),'DisplayName',[MET_name])
    hold on
    %NYC
    MET_name = metro_name(1);
    semilogy(Metro_cty(:,1,1),Metro_cty(:,2,1),'DisplayName',[MET_name])
    hold on
    %Philly
    MET_name = metro_name(11);
    semilogy(Metro_cty(:,1,11),Metro_cty(:,2,11),'DisplayName',[MET_name])
    hold on
    %DC
    MET_name = metro_name(12);
    %semilogy(Metro_cty(:,1,12),Metro_cty(:,2,12),'DisplayName',[MET_name])
    semilogy(Metro_cty(:,1,12),Metro_cty(:,2,12),...
        'DisplayName',['Washington, D.C.*'])
    hold on
    
    xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    ylim(y_lmt_cst)
    title('COrVID1920 - Northeast Metros');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    
    if cust_tick_on == 1    
        tick1=startdate+t_pad_cst(1);
        tick2=enddate+t_pad_cst(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
        
    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_cst(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    
    str = ["* - data from some counties in the", ...
           "D.C. Metropolitan Statistical Area", ...
           "are missing from the numbers shown"]; 
    dc_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
    dc_ann.FontSize = 5;
    dc_ann.LineStyle = 'none';
    dc_ann.Position = [0.65 0.1 0.3 0.2];
    
    hold off   
    if write_png == 1
        saveas(gcf,'08_Northeast.png')
    end
end

%CCTY plot 4, California Metros
if CCTY_plots_on(4) == 1
    figure('Renderer', 'painters', 'Position', fig_size_1)
    %plot US cases
    if CCTY_include_us(4) == 1;        
        semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        hold on
    end
    if CCTY_include_reg(4) == 1;
        reg = 4;
        semilogy(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',['West U.S.'])
        hold on
    end
    if CCTY_include_div(4) == 1;
        div = 9;
        semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',...
            ['Pacific'])
        hold on
    end
    if CCTY_include_st(4) == 1;
        fips = 06;
        semilogy(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',...
            ['California'])
        hold on
    end
    if CCTY_include_area(4) == 1;
        area = 1;
        semilogy(Areas_st(:,1,area),Areas_st(:,2,area),'DisplayName',['Pacific NW States'])
        hold on
    end

    %Los Angeles
    MET_name = metro_name(13);
    semilogy(Metro_cty(:,1,13),Metro_cty(:,2,13),'DisplayName',[MET_name])
    hold on
    %SF Bay
    MET_name = metro_name(14);
    semilogy(Metro_cty(:,1,14),Metro_cty(:,2,14),'DisplayName',[MET_name])
    hold on
    %San Diego
    MET_name = metro_name(15);
    semilogy(Metro_cty(:,1,15),Metro_cty(:,2,15),'DisplayName',[MET_name])
    hold on
    %Sacramento
    MET_name = metro_name(32);
    semilogy(Metro_cty(:,1,32),Metro_cty(:,2,32),'DisplayName',[MET_name])
    hold on
    
    xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    ylim(y_lmt_cst)
    title('COrVID1920 - California Metros');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_cst(1);
        tick2=enddate+t_pad_cst(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    
    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_cst(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    
    hold off   
    if write_png == 1
        saveas(gcf,'09_CA.png')
    end
end


%CCTY Plot 5, Florida Metros
if CCTY_plots_on(5) == 1
    figure('Renderer', 'painters', 'Position', fig_size_1)
    %plot US cases
    if CCTY_include_us(5) == 1;        
        semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        hold on
    end
    if CCTY_include_reg(5) == 1;
        reg = 3;
        semilogy(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',['South U.S.'])
        hold on
    end
    if CCTY_include_div(5) == 1;
        div = 5;
        semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',...
            ['South Atlantic'])
        hold on
    end
    if CCTY_include_st(5) == 1;
        fips = 12;
        semilogy(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',...
            ['Florida'])
        hold on
    end
    if CCTY_include_area(5) == 1;
        area = 1;
        semilogy(Areas_st(:,1,area),Areas_st(:,2,area),'DisplayName',['Pacific NW'])
        hold on
    end
    %Jacksonville
    MET_name = metro_name(16);
    semilogy(Metro_cty(:,1,16),Metro_cty(:,2,16),'DisplayName',[MET_name])
    hold on
    %Miami
    MET_name = metro_name(17);
    semilogy(Metro_cty(:,1,17),Metro_cty(:,2,17),'DisplayName',[MET_name])
    hold on
    %Orlando
    MET_name = metro_name(18);
    semilogy(Metro_cty(:,1,18),Metro_cty(:,2,18),'DisplayName',[MET_name])
    hold on
    %Tampa Bay
    MET_name = metro_name(19);
    semilogy(Metro_cty(:,1,19),Metro_cty(:,2,19),'DisplayName',[MET_name])
    hold on
    
    xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    ylim(y_lmt_cst)
    title('COrVID1920 - Florida Metros');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    
    if cust_tick_on == 1    
        tick1=startdate+t_pad_cst(1);
        tick2=enddate+t_pad_cst(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
        
    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_cst(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    
    hold off 
    if write_png == 1
        saveas(gcf,'10_FL.png')
    end  
end

%CCTY Plot 6, Texas Metros
if CCTY_plots_on(6) == 1
    figure('Renderer', 'painters', 'Position', fig_size_1)
    %plot US cases
    if CCTY_include_us(6) == 1;        
        semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        hold on
    end
    if CCTY_include_reg(6) == 1;
        reg = 3;
        semilogy(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',['South U.S.'])
        hold on
    end
    if CCTY_include_div(6) == 1;
        div = 7;
        semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',...
            ['West South Central U.S.'])
        hold on
    end
    if CCTY_include_st(6) == 1;
        fips = 48;
        semilogy(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',...
            ['Texas'])
        hold on
    end
    if CCTY_include_area(6) == 1;
        area = 1;
        semilogy(Areas_st(:,1,area),Areas_st(:,2,area),'DisplayName',['Pacific NW'])
        hold on
    end
    %Dallas/F.W.
    MET_name = metro_name(20);
    semilogy(Metro_cty(:,1,20),Metro_cty(:,2,20),'DisplayName',[MET_name])
    hold on
    %Houston
    MET_name = metro_name(21);
    semilogy(Metro_cty(:,1,21),Metro_cty(:,2,21),'DisplayName',[MET_name])
    hold on
    %San Antonio
    MET_name = metro_name(22);
    semilogy(Metro_cty(:,1,22),Metro_cty(:,2,22),'DisplayName',[MET_name])
    hold on
    %Austin
    MET_name = metro_name(23);
    semilogy(Metro_cty(:,1,23),Metro_cty(:,2,23),'DisplayName',[MET_name])
    hold on
    
    xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    ylim(y_lmt_cst)
    title('COrVID1920 - Texas Metros');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    
    if cust_tick_on == 1    
        tick1=startdate+t_pad_cst(1);
        tick2=enddate+t_pad_cst(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
        
    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_cst(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    
    hold off   
    if write_png == 1
        saveas(gcf,'11_TX.png')
    end
end

%CCTY Plot 7, Midwest Metros
if CCTY_plots_on(7) == 1
    figure('Renderer', 'painters', 'Position', fig_size_1)
    %plot US cases
    if CCTY_include_us(7) == 1;        
        semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        hold on
    end
    if CCTY_include_reg(7) == 1;
        reg = 2;
        semilogy(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',['Midwest U.S.'])
        hold on
    end
    if CCTY_include_div(7) == 1;
        div = 3;
        semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',...
            ['East North Central U.S.'])
        hold on
    end
    if CCTY_include_st(7) == 1;
        fips = 39;
        semilogy(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',...
            ['Ohio'])
        hold on
    end
    if CCTY_include_area(7) == 1;
        area = 2;
        semilogy(Areas_st(:,1,area),Areas_st(:,2,area),'DisplayName',['NYC Metro'])
        hold on
    end
    %Chicago
    MET_name = metro_name(24);
    semilogy(Metro_cty(:,1,24),Metro_cty(:,2,24),'DisplayName',[MET_name])
    hold on
    %Detroit
    MET_name = metro_name(25);
    semilogy(Metro_cty(:,1,25),Metro_cty(:,2,25),'DisplayName',[MET_name])
    hold on
    %Minn/St 
    MET_name = metro_name(26);
    semilogy(Metro_cty(:,1,26),Metro_cty(:,2,26),'DisplayName',[MET_name])
    hold on
    %Inndinapolis
    MET_name = metro_name(27);
    semilogy(Metro_cty(:,1,27),Metro_cty(:,2,27),'DisplayName',[MET_name])
    hold on
    %Cleveland
    MET_name = metro_name(28);
    semilogy(Metro_cty(:,1,28),Metro_cty(:,2,28),'DisplayName',[MET_name])
    hold on
    %Columbus
    MET_name = metro_name(29);
    semilogy(Metro_cty(:,1,29),Metro_cty(:,2,29),'DisplayName',[MET_name])
    hold on
    %Cinnnnati
    MET_name = metro_name(30);
    semilogy(Metro_cty(:,1,30),Metro_cty(:,2,30),'DisplayName',[MET_name])
    hold on
    %Kansas City
    MET_name = metro_name(31);
    semilogy(Metro_cty(:,1,31),Metro_cty(:,2,31),'DisplayName',[MET_name])
    hold on
    %Lansing
    MET_name = metro_name(44);
    semilogy(Metro_cty(:,1,44),Metro_cty(:,2,44),'DisplayName',[MET_name])
    hold on
   
    xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    ylim(y_lmt_cst)
    title('COrVID1920 - Midwest Metros');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_cst(1);
        tick2=enddate+t_pad_cst(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end

    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_cst(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    
    hold off   
    if write_png == 1
        saveas(gcf,'12_Midwest.png')
    end
end

%CCTY Plot 8, Mountain West
if CCTY_plots_on(8) == 1
    figure('Renderer', 'painters', 'Position', fig_size_1)
    %plot US cases
    if CCTY_include_us(8) == 1;        
        semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        hold on
    end
    if CCTY_include_reg(8) == 1;
        reg = 4;
        semilogy(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',['West U.S.'])
        hold on
    end
    if CCTY_include_div(8) == 1;
        div = 3;
        semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',...
            ['***'])
        hold on
    end
    if CCTY_include_st(8) == 1;
        fips = 39;
        semilogy(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',...
            ['***'])
        hold on
    end
    if CCTY_include_area(8) == 1;
        area = 2;
        semilogy(Areas_st(:,1,area),Areas_st(:,2,area),'DisplayName',['*'])
        hold on
    end
    
    %Denver
    MET_name = metro_name(33);
    semilogy(Metro_cty(:,1,33),Metro_cty(:,2,33),'DisplayName',[MET_name])
    hold on
    %SLC/Provo
    MET_name = metro_name(34);
    semilogy(Metro_cty(:,1,34),Metro_cty(:,2,34),'DisplayName',[MET_name])
    hold on
    %Las Vegas
    MET_name = metro_name(35);
    semilogy(Metro_cty(:,1,35),Metro_cty(:,2,35),'DisplayName',[MET_name])
    hold on
    %Phoenix
    MET_name = metro_name(36);
    semilogy(Metro_cty(:,1,36),Metro_cty(:,2,36),'DisplayName',[MET_name])
    hold on
    %Albuquerque
    MET_name = metro_name(37);
    semilogy(Metro_cty(:,1,37),Metro_cty(:,2,37),'DisplayName',[MET_name])
    hold on
    %Tuscon
    MET_name = metro_name(38);
    semilogy(Metro_cty(:,1,38),Metro_cty(:,2,38),'DisplayName',[MET_name])
    hold on
    %El Paso
    MET_name = metro_name(39);
    semilogy(Metro_cty(:,1,39),Metro_cty(:,2,39),'DisplayName',[MET_name])
    hold on
    
    xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    ylim(y_lmt_cst)
    title('COrVID1920 - Mountain West Metros');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_cst(1);
        tick2=enddate+t_pad_cst(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end    
    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_cst(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    
    hold off  
    if write_png == 1
        saveas(gcf,'13_Mountain.png')
    end 
end


%CCTY Plot 9 - South US
if CCTY_plots_on(9) == 1
    figure('Renderer', 'painters', 'Position', fig_size_1)
    %plot US cases
    if CCTY_include_us(9) == 1;        
        semilogy(All_st(:,1),All_st(:,2),'DisplayName',['Total U.S.'])
        hold on
    end
    if CCTY_include_reg(9) == 1;
        reg = 3;
        semilogy(Region_st(:,1,reg),Region_st(:,2,reg),'DisplayName',['South U.S.'])
        hold on
    end
    if CCTY_include_div(9) == 1;
        div = 3;
        semilogy(Division_st(:,1,div),Division_st(:,2,div),'DisplayName',...
            ['***'])
        hold on
    end
    if CCTY_include_st(9) == 1;
        fips = 39;
        semilogy(Master_st(:,1,fips),Master_st(:,2,fips),'DisplayName',...
            ['***'])
        hold on
    end
    if CCTY_include_area(9) == 1;
        area = 2;
        semilogy(Areas_st(:,1,area),Areas_st(:,2,area),'DisplayName',['*'])
        hold on
    end
    %Atlanta
    MET_name = metro_name(40);
    semilogy(Metro_cty(:,1,40),Metro_cty(:,2,40),'DisplayName',[MET_name])
    hold on
    %Charlotte
    MET_name = metro_name(41);
    semilogy(Metro_cty(:,1,41),Metro_cty(:,2,41),'DisplayName',[MET_name])
    hold on
    %Nashviille
    MET_name = metro_name(42);
    semilogy(Metro_cty(:,1,42),Metro_cty(:,2,42),'DisplayName',[MET_name])
    hold on
    %New Orleans
    MET_name = metro_name(43);
    semilogy(Metro_cty(:,1,43),Metro_cty(:,2,43),'DisplayName',[MET_name])
    hold on

    xlim([(startdate+t_pad_cst(1)) (enddate+t_pad_cst(2))])
    ylim(y_lmt_cst)
    title('COrVID1920 - South Metros');
    xlabel('Date');
    ylabel('Cases');
    legend('Location','northwest','FontSize',lgd_font)
    
    if cust_tick_on == 1    
        tick1=startdate+t_pad_cst(1);
        tick2=enddate+t_pad_cst(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    
    %Plot lines of constant doubling time, tau, in days
    if dbl_lines_on == 1
        time_d0 = linspace(1,H_M,100);
        time_d = time_d0 + startdate + t_pad_cst(1);
        dt = zeros(n_dbl,100);
        for i = 1:n_dbl
            dt(i,:) = (10)*(2.^(time_d0/dbl_lines_t(i)));
            pl_temp = semilogy(time_d,dt(i,:),'--','LineWidth',.5,...
            'HandleVisibility','off','color',[0 0 0]+0.5);
            uistack(pl_temp,'bottom');
        end    
        str = ["Slopes of dashed lines correspond to"...
            "doubling times \tau_{d} = 2, 3, 5, 10, 20 days"]; 
        t_ann = annotation('textbox','String',str,'FitBoxToText','on'); 
        t_ann.FontSize = 7;
        t_ann.LineStyle = 'none';
        t_ann.Position = [0.55 0 0.4 0.2];
    end
    
    hold off   
    if write_png == 1
        saveas(gcf,'14_South.png')
    end
end

%Plot doubling times for assorted areas
figure('Renderer', 'painters', 'Position', fig_size_2)
us = plot(dbl_t_us(:,1),dbl_t_us(:,2),'-.k','DisplayName',['All U.S.']);
hold on

for s = DTime_states
    ST_name = string(fipscode_2.Name(s));
    plot(dbl_t_state(:,1,s),dbl_t_state(:,2,s),'DisplayName',[ST_name])
end

for d = DTime_divisions
    DV_name = string(divcode.Name(d));
    plot(dbl_t_div(:,1,d),dbl_t_div(:,2,d),'DisplayName',[DV_name])
end

for r = DTime_regions
    RG_name = string(regcode.Name(r));
    plot(dbl_t_reg(:,1,r),dbl_t_reg(:,2,r),'DisplayName',[RG_name])
end

for a = DTime_areas
    CST_name = areas_name(a);
    plot(dbl_t_area(:,1,a),dbl_t_area(:,2,a),'DisplayName',[CST_name])
end

for m = DTime_metros
    MET_name = metro_name(m);
    plot(dbl_t_metro(:,1,m),dbl_t_metro(:,2,m),'DisplayName',[MET_name])
end

xlim([(startdate+t_pad_dbl(1)) (enddate+t_pad_dbl(2))])
ylim(y_lmt_dbl)
title('COrVID1920 - Cases Doubling Time (smoothing t = 7 days)');
xlabel('Date');
ylabel('Doubling Time (days)');
legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_dbl(1);
        tick2=enddate+t_pad_dbl(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end 
uistack(us,'top')
hold off
if write_png == 1
    saveas(gcf,'15_Double.png')
end


%%
%plot testing per 1000 residents for each state, grouped by selected 
%regions

%New England
if st_tests_per_th == 1;
    figure('Renderer', 'painters', 'Position', fig_size_1)
    temp_us_thou = Per_Capita_us(:,4).*1000;
    plot(Per_Capita_us(:,1),temp_us_thou,'-.k','DisplayName',['All U.S.']);
    hold on
    
    plt_cnt = 0;
    for i = [09 23 25 33 44 50]
        plt_cnt = plt_cnt + 1;
        date_temp = Per_Capita_st(:,1,i);
        test_temp = Per_Capita_st(:,4,i).*1000;
        ST_name = string(fipscode_2.ABR(i));
        if plt_cnt <= 7
            plot(date_temp, test_temp,'DisplayName',[ST_name]);
        else
            plot(date_temp, test_temp,'-.','DisplayName',[ST_name]);
        end
        hold on
    end
    xlim([(startdate+t_pad_us(1)) (enddate+t_pad_us(2))])
    if y_lmt_tst_on == 1
        ylim(y_lmt_tst)
    end
    title({'COrVID1920 - Total Tests (Pos + Neg) Per 1000 Residents','New England States'});
    xlabel('Date');
    ylabel('Cumulative Tests to Date');
    legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_us(1);
        tick2=enddate+t_pad_us(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        yticks(y_lmt_tst(1):y_tk_tst_maj:y_lmt_tst(2));
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    if write_png == 1
        saveas(gcf,'16_Tst_NewEng.png')
    end
end

%Mid-Atlantic
if st_tests_per_th == 1;
    figure('Renderer', 'painters', 'Position', fig_size_1)
    temp_us_thou = Per_Capita_us(:,4).*1000;
    plot(Per_Capita_us(:,1),temp_us_thou,'-.k','DisplayName',['All U.S.']);
    hold on
    
    plt_cnt = 0;
    for i = [34 36 42 10 11 24 51 54] 
        plt_cnt = plt_cnt + 1;
        date_temp = Per_Capita_st(:,1,i);
        test_temp = Per_Capita_st(:,4,i).*1000;
        ST_name = string(fipscode_2.ABR(i));
        if plt_cnt <= 7
            plot(date_temp, test_temp,'DisplayName',[ST_name]);
        else
            plot(date_temp, test_temp,'-.','DisplayName',[ST_name]);
        end
        hold on
    end
    xlim([(startdate+t_pad_us(1)) (enddate+t_pad_us(2))])
    if y_lmt_tst_on == 1
        ylim(y_lmt_tst)
    end
    title({'COrVID1920 - Total Tests (Pos + Neg) Per 1000 Residents','Mid-Atlantic States'});
    xlabel('Date');
    ylabel('Cumulative Tests to Date');
    legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_us(1);
        tick2=enddate+t_pad_us(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        yticks(y_lmt_tst(1):y_tk_tst_maj:y_lmt_tst(2));
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    if write_png == 1
        saveas(gcf,'17_Tst_MidAtl.png')
    end
end

%South
if st_tests_per_th == 1;
    figure('Renderer', 'painters', 'Position', fig_size_1)
    temp_us_thou = Per_Capita_us(:,4).*1000;
    plot(Per_Capita_us(:,1),temp_us_thou,'-.k','DisplayName',['All U.S.']);
    hold on
    
    plt_cnt = 0;
    for i = [12 13 37 45 01 21 28 47 05 22 40 48]  
        plt_cnt = plt_cnt + 1;
        date_temp = Per_Capita_st(:,1,i);
        test_temp = Per_Capita_st(:,4,i).*1000;
        ST_name = string(fipscode_2.ABR(i));
        if plt_cnt <= 7
            plot(date_temp, test_temp,'DisplayName',[ST_name]);
        else
            plot(date_temp, test_temp,'-.','DisplayName',[ST_name]);
        end
        hold on
    end
    xlim([(startdate+t_pad_us(1)) (enddate+t_pad_us(2))])
    if y_lmt_tst_on == 1
        ylim(y_lmt_tst)
    end
    title({'COrVID1920 - Total Tests (Pos + Neg) Per 1000 Residents','Southern States'});
    xlabel('Date');
    ylabel('Cumulative Tests to Date');
    legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_us(1);
        tick2=enddate+t_pad_us(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        yticks(y_lmt_tst(1):y_tk_tst_maj:y_lmt_tst(2));
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    if write_png == 1
        saveas(gcf,'18_Tst_South.png')
    end
end

%Midwest
if st_tests_per_th == 1;
    figure('Renderer', 'painters', 'Position', fig_size_1)
    temp_us_thou = Per_Capita_us(:,4).*1000;
    plot(Per_Capita_us(:,1),temp_us_thou,'-.k','DisplayName',['All U.S.']);
    hold on

    plt_cnt = 0;
    for i = [17 18 26 39 55 19 20 27 29 31 38 46]  
        plt_cnt = plt_cnt + 1;
        date_temp = Per_Capita_st(:,1,i);
        test_temp = Per_Capita_st(:,4,i).*1000;
        ST_name = string(fipscode_2.ABR(i));
        if plt_cnt <= 7
            plot(date_temp, test_temp,'DisplayName',[ST_name]);
        else
            plot(date_temp, test_temp,'-.','DisplayName',[ST_name]);
        end
        hold on
    end
    xlim([(startdate+t_pad_us(1)) (enddate+t_pad_us(2))])
    if y_lmt_tst_on == 1
        ylim(y_lmt_tst)
    end
    title({'COrVID1920 - Total Tests (Pos + Neg) Per 1000 Residents','Midwest States'});
    xlabel('Date');
    ylabel('Cumulative Tests to Date');
    legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_us(1);
        tick2=enddate+t_pad_us(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        yticks(y_lmt_tst(1):y_tk_tst_maj:y_lmt_tst(2));
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    if write_png == 1
        saveas(gcf,'19_Tst_MidWest.png')
    end
end

%Mountain West
if st_tests_per_th == 1;
    figure('Renderer', 'painters', 'Position', fig_size_1)
    temp_us_thou = Per_Capita_us(:,4).*1000;
    plot(Per_Capita_us(:,1),temp_us_thou,'-.k','DisplayName',['All U.S.']);
    hold on
    
    plt_cnt = 0;
    for i = [04 08 16 30 32 35 49 56]
        plt_cnt = plt_cnt + 1;
        date_temp = Per_Capita_st(:,1,i);
        test_temp = Per_Capita_st(:,4,i).*1000;
        ST_name = string(fipscode_2.ABR(i));
        if plt_cnt <= 7
            plot(date_temp, test_temp,'DisplayName',[ST_name]);
        else
            plot(date_temp, test_temp,'-.','DisplayName',[ST_name]);
        end
        hold on
    end
    xlim([(startdate+t_pad_us(1)) (enddate+t_pad_us(2))])
    if y_lmt_tst_on == 1
        ylim(y_lmt_tst)
    end
    title({'COrVID1920 - Total Tests (Pos + Neg) Per 1000 Residents','Mountain West States'});
    xlabel('Date');
    ylabel('Cumulative Tests to Date');
    legend('Location','northwest','FontSize',lgd_font)
    if cust_tick_on == 1    
        tick1=startdate+t_pad_us(1);
        tick2=enddate+t_pad_us(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        yticks(y_lmt_tst(1):y_tk_tst_maj:y_lmt_tst(2));
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    if write_png == 1
        saveas(gcf,'20_Tst_Mountain.png')
    end
end

%Pacific
if st_tests_per_th == 1;
    figure('Renderer', 'painters', 'Position', fig_size_1)
    temp_us_thou = Per_Capita_us(:,4).*1000;
    plot(Per_Capita_us(:,1),temp_us_thou,'-.k','DisplayName',['All U.S.']);
    hold on
    
    plt_cnt = 0;
    for i = [02 06 15 41 53]  
        plt_cnt = plt_cnt + 1;
        date_temp = Per_Capita_st(:,1,i);
        test_temp = Per_Capita_st(:,4,i).*1000;
        ST_name = string(fipscode_2.ABR(i));
        if plt_cnt <= 7
            plot(date_temp, test_temp,'DisplayName',[ST_name]);
        else
            plot(date_temp, test_temp,'-.','DisplayName',[ST_name]);
        end
        hold on
    end
    xlim([(startdate+t_pad_us(1)) (enddate+t_pad_us(2))])
    if y_lmt_tst_on == 1
        ylim(y_lmt_tst)
    end
    title({'COrVID1920 - Total Tests (Pos + Neg) Per 1000 Residents','Pacific States'});
    xlabel('Date');
    ylabel('Cumulative Tests to Date');
    legend('Location','northwest','FontSize',lgd_font)
       
    if cust_tick_on == 1    
        tick1=startdate+t_pad_us(1);
        tick2=enddate+t_pad_us(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        yticks(y_lmt_tst(1):y_tk_tst_maj:y_lmt_tst(2));
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
    else 
        grid on
        grid minor
        datetick('x',6,'keepticks','keeplimits')
    end
    if write_png == 1
        saveas(gcf,'21_Tst_Pacific.png')
    end
end

%Chocolate Microscopes?