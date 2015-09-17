function orb_out=tle(norad,startdate,stopdate,deltamin,orb_filename,tle_filename,tle_startdate)

if ~exist('orb_filename','var') || isempty(orb_filename)
  fid_orb=1;
else
  fid_orb = fopen(orb_filename, 'wt');
end

if ~exist('tle_filename','var') || isempty(tle_filename)
  fid_tle=1;
else
  fid_tle = fopen(tle_filename, 'wt');
end

if ~exist('tle_startdate','var') || isempty(tle_startdate)
  tle_startdate=startdate;
end

% these are set in sgp4init
global tumin mu radiusearthkm xke j2 j3 j4 j3oj2

global opsmode

% // ------------------------  implementation   --------------------------

% add operation smode for afspc (a) or improved (i)
opsmode='a';

whichconst = 72;
rad = 180.0 / pi;

% get TLE from space-track.org
longstr=get_tle(norad,tle_startdate);

fprintf(fid_tle,'%s\n',longstr{1});
fprintf(fid_tle,'%s\n',longstr{2});

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

%print NORAD satellite ID
fprintf(fid_orb,' %d\n', satrec.satnum);

% // call the propagator to get the initial state vector value
[satrec, ro ,vo] = sgp4 (satrec,  0.0);

fprintf(fid_orb, ' %16.8f %16.8f %16.8f %16.8f %12.9f %12.9f %12.9f\n',...
  satrec.t,ro(1),ro(2),ro(3),vo(1),vo(2),vo(3));

tsince = startmfe;

% // check so the first value isn't written twice
if ( abs(tsince) > 1.0e-8 )
  tsince = tsince - deltamin;
end

t=transpose(startmfe:deltamin:stopmfe);
orb_out=struct(...
  'time',t,...
  'jd', zeros(size(t)),...
  'year', zeros(size(t)),...
  'month', zeros(size(t)),...
  'day', zeros(size(t)),...
  'hour', zeros(size(t)),...
  'min', zeros(size(t)),...
  'sec', zeros(size(t)),...
  'pos',zeros(numel(t),3),...
  'pos_ecef',zeros(numel(t),3),...
  'vel',zeros(numel(t),3),...
  'satrec',satrec);

% // loop to perform the propagation
while ((tsince < stopmfe) && (satrec.error == 0))

  tsince = tsince + deltamin;

  if(tsince > stopmfe)
    tsince = stopmfe;
  end

  [satrec, ro, vo] = sgp4 (satrec,  tsince);

  if (satrec.error ~= 0)
    fprintf(fid_orb,'# *** error: t:= %f *** code = %3i\n', tsince, satrec.error);
  else

    fprintf(fid_orb, ' %16.8f %16.8f %16.8f %16.8f %12.9f %12.9f %12.9f \n',...
      tsince,ro(1),ro(2),ro(3),vo(1),vo(2),vo(3));

    trel=abs(t-tsince);
    idx=find(min(trel)==trel);
    if isempty(idx)
      error([mfilename,': a-priori time domain does not contain value ',num2str(tsince),'.'])
    end
    orb_out.pos(idx,:)=ro;
    orb_out.vel(idx,:)=vo;

    %save julian date
    jd = satrec.jdsatepoch + tsince/1440.0;
    orb_out.jd(idx)=jd;
    %save UTC data
    orb_out.utc(idx)=datetime(jd,'ConvertFrom','juliandate','TimeZone','UTC');
    %save matlab's datetime object
    [orb_out.year(idx),orb_out.month(idx),orb_out.day(idx),orb_out.hour(idx),orb_out.min(idx),orb_out.sec(idx)] = invjday ( jd );
    [year,mon,day,hr,minute,sec] = datevec(orb_out.utc(idx));
    if any([orb_out.year(idx),orb_out.month(idx),orb_out.day(idx),orb_out.hour(idx),orb_out.min(idx)]~=[year,mon,day,hr,minute]) || abs(orb_out.sec(idx)-sec)>1e-6
      error([mfilename,': discrepancy in date/time convertion from different algorithms'])
    end
    orb_out.dt(idx)=datetime(year,mon,day,hr,minute,sec);
  end


end

%save latitude, longitude, radius
[long,lat,rad]=cart2sph(orb_out.pos(:,1)*1e3,orb_out.pos(:,2)*1e3,orb_out.pos(:,3)*1e3);
orb_out.llr=[rad2deg(long)-deltalongeci2ecef(orb_out.jd),rad2deg(lat),rad];

%compute ECI->ECEF transformation coordinates
eci2ecef=dcmeci2ecef('IAU-2000/2006',[orb_out.year,orb_out.month,orb_out.day,orb_out.hour,orb_out.min,orb_out.sec]);
%save ECEF coordinates
for i=1:size(orb_out.pos,1)
  orb_out.pos_ecef(i,:)=eci2ecef(:,:,i)*transpose(orb_out.pos(i,:)*1e3);
end
[long,lat,rad]=cart2sph(orb_out.pos_ecef(:,1),orb_out.pos_ecef(:,2),orb_out.pos_ecef(:,3));
orb_out.llr_alt=[rad2deg(long),rad2deg(lat),rad];

if (idebug && (dbgfile ~= -1))
  fclose(dbgfile);
end


