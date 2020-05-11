%CustomAreas.m
%
%Custom Areas - sum up cases across any number of specified states, to 
%calculate/plot numbers for one or more custom areas.  Define a number of 
%separate custom areas as described below.  States and territories are 
%identified by a unique 2-digit FIPS number between 1 and 78.  Also see 
%READ_ME.txt' & 'InputVars.m' for more info about FIPS codes & variable 
%conventions.

%Number of custom areas to be summed and plotted, alter as needed.
n_areas = 2;

%Allocate state/name arrays.  Don't touch these two lines
areas_states = zeros(n_areas,78);                  
areas_name = strings(1,n_areas);                         

%Custom area 1
%put 2-digit FIPS numbers for states to be summed in 1xN arrays to a max 
%of N=78
%States to sum, below.  For area_1, it's AK + WA + OR 
%change 'area_#_states' as needed below for subsequent cases
area_1_states = [02 41 53] ;                                              
areas_name(1) = 'Pacific NW';     %change area_name(#)index as needed later
area_size = size(area_1_states,2);   
naughts = 78-area_size;                           %Don't touch this, either
area_temp = padarray(area_1_states,[0 naughts],0,'post');
areas_states(1,:) = area_temp;       
%change change 'area_#_states' and 'area_states(#,:)' in lines above also, 
%as needed, for subsequent areas.

%Custom area 2
area_2_states = [09 34 36];                        %This one's NY + NJ + CT
areas_name(2) = 'NY Tri-State';
area_size = size(area_2_states,2);   
naughts = 78-area_size;              
area_temp = padarray(area_2_states,[0 naughts],0,'post');
areas_states(2,:) = area_temp;

%rinse, repeat as needed...
