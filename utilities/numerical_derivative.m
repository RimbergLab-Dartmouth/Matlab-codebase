function [reqd_derivative]=numerical_derivative(function_values,x_values,order)
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
for l=1:order
    for i=3:length(x_values)-2
       derivatives(i,l+1)=1/12/difference*(derivatives(i-2,l)-8*derivatives(i-1,l)+8*derivatives(i+1,l)-derivatives(i+2,l));
    end
    for i=1:2
        derivatives(i,l+1)=1/12/difference*(-25*derivatives(i,l)+48*derivatives(i+1,l)-36*derivatives(i+2,l)+16*derivatives(i+3,l)-3*derivatives(i+4,l));
    end
    for i=length(x_values)-1:length(x_values)
       derivatives(i,1+1)=1/12/difference*(-25*derivatives(i,l)+48*derivatives(i-1,l)-36*derivatives(i-2,l)+16*derivatives(i-3,l)-3*derivatives(i-4,l));
    end 
end
reqd_derivative=derivatives(:,order+1);
end