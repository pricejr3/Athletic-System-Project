#!/usr/bin/perl

#
# search_for_athlete
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: April 4, 1999
#
# Description:
#    Performs a query on the database.
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "database_utilities.pl";

use DBI;


auth_user ($CLEARANCE_STUDENT);

$cgi_data = parse_cgi_data();

prepare_cgi_data ($cgi_data);

print_html_header ("Query results", $BASE_HREF);

my $sql = build_sql_statement ($cgi_data);      # First build the SQL statement

my $dbh = database_connect();                   # Establish connection to the database

my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

display_results ($sth);                         # Display the results

database_disconnect ($dbh);                     # Disconnect from the database

print_html_trailer();

exit;



sub build_sql_statement
{
    my $cgi_data = shift;

    #
    # The "ORIG_VERSION_ID > 0" clause is there only to serve as a first clause
    #
    $sql = "
SELECT ORIG_VERSION_ID as ORIG_ATHLETE_ID, LAST_NAME, FIRST_NAME, MIDDLE_NAME, SPORT
    from athlete_lv
WHERE
    ORIG_VERSION_ID > 0
";

    if ($cgi_data->{'LAST_NAME'}) {
	$sql .= " and UPPER(LAST_NAME) like UPPER('$cgi_data->{'LAST_NAME'}%')";
    }

    if ($cgi_data->{'FIRST_NAME'}) {
	$sql .= " and UPPER(FIRST_NAME) like UPPER('$cgi_data->{'FIRST_NAME'}%')";
    }

    if ($cgi_data->{'MIDDLE_NAME'}) {
	$sql .= " and UPPER(MIDDLE_NAME) like UPPER('$cgi_data->{'MIDDLE_NAME'}%')";
    }

    if ($cgi_data->{'SPORT'}) {
	$sql .= " and SPORT = '$cgi_data->{'SPORT'}'";
    }

    if ($cgi_data->{'SEX'}) {
	$sql .= " and SEX = '$cgi_data->{'SEX'}'";
    }

    if ($cgi_data->{'SSN'}) {
	$sql .= " and SSN like '$cgi_data->{'SSN'}%'";
    }

    if ($cgi_data->{'STATUS'}) {
	$sql .= " and STATUS = '$cgi_data->{'STATUS'}'";
    }

    if ($cgi_data->{'NOTE'}) {
	$sql .= " and UPPER(NOTE) like UPPER('%" . $cgi_data->{'NOTE'} . "%')";
    }
    
    $sql .= " order by UPPER (LAST_NAME)";
    
    $sql = format_sql_statement ($sql);

    return $sql;
}



sub display_results
{
    my $sth = shift;

    print <<EOF;
<table border=0 width="100%">
<tr><td><b><u>Athlete</u></b>    <td><b><u>Sport</u></b></tr>
EOF
    ;

    my $num_rows = 0;
    my $db_data;
    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;
    
	print <<EOF;
<tr>
<td>
<a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$db_data->{'orig_athlete_id'}" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a></td>

<td>$db_data->{'sport'}</td>
</tr>

EOF
    ;
    }

    
    $sth->finish;


    print <<EOF;
</table>

<hr>

<b>$num_rows Athlete(s) Found</b>
EOF
    ;
}
