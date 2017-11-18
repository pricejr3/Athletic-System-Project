#!/usr/bin/perl

#
# system_diagnostics
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael Duff
# Last modified: March 20, 1999
#
# Description: 
#

require "global.pl";
require "commands.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";


$SYSTEM_LOG         = "/var/log/messages";
$CRON_LOG           = "/usr/lib/cron/log";
$WEB_SERVER_LOG_DIR = "/etc/httpd/logs";


# Authenticate and authorize user:
($login_id, $clearance) = auth_user ($CLEARANCE_ADMIN);


print_html_header ("System Status", $BASE_HREF);

print <<EOF;

<br>
<center><img src="Images/system_diagnostics.gif"><br>
(<a href="/bin/system_diagnostics.pl">refresh</a>)
</center>

<br>
<hr noshade>
<h1 align=center><u>Filesystem usage</u></h1>
<pre>
EOF
    ;


print `$DF`;

print <<EOF;
</pre>

<hr noshade>
<h1 align=center><u>Processes</u></h1>
<pre>
EOF
    ;

print `$PS $PS_ARGS`;

print <<EOF;
</pre>

<hr noshade>
<h1 align=center><u>auth directory listing</u></h1>
<pre>
EOF
    ;

print `$LS -la $AUTH_DIR`;

print <<EOF;
</pre>

<hr noshade>
<h1 align=center><u>Last 100 logins</u></h1>
<pre>
EOF
    ;

$LOGS_DIR = "$INTRANET_BASE_DIR/logs";
print `$TAIL -100 $LOGS_DIR/auth`;

print <<EOF;
</pre>

<hr noshade>
<h1 align=center><u>Database backup log</u></h1>
<pre>
EOF
    ;

print `$TAIL -100 $LOGS_DIR/database_backup`;

print <<EOF;
</pre>

<hr noshade>
<h1 align=center><u>Cron log</u></h1>
<pre>
EOF
    ;

print `$TAIL -100 $CRON_LOG`;

print <<EOF;
</pre>

<hr noshade>
<h1 align=center><u>cgi-bin directory listing</u></h1>
<pre>
EOF
    ;

print `$LS -la $BASE_DIR/cgi-bin`;

print <<EOF;
</pre>

<hr noshade>
<h1 align=center><u>cgi-lib directory listing</u></h1>
<pre>
EOF
    ;

print `$LS -la $CGI_LIB`;

print <<EOF;
</pre>

<hr noshade>
<h1 align=center><u>Web server access log</u></h1>
<pre>
EOF
    ;

print `$TAIL -200 $WEB_SERVER_LOG_DIR/ssl_access_log`;
print <<EOF;
</pre>

<hr noshade>
<h1 align=center><u>Web server error log</u></h1>
<pre>
EOF
    ;

print `$TAIL -200 $WEB_SERVER_LOG_DIR/ssl_error_log`;

print <<EOF;
</pre>
<hr noshade>
</body>
</html>
EOF
    ;


exit;
