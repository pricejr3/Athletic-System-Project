#!/usr/bin/perl

# student_access.pl
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: March 28, 1999
#
# Description: Editing utility for student_access file
#

require "global.pl";
require "auth_user.pl";
require "file_locking.pl";
require "parse.pl";
require "html_utilities.pl";
require "logging.pl";


($login_id, $clearance) = auth_user ($CLEARANCE_ADMIN);

$cgi_data  = parse_cgi_data();
$operation = $cgi_data->{'OPERATION'};

$STUDENT_ACCESS = "$AUTH_DIR/student_access";


# Dispatch the request:
if    ($operation eq "MODIFY")        { modify_student_access(); }
elsif ($operation eq "MODIFY_SUBMIT") { modify_student_access_submit(); }
else                                  { display_addresses(); }

exit;



sub display_addresses
{
    print_html_header ("Student Access", $BASE_HREF);

    print <<EOF;
<br>
<center><img src="Images/student_access.gif"></center>

<br><br>

<p align=center>
<b>The following are the IP addresses of the computers from which Intranet
users with "STUDENT" clearance are permitted to log into the MUSM Intranet. To add, remove,
or edit entries on this list, click the "Modify" button below.</b>
</p>

<br><br>
<p>
<center>

<table border=2>
EOF
    ;

    open (ADDRESSES, $STUDENT_ACCESS);
    flock (ADDRESSES, $LOCK_SH);
    seek (ADDRESSES, 0, 0);    # Rewind back to the beginning of the file
    while (<ADDRESSES>) { print "<tr><td bgcolor=\"#88aa99\">$_\n"; }
    close (ADDRESSES);


    print <<EOF;
</table>

<br>
<p>
<form name="student_access" action="/bin/student_access.pl" method="POST">
<input type="hidden" name="OPERATION" value="MODIFY">
<input type="submit" value=" Modify ">
</form>

</center>
EOF
    ;

    print_html_trailer();

    exit;
}




sub modify_student_access
{
    print_html_header ("Modify Student Access", $BASE_HREF);

    print <<EOF;
<br>
<center><img src="Images/student_access.gif"></center>

<br><br>

<p align=center><b>
Add or remove IP addresses from the window below.  The addresses must be in the
format of w.x.y.z (where w, x, y, and z are integers between 0 and 255 inclusive).
</b></p>

<br>
EOF
    ;

    
    if ($#errors >= 0) {
        print "<center><font color=\"#ff0000\"><b>\n";
        print @errors;
        print "</b></font></center>\n";
    }


    print <<EOF;
<br>
<p>
<center>
<form name="student_access" action="/bin/student_access.pl" method="POST">
<input type="hidden" name="OPERATION" value="MODIFY_SUBMIT">

<textarea name="ADDRESSES" rows=10 cols=15 wrap="physical">
EOF
    ;

    open (ADDRESSES, $STUDENT_ACCESS);
    flock (ADDRESSES, $LOCK_SH);
    seek (ADDRESSES, 0, 0);    # Rewind back to the beginning of the file
    while (<ADDRESSES>) { print; }
    close (ADDRESSES);

print <<EOF;
</textarea>

<br>
<input type="submit" value=" Submit Modifications ">
</form>

</center>
EOF
    ;

    print_html_trailer();

    exit;
}



sub modify_student_access_submit
{
    my $addresses = $cgi_data->{'ADDRESSES'};
 
    # First check the entries for format:
    my @address_list = split (/\n/, $addresses);
    @errors = ();
    my @verified_address_list;
    my $address;

    foreach $address (@address_list) {
	$address =~ s/^(\s+)//;
	$address =~ s/(\s+)$//;

	if ($address !~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/ ||
	    $1 < 0 || $1 > 255 || $2 < 0 || $2 > 255 ||
	    $3 < 0 || $3 > 255 || $4 < 0 || $4 > 255) {
	    push (@errors, "\"$address\" does not have the correct format.<br>\n");
	} else {
	    push (@verified_address_list, $address);
	}
    }


    if ($#errors >= 0) { modify_student_access(); }

    
    open (ADDRESSES, ">$STUDENT_ACCESS");
    flock (ADDRESSES, $LOCK_EX);
    seek (ADDRESSES, 0, 0);
    foreach $address (sort (@verified_address_list)) { print ADDRESSES "$address\n"; }
    close (ADDRESSES);

    display_addresses();
}




sub operation_not_permitted
{
    print_html_header ("Student Access", $BASE_HREF);

    print <<EOF;
<br>
<center><img src="Images/student_access.gif"></center>


<br><br>

<h1 align=center>Operation Not Permitted (need STAFF clearance)</h1>

EOF
    ;

    print_html_trailer();

    exit;
}
