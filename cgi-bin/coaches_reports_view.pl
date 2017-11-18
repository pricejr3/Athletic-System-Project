#!/usr/bin/perl

#
# coaches_reports_view
#
# Copyright 2000, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: May 9, 2007
#
# Description:
#    Performs a query on the database to find all coaches reports
#    satisfying the users search criteria.
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

if ($cgi_data->{'INSERT'}) { insert_coaches_reports(); }

prepare_cgi_data ($cgi_data);

$injury_status = $cgi_data->{'INJURY_STATUS'};
$display_mode  = $cgi_data->{'DISPLAY_MODE'};

print_html_header ("Query results", $BASE_HREF);

my $sql = build_sql_statement ();               # First build the SQL statement

my $dbh = database_connect();                   # Establish connection to the database

my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

display_results ($sth);                         # Display the results

database_disconnect ($dbh);                     # Disconnect from the database

print_html_trailer();

exit;




sub build_sql_statement
{
    $sport_specified = 0;
    $date_specified = 0;

    my $sql;

    if ($injury_status eq "") {
	# Build SQL statement:
	$sql = "
SELECT ALV.ORIG_VERSION_ID as ORIG_ATHLETE_ID, CRLV.ORIG_VERSION_ID as ORIG_COACHES_REPORT_ID,
       ALV.LAST_NAME, ALV.FIRST_NAME, ALV.MIDDLE_NAME,
       CRLV.SPORT, CRLV.STATUS, CRLV.INJURY, CRLV.ASSOCIATED_INJURIES, CRLV.COMMENTS,
       TO_CHAR(CRLV.FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR,
       TO_CHAR(now(), 'MM-DD-YYYY') as CURRENT_DATE_CHAR,
       CRLV.NO_SHOWS
       
FROM   ATHLETE_LV as ALV, COACHES_REPORT_LV as CRLV

WHERE  ALV.ORIG_VERSION_ID = CRLV.ATHLETE_ID and
       ALV.STATUS = 'Active'
";

	if ($cgi_data->{'SPORT'}) {
	    $sql .= " and CRLV.SPORT = '$cgi_data->{'SPORT'}'";
	    $sport_specified = 1;
	}
	
	if ($cgi_data->{'FORM_DATE1'}) {
	    $sql .= " and CRLV.FORM_DATE >= TO_DATE('$cgi_data->{'FORM_DATE1'}', 'MM-DD-YYYY')";
	}
	
	if ($cgi_data->{'FORM_DATE2'}) {
	    $sql .= " and CRLV.FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE2'}', 'MM-DD-YYYY')";
	}

	if ($cgi_data->{'SEX'}) {
	    $sql .= " and ALV.SEX = '$cgi_data->{'SEX'}'";
	}
    
	$sql .= " ORDER BY ALV.LAST_NAME, ALV.FIRST_NAME, ALV.ORIG_VERSION_ID, CRLV.FORM_DATE desc, CRLV.ORIG_VERSION_ID desc";
	

    } else {   # $injury_status eq "Open"
	# Get list of all injuries reports which match the desired status:

	$sql = "
SELECT ALV.ORIG_VERSION_ID as ORIG_ATHLETE_ID, IRLV.ORIG_VERSION_ID as ORIG_INJURY_REPORT_ID,
       ALV.LAST_NAME, ALV.FIRST_NAME, ALV.MIDDLE_NAME,
       IRLV.SPORT, IRLV.POSITION, IRLV.BODY_PART, IRLV.INJURY_TYPE,
       TO_CHAR(IRLV.DATE_REPORTED, 'MM-DD-YYYY') as FORM_DATE_CHAR,
       TO_CHAR(now(), 'MM-DD-YYYY') as CURRENT_DATE_CHAR,
       IRLV.ASSOCIATED_INJURIES

FROM   ATHLETE_LV as ALV, INJURY_REPORT_LV as IRLV

WHERE  ALV.ORIG_VERSION_ID = IRLV.ATHLETE_ID and
       ALV.STATUS = 'Active' and
       IRLV.INJURY_STATUS = 'Open'
";

	if ($cgi_data->{'SPORT'}) {
	    $sql .= " and IRLV.SPORT = '$cgi_data->{'SPORT'}'";
	    $sport_specified = 1;
	}
	
	if ($cgi_data->{'FORM_DATE1'}) {
	    $sql .= " and IRLV.DATE_REPORTED >= TO_DATE('$cgi_data->{'FORM_DATE1'}', 'MM-DD-YYYY')";
	}
	
	if ($cgi_data->{'FORM_DATE2'}) {
	    $sql .= " and IRLV.DATE_REPORTED <= TO_DATE('$cgi_data->{'FORM_DATE2'}', 'MM-DD-YYYY')";
	}

	if ($cgi_data->{'SEX'}) {
	    $sql .= " and ALV.SEX = '$cgi_data->{'SEX'}'";
	}

    
	$sql .= " ORDER BY ALV.LAST_NAME, ALV.FIRST_NAME, ALV.ORIG_VERSION_ID, IRLV.DATE_REPORTED desc, IRLV.ORIG_VERSION_ID desc";
    }

    
    if ($cgi_data->{'FORM_DATE1'} && $cgi_data->{'FORM_DATE2'} &&
	($cgi_data->{'FORM_DATE1'} eq $cgi_data->{'FORM_DATE2'})) {
	$date_specified = 1;
    }

    $sql = format_sql_statement ($sql);

    return $sql;
}




sub display_results
{
    my $sth = shift;

    if ($cgi_data->{'SEX'} eq "Male")      { $mens_womens = "Men's"; }
    elsif ($cgi_data->{'SEX'} eq "Female") { $mens_womens = "Women's"; }
    else { $mens_womens = "Men and Women's"; }

    if ($display_mode eq "EDIT") { $date_specified = 0; }
    if ($date_specified) { $specified_date = $cgi_data->{'FORM_DATE1'}; }


    print <<EOF;
<h1 align=center>$mens_womens $cgi_data->{'SPORT'} Daily Coaches Report</h1>
<h2 align=center>$specified_date</h2>

<br><br>
EOF
    ;


    if ($display_mode eq "EDIT") {
	print qq|<form name="coaches_report_view" action="/bin/coaches_reports_view.pl" method="post">\n|;
    }


    print qq|<table border="1" class="dataTable" cellpadding="5" width="100%">\n<tr>\n|;

    if ($display_mode eq "EDIT") { print '<td align="center"><b>Save</b></td>' . "\n"; }

    print <<EOF;
<td><b>Athlete</b></td>                     <td><b>Injury</b></td>
<td><b>Treatment/<br>Comments</b></td>      <td align="center"><b>Status</b></td>
EOF
    ;

    if (! $sport_specified) { print '<td align="center"><b>Sport</b></td>' . "\n"; }
    if (! $date_specified)  { print '<td align="center"><b>Date</b></td>' . "\n"; }

    print <<EOF;
<td align="center"><b>No-Shows</b></td>
</tr>
EOF
    ;


    my $num_rows = 0;
    my $db_data;
    my $no_shows = 0;
    
    while ($db_data = $sth->fetchrow_hashref) {
	$orig_athlete_id = $db_data->{'orig_athlete_id'};
	$orig_coaches_report_id = $db_data->{'orig_coaches_report_id'};

	if ($display_mode eq "EDIT" || $display_mode eq "PRINT_READY_NO_DUPS") {
	    # In edit mode, only one report per athlete:
	    if ($orig_athlete_id == $prev_athlete_id) {  # same athlete
		if ($display_mode eq "PRINT_READY_NO_DUPS") {
		    $no_shows += $db_data->{'no_shows'};  # sum no-shows
		}
		next;

	    } elsif ($display_mode eq "PRINT_READY_NO_DUPS") {
		# different athlete --> display previous athlete's # of no-shows:
		if ($num_rows > 0) {
		    print qq|<td align="center">$no_shows<br></td>\n|;
		    print "</tr>\n\n";
		}
		$no_shows = $db_data->{'no_shows'};  # reset for next athlete
		if (! $no_shows) { $no_shows = 0; }
	    }

	    $prev_athlete_id = $orig_athlete_id;
	}

	$num_rows++;


	if ($injury_status eq "Open" && $display_mode eq "EDIT") {
	    # Query to find the latest coaches report (if any) for this athlete:
	    # (only get report if it is newer than reference injury report)
	    ($injury, $comments, $status, $sport, $associated_injuries) =
		get_latest_coaches_report ($orig_athlete_id, $db_data->{'form_date_char'});

	    if ($injury)   {
		$db_data->{'injury'}              = $injury;
		$db_data->{'associated_injuries'} = $associated_injuries;
	    } else {
		$db_data->{'injury'} =
		    "$db_data->{'position'}, $db_data->{'body_part'}, $db_data->{'injury_type'}";
	    }
	    if ($comments) { $db_data->{'comments'} = $comments; }
	    if ($status)   { $db_data->{'status'}   = $status; }
	    if ($sport)    { $db_data->{'sport'}    = $sport; }

	} elsif ($injury_status eq "Open") {
	    $db_data->{'injury'} =
		"$db_data->{'position'}, $db_data->{'body_part'}, $db_data->{'injury_type'}";
	}



	print "<tr>\n";

	if ($display_mode eq "EDIT") {
	    print qq|<td align="center"><input name="SAVE_$orig_athlete_id" type="checkbox" value="YES" checked></td>\n|;
	}

	if ($display_mode eq "SHOW_LINKS") {
	    print qq|<td><a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$orig_athlete_id" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a>\n|;

	} else {
	    print qq|<td>$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}\n|;
	}

	print qq|<input name="ORIG_ATHLETE_ID_$orig_athlete_id" type="hidden" value="$orig_athlete_id"></td>\n|;



	if ($display_mode eq "EDIT") {
	    print qq|<td><font size="-1"><input name="INJURY_$orig_athlete_id" type="text" size="20" value="$db_data->{'injury'}"></font><br>\n|;
	    print qq|<input name="ASSOCIATED_INJURIES_$orig_athlete_id" type="hidden" value="$db_data->{'associated_injuries'}">Associated: $db_data->{'associated_injuries'}</td>\n|;
	} else {
	    print qq|<td>$db_data->{'injury'}<br>Associated: $db_data->{'associated_injuries'}</td>\n|;
	}


	if ($display_mode eq "EDIT") {
	    print qq|<td><font size="-1"><textarea name="COMMENTS_$orig_athlete_id" rows="5" cols="40" wrap="virtual">$db_data->{'comments'}</textarea></font></td>\n|;
	} else {
	    print qq|<td>$db_data->{'comments'}<br></td>\n|;
	}


	if ($display_mode eq "SHOW_LINKS") {
	    print qq|<td align="center"><a href="/bin/process_form?OPERATION=VIEW_FORM&VIEW_LATEST=1&FORM_NAME=COACHES_REPORT&ORIG_VERSION_ID=$orig_coaches_report_id&ORIG_ATHLETE_ID=$orig_athlete_id" target="top">$db_data->{'status'}</a><br></td>\n|;

	} elsif ($display_mode eq "EDIT") {
	    print qq|<td align="center"><select name="STATUS_$orig_athlete_id" size="1">\n|;
	    print qq|<option value="Out"| .
		(($db_data->{'status'} eq "Out") ? ' selected' : '') . qq|>Out</option>\n|;
	    print qq|<option value="Limited"| .
		(($db_data->{'status'} eq "Limited") ? ' selected' : '') . qq|>Limited</option>\n|;
	    print qq|<option value="GAPP"| .
		(($db_data->{'status'} eq "GAPP") ? ' selected' : '') . qq|>GAPP</option>\n|;
	    print qq|<option value="Full"| .
		(($db_data->{'status'} eq "Full") ? ' selected' : '') . qq|>Full</option>\n|;
	    print qq|</select></td>\n|;

	} else {
	    print qq|<td align="center">$db_data->{'status'}<br></td>\n|;
	}


	if (! $sport_specified)  { print qq|<td>$db_data->{'sport'}<br></td>\n|; }
	
	if ($display_mode eq "EDIT") {
	    print qq|<input name="SPORT_$orig_athlete_id" type="hidden" value="$db_data->{'sport'}">\n|;
	}

	
	if (! $date_specified) {
	    if ($display_mode eq "EDIT") {
		print qq|<td align="center"><input name="FORM_DATE_$orig_athlete_id" type="text" size="10" value="$db_data->{'current_date_char'}"></td>\n|;
	    } else {
		print qq|<td align="center">$db_data->{'form_date_char'}<br></td>\n|;
	    }
	}

	
	# Handle display of no-shows:
	if ($display_mode eq "EDIT") {
	    print qq|<td align="center"><select name="NO_SHOWS_$orig_athlete_id" size="1">
   <option value="0" selected="selected">None</option>
   <option value="1">Missed 1</option>
   <option value="2">Missed 2</option>
   <option value="3">Missed 3</option>
</select></td>\n|;
	} elsif ($display_mode ne "PRINT_READY_NO_DUPS") {
	    print qq|<td align="center">$db_data->{'no_shows'}<br></td>\n|;
	}

	if ($display_mode ne "PRINT_READY_NO_DUPS") {
	    print "</tr>\n\n";
	}
    }


    # Display total no-shows for final athlete in table:
    if ($display_mode eq "PRINT_READY_NO_DUPS") {
	print qq|<td align="center">$no_shows<br></td>\n|;
	print "</tr>\n\n";
    }


    $sth->finish;

    print "</table>\n";


    if ($display_mode eq "EDIT" && $num_rows > 0) {
	print qq|<p><center><input name="INSERT" type="submit" value=" Insert Marked Coaches Reports "></center></form>|;
    }


    print <<EOF;
<hr>

<b>$num_rows Report(s) Found</b>
EOF
    ;

}



sub get_latest_coaches_report
{
    my ($orig_athlete_id, $injury_report_date_char) = @_;

    my $sql2 = "
SELECT SPORT, STATUS, INJURY, COMMENTS, NO_SHOWS, ASSOCIATED_INJURIES
       
FROM   COACHES_REPORT_LV

WHERE  ATHLETE_ID = '$orig_athlete_id' and
       FORM_DATE >= TO_DATE('$injury_report_date_char', 'MM-DD-YYYY')

ORDER BY FORM_DATE desc, ORIG_VERSION_ID desc
";


    my $sth2 = execute_sql_statement ($dbh, $sql2);   # Now execute the query
    my $db_data2 = $sth2->fetchrow_hashref();         # Only need to fetch the first row
    $sth2->finish;

    if ($db_data2) {
	return ($db_data2->{'injury'}, $db_data2->{'comments'},
		$db_data2->{'status'}, $db_data2->{'sport'},
		$db_data2->{'associated_injuries'});
    } else {
	return ("", "", "", "", "");
    }
}



sub insert_coaches_reports
{
    print_html_header ("Bulk Report Insertion", $BASE_HREF);

    # Get all athlete ID's:
    foreach (keys (%$cgi_data)) {
	if ($_ =~ /ORIG_ATHLETE_ID_(\d+)/) { $orig_athlete_ids->{$1} = $1; }
    }

    $cgi_data->{'FORM_SIGN_USER_ID'} = $login_id;

    $num_inserted = 0;
    foreach $orig_athlete_id (keys (%$orig_athlete_ids)) {
	if ($cgi_data->{"SAVE_$orig_athlete_id"} ne "YES") { next; }

	$num_inserted++;

	$cgi_data->{'ORIG_ATHLETE_ID'}       = $orig_athlete_id;
	$cgi_data->{'SPORT'}                 = $cgi_data->{"SPORT_$orig_athlete_id"};
	$cgi_data->{'INJURY'}                = $cgi_data->{"INJURY_$orig_athlete_id"};
	$cgi_data->{'FORM_DATE'}             = $cgi_data->{"FORM_DATE_$orig_athlete_id"};
	$cgi_data->{'STATUS'}                = $cgi_data->{"STATUS_$orig_athlete_id"};
	$cgi_data->{'COMMENTS'}              = $cgi_data->{"COMMENTS_$orig_athlete_id"};

	# MJD (09-May-2007): Need to special chars in the comments:
	#$cgi_data->{'COMMENTS'} =~ s/\'/\'\'/g;   # Prepare single quotes for database
	#$cgi_data->{'COMMENTS'} =~ s/\\/\\\\/g;   # Prepare backslashes for database

	$cgi_data->{'NO_SHOWS'}              = $cgi_data->{"NO_SHOWS_$orig_athlete_id"};
	$cgi_data->{'ASSOCIATED_INJURIES[]'} = [$cgi_data->{"ASSOCIATED_INJURIES_$orig_athlete_id"}];

	insert_into_database ("COACHES_REPORT");
    }
    

    print <<EOF;
<br><br><br><br>
<h1 align=center>
<font color="#aa0000">$num_inserted Report(s) Successfully Inserted</font><br>
</h1>
EOF
    ;

    print_html_trailer();

    exit;
}
