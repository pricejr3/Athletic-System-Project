#!/usr/bin/perl

#
# insurance_worksheet_entries_view.pl
#
# Copyright 2010
# Author: Michael J. Duff
# Last modified: December 20, 2010
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
       IRLV.POSITION, IRLV.BODY_PART, IRLV.INJURY_TYPE,
       IW.WORKSHEET_ID, IW.TOTAL_BALANCE, TO_CHAR(IW.FORM_SIGN_DATE, 'MM-DD-YYYY') as FORM_SIGN_DATE_CHAR, IW.INJURY_REPORT_ID as ORIG_INJURY_REPORT_ID,
       TO_CHAR(IWE.DATE_RECEIVED, 'MM-DD-YYYY') as DATE_RECEIVED_CHAR, TO_CHAR(IWE.SERVICE_DATE, 'MM-DD-YYYY') as SERVICE_DATE_CHAR,  IWE.MEDICAL_PROVIDER,
       IWE.SERVICE_COST, IWE.PAID_BY_ATHLETE_PRIMARY, IWE.PAID_BY_ATHLETE_SECONDARY, IWE.INSURANCE_WRITEOFF, IWE.PAID_BY_MIAMI_PRIMARY, IWE.PAID_BY_MIAMI_SECONDARY

FROM   ATHLETE_LV as ALV, INJURY_REPORT_LV as IRLV, INSURANCE_WORKSHEETS as IW, INSURANCE_WORKSHEET_ENTRIES as IWE
WHERE  ALV.ORIG_VERSION_ID = IW.ATHLETE_ID AND IRLV.ORIG_VERSION_ID = IW.INJURY_REPORT_ID AND IW.WORKSHEET_ID = IWE.WORKSHEET_ID
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

    if ($cgi_data->{'MEDICAL_PROVIDER'}) {
	$sql .= " and IWE.MEDICAL_PROVIDER = '$cgi_data->{'MEDICAL_PROVIDER'}'";
    }

    if ($cgi_data->{'DATE_RECEIVED1'}) {
	$sql .= " and IWE.DATE_RECEIVED >= TO_DATE('$cgi_data->{'DATE_RECEIVED1'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'DATE_RECEIVED2'}) {
	$sql .= " and IWE.DATE_RECEIVED <= TO_DATE('$cgi_data->{'DATE_RECEIVED2'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'SERVICE_DATE1'}) {
	$sql .= " and IWE.SERVICE_DATE >= TO_DATE('$cgi_data->{'SERVICE_DATE1'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'SERVICE_DATE2'}) {
	$sql .= " and IWE.SERVICE_DATE <= TO_DATE('$cgi_data->{'SERVICE_DATE2'}', 'MM-DD-YYYY')";
    }

    $sql .= " ORDER BY " . $cgi_data->{'SORT_BY'};

    $sql = format_sql_statement ($sql);

    #print "<b>$sql</b><br><br>\n";

    return $sql;
}




sub display_results
{
    my $sth = shift;

    print <<EOF;
<table border="0" width="100%">
<tr><td><b><u>Athlete</u></b>
    <td align="center"><b><u>Sport</u></b></td>
    <td align="center"><b><u>Injury Date</u></b></td>
    <td align="center"><b><u>Date Received</u></b></td>
    <td align="center"><b><u>Medical Provider</u></b></td>
    <td align="center"><b><u>Service Date</u></b></td>
    <td align="right"><b><u>Amount Charged</u></b></td>
    <td align="right"><b><u>Athlete Primary</u></b></td>
    <td align="right"><b><u>Athlete Secondary</u></b></td>
    <td align="right"><b><u>Insurance Writeoff</u></b></td>
    <td align="right"><b><u>Maksim</u></b></td>
    <td align="right"><b><u>Miami Athlete Insurance</u></b></td>
EOF
    ;

    my $show_entries = ($cgi_data->{'SHOW_HIDE_ENTRIES'} eq 'Show' ? 1: 0);

    my $total_paid_by_athlete_primary   = 0;
    my $total_paid_by_athlete_secondary = 0;
    my $total_insurance_writeoff        = 0;
    my $total_paid_by_miami_primary     = 0;
    my $total_paid_by_miami_secondary   = 0;

    my $num_rows = 0;
    my $db_data;
    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;

	$total_service_cost              += $db_data->{'service_cost'};
	$total_paid_by_athlete_primary   += $db_data->{'paid_by_athlete_primary'};
	$total_paid_by_athlete_secondary += $db_data->{'paid_by_athlete_secondary'};
	$total_insurance_writeoff        += $db_data->{'insurance_writeoff'};
	$total_paid_by_miami_primary     += $db_data->{'paid_by_miami_primary'};
	$total_paid_by_miami_secondary   += $db_data->{'paid_by_miami_secondary'};

	if (! $show_entries)  { next; }
	
	my $orig_athlete_id       = $db_data->{'orig_athlete_id'};
	my $orig_injury_report_id = $db_data->{'orig_injury_report_id'};

	my $service_cost_char              = currency_format ($db_data->{'service_cost'},              1);
	my $paid_by_athlete_primary_char   = currency_format ($db_data->{'paid_by_athlete_primary'},   1);
	my $paid_by_athlete_secondary_char = currency_format ($db_data->{'paid_by_athlete_secondary'}, 1);
	my $insurance_writeoff_char        = currency_format ($db_data->{'insurance_writeoff'},        1);
	my $paid_by_miami_primary_char     = currency_format ($db_data->{'paid_by_miami_primary'},     1);
	my $paid_by_miami_secondary_char   = currency_format ($db_data->{'paid_by_miami_secondary'},   1);

	print <<EOF;
<tr>
<td><a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$orig_athlete_id" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a></td>

<td align="center">$db_data->{'sport'}</td>

<td align="center">$db_data->{'date_occurred_char'}</td>

<td align="center"><a href="/bin/insurance_worksheet.pl?ORIG_ATHLETE_ID=$orig_athlete_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id">$db_data->{'date_received_char'}</a></td>

<td align="center">$db_data->{'medical_provider'}</td>

<td align="center"><a href="/bin/insurance_worksheet.pl?ORIG_ATHLETE_ID=$orig_athlete_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id">$db_data->{'service_date_char'}</a></td>

<td align="right">$service_cost_char</td>

<td align="right">$paid_by_athlete_primary_char</td>

<td align="right">$paid_by_athlete_secondary_char</td>

<td align="right">$insurance_writeoff_char</td>

<td align="right">$paid_by_miami_primary_char</td>

<td align="right">$paid_by_miami_secondary_char</td>
</tr>
EOF
    ;
    }

    
    $sth->finish;


    my $total_service_cost_char              = currency_format ($total_service_cost,              1);
    my $total_paid_by_athlete_primary_char   = currency_format ($total_paid_by_athlete_primary,   1);
    my $total_paid_by_athlete_secondary_char = currency_format ($total_paid_by_athlete_secondary, 1);
    my $total_insurance_writeoff_char        = currency_format ($total_insurance_writeoff,        1);
    my $total_paid_by_miami_primary_char     = currency_format ($total_paid_by_miami_primary,     1);
    my $total_paid_by_miami_secondary_char   = currency_format ($total_paid_by_miami_secondary,   1);

    print <<EOF;
<tr><td colspan="12"><hr/></td></tr>
<tr>
  <td colspan="6" align="right"><b>Totals:</b></td>
  <td align="right"><b>\$$total_service_cost_char</b></td>
  <td align="right"><b>\$$total_paid_by_athlete_primary_char</b></td>
  <td align="right"><b>\$$total_paid_by_athlete_secondary_char</b></td>
  <td align="right"><b>\$$total_insurance_writeoff_char</b></td>
  <td align="right"><b>\$$total_paid_by_miami_primary_char</b></td>
  <td align="right"><b>\$$total_paid_by_miami_secondary_char</b></td>
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
