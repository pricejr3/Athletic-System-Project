$HOSTNAME          = $ENV{'HTTP_HOST'};
#$HOSTNAME          = 'musm.ica.muohio.edu';
#$HOSTNAME          = 'icalamsp01.mcs.muohio.edu';
#$HOSTNAME          = '134.53.17.222';
#$HOSTNAME          = 'icalnx01.mcs.muohio.edu';
$BASE_DIR          = '/usr/local/musm';
$DOMAIN_NAME       = 'ica.muohio.edu';
$INTRANET_BASE_DIR = "$BASE_DIR/internal";
$AUTH_DIR          = "$INTRANET_BASE_DIR/auth";
$USER_ACCOUNTS_DIR = "$INTRANET_BASE_DIR/users";
$WWW_INTERNAL_DIR  = "$INTRANET_BASE_DIR/www";
$FORMS_DIR         = "$WWW_INTERNAL_DIR/Athlete_Records/Forms";
$LOGS_DIR          = "$INTRANET_BASE_DIR/logs";
$CGI_LIB           = "$BASE_DIR/cgi-lib";  unshift (@INC, $CGI_LIB);
$BASE_URL          = "https://$HOSTNAME";
$BASE_HREF         = "https://$HOSTNAME/bin/auth/";

$DATABASE          = 'dbname=musmdb';
$DATABASE_USERID   = 'musmdb_user';
#$DATABASE_PASSWORD = '5Sya1WfZ';
$DATABASE_PASSWORD = '.Hdq58Nz-u';
$PURGE_USERID      = 'musmdb_purge';
#$PURGE_PASSWORD    = 'qLG8vhI6';
$PURGE_PASSWORD    = 'i9Gsy:Co3E';

$ATHLETE_LOGIN_ID  = 'athlete';

$GZIP_CMD          = '/bin/gzip';
$PS_CMD            = '/bin/ps -elf';
$NETSTAT_CMD       = '/bin/netstat -an';
$VMSTAT_CMD        = '/usr/bin/vmstat';

$CLEARANCE_ADMIN   = "ADMIN";
$CLEARANCE_STAFF   = "STAFF";
$CLEARANCE_STUDENT = "STUDENT";
$CLEARANCE_ATHLETE = "ATHLETE";


1;
