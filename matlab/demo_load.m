import api.OTM
root = fileparts(fileparts(mfilename('fullpath')));
otm = OTMWrapper(fullfile(root,'configs','line_macro.xml'));
otm.run_simple(0,1000,[],10)
