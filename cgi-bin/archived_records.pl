#!/usr/bin/perl

#
# archived_records
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: March 30, 1999
#
# Description:
#    Utility for listing and purging archived athlete records
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "database_utilities.pl";

use DBI;


($login_id, $clearance) = auth_user ($CLEARANCE_ADMIN);


$cgi_data = parse_cgi_data();

$operation = $cgi_data->{'OPERATION'};

if    ($operation eq "LIST_ALL_ARCHIVED")          { list_all_archived(); }
elsif ($operation eq "LIST_ALL_ELIGIBLE")          { list_all_eligible(); }
elsif ($operation eq "PURGE_ATHLETE_CONFIRM")      { purge_confirm(); }
elsif ($operation eq "PURGE_ALL_ELIGIBLE_CONFIRM") { purge_confirm(); }
elsif ($operation eq "PURGE_ATHLETE")              { purge(); }
elsif ($operation eq "PURGE_ALL_ELIGIBLE")         { purge(); }
else                                               { list_all_archived(); }

exit;




sub list_all_archived
{
    print_html_header ("Query results", $BASE_HREF);

    my $sql = build_sql_statement_list_all ($cgi_data); # First build the SQL statement

    my $dbh = database_connect();                       # Establish connection to the database

    my $sth = execute_sql_statement ($dbh, $sql);       # Now execute the query

    display_results_list_all ($sth);                    # Display the results
    
    database_disconnect ($dbh);                         # Disconnect from the database

    print_html_trailer();

    exit;
}




sub build_sql_statement_list_all
{
    my $cgi_data = shift;

    $sql = "
SELECT ORIG_VERSION_ID as ORIG_ATHLETE_ID, LAST_NAME, FIRST_NAME, MIDDLE_NAME, SPORT,
       TO_CHAR (FORM_SIGN_DATE, 'MM-DD-YYYY') as ARCHIVED_SINCE,
       date_part ('day', (now() - FORM_SIGN_DATE)) / 365 as ELAPSED_YEARS

FROM athlete_lv

WHERE STATUS = 'Archived'

order by UPPER (LAST_NAME)";
    
    $sql = format_sql_statement ($sql);

    return $sql;
}



sub display_results_list_all
{
    my $sth = shift;

    print <<EOF;
<center>
<table border=0 width="100%">
<tr><td><b><u>Athlete</u></b>            <td><b><u>Sport</u></b>
    <td><b><u>Archived Since</u></b>     <td><b><u>Elapsed Time<br>(in years)</u></b>
EOF
    ;

    my $num_rows = 0;
    my $db_data;
    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;
 	$orig_athlete_id = $db_data->{'orig_athlete_id'};
	
	$db_data->{'elapsed_years'} =~ s/\.(\d)(\d)(\d*)/\.$1$2/;   # Display only two decimal places

	print <<EOF;
<tr>
<td>
<a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$orig_athlete_id" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a>

<td>$db_data->{'sport'}

<td>$db_data->{'archived_since'}

<td>$db_data->{'elapsed_years'}
EOF
    ;
    }

    
    $sth->finish;


    print <<EOF;
</table>

<hr>

<b>$num_rows Archived Record(s) Found</b>
</center>
EOF
    ;
}




sub list_all_eligible
{
    print_html_header ("Archived Athlete Records", $BASE_HREF);

    my $sql = build_sql_statement_eligible ($cgi_data); # First build the SQL statement

    my $dbh = database_connect();                       # Establish connection to the database

    my $sth = execute_sql_statement ($dbh, $sql);       # Now execute the query

    display_results_eligible ($sth);                    # Display the results
    
    database_disconnect ($dbh);                         # Disconnect from the database

    print_html_trailer();

    exit;
}




sub build_sql_statement_eligible
{
    my $cgi_data = shift;

    $sql = "
SELECT ORIG_VERSION_ID as ORIG_ATHLETE_ID, LAST_NAME, FIRST_NAME, MIDDLE_NAME, SPORT,
       TO_CHAR (FORM_SIGN_DATE, 'MM-DD-YYYY') as ARCHIVED_SINCE,
       date_part ('day', (now() - FORM_SIGN_DATE)) / 365 as ELAPSED_YEARS

FROM athlete_lv

WHERE STATUS = 'Archived' and date_part ('day', (now() - FORM_SIGN_DATE)) / 365 >= 7

order by UPPER (LAST_NAME)";
    
    $sql = format_sql_statement ($sql);

    return $sql;
}



sub display_results_eligible
{
    my $sth = shift;

    print <<EOF;
<table border=0 width="100%">
<tr><td><b><u>Athlete</u></b>            <td><b><u>Sport</u></b>
    <td><b><u>Archived Since</u></b>     <td><b><u>Elapsed Time<br>(in years)</u></b>
    <td><b><u>Action</u></b>
EOF
    ;

    my $num_rows = 0;
    my $db_data;
    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;
	$orig_athlete_id = $db_data->{'orig_athlete_id'};

	# Format elapsed years:
	$elapsed_years = $db_data->{'elapsed_years'};
	$elapsed_years =~ s/\.(\d)(\d)(\d*)/\.$1$2/;   # Display only two decimal places
	if ($elapsed_years =~ /^\./) { $elapsed_years =~ s/\./0\./; }  # Append a zero
	
	print <<EOF;
<tr>
<td>
<a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$orig_athlete_id" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a>

<td>$db_data->{'sport'}

<td>$db_data->{'archived_since'}

<td>$elapsed_years

<td>
<a href="/bin/archived_records.pl?OPERATION=PURGE_ATHLETE_CONFIRM&ORIG_ATHLETE_ID=$orig_athlete_id">
<b>purge</b></a>
EOF
    ;
    }

    
    $sth->finish;


    print <<EOF;
</table>

<hr>

<b>$num_rows Archived Record(s) Found</b>
EOF
    ;

    if ($num_rows > 0) {
	print <<EOF;
<p>
<center>
<a href="/bin/archived_records.pl?OPERATION=PURGE_ALL_ELIGIBLE_CONFIRM">Purge All
Eligible Records</a>
</center>
EOF
    ;
    }
}



sub purge_confirm
{
    print_html_header ("Archived Athlete Records", $BASE_HREF);

    my $operation = $cgi_data->{'OPERATION'};
    my $args;

    if ($operation eq "PURGE_ATHLETE_CONFIRM") {
	$args = "OPERATION=PURGE_ATHLETE&ORIG_ATHLETE_ID=$cgi_data->{'ORIG_ATHLETE_ID'}";
    } else {   # PURGE_ALL_ELIGIBLE_CONFIRM
	$args = "OPERATION=PURGE_ALL_ELIGIBLE";
    }

    print <<EOF;
<br><br><br><br><br><br>

<h1 align=center><font color="#a50000"><b>Are you certain you want to purge this/these records?</b></font></h1>

<center>
<table border="0" cellpadding=10>
<tr>
<td><a href="/bin/archived_records.pl?$args"><img src="Images/yes.gif" border=1></a></td>
<td><a href="/bin/archived_records.pl?OPERATION=LIST_ALL_ELIGIBLE"><img src="Images/no.gif" border=1></a></td>
</tr>
</table>
</center>
EOF
    ;

    print_html_trailer();

    exit;
}



sub purge
{
    my $sql = build_sql_statement_purge ($cgi_data);

    my $dbh = database_purge_connect();         # Connect as user with special priviledges

    my $sth = execute_sql_statement ($dbh, $sql);             # Execute the SQL statement

    database_disconnect ($dbh);                               # Disconnect from the database

    list_all_eligible();                        # Redisplay list of eligible records
}




sub build_sql_statement_purge
{
    my $cgi_data = shift;
    my $operation = $cgi_data->{'OPERATION'};
    my $orig_athlete_id = $cgi_data->{'ORIG_ATHLETE_ID'};

    #
    # Must remove all athlete records with the given ORIG_ATHLETE_ID.
    #
    # Keep eligibility clause for security purposes.
    #
    my $sql;
    if ($operation eq "PURGE_ATHLETE") {
	$sql = "
DELETE FROM athlete WHERE

ORIG_VERSION_ID in

(SELECT ORIG_VERSION_ID from athlete_lv WHERE
        ORIG_VERSION_ID = '$orig_athlete_id' and
        STATUS = 'Archived' and
        date_part ('day', (now() - FORM_SIGN_DATE)) / 365 >= 7)
";


    } elsif ($operation eq "PURGE_ALL_ELIGIBLE") {
        $sql = "
DELETE FROM athlete WHERE

ORIG_VERSION_ID in

(SELECT ORIG_VERSION_ID from athlete_lv WHERE
        STATUS = 'Archived' and
        date_part ('day', (now() - FORM_SIGN_DATE)) / 365 >= 7)
";
    }


    $sql = format_sql_statement ($sql);

    return $sql;
}

