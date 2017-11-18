#!/usr/bin/perl

#
# unsigned_forms_view
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: April 2, 1999
#
# Description:
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

my ($sql, $num_form_types) = build_sql_statement(); # First build the SQL statement

if ($num_form_types > 0) {
    my $dbh = database_connect();                   # Establish connection to the database
    
    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query
    
    display_results ($sth);                         # Display the results
    
    database_disconnect ($dbh);                     # Disconnect from the database
}

print_html_trailer();

exit;



sub build_sql_statement
{
    my $sql;
    my $first_statement = 1;
    my $num_form_types = 0;

    if ($cgi_data->{'INJURY_REPORT'} eq "YES") {
	if (! $first_statement) { $sql .= " UNION ALL "; }

	$sql .= build_sub_sql_statement ('INJURY_REPORT',
					 'Injury Report', 0);
	$first_statement = 0;
	$num_form_types++;
    }


    if ($cgi_data->{'INJURY_ADDTNL_INFO'} eq "YES") {
	if (! $first_statement) { $sql .= " UNION ALL "; }

	$sql .= build_sub_sql_statement ('INJURY_ADDTNL_INFO',
					 'Injury Additional Information', 1);
	$first_statement = 0;
	$num_form_types++;
    }


    if ($cgi_data->{'TREATMENT_REMARK'} eq "YES") {
	if (! $first_statement) { $sql .= " UNION ALL "; }

	$sql .= build_sub_sql_statement ('TREATMENT_REMARK',
					 'Treatment Remark', 1);
	$first_statement = 0;
	$num_form_types++;
    }


    if ($cgi_data->{'TREATMENT_ADDTNL_INFO'} eq "YES") {
	if (! $first_statement) { $sql .= " UNION ALL "; }
	
	$sql .= build_sub_sql_statement ('TREATMENT_ADDTNL_INFO',
					 'Treatment Additional Information', 0);
	$first_statement = 0;
	$num_form_types++;
    }
    
    
    if ($cgi_data->{'PHYSICIAN_REMARK'} eq "YES") {
	if (! $first_statement) { $sql .= " UNION ALL "; }
	
	$sql .= build_sub_sql_statement ('PHYSICIAN_REMARK',
					 'Physician Remark', 1);
	$first_statement = 0;
	$num_form_types++;
    }
    

    if ($cgi_data->{'PERSONAL_ADDTNL_INFO'} eq "YES") {
	if (! $first_statement) { $sql .= " UNION ALL "; }

	$sql .= build_sub_sql_statement ('PERSONAL_ADDTNL_INFO',
					 'Personal Additional Information', 0);
	$first_statement = 0;
	$num_form_types++;
    }


    if ($cgi_data->{'RECOMMENDED_TREATMENT'} eq "YES") {
	if (! $first_statement) { $sql .= " UNION ALL "; }

	$sql .= build_sub_sql_statement ('RECOMMENDED_TREATMENT',
					 'Recommended Treatment', 0);
	$first_statement = 0;
	$num_form_types++;
    }

    $sql .= " ORDER BY FORM_SIGN_DATE DESC";

    $sql = format_sql_statement ($sql);

    # print "<b>$sql</b><br><br>\n";

    return ($sql, $num_form_types);
}




sub build_sub_sql_statement
{
    my ($table_name, $form_type, $keyed_on_injury_id) = @_;
    my $sql;

    if ($keyed_on_injury_id) {
	$sql .= "
SELECT '$table_name' as FORM_NAME, TNLV.ORIG_VERSION_ID as ORIG_FORM_ID,
       '$form_type' as FORM_TYPE, ALV.ORIG_VERSION_ID as ORIG_ATHLETE_ID,
       ALV.LAST_NAME, ALV.FIRST_NAME, ALV.MIDDLE_NAME,
       IRLV.ORIG_VERSION_ID as ORIG_INJURY_REPORT_ID, IRLV.SPORT,
       TO_CHAR(TNLV.FORM_SIGN_DATE, 'MM-DD-YYYY') as FORM_SIGN_DATE_CHAR,
       TNLV.FORM_SIGN_DATE as FORM_SIGN_DATE

FROM   ATHLETE_LV as ALV, INJURY_REPORT_LV as IRLV, " . $table_name . "_LV as TNLV

WHERE  ALV.ORIG_VERSION_ID = IRLV.ATHLETE_ID and TNLV.INJURY_REPORT_ID = IRLV.INJURY_REPORT_ID
";

    } else {
	$sql .= "
SELECT '$table_name' as FORM_NAME, TNLV.ORIG_VERSION_ID as ORIG_FORM_ID,
       '$form_type' as FORM_TYPE, ALV.ORIG_VERSION_ID as ORIG_ATHLETE_ID,
       ALV.LAST_NAME, ALV.FIRST_NAME, ALV.MIDDLE_NAME,
       0 as ORIG_INJURY_REPORT_ID, TNLV.SPORT,
       TO_CHAR(TNLV.FORM_SIGN_DATE, 'MM-DD-YYYY') as FORM_SIGN_DATE_CHAR,
       TNLV.FORM_SIGN_DATE as FORM_SIGN_DATE

FROM   ATHLETE_LV as ALV, " . $table_name. "_LV as TNLV

WHERE  ALV.ORIG_VERSION_ID = TNLV.ATHLETE_ID
";
    }


    $sql .= " and TNLV.REVIEW_REQUIRED = 'Yes'";

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

    if ($cgi_data->{'SPORT'}) {
	if ($keyed_on_injury_id) { $sql .= " and IRLV.SPORT = '$cgi_data->{'SPORT'}'"; }
	else { $sql .= " and TNLV.SPORT = '$cgi_data->{'SPORT'}'"; }
    }

    if ($cgi_data->{'STATUS'}) {
	$sql .= " and ALV.STATUS = '$cgi_data->{'STATUS'}'";
    }

    if ($cgi_data->{'FORM_SIGN_DATE1'}) {
	$sql .= " and TNLV.FORM_SIGN_DATE >= TO_DATE('$cgi_data->{'FORM_SIGN_DATE1'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'FORM_SIGN_DATE2'}) {
	$sql .= " and TNLV.FORM_SIGN_DATE <= TO_DATE('$cgi_data->{'FORM_SIGN_DATE2'}', 'MM-DD-YYYY')";
    }
    
    return $sql;
}




sub display_results
{
    my $sth = shift;

    print <<EOF;
<table border=0 width="100%">
<tr><td><b><u>Athlete</u></b>
    <td><b><u>Sport</u></b>
    <td><b><u>Date Submitted</u></b>
    <td><b><u>Form Type</u></b>
EOF
    ;


    my $num_rows = 0;
    my $db_data;
    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;
	
	$form_name = $db_data->{'form_name'};
	$form_type = $db_data->{'form_type'};
	$orig_form_id = $db_data->{'orig_form_id'};
	$orig_athlete_id = $db_data->{'orig_athlete_id'};
	$orig_injury_report_id = $db_data->{'orig_injury_report_id'};

	print <<EOF;
<tr>
<td>
<a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$orig_athlete_id" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a>

<td>$db_data->{'sport'}

<td>$db_data->{'form_sign_date_char'}

<td nowrap>
EOF
    ;

	if ($orig_injury_report_id) {
	    print qq|<a href="/bin/process_form?OPERATION=VIEW_FORM&VIEW_LATEST=1&FORM_NAME=$form_name&ORIG_VERSION_ID=$orig_form_id&ORIG_ATHLETE_ID=$orig_athlete_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id" target="top">$form_type</a>\n|;

	} else {
	    print qq|<a href="/bin/process_form?OPERATION=VIEW_FORM&VIEW_LATEST=1&FORM_NAME=$form_name&ORIG_VERSION_ID=$orig_form_id&ORIG_ATHLETE_ID=$orig_athlete_id" target="top">$form_type</a>\n|;
	}
    }
    
    
    $sth->finish;


    print <<EOF;
</table>

<hr>

<b>$num_rows Report(s) Found</b>
EOF
    ;
}
