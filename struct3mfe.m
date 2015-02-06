function mfe=struct3mfe(datestruct,jdsatepoch)

  jd = jday( datestruct.year,datestruct.mon,datestruct.day,datestruct.hr,datestruct.min,datestruct.sec );
  mfe = (jd -jdsatepoch) * 1440.0;
