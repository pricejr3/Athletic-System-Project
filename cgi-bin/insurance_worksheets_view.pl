#!/usr/bin/perl

#
# insurance_worksheets_view.pl
#
# Copyright 2010
# Author: Michael J. Duff
# Last modified: November 15, 2010
#
# Description:
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "database_utilities.pl";

use DBI;


auth_user ($CLEARANCE_STAFF);

$cgi_data = parse_cgi_data();

prepare_cgi_data ($cgi_data);

print_html_header ("Query results", $BASE_HREF);

my $sql = build_sql_statement(); # First build the SQL statement

my $dbh = database_connect();                   # Establish connection to the database
    
my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query
    
display_results ($sth);                         # Display the results
    
database_disconnect ($dbh);                     # Disconnect from the database

print_html_trailer();

exit;



sub build_sql_statement
{
    my $sql = "
SELECT ALV.ORIG_VERSION_ID as ORIG_ATHLETE_ID, ALV.LAST_NAME, ALV.FIRST_NAME, ALV.MIDDLE_NAME,
       IRLV.SPORT, TO_CHAR(IRLV.DATE_OCCURRED, 'MM-DD-YYYY') as DATE_OCCURRED_CHAR,
       IRLV.POSITION, IRLV.BODY_PART, IRLV.INJURY_TYPE, IRLV.ATHLETICALLY_RELATED,
       IW.WORKSHEET_ID, IW.TOTAL_BALANCE, TO_CHAR(IW.FORM_SIGN_DATE, 'MM-DD-YYYY') as FORM_SIGN_DATE_CHAR, IW.INJURY_REPORT_ID as ORIG_INJURY_REPORT_ID

FROM   ATHLETE_LV as ALV, INJURY_REPORT_LV as IRLV, INSURANCE_WORKSHEETS as IW
WHERE  ALV.ORIG_VERSION_ID = IW.ATHLETE_ID AND IRLV.ORIG_VERSION_ID = IW.INJURY_REPORT_ID
";

    if ($cgi_data->{'LAST_NAME'}) {
	$sql .= " and UPPER(ALV.LAST_NAME) like UPPER('$cgi_data->{'LAST_NAME'}%')";
    }

    if ($cgi_data->{'FIRST_NAME'}) {
	$sql .= " and UPPER(ALV.FIRST_NAME) like UPPER('$cgi_data->{'FIRST_NAME'}%')";
    }

    if ($cgi_data->{'MIDDLE_NAME'}) {
	$sql .= " and UPPER(ALV.MIDDLE_NAME) like UPPER('$cgi_data->{'MIDDLE_NAME'}%')";
    }

    if ($cgi_data->{'SEX'}) {
	$sql .= " and ALV.SEX = '$cgi_data->{'SEX'}'";
    }

    if ($cgi_data->{'STATUS'}) {
	$sql .= " and ALV.STATUS = '$cgi_data->{'STATUS'}'";
    }

    if ($cgi_data->{'SPORT'}) {
	$sql .= " and IRLV.SPORT = '$cgi_data->{'SPORT'}'";
    }

    if ($cgi_data->{'TOTAL_BALANCE1'}) {
	$sql .= " and IW.TOTAL_BALANCE >= '$cgi_data->{'TOTAL_BALANCE1'}'";
    }

    if ($cgi_data->{'TOTAL_BALANCE2'}) {
	$sql .= " and IW.TOTAL_BALANCE <= '$cgi_data->{'TOTAL_BALANCE2'}'";
    }

    $sql .= " ORDER BY IW.FORM_SIGN_DATE";

    $sql = format_sql_statement ($sql);

    #print "<b>$sql</b><br><br>\n";

    return $sql;
}




sub display_results
{
    my $sth = shift;

    print <<EOF;
<table border=0 width="100%">
<tr><td><b><u>Athlete</u></b>
    <td><b><u>Sport</u></b>
    <td align="center"><b><u>Injury Date</u></b>
    <td><b><u>Position</u></b>
    <td><b><u>Body Part</u></b>
    <td><b><u>Injury Type</u></b>
    <td><b><u>Athletically Related</u></b>
    <td align="center"><b><u>Date Submitted</u></b>
    <td align="right"><b><u>Balance</u></b>
EOF
    ;

    my $hide_zero_balances = ($cgi_data->{'ZERO_BALANCES'} eq 'Hide');

    my $grand_total_balance = 0;

    my $num_rows = 0;
    my $db_data;
    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;

	my $total_balance         = $db_data->{'total_balance'};
	if ($hide_zero_balances && $total_balance == 0)  { next; }
	
	my $orig_athlete_id       = $db_data->{'orig_athlete_id'};
	my $orig_injury_report_id = $db_data->{'orig_injury_report_id'};
	my $total_balance_char    = currency_format ($total_balance, 1);

	$grand_total_balance += $total_balance;

	print <<EOF;
<tr>
<td><a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$orig_athlete_id" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a></td>

<td>$db_data->{'sport'}</td>

<td align="center">$db_data->{'date_occurred_char'}</td>

<td>$db_data->{'position'}</td>

<td>$db_data->{'body_part'}</td>

<td>$db_data->{'injury_type'}</td>

<td>$db_data->{'athletically_related'}</td>

<td align="center">$db_data->{'form_sign_date_char'}</td>

<td nowrap align="right"><a href="/bin/insurance_worksheet.pl?ORIG_ATHLETE_ID=$orig_athlete_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id">\$$total_balance_char</a></td>
EOF
    ;
    }

    
    $sth->finish;


    my $grand_total_balance_char = currency_format ($grand_total_balance, 1);

    print <<EOF;
<tr>
<td colspan="9" align="right"><hr/><br/><b>Total Balance: \$$grand_total_balance_char</b></td>
</tr>
</table>

<hr>

<b>$num_rows Report(s) Found</b>
EOF
    ;
}



sub currency_format {
    my ($amount, $show_zero) = @_;
    if ($amount == 0 && ! $show_zero) { return ''; }
    else                              { return sprintf ("%.2f", $amount); }
}
