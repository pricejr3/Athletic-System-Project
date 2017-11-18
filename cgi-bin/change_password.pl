#!/usr/bin/perl

#
# change_password
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael Duff
# Last modified: March 20, 1999
#
# Description: Allows user to change personal password.
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "encryption.pl";
require "password.pl";


# Authenticate and authorize user:
($login_id, $clearance) = auth_user ($CLEARANCE_STUDENT);


$cgi_data = parse_cgi_data();

$old_password  = $cgi_data->{'OLD_PASSWORD'};
$new_password1 = $cgi_data->{'NEW_PASSWORD1'};
$new_password2 = $cgi_data->{'NEW_PASSWORD2'};


# Check new password:
if ( $new_password1 ne $new_password2 ) {
    $reason = "You mistyped your new password.\n";
}


if (( $new_password1 ne $new_password2 ) ||
    ( ! check_password_quality ( $login_id, $new_password1 ) ) ) {
    print_html_header ( "Password Change Failed", $BASE_HREF );

    print <<EOF;

<h1 align=center><font color="#ff0000">
<blink>Password Change Failed!</blink>
</font></h1>

<p align=center>$reason</p>

<p align=center>
<a href="Change_Password/change_password.html">Try Again</A>
</p>

EOF
    ;

    print_html_trailer();
    exit;
}



if ( change_password ( $login_id, $old_password, $new_password1 ) ) {
    print_html_header ( "Password Successfully Changed", $BASE_HREF );

    print <<EOF;

<h1 align=center><font color="#ff0000">
Password Successfully Changed for $login_id
</font></h1>

EOF
    ;
    
    print_html_trailer();
    exit;

    
} else {
    print_html_header ( "Password Change Failed", $BASE_HREF );

    print <<EOF;

<h1 align=center><font color="#ff0000">
<blink>Password Change Failed!</blink>
</font></h1>

<p align=center>$reason</p>

<p align=center>
<a href="Change_Password/change_password.html">Try Again</A>
</p>

EOF
    ;

    print_html_trailer();
}

exit;



# change_password assumes that user has already been authenticated

sub change_password
{
    my ($login_id, $old_password, $new_password) = @_;

    sleep (3);   # wait for a brief time before doing anything
    
    if (! verify_password ($login_id, $old_password)) {   # Incorrect password
	$reason = "You supplied an incorrect password as your current password.";
	return 0;
    }

    my $new_password_hash = compute_hash ("$login_id:$new_password");

    update_passwd_file ($login_id, $new_password_hash);

    return 1;
}

