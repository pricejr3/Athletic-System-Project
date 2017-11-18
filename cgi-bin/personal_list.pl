#!/usr/bin/perl

#
# personal_list
#
# Copyright 2011, Michael J. Duff
# Author: Michael J. Duff
# Last modified: May 21, 2011
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

$cgi_data        = parse_cgi_data();
$orig_athlete_id = $cgi_data->{'ORIG_ATHLETE_ID'};


print_http_header();

my $sql = build_sql_statement();                # First build the SQL statement

my $dbh = database_connect();                   # Establish connection to the database

my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

display_results ($sth);                         # Display the results

database_disconnect ($dbh);                     # Disconnect from the database

print_html_trailer();

exit;




sub build_sql_statement
{
    my $sql = "
SELECT 'PERSONAL_ADDTNL_INFO' as FORM_NAME, 'Personal Addtnl Info' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from PERSONAL_ADDTNL_INFO_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'FAMILY_HISTORY' as FORM_NAME, 'Family History' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from FAMILY_HISTORY_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'HEALTH_APPRAISAL' as FORM_NAME, 'Health Appraisal' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from HEALTH_APPRAISAL_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'HEALTH_HISTORY' as FORM_NAME, 'Health History' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from HEALTH_HISTORY_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'HEALTH_HISTORY2' as FORM_NAME, 'Health History v2' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from HEALTH_HISTORY2_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'INSURANCE' as FORM_NAME, 'Insurance' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from INSURANCE_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'INSURANCE2' as FORM_NAME, 'Insurance v2' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from INSURANCE2_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'MENTAL_HEALTH' as FORM_NAME, 'Mental Health' as FORM_TYPE,
        ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from MENTAL_HEALTH_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'PHYSICAL' as FORM_NAME, 'Physical' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from PHYSICAL_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'FUNCTIONAL_MOVEMENT_SCREEN' as FORM_NAME, 'Functional Movement Screen' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from FUNCTIONAL_MOVEMENT_SCREEN_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'WAIVER' as FORM_NAME, 'Waiver' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from WAIVER_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'ATHLETE_RELEASE' as FORM_NAME, 'Athlete Release' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from ATHLETE_RELEASE_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'FERPA_RELEASE' as FORM_NAME, 'FERPA Release' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from FERPA_RELEASE_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'HEALTH_INFO_RELEASE' as FORM_NAME, 'Health Information Release' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from HEALTH_INFO_RELEASE_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'MEDICAL_CONDITION_DECLARATION' as FORM_NAME, 'Declaration of Medical Condition' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from MEDICAL_CONDITION_DECLARATION_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'ADHD_MEDICAL_EXCEPTIONS' as FORM_NAME, 'ADHD Medical Exceptions' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from ADHD_MEDICAL_EXCEPTIONS_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'NUTRITION_MENSTRUATION_HISTORY' as FORM_NAME, 'Nutritional and Menstrual History' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR
  from NUTRITION_MENSTRUATION_HISTORY_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'

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

<body bgcolor="#95d45a">


<form method="POST" action="/bin/process_form" target="personal_body">

<input type="hidden" name="OPERATION" value="PREPARE_BLANK_FORM">
<input type="hidden" name="ORIG_ATHLETE_ID" value="$orig_athlete_id">

<p>Choose form:
  <select name="FORM_NAME" size="1">
    <option value="PERSONAL_ADDTNL_INFO">Additional Info</option>
    <option value="ADHD_MEDICAL_EXCEPTIONS">ADHD Medical Exceptions</option>
    <option value="ATHLETE_RELEASE">Athlete Release</option>
    <option value="MEDICAL_CONDITION_DECLARATION">Declaration of Medical Condition</option>
    <option value="FAMILY_HISTORY">Family History (Freshmen/Transfers Only)</option>
    <option value="FERPA_RELEASE">FERPA Release</option>
    <option value="FUNCTIONAL_MOVEMENT_SCREEN">Functional Movement Screen</option>
    <option value="HEALTH_APPRAISAL">Health Appraisal</option>
    <option value="HEALTH_HISTORY2">Health History (Freshmen/Transfers Only)</option>
    <option value="HEALTH_INFO_RELEASE">Health Information Release</option>
    <option value="INSURANCE2">Insurance</option>
    <option value="MENTAL_HEALTH">Mental Health</option>
    <option value="NUTRITION_MENSTRUATION_HISTORY">Nutritional and Menstrual History (Women Only)</option>
    <option value="PHYSICAL">Physical</option>
    <option value="WAIVER">Waiver</option>
  </select>

<input type="submit" value=" Fill Out New Form ">

</form>
<hr>

<table border=0 width="100%">
<tr><td><b><u>Date</u></b>     <td><b><u>Form Type</u></b>
EOF
    ;


    my ($db_data, $orig_version_id);
    my $num_rows = 0;

    while ($db_data = $sth->fetchrow_hashref) {
	$orig_version_id = $db_data->{'orig_version_id'};
	$form_name       = $db_data->{'form_name'};
	$form_type       = $db_data->{'form_type'};

	$num_rows++;

	print <<EOF;
<tr>
<td>$db_data->{'form_date_char'}

<td>
<a href="/bin/process_form?OPERATION=VIEW_FORM&VIEW_LATEST=1&FORM_NAME=$form_name&ORIG_VERSION_ID=$orig_version_id&ORIG_ATHLETE_ID=$orig_athlete_id" target="personal_body">$form_type</a>


EOF
    ;
    }


    $sth->finish;


    print <<EOF;
</table>

<hr>

<b>$num_rows Personal Record(s) Found</b>


<form method="POST" action="/bin/process_form" target="personal_body">

<input type="hidden" name="OPERATION" value="PREPARE_BLANK_FORM">
<input type="hidden" name="ORIG_ATHLETE_ID" value="$orig_athlete_id">

<p>Choose form:
  <select name="FORM_NAME" size="1">
    <option value="PERSONAL_ADDTNL_INFO">Additional Info</option>
    <option value="ADHD_MEDICAL_EXCEPTIONS">ADHD Medical Exceptions</option>
    <option value="ATHLETE_RELEASE">Athlete Release</option>
    <option value="MEDICAL_CONDITION_DECLARATION">Declaration of Medical Condition</option>
    <option value="FAMILY_HISTORY">Family History (Freshmen/Transfers Only)</option>
    <option value="FERPA_RELEASE">FERPA Release</option>
    <option value="FUNCTIONAL_MOVEMENT_SCREEN">Functional Movement Screen</option>
    <option value="HEALTH_APPRAISAL">Health Appraisal</option>
    <option value="HEALTH_HISTORY2">Health History (Freshmen/Transfers Only)</option>
    <option value="HEALTH_INFO_RELEASE">Health Information Release</option>
    <option value="INSURANCE2">Insurance</option>
    <option value="MENTAL_HEALTH">Mental Health</option>
    <option value="NUTRITION_MENSTRUATION_HISTORY">Nutritional and Menstrual History (Women Only)</option>
    <option value="PHYSICAL">Physical</option>
    <option value="WAIVER">Waiver</option>
  </select>

<input type="submit" value=" Fill Out New Form ">

</form>


EOF
    ;
}
