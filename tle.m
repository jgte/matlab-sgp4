
% these are set in sgp4init
global tumin mu radiusearthkm xke j2 j3 j4 j3oj2

global opsmode

% // ------------------------  implementation   --------------------------

% add operation smode for afspc (a) or improved (i)
opsmode='a';

whichconst = 72;
rad = 180.0 / pi;

norad='32789';

startdate=datenum(2014,12,31,12,00,00);
stopdate =datenum(2014,12,31,12,10,00);
deltamin=0.1;

% get TLE from space-track.org
longstr=get_tle(norad,startdate);

global idebug dbgfile

if idebug
  catno = strtrim(longstr{1}(3:7));
  dbgfile = fopen(strcat('sgp4test.dbg.',catno), 'wt');
  fprintf(dbgfile,'this is the debug output\n\n' );
end
% // convert the char string to sgp4 elements
% // includes initialization of sgp4
satrec = twoline2rv( whichconst,longstr);

%get start/stop mfe
startmfe=datenum3mfe(startdate,satrec.jdsatepoch);
stopmfe =datenum3mfe(stopdate, satrec.jdsatepoch);

fprintf(1,' %d\n', satrec.satnum);

% // call the propagator to get the initial state vector value
[satrec, ro ,vo] = sgp4 (satrec,  0.0);

% fprintf(1, ' %16.8f %16.8f %16.8f %16.8f %12.9f %12.9f %12.9f\n',...
%   satrec.t,ro(1),ro(2),ro(3),vo(1),vo(2),vo(3));

tsince = startmfe;

% // check so the first value isn't written twice
if ( abs(tsince) > 1.0e-8 )
  tsince = tsince - deltamin;
end

% // loop to perform the propagation
while ((tsince < stopmfe) && (satrec.error == 0))

  tsince = tsince + deltamin;

  if(tsince > stopmfe)
    tsince = stopmfe;
  end

  [satrec, ro, vo] = sgp4 (satrec,  tsince);

  if (satrec.error ~= 0)
    fprintf(1,'# *** error: t:= %f *** code = %3i\n', tsince, satrec.error);
  else
    jd = satrec.jdsatepoch + tsince/1440.0;
    [year,mon,day,hr,minute,sec] = invjday ( jd );

    fprintf(1, ' %16.8f %16.8f %16.8f %16.8f %12.9f %12.9f %12.9f \n',...
      tsince,ro(1),ro(2),ro(3),vo(1),vo(2),vo(3));
  end

end

if (idebug && (dbgfile ~= -1))
  fclose(dbgfile);
end


