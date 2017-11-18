#!/usr/bin/perl

#
# recommended_treatments_view
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: April 5, 1999
#
# Description:
#    Performs a query on the database to find all recommended_treatments
#    satisfying the users search criteria.
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
SELECT RTLV.RECOMMENDED_TREATMENT_ID as RECOMMENDED_TREATMENT_ID,
	   RTLV.ORIG_VERSION_ID as ORIG_RECOMMENDED_TREATMENT_ID,
       ALV.ORIG_VERSION_ID as ORIG_ATHLETE_ID,
       ALV.LAST_NAME, ALV.FIRST_NAME, ALV.MIDDLE_NAME, ALV.SEX,
       RTLV.SPORT, RTLV.TREATMENT_FACILITY,
       TO_CHAR(RTLV.TREATMENT_DATE, 'MM-DD-YYYY') as TREATMENT_DATE_CHAR,
       RTLV.TREATMENT_TIME, RTLV.INJURY, RTLV.RECOMMENDED_TREATMENT

FROM   ATHLETE_LV as ALV, RECOMMENDED_TREATMENT_LV as RTLV
WHERE  ALV.ORIG_VERSION_ID = RTLV.ATHLETE_ID and
       ALV.STATUS = 'Active'
";

    if ($cgi_data->{'SEX'}) {
	$sql .= " and ALV.SEX = '$cgi_data->{'SEX'}'";
    }

    if ($cgi_data->{'SPORT'}) {
	$sql .= " and RTLV.SPORT = '$cgi_data->{'SPORT'}'";
    }

    if ($cgi_data->{'TREATMENT_FACILITY'}) {
	$sql .= " and RTLV.TREATMENT_FACILITY = '$cgi_data->{'TREATMENT_FACILITY'}'";
	$facility_specified = 1;
    }
	
    if ($cgi_data->{'TREATMENT_TIME'}) {
	$sql .= " and RTLV.TREATMENT_TIME = '$cgi_data->{'TREATMENT_TIME'}'";
    }

    if ($cgi_data->{'TREATMENT_DATE1'}) {
	$sql .= " and RTLV.TREATMENT_DATE >= TO_DATE('$cgi_data->{'TREATMENT_DATE1'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'TREATMENT_DATE2'}) {
	$sql .= " and RTLV.TREATMENT_DATE <= TO_DATE('$cgi_data->{'TREATMENT_DATE2'}', 'MM-DD-YYYY')";
    }

    $sql .= " ORDER BY RTLV.TREATMENT_DATE DESC";

    $sql = format_sql_statement ($sql);

    #print "$statement <br>\n";

    return $sql;
}



sub display_results
{
    my $sth = shift;
	my $edit = 0;
	
	if ($cgi_data->{'EDIT_TREATMENT'} eq "YES") {
	    $edit = 1;
	}

	my $quckvar = "";
	my $tid = "";
	my $did = "";

	if ($edit == 1) {
			#target="recommend_treatment_view_results"
			print  <<EOF;
			<form method="GET" action="/bin/update_recommended_treatment.pl" target="recommended_treatments_view_results" > 
EOF
	;
			
	}

    if ($facility_specified) {
	print "<br><h1 align=center><b>$cgi_data->{'TREATMENT_FACILITY'}</b></h1>\n";
    }
	print <<EOF;
<input id='EDIT_IDS' name='EDIT_IDS' style='visibility:hidden;'>
<input id='NEW_RT' name='NEW_RT' style='visibility:hidden;'>

EOF
	;

	
	print <<EOF;
<script>
var ed_id = [];
var new_date = [];
function addIfExists(iidd) {	
	if (ed_id.length===0) {
			ed_id.push(iidd);
	}
	var cc = 0;
	for (i=0; i<ed_id.length; i++) {
		if (ed_id[i]===iidd) {
			cc++
		}
	}
	if (cc===0) {
			ed_id.push(iidd);
	}
		
}
function checkFunction(treat_id) {
	document.getElementById(treat_id).checked = true; 
	addIfExists(treat_id);
	document.getElementById('EDIT_IDS').value = ed_id; 
	document.getElementById('EDIT_IDS').innerHTML = ed_id;
}

function addDateIfExists(iidd) {	
	if (new_date.length===0) {
			new_date.push(iidd);
	}
	var cc = 0;
	for (i=0; i<new_date.length; i++) {
		if (new_date[i]===iidd) {
			cc++
		}
	}
	if (cc===0) {
			new_date.push(iidd);
	}
		
}

function checkDateFunction(treat_id) {
	document.getElementById(treat_id).checked = true; 
	addDateIfExists(treat_id);
	document.getElementById('NEW_RT').value = new_date; 
	document.getElementById('NEW_RT').innerHTML = new_date;
}
	
</script>

EOF
	;
    print <<EOF;
<br>
<table border=2 width="100%">
<tr>
EOF
	;
	if ($edit == 1) {
			print "<td><b>Edit</b></td>";
			
	}

	print <<EOF;
<td><b>Athlete</b></td>           
<td><b>Sport</b></td>
<td><b>Injury</b></td>
<td><b>Treatment Date</b></td>
<td><b>Recommended Treatment</b></td>
EOF
    ;

    if (! $facility_specified) { print "  <td><b>Facility</b></td>\n"; }
	print "</tr>";

    my $num_rows = 0;
    my $db_data;

    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;
    
	if ($cgi_data->{'SHOW_LINKS'} eq "YES") {
	    $orig_athlete_id = $db_data->{'orig_athlete_id'};

	   

	print"<tr>";
	
	if ($edit == 1) {
			print "<td><input name='$db_data->{'recommended_treatment_id'}' id='$db_data->{'recommended_treatment_id'}' type='checkbox'></td>";
			
	}

	 print <<EOF;

<td><a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$orig_athlete_id" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a></td>

<td>$db_data->{'sport'}</td>

<td>$db_data->{'injury'}</td>

EOF
	;

	
	if ($edit == 1) {
			$quickvar = $db_data->{'recommended_treatment_id'};
			$tid = "rt_id_" . $quickvar;
			$did = "rt_date_" . $quickvar;
			print "<td><textarea cols='20' id='$did' name='$did' onkeyup='checkDateFunction($quickvar)'>$db_data->{'treatment_date_char'}</textarea></td>";
			print "<td><textarea cols='20' rows='4' id='$tid' name='$tid' onkeyup='checkFunction($quickvar)'>$db_data->{'recommended_treatment'}</textarea></td>";
			
	} else {
			print "<td>$db_data->{'treatment_date_char'}</td>";
			print "<td>$db_data->{'recommended_treatment'}</td>";

	}

	if (! $facility_specified) { print "  <td>$db_data->{'treatment_facility'}\n"; }

	} else {    # SHOW_LINKS == "NO"

		print "</tr><tr>";
		
		if ($edit == 1) {
			print "<td><input name='$db_data->{'recommended_treatment_id'}' id='$db_data->{'recommended_treatment_id'}' type='checkbox'></td>";
			
		}
		print <<EOF;

<td>$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</td>

<td>$db_data->{'sport'}</td>

<td>$db_data->{'injury'}</td>



EOF
    ;
	
		if ($edit == 1) {
			$quickvar = $db_data->{'recommended_treatment_id'};
			$tid = "rt_id_" . $quickvar;
			$did = "rt_date_" . $quickvar;
			print "<td><textarea cols='20' name='$did' id='$did' onkeyup='checkDateFunction($quickvar)'>$db_data->{'treatment_date_char'}</textarea></td>";
			print "<td><textarea cols='20' rows='4' name='$tid' id='$tid' onkeyup='checkFunction($quickvar)'>$db_data->{'recommended_treatment'}</textarea></td>";
		} else {
			print "<td>$db_data->{'treatment_date_char'}</td>";
			print "<td>$db_data->{'recommended_treatment'}</td>";

		}

			if (! $facility_specified) { 
				print "  <td>$db_data->{'treatment_facility'}</td>\n"; }
		}
    }

	print "</tr>";
    $sth->finish;


    print <<EOF;
</table>

<hr>

<b>$num_rows Report(s) Found</b>
EOF
    ;
	
	if ($edit == 1) {
		print <<EOF;
			<br />
			<input type="submit" value="Update Recommended Treatment(s)">
			</form>
			
EOF
	;
	}
}
