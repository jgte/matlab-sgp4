function longstr=loadtle(infilename)

% // input 2-line element set file
infile = fopen(infilename, 'r');
if (infile == -1)
  error([mfilename,'Failed to open file: ', infilename]);
end

%inits
longstr={'#','#'};

while ( (longstr{1}(1) == '#') && (feof(infile) == 0) )
  longstr{1} = fgets(infile, 130);
end
while ( (longstr{2}(1) == '#') && (feof(infile) == 0) )
  longstr{2} = fgets(infile, 130);
end

fclose(infile);