#!/usr/bin/perl

# view_user_log_info.pl
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael Duff
# Last modified: March 16, 1999
#
# Description:
#    Displays user auth logs
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";


# Authenticate and authorize user:
($login_id, $clearance) = auth_user ($CLEARANCE_ADMIN);

$cgi_data      = parse_cgi_data();
$this_login_id = $cgi_data->{'login_id'};

print_html_header ("User Log Information", $BASE_HREF);

print <<EOF;

<br>
<h1 align=center>Authentication/Authorization logs for user "$this_login_id"</h1>
<h2 align=center>(<a href="/bin/account_administration.pl">Return to Account Administration page</a>)</h2>
<hr noshade>
<pre>
EOF
    ;

# print the lines that contain "user $this_login_id":
open (LOG, "$LOGS_DIR/auth");
while ( <LOG> ) { if (/user $this_login_id/oi) { print "$_"; } }
close (LOG);

print <<EOF;
</pre>

<hr noshade>
EOF
    ;

print_html_trailer();


exit;
