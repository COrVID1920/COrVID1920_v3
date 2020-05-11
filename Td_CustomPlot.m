%Td_CustomPlot.m
%
%Custom doubling time plots.  Note that this script may not work with 
%MATLAB versions prior to 2019a.  Using older versions may require user to 
%convert HEX color codes to RGB vector format.

%DTime_states = [02 46 35];
%DTime_divisions = [];
%DTime_regions = [];
%DTime_areas = [];
%DTime_metros = [3 4 14 1 9 2 21];

figure('Renderer', 'painters', 'Position', fig_size_2);
us = plot(dbl_t_us(:,1),dbl_t_us(:,2),'-.k','DisplayName',['All U.S.']);
hold on

y_lmt_dbl = [0 60];

%AK
s = 02;
ST_name = string(fipscode_2.Name(s));
plot(dbl_t_state(:,1,s),dbl_t_state(:,2,s),'b','DisplayName',[ST_name])

%SeaTac
m = 03;
MET_name = metro_name(m);
plot(dbl_t_metro(:,1,m),dbl_t_metro(:,2,m),'Color','#ff008c','DisplayName',[MET_name])

%Portland, OR
m = 04;
MET_name = metro_name(m);
plot(dbl_t_metro(:,1,m),dbl_t_metro(:,2,m),'Color','#ff8400','DisplayName',[MET_name])

%S.F.
m = 14;
MET_name = metro_name(m);
plot(dbl_t_metro(:,1,m),dbl_t_metro(:,2,m),'Color','#00db00','DisplayName',[MET_name])

%L.A.
m = 13;
MET_name = metro_name(m);
plot(dbl_t_metro(:,1,m),dbl_t_metro(:,2,m),'DisplayName',[MET_name])

%Boston
m = 2;
MET_name = metro_name(m);
plot(dbl_t_metro(:,1,m),dbl_t_metro(:,2,m),'r','DisplayName',[MET_name])

%Providence-New Beige
m = 9;
MET_name = metro_name(m);
plot(dbl_t_metro(:,1,m),dbl_t_metro(:,2,m),'Color','#6aff00','DisplayName',[MET_name])

%NYC
m = 1;
MET_name = metro_name(m);
plot(dbl_t_metro(:,1,m),dbl_t_metro(:,2,m),'Color','#8c4906','DisplayName',[MET_name])

%Houston
%m = 21;
%MET_name = metro_name(m);
%plot(dbl_t_metro(:,1,m),dbl_t_metro(:,2,m),'DisplayName',[MET_name])

%New Mexico
s = 35;
ST_name = string(fipscode_2.Name(s));
plot(dbl_t_state(:,1,s),dbl_t_state(:,2,s),'Color','#e2e602','DisplayName',[ST_name])

%S. Dakota
s = 46;
ST_name = string(fipscode_2.Name(s));
plot(dbl_t_state(:,1,s),dbl_t_state(:,2,s),'DisplayName',[ST_name])

%datetick('x',6,'keepticks','keeplimits')
%xlim([(startdate+t_pad_dbl(1)) (enddate+t_pad_dbl(2))])
%ylim([0 25])
%title({'COrVID1920 - Case Doubling Time, \tau_{d}';...
%    '(7-day smoothing window)'});
xlim([(startdate+t_pad_dbl(1)) (enddate+t_pad_dbl(2))])
ylim(y_lmt_dbl)
title('COrVID1920 - Cases Doubling Time, \tau_{d} (smoothing t_{s} = 7 days)');
xlabel('Date');
ylabel('Doubling Time (days)');
legend('Location','northwest','FontSize',lgd_font)

        tick2=enddate+t_pad_dbl(2);
        grid on
        grid minor
        xticks(tick1:tk_spc_maj:tick2);
        axe = gca;
        %axe.XAxis.MinorTick = 'on'; 
        axe.XAxis.MinorTickValues = tick1:tk_spc_min:tick2;
        datetick('x',6,'keepticks','keeplimits')
uistack(us,'top')
if write_png == 1
    saveas(gcf,'15_Double.png')
end

hold off