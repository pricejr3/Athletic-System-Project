#!/usr/bin/perl

#
# injury_details
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: March 25, 1999
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

$cgi_data              = parse_cgi_data();
$operation             = $cgi_data->{'OPERATION'};
$orig_athlete_id       = $cgi_data->{'ORIG_ATHLETE_ID'};
$orig_injury_report_id = $cgi_data->{'ORIG_INJURY_REPORT_ID'};

if    ($operation eq "SELECTED_INJURY")     { display_selected_injury(); }
elsif ($operation eq "INJURY_DETAILS_LIST") { display_injury_details_list(); }
else                                        { print_injury_frames(); }  # set up initial frames

exit;




sub print_injury_frames
{
    print_http_header();

    # HTTP-ize the CGI data for passing to selected injury display:
    $cgi_data->{'DATE_REPORTED_CHAR'} =~ s/ /+/g;
    $cgi_data->{'POSITION'} =~ s/ /+/g;
    $cgi_data->{'BODY_PART'} =~ s/ /+/g;
    $cgi_data->{'INJURY_TYPE'} =~ s/ /+/g;
    $cgi_data->{'INJURY_STATUS'} =~ s/ /+/g;

    print <<EOF;
<html>
<head>
  <base href="$BASE_HREF">
</head>

<frameset framespacing="0" rows="40,*" frameborder="0">
  <frame name="records_tabs" scrolling="no" target="main" src="/bin/athlete_homepage.pl?OPERATION=RECORDS_TABS&TAB=INJURY&ORIG_ATHLETE_ID=$orig_athlete_id" marginwidth="0" marginheight="0">

  <frameset framespacing="0" rows="91,*" frameborder="0">
  <frame name="selected_injury" scrolling="no" src="/bin/injury_details.pl?OPERATION=SELECTED_INJURY&ORIG_ATHLETE_ID=$orig_athlete_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id&DATE_REPORTED_CHAR=$cgi_data->{'DATE_REPORTED_CHAR'}&POSITION=$cgi_data->{'POSITION'}&BODY_PART=$cgi_data->{'BODY_PART'}&INJURY_TYPE=$cgi_data->{'INJURY_TYPE'}&INJURY_STATUS=$cgi_data->{'INJURY_STATUS'}" marginwidth="0" marginheight="0">

  <frameset framespacing="0" rows="30%,70%" frameborder="1">
  <frame name="injury_details_list" src="/bin/injury_details.pl?OPERATION=INJURY_DETAILS_LIST&ORIG_ATHLETE_ID=$orig_athlete_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id" scrolling="auto">

  <frame name="injury_details_body" src="/bin/process_form?OPERATION=VIEW_FORM&VIEW_LATEST=1&FORM_NAME=INJURY_REPORT&ORIG_VERSION_ID=$orig_injury_report_id&ORIG_ATHLETE_ID=$orig_athlete_id" scrolling="auto">
  </frameset>
  </frameset>

  <noframes>
  <body>
  <p>This page uses frames, but your browser does not support them.</p>
  </body>
  </noframes>
</frameset>
</html>

EOF
    ;
}





sub display_selected_injury
{
    print_http_header();

    #
    # Need to do a query here to get the desired info (or pass using CGI?)
    #

    print <<EOF;
<html>
<head>
  <base href="$BASE_HREF">
  <link rel="stylesheet" type="text/css" href="/www/common.css"/>
</head>

<body bgcolor="#73b5ef">

<b>SELECTED INJURY</b><br>

<table border=0 width="100%">
<tr><td nowrap><b><u>Date Reported</u></b></td>
    <td nowrap><b><u>Position</u></b></td>
    <td nowrap><b><u>Body Part</u></b></td>
    <td nowrap><b><u>Injury Type</u></b></td>
    <td nowrap><b><u>Injury Status</u></b></td>
</tr>

<tr>
<td nowrap><a href="/bin/process_form?OPERATION=VIEW_FORM&VIEW_LATEST=1&FORM_NAME=INJURY_REPORT&ORIG_VERSION_ID=$orig_injury_report_id&ORIG_ATHLETE_ID=$orig_athlete_id" target="injury_details_body">$cgi_data->{'DATE_REPORTED_CHAR'}</a></td>

<td nowrap>$cgi_data->{'POSITION'}</td>

<td nowrap>$cgi_data->{'BODY_PART'}</td>

<td nowrap>$cgi_data->{'INJURY_TYPE'}</td>

<td nowrap>$cgi_data->{'INJURY_STATUS'}</td>

</tr>
</table>

EOF
    ;

    print_html_trailer();

    exit;
}




sub display_injury_details_list
{
    print_http_header();

    my $sql = build_sql_statement();                # First build the SQL statement
    
    my $dbh = database_connect();                   # Establish connection to the database
    
    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query
    
    display_results ($sth);                         # Display the results
    
    database_disconnect ($dbh);                     # Disconnect from the database

    print_html_trailer();

    exit;
}




sub build_sql_statement
{
    my $sql = "
SELECT 'INJURY_ADDTNL_INFO' as FORM_NAME, 'Additional Information' as FORM_TITLE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from INJURY_ADDTNL_INFO_LV
WHERE
  INJURY_REPORT_ID = '$orig_injury_report_id'

UNION ALL

SELECT 'PHYSICIAN_REMARK' as FORM_NAME, 'Physician Remark' as FORM_TITLE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from PHYSICIAN_REMARK_LV
WHERE
  INJURY_REPORT_ID = '$orig_injury_report_id'

UNION ALL

SELECT 'TREATMENT_REMARK' as FORM_NAME, 'Treatment Remark' as FORM_TITLE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from TREATMENT_REMARK_LV
WHERE
  INJURY_REPORT_ID = '$orig_injury_report_id'

UNION ALL

SELECT 'TREATMENT_ADDTNL_INFO' as FORM_NAME, 'Treatment Addtnl Info' as FORM_TITLE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from TREATMENT_ADDTNL_INFO_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id' AND ASSOCIATED_INJURIES like '%[IR:$orig_injury_report_id]%'

UNION ALL

SELECT 'TREATMENT_RECORD' as FORM_NAME, 'Treatment Record' as FORM_TITLE,
       ORIG_VERSION_ID, TREATMENT_DATE as FORM_DATE,
       TO_CHAR (TREATMENT_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from TREATMENT_RECORD_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id' AND ASSOCIATED_INJURIES like '%[IR:$orig_injury_report_id]%'

UNION ALL

SELECT 'RECOMMENDED_TREATMENT' as FORM_NAME, 'Recommended Treatment' as FORM_TITLE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from RECOMMENDED_TREATMENT_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id' AND ASSOCIATED_INJURIES like '%[IR:$orig_injury_report_id]%'

UNION ALL

SELECT 'COACHES_REPORT' as FORM_NAME, 'Coaches Report' as FORM_TITLE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from COACHES_REPORT_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id' AND ASSOCIATED_INJURIES like '%[IR:$orig_injury_report_id]%'

order by FORM_DATE desc
";

    $sql = format_sql_statement ($sql);

    return $sql;
}




sub display_results
{
    my $sth = shift;

    print <<EOF;
<html>
<head>
  <base href="$BASE_HREF">
  <link rel="stylesheet" type="text/css" href="/www/common.css"/>
</head>

<body bgcolor="#73b5ef">


<form method="POST" action="/bin/process_form" target="injury_details_body">

<input type="hidden" name="OPERATION" value="PREPARE_BLANK_FORM">
<input type="hidden" name="ORIG_ATHLETE_ID" value="$orig_athlete_id">
<input type="hidden" name="ORIG_INJURY_REPORT_ID" value="$orig_injury_report_id">

<p>Choose form:
  <select name="FORM_NAME" size="1">
    <option value="INJURY_ADDTNL_INFO">Additional Info</option>
    <option value="PHYSICIAN_REMARK">Physician Remark</option>
    <option value="TREATMENT_REMARK" selected>Treatment Remark</option>
  </select>

<input type="submit" value=" Fill Out New Form ">

</form>
<hr>

<table border=0 width="100%">
<tr><td nowrap><b><u>Date</u></b>
    <td nowrap><b><u>Form Type</u></b>
EOF
    ;

    my $num_rows = 0;
    my $db_data;

    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;

	$form_name = $db_data->{'form_name'};
	$form_title = $db_data->{'form_title'};
	$orig_version_id = $db_data->{'orig_version_id'};
    	
	print <<EOF;
<tr>
<td>$db_data->{'form_date_char'}

<td>
<a href="/bin/process_form?OPERATION=VIEW_FORM&VIEW_LATEST=1&FORM_NAME=$form_name&ORIG_VERSION_ID=$orig_version_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id&ORIG_ATHLETE_ID=$orig_athlete_id" target="injury_details_body">$form_title</a>

EOF
    ;
    }

    $sth->finish;


    print <<EOF;
</table>

<hr>

<b>$num_rows Injury Record(s) Found</b>


<form method="POST" action="/bin/process_form" target="injury_details_body">

<input type="hidden" name="OPERATION" value="PREPARE_BLANK_FORM">
<input type="hidden" name="ORIG_ATHLETE_ID" value="$orig_athlete_id">
<input type="hidden" name="ORIG_INJURY_REPORT_ID" value="$orig_injury_report_id">

<p>Choose form:
  <select name="FORM_NAME" size="1">
    <option value="INJURY_ADDTNL_INFO">Additional Info</option>
    <option value="PHYSICIAN_REMARK">Physician Remark</option>
    <option value="TREATMENT_REMARK" selected>Treatment Remark</option>
  </select>

<input type="submit" value=" Fill Out New Form ">

</form>

EOF
    ;
}

