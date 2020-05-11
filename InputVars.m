%InputVars.m
%
%Assorted input parameters for plots generated by COrVID1920
%
%variables ending in '_on' should be set to 1 or 0 for yes/no
%'_semilog' variables set to 1 have log scale for y, linear when set to 0
%'_cases_on' vaiables set to 1 will included positive test cases on plot
%'_deaths_on' variables set to 1 will include deaths on plot
%'_tests_on' variable (US only) set to 1 will plot total COVID test result 
%reports, positive plus negative
%'_hosp_on' variable (US only) set to 1 will plot hospitalized cases
%
%selected state/division/region '_plot' variables are vectors of any size
%containing the FIPS code and/or U.S. Census identifiers for a specific 
%state/division/region to be plotted, such that state_plots[09 34 36] would 
%generate a state plot for NY, NY and CT, division_plots[01 09] would 
%generate a division plot for New England and Pacific, and so on.  See 
%'state-geocodes-v2017' file to find the right numbers for corresponding 
%areas.

%US data
US_plot_on = 1;
%for U.S. data ONLY semilog_US_on = 2 will generate both linear and log
semilog_US_on = 1;
US_cases_on = 1;
US_deaths_on = 1;
US_tests_on = 1;
US_hosp_on = 1;

%Selected region data
RG_plot_on = 1;
RG_include_US = 1;
semilog_RG_on = 1;
reg_plots = [1 2 3 4];

%Selected division data
DV_plot_on = 1;
DV_include_US = 1;
semilog_DV_on = 1;
div_plots = [1 2 3 4 5 6 7 8 9];

%Selected state data
ST_plot_on = 1;
ST_include_US = 1;
ST_include_DIV = 1;
semilog_ST_on = 1;
state_plots = [09 23 25 33 44 50];
state_div = 1;      %census division to include on plot

%Custom area plots from state data. See 'CustomAreas.m' for details & 
%to edit inputs
CST_plot_on = 1;
CST_include_US = 1;
semilog_CST_on = 1;
run('CustomAreas.m')

%Custom area plots from county data.  See lines 690+ of 'COrVID1920.m' for 
%more options
N_CCTY_plots = 9;            %number of metro areas plots
CCTY_plots_on = zeros(N_CCTY_plots,1);    % Don't touch me.
CCTY_include_us = zeros(N_CCTY_plots,1);  % or me.
CCTY_include_reg = zeros(N_CCTY_plots,1); % me either.
CCTY_include_div = zeros(N_CCTY_plots,1); % also me.
CCTY_include_area = zeros(N_CCTY_plots,1);% me too.
CCTY_include_st = zeros(N_CCTY_plots,1);  % and ESPECIALLY me.

%Plot 1 - NY Metro
CCTY_plots_on(1) = 1;
CCTY_include_us(1) = 1;
CCTY_include_reg(1) = 0;
CCTY_include_div(1) = 0;
CCTY_include_area(1) = 1;
CCTY_include_st(1) = 0;

%Plot 2 - Pacific NW
CCTY_plots_on(2) = 1;
CCTY_include_us(2) = 1;
CCTY_include_reg(2) = 0;
CCTY_include_div(2) = 0;
CCTY_include_area(2) = 1;
CCTY_include_st(2) = 0;

%Plot 3 - Northeast Metros
CCTY_plots_on(3) = 1;
CCTY_include_us(3) = 1;
CCTY_include_reg(3) = 0;
CCTY_include_div(3) = 0;
CCTY_include_area(3) = 0;
CCTY_include_st(3) = 0;

%Plot 4 - California Plot
CCTY_plots_on(4) = 1;
CCTY_include_us(4) = 1;
CCTY_include_reg(4) = 0;
CCTY_include_div(4) = 1;
CCTY_include_area(4) = 0;
CCTY_include_st(4) = 1;

%Plot 5 - Texas Plot
CCTY_plots_on(5) = 1;
CCTY_include_us(5) = 1;
CCTY_include_reg(5) = 1;
CCTY_include_div(5) = 0;
CCTY_include_area(5) = 0;
CCTY_include_st(5) = 1;

%Plot 6 - Florida Plot
CCTY_plots_on(6) = 1;
CCTY_include_us(6) = 1;
CCTY_include_reg(6) = 1;
CCTY_include_div(6) = 0;
CCTY_include_area(6) = 0;
CCTY_include_st(6) = 1;

%Plot 7 - Midwest Plot
CCTY_plots_on(7) = 1;
CCTY_include_us(7) = 1;
CCTY_include_reg(7) = 1;
CCTY_include_div(7) = 0;
CCTY_include_area(7) = 0;
CCTY_include_st(7) = 0;
semilog_CST_on = 1;

%Plot 8 - Mountain West Plot
CCTY_plots_on(8) = 1;
CCTY_include_us(8) = 1;
CCTY_include_reg(8) = 1;
CCTY_include_div(8) = 0;
CCTY_include_area(8) = 0;
CCTY_include_st(8) = 0;
semilog_CST_on = 1;

%Plot 9 - South
CCTY_plots_on(9) = 1;
CCTY_include_us(9) = 1;
CCTY_include_reg(9) = 1;
CCTY_include_div(9) = 0;
CCTY_include_area(9) = 0;
CCTY_include_st(9) = 0;
semilog_CST_on = 1;

run('CustomMetros.m')

%Specify states, divisions, regions, areas, & metros for which to 
%calculate case doubling times
DTime_states = [02 46 35];
DTime_divisions = [];
DTime_regions = [];
DTime_areas = [];
DTime_metros = [3 4 14 1 9 2 21];

%state plots for testing per thousand residents on/off, set to 1/0

st_tests_per_th = 1;

%include lines of constant doubling times.
%for semilog plots ONLY.
dbl_lines_on = 1;
%doubling times of lines
dbl_lines_t = [2 3 5 10 20];
n_dbl = length(dbl_lines_t);

%set time (x-axis) padding in days, since 1/22/20 for start, and end of 
%US, state/division/region, custom, & doubling time plots.  Note that if 
%cust_tick_on is set = 1 below, values may be automatically altered by +/-1
t_pad_us = [40 2];
t_pad_sdr = [40 2];
t_pad_cst = [40 2];
t_pad_dbl = [54 1];

%set y limits for US, state/division/region, custom, & doubling t plots,
%for semi-log only, see 'CustomMetros.m' for special limits on Metro Areas
y_lmt_us = [10 10000000];
y_lmt_sdr = [10 2000000];
y_lmt_cst = [10 2000000];
y_lmt_dbl = [0 35];
y_lmt_tst = [0 100];

%Turn this on for all plots to have same label as above, turn off for auto
y_lmt_tst_on = 0;

%Turn custom ticks on/off and set custom major/minor tick marks.  Note 
%that for some older versions of MATLAB, this may cause problems & need to 
%be turned off
cust_tick_on = 1;
tk_spc_maj = 10;
tk_spc_min = 2;

%custom y-ticks for testing plots
y_tk_tst_maj = 10;
y_tk_tst_min = 2;

%set plot line width 
set(0, 'DefaultLineLineWidth', 1.5)

%set figure window location, size for case plots
fig_size_1 = [10 10 500 400];
%for doubling time plots
fig_size_2 = [10 10 500 450];

%set legend font size
lgd_font = 7;