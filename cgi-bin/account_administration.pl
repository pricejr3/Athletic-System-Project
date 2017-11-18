#!/usr/bin/perl

# account_administration
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael Duff
# Last modified: March 28, 1999
#
# Description: Utilities for account administration and security audits
#

use File::Path;

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "encryption.pl";
require "password.pl";


# Authenticate and authorize user:
($login_id, $clearance) = auth_user ($CLEARANCE_ADMIN);


$cgi_data  = parse_cgi_data();
$operation = $cgi_data->{'OPERATION'};


# Dispatch the request based on the named operation:
if    ($operation eq "ADD_INTRANET_USER")     { add_intranet_user(); }
elsif ($operation eq "MODIFY_INTRANET_USER")  { modify_intranet_user(); }
elsif ($operation eq "PERFORM_MODIFICATIONS") { perform_modifications(); }
else                                          { admin_homepage(); }

exit;



sub admin_homepage
{
    print_html_header ("Intranet Administration Homepage", $BASE_HREF);

    print <<EOF;

<br>
<center>
<img src="Images/account_administration.gif"><br>
(<a href="/bin/account_administration.pl">refresh</a>)
</center>
<br>

<p align=center><b><u>Active Accounts</u></b></p>

<table border=0 width="100%" cellspacing=0>
<tr><td><b>Login ID</b>  <td><b>Full Name</b>  <td><b>Clearance</b>
    <td><b>Status</b>    <td align=center><b>Auth Log</b>
EOF
    ;

    opendir (AUTH_DIR, $AUTH_DIR);
    @active_accounts = grep /\.passwd$/, readdir (AUTH_DIR);
    closedir (AUTH_DIR);

    foreach $passwd_file (sort (@active_accounts)) {
	open (PASSWD, "$AUTH_DIR/$passwd_file");
	chop ($passwd_contents = <PASSWD>);
	($login_id, $password_hash, $clearance, $full_name) =
	    split (/:/, $passwd_contents);
	close (PASSWD);

	$full_name =~ s/,/ /g;
	print "<tr><td>";
	
	if ($clearance =~ /ADMIN/) { $color = "#ff0040"; }
	elsif ($clearance =~ /PHYSICIAN/) { $color = "#ffff90"; }
	elsif ($clearance =~ /STAFF/) { $color = "#0090ff"; }
	else { $color = "#00ff90"; }
	
	print "<tr bgcolor=\"$color\">\n";

	if ($login_id ne "admin") {
	    print "<td><a href=\"/bin/account_administration.pl?OPERATION=MODIFY_INTRANET_USER&LOGIN_ID=$login_id\">$login_id</a>\n";
	} else {
	    print "<td>$login_id\n";
	}

	if (-e "$AUTH_DIR/$login_id.auth") {
	    if (is_session_key_expired ($login_id)) {
		$status = "Session Key Is Expired";
	    } else {
		$status = "Logged In";
	    }
	}
	else { $status = "<br>"; }

	print "<td>$full_name  <td>$clearance  <td>$status\n";

	print "<td align=center>(<a href=\"/bin/view_user_log_info.pl?login_id=$login_id\">view</a>)\n";
    }


    print <<EOF;
</table>

<br>

<h1 align=center><a href="Administration/add_intranet_user.html"><b>Add
New Intranet User</b></a></h1>

<hr>
<br>

<p align=center><b><u>Deactivated Accounts</u></b></p>

<table border=0 width="100%" cellspacing=0>
<tr><td><b>Login ID</b>  <td><b>Full Name</b>
    <td><b>Clearance</b>   <td align=center><b>Auth Log</b>
EOF
    ;

    opendir (AUTH_DIR, $AUTH_DIR);
    @deactivated_accounts = grep /\.deactivated$/, readdir (AUTH_DIR);
    closedir (AUTH_DIR);

    foreach $passwd_file (sort (@deactivated_accounts)) {
	open (PASSWD, "$AUTH_DIR/$passwd_file");
	chop ($passwd_contents = <PASSWD>);
	($login_id, $encrypted_password, $clearance, $full_name) =
	    split (/:/, $passwd_contents);
	close (PASSWD);

	$full_name =~ s/,/ /g;
	print "<tr><td>";
	
	if ($clearance =~ /ADMIN/) { $color = "#ff0040"; }
	elsif ($clearance =~ /PHYSICIAN/) { $color = "#ffff90"; }
	elsif ($clearance =~ /STAFF/) { $color = "#0090ff"; }
	else { $color = "#00ff90"; }
	
	print "<tr bgcolor=\"$color\">";
	print "<td><a href=\"/bin/account_administration.pl?OPERATION=MODIFY_INTRANET_USER&LOGIN_ID=$login_id\">$login_id</a>\n";
	print "<td>$full_name <td>$clearance\n";

	print "<td align=center>(<a href=\"/bin/view_user_log_info.pl?login_id=$login_id\">view</a>)\n";
    }

    print <<EOF;
</table>

EOF
    ;

    print_html_trailer();
}



sub add_intranet_user
{
    my ($login_id, $user_dir, $clearance, $full_name);
    my ($password, $password_hash);

    $login_id = $cgi_data->{'LOGIN_ID'};
    $login_id =~ tr/A-Z/a-z/;    # make sure the login_id is lowercase

    $user_dir = "$USER_ACCOUNTS_DIR/$login_id";

    # Check user name for length, format, etc...

    if (length ($login_id) < 3) {
	# username too short
	html_header_and_die ("Username $login_id is too short - must be at least 3 characters in length");
    }


    if (-e "$AUTH_DIR/$login_id.passwd" ||
	-e "$AUTH_DIR/$login_id.deactivated") {
	html_header_and_die ("User $login_id already exists in the system");
    }

    if (-e $user_dir) {
	html_header_and_die ("Home directory for $login_id already exists.");
    }


    # Check all inputs - some may not be empty:

    # Must have first name and last name:

    # check clearance for consistency:
    if ($cgi_data->{'CLEARANCE1'} eq "STUDENT") {
	$clearance = "STUDENT";
    } else {
	$clearance = "STAFF";
	if ($cgi_data->{'ADMIN'} eq "TRUE") { $clearance .= ",ADMIN"; }
	if ($cgi_data->{'PHYSICIAN'} eq "TRUE") { $clearance .= ",PHYSICIAN"; }
    }

    
    # Generate password file:
    if ( $cgi_data->{'GENERATE_PASSWORD'} eq "TRUE" ) {
	$password = generate_password();
    } else {
	$password = $cgi_data->{'PASSWORD'};
    }
    
    
    $full_name = join ( ',',
		       $cgi_data->{'FIRST_NAME'},
		       $cgi_data->{'MIDDLE_NAME'},
		       $cgi_data->{'LAST_NAME'} );


    if ( ! check_password_quality ( $login_id, $password ) ) {
	html_header_and_die ( $reason );
    }

    $password_hash = compute_hash ( "$login_id:$password" );
    
    # set umask for creating files and directories:
    # Want mode: 770 ==> 777-770 = 007
    umask (007);

    # Write $login_id.passwd file:
    open ( PASSWD, ">$AUTH_DIR/$login_id.passwd" );
    print PASSWD "$login_id:$password_hash:$clearance:$full_name\n";
    close ( PASSWD );

    # Create prototype user account:
    # Create home directory:
    mkdir ( "$user_dir", 0770 );

    print_html_header ( "Intranet User Added", $BASE_HREF );

    print <<EOF;

<br>
<h1 align=center><strong>New Intranet User Successfully Added</strong></h1>

<p>
User: $login_id<br>
Password: $password
</p>

<center>
<a href="/bin/account_administration.pl">Return to Account Administration Homepage</a>
</center>


EOF
    ;

    print_html_trailer();		       
}




sub modify_intranet_user
{
    $login_id = $cgi_data->{'LOGIN_ID'};

    print_html_header ( "Modify Intranet User Account", $BASE_HREF );

    print <<EOF;

<br>
<h1 align=center>Modify Intranet User Account<br>
for "$login_id"</h1>

<br>
EOF
    ;


    if ( -e "$AUTH_DIR/$login_id.passwd" ) {
	print <<EOF;
<form method="post" action="/bin/account_administration.pl">

<input type="hidden" name="OPERATION" value="PERFORM_MODIFICATIONS">
<input type="hidden" name="LOGIN_ID" value="$login_id">
<input type="hidden" name="RESET_PASSWORD" value="TRUE">

<center>
<strong>New Password:</strong>
<input type="text" name="NEW_PASSWORD" size=12>
<input type="submit" value=" Reset Password ">
</center>
</form>

<form method="post" action="/bin/account_administration.pl">

<input type="hidden" name="OPERATION" value="PERFORM_MODIFICATIONS">
<input type="hidden" name="LOGIN_ID" value="$login_id">
<input type="hidden" name="RETIRE_ACCOUNT" value="TRUE">

<center><input type="submit" value=" Retire Account "></center>
</form>
EOF
    ;

    } elsif ( -e "$AUTH_DIR/$login_id.deactivated" ) {
	print <<EOF;
<form method="post" action="/bin/account_administration.pl">

<input type="hidden" name="OPERATION" value="PERFORM_MODIFICATIONS">
<input type="hidden" name="LOGIN_ID" value="$login_id">
<input type="hidden" name="REACTIVATE_ACCOUNT" value="TRUE">

<center><input type="submit" value=" Reactivate Account "></center>
</form>
EOF
    ;
	
    }



    print <<EOF;
<br>
<hr>

<center><strong><a href="/bin/account_administration.pl">Return without
making any changes</a></strong></center>

EOF
    ;

    print_html_trailer();

}



sub perform_modifications
{
    my $login_id = $cgi_data->{'LOGIN_ID'};

    if (defined ($cgi_data->{'RETIRE_ACCOUNT'})) {
	retire_account ($login_id);

    } elsif (defined ($cgi_data->{'REACTIVATE_ACCOUNT'})) {
	reactivate_account ($login_id);

    } elsif (defined ($cgi_data->{'RESET_PASSWORD'})) {
	reset_password ($login_id, $cgi_data->{'NEW_PASSWORD'});
    }

    # For now, just return to the admin homepage:
    admin_homepage();
}



sub generate_password
{
    my ($time, @radix64_chars, $temp_password);

    # Seed random number generator for temporary password:
    # (Use bitwise XOR of system time and process ID)
    $time = time();
    srand ($time ^ $$);
    
    # Generate Radix64 character set:
    @radix64_chars = ('a'..'z', 'A'..'Z', '0'..'9', '.', '/');

    
    # Generate temporary password (temporary password is a
    # 10-character string):
    for ($i = 0; $i < 8; $i++) {
        $char = int (rand (64));
        if ($char == 64) { $char = 63; }
        push (@temp_password_characters, $radix64_chars[$char]);
    }
    
    $temp_password = pack ("a" x 10, @temp_password_characters);
    
    return $temp_password;
}




sub retire_account
{
    my $login_id = shift;

    # Remove the user account directory:
    rmtree ("$USER_ACCOUNTS_DIR/$login_id");

    # Make sure .auth file is removed (if it exists):
    unlink ("$AUTH_DIR/$login_id.auth");

    # Changed the password file from *.passwd to *.deactivated:
    rename ("$AUTH_DIR/$login_id.passwd", "$AUTH_DIR/$login_id.deactivated");
}




sub reactivate_account
{
    my $login_id = shift;

    # Recreate prototype user account:

    # set umask for creating files and directories:
    # Want mode: 770 ==> 777-770 = 007
    umask (007);

    # Create home directory:
    mkdir ("$user_dir", 0770);

    # Changed the password file from *.deactivated to *.passwd:
    rename ("$AUTH_DIR/$login_id.deactivated", "$AUTH_DIR/$login_id.passwd");
}



sub reset_password
{
    my  ($login_id, $new_password) = @_;
    my $new_password_hash;
    
    $new_password =~ s/^(\s*)//;
    $new_password =~ s/(\s*)$//;

    if (! check_password_quality ($login_id, $new_password)) {
	html_header_and_die ($reason);
    }

    $new_password_hash = compute_hash ("$login_id:$new_password");
    update_passwd_file ($login_id, $new_password_hash);


    print_html_header ("Password Successfully Changed", $BASE_HREF);

    print <<EOF;
<br><br>
<font size=+1><center>
Password for $login_id has been successfully changed to "$new_password".
</center></font>

<br><br>

<hr>
<center>
<a href="/bin/account_administration.pl">Return to Administration Homepage</a>
</center>

EOF

    print_html_trailer();
    
    exit;
}



sub is_session_key_expired
{
    # Read auth data from $login_id.auth file:
    open (AUTH, "$AUTH_DIR/$login_id.auth");
    flock (AUTH, LOCK_SH);
    while (<AUTH>) {
	if (/^(.*)=(.*)$/) { $auth_data{$1} = $2; }
    }
    flock (AUTH, LOCK_UN);
    close (AUTH);

    if ($auth_data{'KEY_EXPIRATION_TIME'} < time()) { return 1; }

    return 0;
}
