function [x,y_primary,y_secondary]=vna_get_data(vna_handle,channel_number,trace_number)
%if channel and trace left empty, defaults to active trace on channel one.
% If just trace empty, defaults to active trace on specified channel.
%y_secondary is the 2nd piece of information from the specified format. 
% all 0s for mlog, phase,group delay, lin mag, SWR, exp phase
% Smith chart (R+jX): it is the reactance. 
%Smith chart (G+jY): susceptance.....
%y_secondary output need not be saved
         if ~exist('channel_number','var')
            channel_number=str2double(query(vna_handle,':serv:chan:act?'));
         end
         if ~exist('trace_number','var')
            trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
         end
         sweep_points=str2double(query(vna_handle,[':sens' num2str(channel_number) ':swe:poin?']));
         fclose(vna_handle);
         if sweep_points<202
            set(vna_handle,'InputBufferSize',8040); 
         elseif 201<sweep_points && sweep_points<402
            set(vna_handle,'InputBufferSize',16040);
         elseif 401<sweep_points && sweep_points<802
            set(vna_handle,'InputBufferSize',32040);
         elseif 801<sweep_points && sweep_points<1602
            set(vna_handle,'InputBufferSize',64040);
         else
            print('Number of points too large');
         end
%%%% establish communication with VNA
         fopen(vna_handle);
%%%%%%%%%  read data %%%%%%%%%%%%%%
         trace_sel_message=[':calc' num2str(channel_number) ':par' num2str(trace_number) ':sel'];
         fprintf(vna_handle,trace_sel_message); 
         fprintf(vna_handle,[':calc' num2str(channel_number) ':trac' num2str(trace_number) ':math:mem']);
         y_data=query(vna_handle,[':calc' num2str(channel_number) ':trac' num2str(trace_number) ':data:fmem?']);
%          y_data=query(vna_handle,[':calc' num2str(channel_number) ':data:fdat?']);
         x_data=query(vna_handle,[':sens' num2str(channel_number) ':freq:data?']);
         

%%%%%%  format data into arrays %%%%%%%%%%%
         y_data1=strsplit(y_data,',');
         y=str2double(y_data1);
         x_data1=strsplit(x_data,',');
         x=str2double(x_data1);
         y_primary=y(1:2:end);
         y_secondary=y(2:2:end);
end
 