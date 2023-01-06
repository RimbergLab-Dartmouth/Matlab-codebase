%%% saves all open images as a comprehensive PDF file in temp file 'fn'.
%%% Open that temp file and save it locally
figHandles = findall(0,'Type','figure');
% Create filename
fn = tempname();  %in this example, we'll save to a temp directory.
% Save first figure
export_fig(fn, '-pdf', figHandles(1))
% Loop through figures 2:end
for i = 2:numel(figHandles)
export_fig(fn, '-pdf', figHandles(i), '-append')
end