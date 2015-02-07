function mfe=datenum3mfe(d,jdsatepoch)

  year  =str2double(datestr(d,'yyyy'));
  month =str2double(datestr(d,'mm'));
  day   =str2double(datestr(d,'dd'));
  hour  =str2double(datestr(d,'HH'));
  minute=str2double(datestr(d,'MM'));
  second=str2double(datestr(d,'SS'));

  jd = jday(year,month,day,hour,minute,second);
  mfe = (jd -jdsatepoch) * 1440.0;
