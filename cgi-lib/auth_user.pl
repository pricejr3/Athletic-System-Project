# auth_user.pl
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: March 16, 1999
#
# Description: Uses Netscape persistent cookie information to authenticate
#              user.
#

require "parse.pl";
require "logging.pl";


sub auth_user
{
    # MJD (13-May-2007): Check for minimum clearance:
    my ($min_required_clearance) = @_;

    my $cookies = parse_persistent_cookies();
    
    # Get persistent cookie-supplied data:
    my $login_id    = $cookies->{'LOGIN_ID'};
    my $session_key = $cookies->{'SESSION_KEY'};
    
    # Get environment variable-supplied data:
    my $remote_hostname   = $ENV{'REMOTE_HOST'};
    my $remote_ip_address = $ENV{'REMOTE_ADDR'};

    # Read auth data from $login_id.auth file:
    open ( AUTH, "$AUTH_DIR/$login_id.auth" );
    flock ( AUTH, LOCK_SH );
    seek (AUTH, 0, 0);
    while ( <AUTH> ) {
	if ( /^(.*?)=(.*)$/ ) { $auth_data{$1} = $2; }
    }
    flock ( AUTH, LOCK_UN );
    close ( AUTH );
    
    my $clearance = $auth_data{'CLEARANCE'};


    if ($auth_data{'LOGIN_ID'}          ne $login_id ||
	$auth_data{'REMOTE_HOSTNAME'}   ne $remote_hostname ||
	$auth_data{'REMOTE_IP_ADDRESS'} ne $remote_ip_address ||
	$auth_data{'SESSION_KEY'}       ne $session_key ) {

	print_log ( "failed authentication attempt by $login_id from $remote_hostname ($remote_ip_address)" );

	print_html_header ( "Melampus: Failed Authentication", $BASE_HREF );

	print <<EOF;
<br><br><br>

<H1 ALIGN=CENTER><FONT COLOR="#FF0000">
Failed Authentication Attempt
</FONT></H1>

<br>

<P>
<CENTER>
You could not be authenticated.  Please try logging in again.
</CENTER>

<br><br><br>
<center>
<a href="/bin/welcome" target="_top"><img src="/www/return_to_login_page.gif" border=1></a>
</center>

EOF
    ;
	print_html_trailer();
	exit;



    } elsif ( $auth_data{'KEY_EXPIRATION_TIME'} < time() ) {
	unlink ( "$AUTH_DIR/$login_id.auth" );        # Log user out
	
	print_html_header();
	print <<EOF;
<br><br><br>

<H1 ALIGN=CENTER><FONT COLOR="#FF0000">
Session key has expired.<br>
You must re-login to continue.
</FONT></H1>

<br><br><br>
<center>
<a href="/bin/welcome" target="_top"><img src="/www/return_to_login_page.gif" border=1></a>
</center>

EOF
    ;
	print_html_trailer();
	exit;



    } elsif (get_clearance_level ($clearance) < get_clearance_level ($min_required_clearance)) {
	print_html_header();
	print <<EOF;
<br><br><br>

<H1 ALIGN=CENTER><FONT COLOR="#FF0000">
Sorry, you do not have the necessary clearance for this page.<br>
Please press the "Back" button in your browser to resume.
</FONT></H1>

EOF
    ;
	print_html_trailer();
	exit;


	
    } else {   # All auth data is correct:
	return ($login_id, $clearance);
    }
}



sub get_clearance_level
{
    my ($clearance) = @_;

    if ($clearance =~ /$CLEARANCE_ADMIN/)   { return 4; }
    if ($clearance =~ /$CLEARANCE_STAFF/)   { return 3; }
    if ($clearance =~ /$CLEARANCE_STUDENT/) { return 2; }
    if ($clearance =~ /$CLEARANCE_ATHLETE/) { return 1; }

    return 0;
}



sub access_denied
{
    print_html_header ( "Access Denied", $BASE_HREF );

    print_html_trailer();

    exit;
}



1;
