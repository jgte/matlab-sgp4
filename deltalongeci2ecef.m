function out=deltalongeci2ecef(jd)

  out=gmst_wrapper(jd,0);
  
end

%this function spits out the GMST in degrees
function gmst=gmst_wrapper(jd,method)
  if ~exist('method','var') || isempty(method)
    method=0; %rad/s
  end
  %branch on method
  switch method
    case 0
      max_method=4;
      out=zeros(numel(jd),max_method);
      for i=1:max_method
        out(:,i)=gmst_wrapper(jd,i);
      end
      if max(std(out,0,2)./mean(out,2))>0.1
        error([mfilename,': found large discrepancies in the GMST methods.'])
      end
      gmst=mean(out,2);
    case 1
      gmst=JD2GMST(jd);
    case 2
      gmst=fraenz(jd);
    case 3
      gmst=Burnett(jd);
    case 4
      gmst=whatwhenhow(jd);
    otherwise
      error([mfilename,': unknown method ',method,'.'])
  end
end

% https://www2.mps.mpg.de/homes/fraenz/systems/systems2art/node10.html
function gmst_angle = fraenz(jd)
%Julian days from J2000.0
d0=jd-2451545.0;
%time difference in Julian centuries of Universal Time (UT1) from J2000.0
Tu=floor(d0)/(365.25*100);
%Greenwich mean sidereal time, in seconds of a day of 86400s UT1
gmst_time = (24110.54841 + 8640184.812866*Tu + 0.093104*Tu.^2 - 6.2e-6*Tu.^3);
%hour angle in degrees
gmst_angle=wrapTo360(gmst_time*360/86400+180+360*d0);
end

% https://www.mathworks.com/matlabcentral/fileexchange/28176-julian-date-to-greenwich-mean-sidereal-time/content//JD2GMST.m
% https://en.wikibooks.org/wiki/Astrodynamics/Time
function GMST = JD2GMST(JD)
%Find the Julian Date of the previous midnight, JD0
JD0 = NaN(size(JD));
JDmin = floor(JD)-.5;
JDmax = floor(JD)+.5;
JD0(JD > JDmin) = JDmin(JD > JDmin);
JD0(JD > JDmax) = JDmax(JD > JDmax);
H = (JD-JD0).*24;       %Time in hours past previous midnight
D = JD - 2451545.0;     %Compute the number of days since J2000
D0 = JD0 - 2451545.0;   %Compute the number of days since J2000
T = D./36525;           %Compute the number of centuries since J2000
%Calculate GMST in hours (0h to 24h) ... then convert to degrees
GMST = mod(6.697374558 + 0.06570982441908.*D0  + 1.00273790935.*H + ...
    0.000026.*(T.^2),24).*15;
end

% http://www2.arnes.si/~gljsentvid10/sidereal.htm
function GMST=Burnett(jd)
%Julian days from J2000.0
d=jd-2451545.0;
%Julian centuries since J2000.0
t=d/36525;
% degrees
GMST = wrapTo360(280.46061837 + 360.98564736629 * d + 0.000388 * t.^2);
end


% http://what-when-how.com/space-science-and-technology/earth-orbiting-satellite-theory/
function gst=whatwhenhow(jd,we)
if ~exist('we','var') || isempty(we)
  we=7.29211585530e-5; %rad/s
end
%Julian days from J2000.0
d0=jd-2451545.0;
%time difference in Julian centuries of Universal Time (UT1) from J2000.0
dT=d0/(365.25*100);
gst0=1.753368560+628.3319706889*dT+6.7707e-6*dT.^2-4.5e-10*dT.^3;
gst=rad2deg(wrapTo2Pi(gst0+we*seconds(timeofday(datetime(jd,'ConvertFrom','juliandate','TimeZone','UTC')))));
end


