#!/usr/bin/perl

#
# insurance_worksheet.pl
#
# Copyright 2016
# Author: Michael J. Duff
# Co-Author: Jarred R. Price
# Last modified: 3/28/2016
#
# Description:
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "form_utilities.pl";
require "database_utilities.pl";

use DBI;


($login_id, $clearance) = auth_user ($CLEARANCE_STAFF);

$cgi_data = parse_cgi_data();

prepare_cgi_data ($cgi_data);  # escape fields for insertion into database

$orig_injury_report_id = $cgi_data->{'ORIG_INJURY_REPORT_ID'};
$orig_athlete_id       = $cgi_data->{'ORIG_ATHLETE_ID'};
$worksheet_id          = $cgi_data->{'WORKSHEET_ID'};

if ($cgi_data->{'OPERATION'} eq 'FRAMES') { display_frames();  exit (0); }


print_html_header ("Insurance Worksheet", $BASE_HREF);


my $dbh = database_connect();  # Establish connection to the database

if ($cgi_data->{'UPDATE'}) {
    # Check to see if the worksheet has been created yet.  If not, then create it:
    if (! $worksheet_id) { $worksheet_id = create_new_worksheet ($dbh, $orig_athlete_id, $orig_injury_report_id); }
    update_worksheet ($dbh, $worksheet_id);
}


if ($worksheet_id) {
    #print "Worksheet ID specified: $worksheet_id<br/>\n";
    my $worksheet_data     = get_worksheet_by_id ($dbh, $worksheet_id);
    $orig_athlete_id       = $worksheet_data->{'athlete_id'};
    $orig_injury_report_id = $worksheet_data->{'injury_report_id'};
    #print "orig_athlete_id = $orig_athlete_id, orig_injury_report_id = $orig_injury_report_id <br/>\n";

} elsif ($orig_injury_report_id && $orig_athlete_id) {  # If only the injury report ID is specified, then look up the corresponding insurance worksheet ID:
    $worksheet_id = find_worksheet_by_injury_report ($dbh, $orig_athlete_id, $orig_injury_report_id);
    # It's okay if a worksheet doesn't exist for this injury report yet -- we will only create it if a worksheet is saved for this report
}


display_worksheet ($dbh, $worksheet_id, $orig_athlete_id, $orig_injury_report_id);

database_disconnect ($dbh);                     # Disconnect from the database

print_html_trailer();

exit;



sub display_frames {
    print_http_header();

    print <<EOF;
<html>
<head>
  <base href="$BASE_HREF">
</head>

<frameset framespacing="0" rows="40,*" frameborder="0">
  <frame name="records_tabs" scrolling="no" target="main" src="/bin/athlete_homepage.pl?OPERATION=RECORDS_TABS&TAB=INSURANCE&ORIG_ATHLETE_ID=$orig_athlete_id" marginwidth="0" marginheight="0">

  <frameset framespacing="0" rows="30%,70%" frameborder="1">
    <frame name="insurance_worksheet_list" src="/bin/insurance_worksheet_list.pl?ORIG_ATHLETE_ID=$orig_athlete_id" scrolling="auto">
    <frame name="insurance_worksheet" src="/bin/insurance_worksheet.pl?ORIG_ATHLETE_ID=$orig_athlete_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id" scrolling="auto">
  </frameset>
</frameset>

  <noframes>
  <body>
  <p>This page uses frames, but your browser does not support them.</p>
  </body>
  </noframes>
</html>
EOF
;
}



sub find_worksheet_by_injury_report {
    my ($dbh, $orig_athlete_id, $orig_injury_report_id) = @_;

    my $sql = "SELECT WORKSHEET_ID FROM INSURANCE_WORKSHEETS WHERE ATHLETE_ID = $orig_athlete_id AND INJURY_REPORT_ID = $orig_injury_report_id";
    #print "$sql<br/>\n";

    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

    my $db_data = $sth->fetchrow_hashref;  # only expecting a single row (at most)

    if ($db_data) { return $db_data->{'worksheet_id'}; }
    else          { return 0; }
}



sub get_next_sequence_value {
    my ($dbh, $sequence_name) = @_;
    my $sql = "select nextval('$sequence_name') as next_id";
    my $sth = execute_sql_statement ($dbh, $sql);
    my $db_data = $sth->fetchrow_hashref;  # only expecting a single row
    return $db_data->{'next_id'};
}



sub get_worksheet_by_id {
    my ($dbh, $worksheet_id) = @_;

    my $sql = "SELECT * FROM INSURANCE_WORKSHEETS WHERE WORKSHEET_ID = $worksheet_id";

    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

    my $db_data = $sth->fetchrow_hashref;  # only expecting a single row (at most)

    if ($db_data) { return $db_data; }
    else          { return 0; }
}



sub create_new_worksheet {
    my ($dbh, $athlete_id, $injury_report_id) = @_;

    my $worksheet_id = get_next_sequence_value ($dbh, 'new_insurance_worksheet_id');

    my $sql = "INSERT INTO INSURANCE_WORKSHEETS
(

WORKSHEET_ID, ATHLETE_ID, INJURY_REPORT_ID, TOTAL_BALANCE,
FORM_SIGN_USER_ID, FORM_SIGN_DATE, FORM_SIGNATURE

)
values
(

$worksheet_id, $athlete_id, $injury_report_id, 0.0,
'$login_id', now(), ''

)";

    my $sth = execute_sql_statement ($dbh, $sql);

    return $worksheet_id;
}



sub display_worksheet {
    my ($dbh, $worksheet_id, $orig_athlete_id, $orig_injury_report_id) = @_;

    display_injury_report_info ($dbh, $orig_athlete_id, $orig_injury_report_id, $worksheet_id);

    # Show the worksheet entries:
    display_worksheet_entries ($dbh, $worksheet_id);
}



sub display_injury_report_info {
    my ($dbh, $orig_athlete_id, $orig_injury_report_id, $worksheet_id) = @_;

    # Get athlete and injury information:
    my $sql1 = "
SELECT ALV.ORIG_VERSION_ID as ORIG_ATHLETE_ID, IRLV.ORIG_VERSION_ID as ORIG_INJURY_REPORT_ID,
       ALV.LAST_NAME, ALV.FIRST_NAME, ALV.MIDDLE_NAME,
       TO_CHAR(ALV.BIRTHDATE, 'MM-DD-YYYY') as BIRTHDATE_CHAR, ALV.SSN,
       IRLV.SPORT, IRLV.INJURY_ENVIRONMENT, IRLV.POSITION, IRLV.BODY_PART,
       IRLV.INJURY_TYPE, IRLV.INJURY_STATUS,
       TO_CHAR(IRLV.DATE_REPORTED, 'MM-DD-YYYY') as DATE_REPORTED_CHAR, IRLV.ATHLETICALLY_RELATED

FROM   ATHLETE_LV as ALV, INJURY_REPORT_LV as IRLV

WHERE  ALV.ORIG_VERSION_ID = IRLV.ATHLETE_ID AND IRLV.ATHLETE_ID = $orig_athlete_id AND IRLV.ORIG_VERSION_ID = $orig_injury_report_id
";

    my $sth1 = execute_sql_statement ($dbh, $sql1);   # Now execute the query

    my $db_data1 = $sth1->fetchrow_hashref;


    # Get athlete insurance information:
    my $sql2 = "
SELECT GUARDIAN1_PRIMARY_INS, GUARDIAN1_INS_NAME, GUARDIAN1_INS_ADDRESS, GUARDIAN1_INS_PHONE, GUARDIAN1_INS_POLICY_NUM, GUARDIAN1_INS_ID_NUM,
       GUARDIAN2_PRIMARY_INS, GUARDIAN2_INS_NAME, GUARDIAN2_INS_ADDRESS, GUARDIAN2_INS_PHONE, GUARDIAN2_INS_POLICY_NUM, GUARDIAN2_INS_ID_NUM

FROM   INSURANCE_LV

WHERE  insurance_id = (select MAX (insurance_id) from insurance_lv where athlete_id = $orig_athlete_id);
";

    my $sth2 = execute_sql_statement ($dbh, $sql2);

    my $db_data2 = $sth2->fetchrow_hashref;


    # Get the contact name from the insurance worksheet master record:
    my $sql3 = "
SELECT CONTACT_NAME, COMMENTS

FROM   INSURANCE_WORKSHEETS

WHERE  worksheet_id = $worksheet_id;
";

    my $sth3 = execute_sql_statement ($dbh, $sql3);

    my $db_data3 = $sth3->fetchrow_hashref;


    my $guardian_primary   = ($db_data2->{'guardian1_primary_ins'} eq 'Yes' ? 'guardian1' : 'guardian2');
    my $guardian_secondary = ($db_data2->{'guardian1_primary_ins'} eq 'Yes' ? 'guardian2' : 'guardian1');

    print '

<script language="JavaScript">

function recalculateBalances (row_num) {
   var service_cost              = getIntegerValue (document.getElementById ("ENTRY_" + row_num + "_SERVICE_COST").value);
   var paid_by_athlete_primary   = getIntegerValue (document.getElementById ("ENTRY_" + row_num + "_PAID_BY_ATHLETE_PRIMARY").value);
   var paid_by_athlete_secondary = getIntegerValue (document.getElementById ("ENTRY_" + row_num + "_PAID_BY_ATHLETE_SECONDARY").value);
   var insurance_writeoff        = getIntegerValue (document.getElementById ("ENTRY_" + row_num + "_INSURANCE_WRITEOFF").value);
   var sub_balance               = service_cost - (paid_by_athlete_primary + paid_by_athlete_secondary + insurance_writeoff);
   var paid_by_miami_primary     = getIntegerValue (document.getElementById ("ENTRY_" + row_num + "_PAID_BY_MIAMI_PRIMARY").value);
   var paid_by_miami_secondary   = getIntegerValue (document.getElementById ("ENTRY_" + row_num + "_PAID_BY_MIAMI_SECONDARY").value);
   var balance                   = sub_balance - (paid_by_miami_primary + paid_by_miami_secondary);

   document.getElementById ("ENTRY_" + row_num + "_SUB_BALANCE").innerHTML = getFloatValue (sub_balance);
   document.getElementById ("ENTRY_" + row_num + "_BALANCE").innerHTML     = getFloatValue (balance);

   var num_rows = 1;

   var total_service_cost              = 0;
   var total_paid_by_athlete_primary   = 0;
   var total_paid_by_athlete_secondary = 0;
   var total_insurance_writeoff        = 0;
   var total_sub_balance               = 0;
   var total_paid_by_miami_primary     = 0;
   var total_paid_by_miami_secondary   = 0;
   var total_balance                   = 0;

   while (document.getElementById ("ENTRY_" + num_rows + "_DATE_RECEIVED") != null) {
      service_cost              = getIntegerValue (document.getElementById ("ENTRY_" + num_rows + "_SERVICE_COST").value);
      paid_by_athlete_primary   = getIntegerValue (document.getElementById ("ENTRY_" + num_rows + "_PAID_BY_ATHLETE_PRIMARY").value);
      paid_by_athlete_secondary = getIntegerValue (document.getElementById ("ENTRY_" + num_rows + "_PAID_BY_ATHLETE_SECONDARY").value);
      insurance_writeoff        = getIntegerValue (document.getElementById ("ENTRY_" + num_rows + "_INSURANCE_WRITEOFF").value);
      sub_balance               = service_cost - (paid_by_athlete_primary + paid_by_athlete_secondary + insurance_writeoff);
      paid_by_miami_primary     = getIntegerValue (document.getElementById ("ENTRY_" + num_rows + "_PAID_BY_MIAMI_PRIMARY").value);
      paid_by_miami_secondary   = getIntegerValue (document.getElementById ("ENTRY_" + num_rows + "_PAID_BY_MIAMI_SECONDARY").value);
      balance                   = sub_balance - (paid_by_miami_primary + paid_by_miami_secondary);

      total_service_cost              += service_cost;
      total_paid_by_athlete_primary   += paid_by_athlete_primary;
      total_paid_by_athlete_secondary += paid_by_athlete_secondary;
      total_insurance_writeoff        += insurance_writeoff;
      total_sub_balance               += sub_balance;
      total_paid_by_miami_primary     += paid_by_miami_primary;
      total_paid_by_miami_secondary   += paid_by_miami_secondary;
      total_balance                   += balance;
      num_rows++;
   }

   document.getElementById ("TOTAL_SERVICE_COST").innerHTML              = "<b>" + getFloatValue (total_service_cost)              + "</b>";
   document.getElementById ("TOTAL_PAID_BY_ATHLETE_PRIMARY").innerHTML   = "<b>" + getFloatValue (total_paid_by_athlete_primary)   + "</b>";
   document.getElementById ("TOTAL_PAID_BY_ATHLETE_SECONDARY").innerHTML = "<b>" + getFloatValue (total_paid_by_athlete_secondary) + "</b>";
   document.getElementById ("TOTAL_INSURANCE_WRITEOFF").innerHTML        = "<b>" + getFloatValue (total_insurance_writeoff)        + "</b>";
   document.getElementById ("TOTAL_SUB_BALANCE").innerHTML               = "<b>" + getFloatValue (total_sub_balance)               + "</b>";
   document.getElementById ("TOTAL_PAID_BY_MIAMI_PRIMARY").innerHTML     = "<b>" + getFloatValue (total_paid_by_miami_primary)     + "</b>";
   document.getElementById ("TOTAL_PAID_BY_MIAMI_SECONDARY").innerHTML   = "<b>" + getFloatValue (total_paid_by_miami_secondary)   + "</b>";
   document.getElementById ("TOTAL_BALANCE").innerHTML                   = "<b>" + getFloatValue (total_balance)                   + "</b>";
}



function getIntegerValue (value) {
  value = trim (value);
  if (value == "")  return 0;

  var intValue;

  try {
      var floatValue = parseFloat (value);
      intValue       = parseInt (Math.round (floatValue * 100));
  } catch (e) { alarm ("Improperly formatted currency amount"); }

  return intValue;
}



function trim (str) {
  return str.replace (/^\s+|\s+$/g, "");
}



function getFloatValue (intValue) {
  if (intValue == 0)  return "0.00";

  var x = parseInt (intValue / 100);
  var y = parseInt (Math.round (Math.abs (intValue - (x * 100))));

  return x + "." + (y < 10 ? "0" : "") + y;
}


</script>


<form action="/bin/insurance_worksheet.pl" method="POST">
<input type="hidden" name="WORKSHEET_ID" value="' . $worksheet_id . '" />
<input type="hidden" name="ORIG_ATHLETE_ID" value="' . $orig_athlete_id . '" />
<input type="hidden" name="ORIG_INJURY_REPORT_ID" value="' . $orig_injury_report_id . '" />

<table border="0" width="100%" cellspacing="0">
<tbody>
<tr>
  <td><b>Name:</b> ' . $db_data1->{'last_name'} . ', ' . $db_data1->{'first_name'} . ' ' . $db_data1->{'middle_name'} . '</td>
  <td><b>Birthday:</b> ' . $db_data1->{'birthdate_char'} . '</td>
  <td><b>SSN:</b> ' . $db_data1->{'ssn'} . '</td>
  <td><b>Date Injured:</b> ' . $db_data1->{'date_reported_char'} . '</td>
</tr>
<tr>
  <td><b>Primary Insurance:</b> ' . $db_data2->{$guardian_primary   . '_ins_name'} .
  '<br/>&nbsp;&nbsp;&nbsp;<b>Address:</b> '  . $db_data2->{$guardian_primary . '_ins_address'} .
  '<br/>&nbsp;&nbsp;&nbsp;<b>Phone:</b> '    . $db_data2->{$guardian_primary . '_ins_phone'}   .
  '<br/>&nbsp;&nbsp;&nbsp;<b>Policy #:</b> ' . $db_data2->{$guardian_primary . '_ins_policy_num'} .
  '<br/>&nbsp;&nbsp;&nbsp;<b>ID #:</b> '     . $db_data2->{$guardian_primary . '_ins_id_num'} .
 '</td>
  <td><b>Secondary Insurance:</b> ' . $db_data2->{$guardian_secondary . '_ins_name'} .
  '<br/>&nbsp;&nbsp;&nbsp;<b>Address:</b> '  . $db_data2->{$guardian_secondary . '_ins_address'} .
  '<br/>&nbsp;&nbsp;&nbsp;<b>Phone:</b> '    . $db_data2->{$guardian_secondary . '_ins_phone'}   .
  '<br/>&nbsp;&nbsp;&nbsp;<b>Policy #:</b> ' . $db_data2->{$guardian_secondary . '_ins_policy_num'} .
  '<br/>&nbsp;&nbsp;&nbsp;<b>ID #:</b> '     . $db_data2->{$guardian_secondary . '_ins_id_num'} .
  '</td>
  <td colspan="2" rowspan="2" valign="top"><b>Contact Name:</b> <input type="text" name="CONTACT_NAME" size="30" value="' . $db_data3->{'contact_name'} . '" /><br/><b>Comments:</b><br/><textarea name="COMMENTS" rows="3" cols="40">' . $db_data3->{'comments'} . '</textarea></td>
</tr>
<tr>
  <td valign="top"><b>Sport:</b> ' . $db_data1->{'sport'} . '</td>
  <td><b>Injury:</b> ' . $db_data1->{'position'} . ', ' . $db_data1->{'body_part'} . ', ' . $db_data1->{'injury_type'} . ', ' .  $db_data1->{'injury_status'} . '<br/><b>Athletically Related:</b> ' . $db_data1->{'athletically_related'} . '</td>
</tr>
</tbody>
</table>

<br/><br/>
';

}



sub display_worksheet_entries {
    my ($dbh, $worksheet_id) = @_;

    my $sql = "SELECT ENTRY_ID, WORKSHEET_ID, TO_CHAR(DATE_RECEIVED, 'MM-DD-YYYY') AS DATE_RECEIVED_CHAR, MEDICAL_PROVIDER, TO_CHAR(SERVICE_DATE, 'MM-DD-YYYY') AS SERVICE_DATE_CHAR, REFERENCE_NUMBER, SERVICE_COST, PAID_BY_ATHLETE_PRIMARY, PAID_BY_ATHLETE_SECONDARY, INSURANCE_WRITEOFF, SUB_BALANCE, PAID_BY_MIAMI_PRIMARY, PAID_BY_MIAMI_SECONDARY, BALANCE, NOTES FROM INSURANCE_WORKSHEET_ENTRIES WHERE WORKSHEET_ID = $worksheet_id ORDER BY DATE_RECEIVED";

    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

    print '

<table border="1" cellpadding="5" cellspacing="0">
<tbody>
<tr>
  <th valign="top">Row #</th>
  <th valign="top">Date Received <font color="#a00000"><b>*</b></font><br/>(mm-dd-yyyy)</th>
  <th valign="top">Medical Provider <font color="#a00000"><b>*</b></font></th>
  <th valign="top">Date of Service <font color="#a00000"><b>*</b></font><br/>(mm-dd-yyyy)</th>
  <th valign="top">Reference #</th>
  <th valign="top">Charged Amount<br/>($)</th>
  <th valign="top">Paid by Primary<br/>($)</th>
  <th valign="top">Paid by Secondary<br/>($)</th>
  <th valign="top">Insurance Writeoff<br/>($)</th>
  <th valign="top">Sub- Balance<br/>($)</th>
  <th valign="top">Paid by Preferred (Maksim)<br/>($)</th>
  <th valign="top">Paid by Miami Athlete Insurance<br/>($)</th>
  <th valign="top">Balance<br/>($)</th>
  <th valign="top">Notes</th>
</tr>
';

    my @medical_providers = (
			     '',
                             'Other',
                             'Anesthesia Associates of Cincinnati',
							 'AMSOL Anesthesia',
							 'AMSOL Physicians',
							 'Beacon',
							 'Bethesda',
							 'Brace Shop',
                             'DJO',
                             'Family Vision Care',
							 'Fort Hamilton Hospital',
							 'Good Samaritan Hospital',
							 'Kenwood',
							 'Lone Star',
                             'McCullough Hyde Memorial Hospital',
							 'Mental Health',
                             'Mercy Hospital',
							 'Mercy Health Partners',
							 'Mercy Health Physicians',
                             'Miami University Treasurer',
							 'Midwest Orthopedic Institute',
                             'Midwest Pain Management',
							 'MU Student Counseling',
							 'Nationwide Children\'s',
							 'Obstetric Anesthesia',
							 'OH State Univ. Hospital',
                             'Oxford Radiology',
							 'Physician Anesthesia',
                             'ProScan',
							 'Seven Hill Anesthesia',
							 'Susan Fortney-Harlan',
                             'Talawanda Emergency Physicians',
							 'Todd Elwert',
							 'TriState Center for Sight',
							 'UC Health',
							 'UC Physicians',
                             'Wellington Orthopedics',
							 'West Chester Hospital'
                            );

    my $row_num = 0;

    my $total_service_cost              = 0;
    my $total_paid_by_athlete_primary   = 0;
    my $total_paid_by_athlete_secondary = 0;
    my $total_insurance_writeoff        = 0;
    my $total_sub_balance               = 0;
    my $total_paid_by_miami_primary     = 0;
    my $total_paid_by_miami_secondary   = 0;
    my $total_balance                   = 0;

    while (my $db_data = $sth->fetchrow_hashref) {
	$row_num++;

        my $id = 'ENTRY_' . $row_num;

	print '
<tr>
  <td align="center">' . $row_num . '</td>
  <td align="center"><input type="text" name="' . $id . '_DATE_RECEIVED" id="' . $id . '_DATE_RECEIVED" value="' . $db_data->{'date_received_char'} . '" size="10" /></td>
  <td align="center"><select name="'. $id . '_MEDICAL_PROVIDER" id="' . $id . '_MEDICAL_PROVIDER">
';

        foreach my $medical_provider (@medical_providers) {
            print '<option' . ($medical_provider eq $db_data->{'medical_provider'} ? ' selected="selected"' : '') . '>' . $medical_provider . "</option>\n";
        }

        print '
</select></td>
<td align="center"><input type="text" name="' . $id . '_SERVICE_DATE" id="' . $id . '_SERVICE_DATE" value="' . $db_data->{'service_date_char'} . '" size="10" /></td>
  <td align="center"><input type="text" name="' . $id . '_REFERENCE_NUMBER" id="' . $id . '_REFERENCE_NUMBER" value="' . $db_data->{'reference_number'} . '" size="10" /></td>
  <td align="center"><input type="text" name="' . $id . '_SERVICE_COST" id="' . $id . '_SERVICE_COST" value="' . currency_format ($db_data->{'service_cost'}) . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="center"><input type="text" name="' . $id . '_PAID_BY_ATHLETE_PRIMARY" id="' . $id . '_PAID_BY_ATHLETE_PRIMARY" value="' . currency_format ($db_data->{'paid_by_athlete_primary'}) . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="center"><input type="text" name="' . $id . '_PAID_BY_ATHLETE_SECONDARY" id="' . $id . '_PAID_BY_ATHLETE_SECONDARY" value="' . currency_format ($db_data->{'paid_by_athlete_secondary'}) . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="center"><input type="text" name="' . $id . '_INSURANCE_WRITEOFF" id="' . $id . '_INSURANCE_WRITEOFF" value="' . currency_format ($db_data->{'insurance_writeoff'}) . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="right" id="' . $id . '_SUB_BALANCE" nowrap="nowrap">&nbsp;' . currency_format ($db_data->{'sub_balance'}, 1) . '</td>
  <td align="center"><input type="text" name="' . $id . '_PAID_BY_MIAMI_PRIMARY" id="' . $id . '_PAID_BY_MIAMI_PRIMARY" value="' . currency_format ($db_data->{'paid_by_miami_primary'}) . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="center"><input type="text" name="' . $id . '_PAID_BY_MIAMI_SECONDARY" id="' . $id . '_PAID_BY_MIAMI_SECONDARY" value="' . currency_format ($db_data->{'paid_by_miami_secondary'}) . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="right" id="' . $id . '_BALANCE" nowrap="nowrap">&nbsp;' . currency_format ($db_data->{'balance'}, 1) . '</td>
  <td align="center"><input type="text" name="' . $id . '_NOTES" id="' . $id . '_NOTES" value="' . $db_data->{'notes'} . '" size="30" /></td>
</tr>
';

	$total_service_cost              += $db_data->{'service_cost'};
	$total_paid_by_athlete_primary   += $db_data->{'paid_by_athlete_primary'};
	$total_paid_by_athlete_secondary += $db_data->{'paid_by_athlete_secondary'};
	$total_insurance_writeoff        += $db_data->{'insurance_writeoff'};
	$total_sub_balance               += $db_data->{'sub_balance'};
	$total_paid_by_miami_primary     += $db_data->{'paid_by_miami_primary'};
	$total_paid_by_miami_secondary   += $db_data->{'paid_by_miami_secondary'};
	$total_balance                   += $db_data->{'balance'};
    }


    # Now add another five blank rows:
    for (my $i = 0; $i < 5; $i++) {
	$row_num++;

        my $id = 'ENTRY_' . $row_num;

	print '
<tr>
  <td align="center">' . $row_num . '</td>
  <td align="center"><input type="text" name="' . $id . '_DATE_RECEIVED" id="' . $id . '_DATE_RECEIVED" value="' . $db_data->{'date_received_char'} . '" size="10" /></td>
  <td align="center"><select name="'. $id . '_MEDICAL_PROVIDER" id="' . $id . '_MEDICAL_PROVIDER">
';

        foreach my $medical_provider (@medical_providers) {
            print '<option' . ($medical_provider eq $db_data->{'medical_provider'} ? ' selected="selected"' : '') . '>' . $medical_provider . "</option>\n";
        }

        print '
<td align="center"><input type="text" name="' . $id . '_SERVICE_DATE" id="' . $id . '_SERVICE_DATE" value="' . $db_data->{'service_date_char'} . '" size="10" /></td>
  <td align="center"><input type="text" name="' . $id . '_REFERENCE_NUMBER" id="' . $id . '_REFERENCE_NUMBER" value="' . $db_data->{'reference_number'} . '" size="10" /></td>
  <td align="center"><input type="text" name="' . $id . '_SERVICE_COST" id="' . $id . '_SERVICE_COST" value="' . $db_data->{'service_cost'} . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="center"><input type="text" name="' . $id . '_PAID_BY_ATHLETE_PRIMARY" id="' . $id . '_PAID_BY_ATHLETE_PRIMARY" value="' . $db_data->{'paid_by_athlete_primary'} . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="center"><input type="text" name="' . $id . '_PAID_BY_ATHLETE_SECONDARY" id="' . $id . '_PAID_BY_ATHLETE_SECONDARY" value="' . $db_data->{'paid_by_athlete_secondary'} . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="center"><input type="text" name="' . $id . '_INSURANCE_WRITEOFF" id="' . $id . '_INSURANCE_WRITEOFF" value="' . $db_data->{'insurance_writeoff'} . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="right" id="' . $id . '_SUB_BALANCE" nowrap="nowrap">&nbsp;' . $db_data->{'sub_balance'} . '</td>
  <td align="center"><input type="text" name="' . $id . '_PAID_BY_MIAMI_PRIMARY" id="' . $id . '_PAID_BY_MIAMI_PRIMARY" value="' . $db_data->{'paid_by_miami_primary'} . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="center"><input type="text" name="' . $id . '_PAID_BY_MIAMI_SECONDARY" id="' . $id . '_PAID_BY_MIAMI_SECONDARY" value="' . $db_data->{'paid_by_miami_secondary'} . '" size="6" style="text-align: right;" onBlur="recalculateBalances (\'' . $row_num . '\')"/></td>
  <td align="right" id="' . $id . '_BALANCE" nowrap="nowrap">&nbsp;' . $db_data->{'balance'} . '</td>
  <td align="center"><input type="text" name="' . $id . '_NOTES" id="' . $id . '_NOTES" value="' . $db_data->{'NOTES'} . '" size="30" /></td>
</tr>
';
    }


    # Now show totals:
    print '
<tr>
  <td align="right" colspan="5"><b>Totals:</b></td>
  <td align="right" nowrap="nowrap" id="TOTAL_SERVICE_COST"><b>'              . currency_format ($total_service_cost, 1)              . '</b></td>
  <td align="right" nowrap="nowrap" id="TOTAL_PAID_BY_ATHLETE_PRIMARY"><b>'   . currency_format ($total_paid_by_athlete_primary, 1)   . '</b></td>
  <td align="right" nowrap="nowrap" id="TOTAL_PAID_BY_ATHLETE_SECONDARY"><b>' . currency_format ($total_paid_by_athlete_secondary, 1) . '</b></td>
  <td align="right" nowrap="nowrap" id="TOTAL_INSURANCE_WRITEOFF"><b>'        . currency_format ($total_insurance_writeoff, 1)        . '</b></td>
  <td align="right" nowrap="nowrap" id="TOTAL_SUB_BALANCE"><b>'               . currency_format ($total_sub_balance, 1)               . '</b></td>
  <td align="right" nowrap="nowrap" id="TOTAL_PAID_BY_MIAMI_PRIMARY"><b>'     . currency_format ($total_paid_by_miami_primary, 1)     . '</b></td>
  <td align="right" nowrap="nowrap" id="TOTAL_PAID_BY_MIAMI_SECONDARY"><b>'   . currency_format ($total_paid_by_miami_secondary, 1)   . '</b></td>
  <td align="right" nowrap="nowrap" id="TOTAL_BALANCE"><b>'                   . currency_format ($total_balance, 1)                   . '</b></td>
  <td>&nbsp;</td>
</tr>
';

    print '
</tbody></table>

<p align="center"><input type="submit" name="UPDATE" value=" Update Worksheet " /></p>
</form>
';
}



sub currency_format {
    my ($amount, $show_zero) = @_;
    $amount = sprintf ("%.2f", $amount);
    if ($amount == 0 && ! $show_zero) { return ''; }
    else                              { return $amount; }
}



sub trim {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}



sub update_worksheet {
    my ($dbh, $worksheet_id) = @_;

    #print "updating worksheet...<br/>\n";

    # Begin a database transaction:
    $dbh->{AutoCommit} = 0;  # disable autocommit so we can do this in a transaction

    # Delete the existing entries:
    my $sql2 = "DELETE FROM INSURANCE_WORKSHEET_ENTRIES WHERE WORKSHEET_ID = $worksheet_id";
    my $sth2 = execute_sql_statement ($dbh, $sql2);

    # Insert the updated entries:
    my $row_num = 1;

    my $total_service_cost              = 0;
    my $total_paid_by_athlete_primary   = 0;
    my $total_paid_by_athlete_secondary = 0;
    my $total_insurance_writeoff        = 0;
    my $total_sub_balance               = 0;
    my $total_paid_by_miami_primary     = 0;
    my $total_paid_by_miami_secondary   = 0;
    my $total_balance                   = 0;

    my $update_problems = 0;

    while (trim ($cgi_data->{'ENTRY_' . $row_num . '_DATE_RECEIVED'})             ne '' ||
	   trim ($cgi_data->{'ENTRY_' . $row_num . '_MEDICAL_PROVIDER'})          ne '' ||
	   trim ($cgi_data->{'ENTRY_' . $row_num . '_SERVICE_DATE'})              ne '' ||
	   trim ($cgi_data->{'ENTRY_' . $row_num . '_REFERENCE_NUMBER'})          ne '' ||
	   trim ($cgi_data->{'ENTRY_' . $row_num . '_PAID_BY_ATHLETE_PRIMARY'})   ne '' ||
	   trim ($cgi_data->{'ENTRY_' . $row_num . '_PAID_BY_ATHLETE_SECONDARY'}) ne '' ||
	   trim ($cgi_data->{'ENTRY_' . $row_num . '_INSURANCE_WRITEOFF'})        ne '' ||
	   trim ($cgi_data->{'ENTRY_' . $row_num . '_PAID_BY_MIAMI_PRIMARY'})     ne '' ||
	   trim ($cgi_data->{'ENTRY_' . $row_num . '_PAID_BY_MIAMI_SECONDARY'})   ne '' ||
	   trim ($cgi_data->{'ENTRY_' . $row_num . '_NOTES'})                     ne '') {
	my $date_received             = $cgi_data->{'ENTRY_' . $row_num . '_DATE_RECEIVED'};
	my $service_cost              = $cgi_data->{'ENTRY_' . $row_num . '_SERVICE_COST'};
	my $medical_provider          = $cgi_data->{'ENTRY_' . $row_num . '_MEDICAL_PROVIDER'};
	my $service_date              = $cgi_data->{'ENTRY_' . $row_num . '_SERVICE_DATE'};
	my $reference_number          = $cgi_data->{'ENTRY_' . $row_num . '_REFERENCE_NUMBER'};
	my $paid_by_athlete_primary   = $cgi_data->{'ENTRY_' . $row_num . '_PAID_BY_ATHLETE_PRIMARY'};
	my $paid_by_athlete_secondary = $cgi_data->{'ENTRY_' . $row_num . '_PAID_BY_ATHLETE_SECONDARY'};
	my $insurance_writeoff        = $cgi_data->{'ENTRY_' . $row_num . '_INSURANCE_WRITEOFF'};
	my $sub_balance               = sprintf ("%.2f", $service_cost - ($paid_by_athlete_primary + $paid_by_athlete_secondary + $insurance_writeoff));
	my $paid_by_miami_primary     = $cgi_data->{'ENTRY_' . $row_num . '_PAID_BY_MIAMI_PRIMARY'};
	my $paid_by_miami_secondary   = $cgi_data->{'ENTRY_' . $row_num . '_PAID_BY_MIAMI_SECONDARY'};
	my $balance                   = sprintf ("%.2f", ($sub_balance - ($paid_by_miami_primary + $paid_by_miami_secondary)));
	my $notes                     = $cgi_data->{'ENTRY_' . $row_num . '_NOTES'};

	# Check the constraints:
	my $constraint_problem = 0;
	my @error_messages     = ();
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Date Received",             $date_received,             'not null');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Date Received",             $date_received,             'date');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Medical Provider",          $medical_provider,          'not null');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Medical Provider",          $medical_provider,          'maxsize=500');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Date of Service",           $service_date,              'not null');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Date of Service",           $service_date,              'date');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Amount Charged",            $service_cost,              'currency');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Reference Number",          $reference_number,          'maxsize=500');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Paid by Primary",           $paid_by_athlete_primary,   'currency');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Paid by Secondary",         $paid_by_athlete_secondary, 'currency');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Insurance Writeoff",        $insurance_writeoff,        'currency');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Sub-Balance",               $sub_balance,               'number');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Paid by Miami Preferred",   $paid_by_miami_primary,     'currency');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Paid by Miami Athlete Insurance", $paid_by_miami_secondary, 'currency');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Balance",                   $balance,                   'number');
	$constraint_problem |= check_constraint (\@error_messages, "Row $row_num Notes",                     $notes,                     'maxsize=500');

	$row_num++;

	if ($constraint_problem) {
	    $update_problems |= $constraint_problem;
	    display_messages (@error_messages);
	    next;
	}

	my $sql3 = "INSERT INTO INSURANCE_WORKSHEET_ENTRIES (ENTRY_ID, WORKSHEET_ID, DATE_RECEIVED, MEDICAL_PROVIDER, SERVICE_DATE, REFERENCE_NUMBER, SERVICE_COST, PAID_BY_ATHLETE_PRIMARY, PAID_BY_ATHLETE_SECONDARY, INSURANCE_WRITEOFF, SUB_BALANCE, PAID_BY_MIAMI_PRIMARY, PAID_BY_MIAMI_SECONDARY, BALANCE, NOTES) VALUES (nextval ('new_insurance_worksheet_entry_id'), $worksheet_id, TO_DATE('$date_received', 'MM-DD-YYYY'), '$medical_provider', TO_DATE('$service_date', 'MM-DD-YYYY'), '$reference_number', " . sprintf ("%.2f", $service_cost + 0) . ", " . sprintf ("%.2f", $paid_by_athlete_primary + 0) . ", " . sprintf ("%.2f", $paid_by_athlete_secondary + 0) . ", " . sprintf ("%.2f", $insurance_writeoff + 0) . ", $sub_balance, " . sprintf ("%.2f", $paid_by_miami_primary + 0) . ", " . sprintf ("%.2f", $paid_by_miami_secondary + 0) . ", $balance, '$notes')";
	#print "$sql3<br/>\n";
	my $sth3 = execute_sql_statement ($dbh, $sql3);

	$total_service_cost              += $service_cost;
	$total_paid_by_athlete_primary   += $paid_by_athlete_primary;
	$total_paid_by_athlete_secondary += $paid_by_athlete_secondary;
	$total_insurance_writeoff        += $insurance_writeoff;
	$total_sub_balance               += $sub_balance;
	$total_paid_by_miami_primary     += $paid_by_miami_primary;
	$total_paid_by_miami_secondary   += $paid_by_miami_secondary;
	$total_balance                   += $balance;
    }


    $constraint_problem |= check_constraint (\@error_messages, "Contact Name is limited to 100 characters", $cgi_data->{'CONTACT_NAME'}, 'maxsize=100');
    $constraint_problem |= check_constraint (\@error_messages, "Comments are limited to 2000 characters", $cgi_data->{'COMMENTS'}, 'maxsize=2000');

    if ($constraint_problem) {
	$update_problems |= $constraint_problem;
	display_messages (@error_messages);
    }

    # Update the balance on the worksheet master record:
    my $sql4 = "UPDATE INSURANCE_WORKSHEETS SET TOTAL_BALANCE = " . sprintf ("%.2f", $total_balance) . ", CONTACT_NAME = '" . $cgi_data->{'CONTACT_NAME'} . "', COMMENTS = '" . $cgi_data->{'COMMENTS'} . "' WHERE WORKSHEET_ID = $worksheet_id";
    my $sth4 = execute_sql_statement ($dbh, $sql4);


    # If all goes well, then commit the changes:
    if (! $update_problems) {
	$dbh->commit();
	display_messages ("The worksheet has been updated");

    } else {
	# Otherwise, rollback:
	$dbh->rollback();
	display_messages ("No changes were made -- please note errors and re-enter the changes");
    }

    print "<br/>\n";
    $dbh->{AutoCommit} = 1;  # re-enable autocommit
}



sub display_messages {
    my (@error_messages) = @_;

    if ($#error_messages >= 0) {
	print '<table align="center" bgcolor="#f0f0f0" border="1" cellspacing="0" cellpadding="5">
<tr><td><font color="#a00000"><b>
';

	if ($#error_messages >= 1) {
	    print '<ul><li>' . join ("</li>\n<li>", @error_messages) . '</li></ul>';
	} else {  # single message
	    print $error_messages[0];
	}

	print '
</b></font></td></tr>
</table>
';
    }
}



sub check_constraint {
    my ($error_messages, $field_name, $value, $constraint) = @_;

    if ($constraint =~ /not null/i &&
	length ($value) == 0) {
	push (@{$error_messages}, "$field_name: Cannot leave this field empty");
	return 1;
    }

    if ($constraint =~ /maxsize=(\d*)/i &&
	length ($value) > $1 ) {
	push (@{$error_messages}, "$field_name: Exceeded max chars limit of $1");
	return 1;
    }

    if ($constraint =~ /integer/i &&
	length ($value) > 0 &&
	$value !~ /^\d+$/) {
	push (@{$error_messages}, "$field_name: Must be an integer");
	return 1;
    }

    if ($constraint =~ /number/i &&
	length ($value) > 0 &&
	$value !~ /^(\-?\d*\.?\d*)?$/) {
	push (@{$error_messages}, "$field_name: Must be a number");
	return 1;
    }

    if ($constraint =~ /currency/i &&
	length ($value) > 0 &&
	$value !~ /^(\d+(\.?\d\d)?)?$/) {
	push (@{$error_messages}, "$field_name: Must be in currency format (.25, 0.25, or 123.45)");
	return 1;
    }

    if ($constraint =~ /date/i &&
	length ($value) > 0 &&
	$value !~ /^(\d\d-\d\d-\d\d\d\d)?$/ &&
	$value !~ /^(\d\d\/\d\d\/\d\d\d\d)?$/) {
	push (@{$error_messages}, "$field_name: Is not in the correct date format (mm-dd-yyyy or mm/dd/yyyy)");
	return 1;
    }

    if ($constraint =~ /format/i &&
	length ($value) > 0) {
	($tag, $format) = split (/=/, $constraint);
	if ($value !~ /$format/) {
	    push (@{$error_messages}, "$field_name: Does not follow specified format ($format)");
	    return 1;
	}
    }

    return 0;
}
