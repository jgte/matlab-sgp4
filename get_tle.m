function tle=get_tle(norad,datestart,username,password)

if ~exist('username','var') || isempty(password) || ~exist(password) || isempty(password)
  if isempty(dir('get_tle.credentials'))
    error([mfilename,': if inputs ''username'' and/or ''password'' are not given, ',...
      'need to read credentials from file ''get_tle.credentials''.'])
  end
  fid=fopen('get_tle.credentials');
  username=fgets(fid);
  password=fgets(fid);
  fclose(fid);
  %get rid of newlines
  %NOTICE: the credentials file must have an empty line as third and last line
  username=username(1:end-1);
  password=password(1:end-1);
end

datestart=floor(datestart);
datestop=datestart+1;

URL='https://www.space-track.org/ajaxauth/login';

post={...
  'identity',username,...
  'password',password,...
  'query',[...
    'https://www.space-track.org/basicspacedata/',...
    'query/class/tle/',...
    'NORAD_CAT_ID/',norad,'/',...
    'EPOCH/',datestr(datestart,'yyyy-mm-dd'),'--',datestr(datestop,'yyyy-mm-dd'),'/',...
    'format/tle',...
  ]...
};

out=urlread(URL,'Post',post,'Timeout',5);

nlidx=findstr(out,10);
if numel(nlidx) ~= 2
  disp(['TLE not found: ', datestr(datestart)])
  disp(post{6})
  datestart=datestart-1;
  disp(['Trying TLE of: ', datestr(datestart)])
  tle=get_tle(norad,datestart,username,password);
  % error([mfilename,': expecting to find 2 newline characters in tle, not ',num2str(numel(nlidx)),'. ',...
  %   'Try other newline characters. Debug needed!'])
  return
end

tle{1}=out(1:nlidx(1)-1);
tle{2}=out(nlidx(1)+1:nlidx(2)-1);
