function [reqd_derivative]=numerical_derivative(function_values,x_values,order)
%%%% based on https://userpages.umbc.edu/~squire/cs455_l24.html
if ~exist('order','var')
    order=1;
end
if ~(length(function_values)==length(x_values))
    return
end
differences=diff(x_values);
if ~(length(find(~((abs(differences-differences(1)))>1e-14)))==length(x_values)-1)
    disp('error in numerical derivative')
    find(~((abs(differences-differences(1)))>1e-14))
    differences
    return
else
    difference=differences(1);
end
derivatives=ones(length(function_values),order+1);
derivatives(:,1)=function_values;
for m_order=1:order
    derivatives(1,m_order+1)=1/12/difference*(-25*derivatives(1,m_order)+48*derivatives(2,m_order)-36*derivatives(3,m_order)+16*derivatives(4,m_order)-3*derivatives(5,m_order));
    derivatives(2,m_order+1)=1/12/difference*(-3*derivatives(1,m_order)-10*derivatives(2,m_order)+18*derivatives(3,m_order)-6*derivatives(4,m_order)+1*derivatives(5,m_order));
    for m_element=3:length(x_values)-2
       derivatives(m_element,m_order+1)=1/12/difference*(derivatives(m_element-2,m_order)-8*derivatives(m_element-1,m_order)+8*derivatives(m_element+1,m_order)-derivatives(m_element+2,m_order));
    end
    derivatives(length(x_values) - 1,m_order+1)=1/12/difference*(-derivatives(length(x_values) - 4,m_order) ...
        +6*derivatives(length(x_values) - 3,m_order)-18*derivatives(length(x_values) - 2,m_order)+10*derivatives(length(x_values) - 1,m_order) ...
        +3*derivatives(length(x_values),m_order));
    derivatives(length(x_values),m_order+1)=1/12/difference*(3 *derivatives(length(x_values) - 4,m_order) ...
        -16*derivatives(length(x_values) - 3,m_order)+36*derivatives(length(x_values) - 2,m_order)-48*derivatives(length(x_values) - 1,m_order) ...
        +25*derivatives(length(x_values),m_order));
end
reqd_derivative=derivatives(:,order+1);
end