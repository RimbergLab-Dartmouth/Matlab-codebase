function []=vna_set_s_parameters(vna_handle,input,channel_number,trace_number)
        if ~exist('channel_number','var')
            channel_number=str2double(query(vna_handle,':serv:chan:act?'));
        end
        if ~exist('trace_number','var')
            trace_number=str2double(query(vna_handle,[':serv:chan' num2str(channel_number) ':trac:act?']));
        end
        if strcmpi(input,'s11')
            se_setting1=[':calc' num2str(channel_number) ':par' num2str(trace_number) ':def s11'];
        elseif strcmpi(input,'s12')
            se_setting1=[':calc' num2str(channel_number) ':par' num2str(trace_number) ':def s12'];
        elseif strcmpi(input,'s21')
            se_setting1=[':calc' num2str(channel_number) ':par' num2str(trace_number) ':def s21'];
        elseif strcmpi(input,'s22')
            se_setting1=[':calc' num2str(channel_number) ':par' num2str(trace_number) ':def s22'];
        else
            print('invalid setting')
        end
        fprintf(vna_handle,se_setting1);
end