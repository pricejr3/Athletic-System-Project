#!/usr/bin/perl

#
# add_new_athlete
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: April 4, 1999
#
# Description:
#    Adds new athlete record to database.
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "form_utilities.pl";
require "database_utilities.pl";

use DBI;


($login_id, $clearance) = auth_user ($CLEARANCE_STUDENT);

$cgi_data = parse_cgi_data();

# First check to make sure this athlete has not already been added
# to the database:

@matches = check_for_matches();

$num_found = $#matches + 1;

if ($num_found == 0) {
    # No matches were found, so go ahead with form processing:
    submit_unsigned_form();

    exit;
}



print_html_header ("Add New Athlete", $BASE_HREF);


print <<EOF;

<font size=+2 color="#ff0000">
<b>
<center>

<blink><p>Warning!</p></blink>

<br>

<p>Possible duplicate athlete record(s) found in the database</p>
</center>
</b>
</font>

<center>
Carefully review the matches below to make sure you are not adding the
same athlete twice into the system.  If you are certain, then click
the "Continue With Addition" button below.
</center>

<hr>

<table border=0>
<tr><td><b><u>Athlete</u></b>    <td><b><u>Sport</u></b>   <td><b><u>SSN#</u></b>

EOF
;


# Display each of the matches:
foreach (@matches) { print "$_\n"; }


print <<EOF;
</table>

<hr>

<b>$num_found Athlete(s) Found</b>


<form method="post" action="/bin/process_form">

EOF
    ;

# Need to indicate form type?

# Pass along all information to process form script:
foreach (keys (%$cgi_data)) {
    print qq|<input type="hidden" name="$_" value="$cgi_data->{$_}">\n|;
}


print <<EOF;

<center><input type="submit" value=" Continue With Addition "></center>
</form>
EOF
    ;


print_html_trailer();

exit;




sub check_for_matches
{
    # Build the select statement:

    # Prepare search fields:
    prepare_cgi_data ($cgi_data);
    
    my $sql = "
SELECT ORIG_VERSION_ID as ORIG_ATHLETE_ID, LAST_NAME, FIRST_NAME, SSN, SPORT
   from athlete_lv WHERE

( ( UPPER(LAST_NAME) = UPPER('$cgi_data->{'LAST_NAME'}') ) and
  ( UPPER(FIRST_NAME) = UPPER('$cgi_data->{'FIRST_NAME'}') ) )

or

( SSN = '$cgi_data->{'SSN'}' )

   order by UPPER (LAST_NAME)";


    $sql = format_sql_statement ($sql);
    
    my $dbh = database_connect();                   # Establish connection to the database

    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query


    my ($db_data, $new_match, @matches);
    while ($db_data = $sth->fetchrow_hashref) {
	$orig_athlete_id = $db_data->{'orig_athlete_id'};

	$new_match = qq|
<tr>
<td>
<a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$orig_athlete_id" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a>

<td>
$db_data->{'sport'}

<td>
$db_data->{'ssn'}
|;

        push (@matches, $new_match);
    }


    $sth->finish;
    $dbh->disconnect;

    foreach ( keys ( %$cgi_data ) ) {
	$cgi_data->{$_} =~ s/''/'/g;   # Return to normal  '
    }

    return @matches;
}

