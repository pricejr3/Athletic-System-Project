#!/usr/bin/perl

# athlete_access.pl
#
# Copyright 2007, Michael Duff-Xu
# Author: Michael J. Duff-Xu
# Last modified: 13-May-2007
#
# Description: Editing utility for athlete_access database
#    Allows administrator to generate the login tickets for students
#    so they can access the site and fill out their forms online.
#

require "global.pl";
require "database_utilities.pl";
require "athlete_access_utilities.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "logging.pl";

use DBI;


($login_id, $clearance) = auth_user ($CLEARANCE_ADMIN);

$cgi_data  = parse_cgi_data();
$operation = $cgi_data->{'OPERATION'};

# Dispatch the request:
if    ($operation eq "SEARCH")        { search_athletes(); }
elsif ($operation eq "MODIFY_ACCESS") { modify_athlete_access(); }
else                                  { search_athletes(); }

exit;



sub search_athletes
{
    prepare_cgi_data ($cgi_data);
    
    print_html_header ("Query results", $BASE_HREF);

    my $sql = build_sql_statement ($cgi_data);      # First build the SQL statement

    #print "SQL: $sql<br>\n";  # testing
    
    my $dbh = database_connect();                   # Establish connection to the database
    
    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query
    
    if ($cgi_data->{'PRINT_VIEW'}) { print_view ($sth); }
    else                           { display_results ($sth); }  # Display the results
    
    database_disconnect ($dbh);                     # Disconnect from the database
    
    print_html_trailer();
    
    exit;
}



sub build_sql_statement
{
    my $cgi_data = shift;

    #
    # The "ORIG_VERSION_ID > 0" clause is there only to serve as a first clause
    #
    $sql = "
SELECT ALV.ATHLETE_ID, ALV.ORIG_VERSION_ID,
    ALV.LAST_NAME, ALV.FIRST_NAME, ALV.MIDDLE_NAME, ALV.SPORT, AA.ENABLED, AA.TICKET,
    TO_CHAR(AA.LAST_LOGIN, 'MM-DD-YYYY HH24:MI:SS') as LAST_LOGIN,
    TO_CHAR(AA.START_DATE, 'MM-DD-YYYY') as START_DATE,
    TO_CHAR(AA.END_DATE, 'MM-DD-YYYY') as END_DATE";

    if ($cgi_data->{'HAVE_ACCESS'}) {  # return only entries that have access
	$sql .= "
    from athlete_lv ALV, athlete_access AA
WHERE ALV.orig_version_id = AA.athlete_id and AA.enabled = 'Yes'
    and AA.start_date <= now() and now() <= AA.end_date
";

    } else { 
	# Using left outer join so that all matching athlete rows will be returned,
	# whether or not there is a corresponding row in the access table.
	$sql .= "
    from athlete_lv ALV LEFT OUTER JOIN athlete_access AA ON
                    ALV.orig_version_id = AA.athlete_id
WHERE
    ALV.ORIG_VERSION_ID > 0
";
    }


    if ($cgi_data->{'LAST_NAME'}) {
	$sql .= " and UPPER(ALV.LAST_NAME) like UPPER('$cgi_data->{'LAST_NAME'}%')";
    }

    if ($cgi_data->{'FIRST_NAME'}) {
	$sql .= " and UPPER(ALV.FIRST_NAME) like UPPER('$cgi_data->{'FIRST_NAME'}%')";
    }

    if ($cgi_data->{'SPORT'}) {
	$sql .= " and ALV.SPORT = '$cgi_data->{'SPORT'}'";
    }

    if ($cgi_data->{'SEX'}) {
	$sql .= " and ALV.SEX = '$cgi_data->{'SEX'}'";
    }

    if ($cgi_data->{'SSN'}) {
	$sql .= " and ALV.SSN like '$cgi_data->{'SSN'}%'";
    }

    if ($cgi_data->{'STATUS'}) {
	$sql .= " and ALV.STATUS like '$cgi_data->{'STATUS'}%'";
    }

    if ($cgi_data->{'BIRTHDATE1'}) {
	$sql .= " and ALV.BIRTHDATE >= TO_DATE('$cgi_data->{'BIRTHDATE1'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'BIRTHDATE2'}) {
	$sql .= " and ALV.BIRTHDATE <= TO_DATE('$cgi_data->{'BIRTHDATE2'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'FORM_SIGN_DATE1'}) {
	$sql .= " and ALV.FORM_SIGN_DATE >= TO_DATE('$cgi_data->{'FORM_SIGN_DATE1'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'FORM_SIGN_DATE2'}) {
	$sql .= " and ALV.FORM_SIGN_DATE <= TO_DATE('$cgi_data->{'FORM_SIGN_DATE2'}', 'MM-DD-YYYY')";
    }

    $sql .= " order by UPPER (ALV.LAST_NAME)";
    
    $sql = format_sql_statement ($sql);

    return $sql;
}



sub display_results
{
    my $sth = shift;

    print <<EOF;
<form action="/bin/athlete_access.pl" method="post">

<table border="1" width="100%"><tr>
  <td><b><u>Athlete</u></b>
  <td align="center"><b><u>Sport</u></b>
  <td align="center"><b><u>Last Login</u></b>
  <td align="center"><b><u>Access Date Range (mm-dd-yyyy)</u></b>
  <td align="center"><b><u>Enable Access</u></b>
  <td align="center"><b><u>Reset Password</u></b>
  <td align="center"><b><u>Delete Account</u></b>
</tr>
EOF
    ;

    my $num_rows = 0;
    my $db_data;

    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;
	
	# Determine whether this athlete has an access record:
	my $access_record = '';
	if ($db_data->{'enabled'}) {
	    $access_record = '<input type="hidden" name="ACCESS_' .
		$db_data->{'orig_version_id'} . '" value="' . $db_data->{'orig_version_id'} . '">';
	}

	if ($db_data->{'enabled'} eq "Yes") { $checked = 'checked="checked"'; }
	else                                { $checked = ''; }

	my $last_login = $db_data->{'last_login'};
	if (! $last_login) { $last_login = '(never)'; }

	print <<EOF;
<tr>
<td><a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$db_data->{'orig_version_id'}" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a>
$access_record</td>
<td align="center">$db_data->{'sport'}</td>
<td align="center">$last_login</td>
<td align="center"><input type="text" size="10" name="START_DATE_$db_data->{'orig_version_id'}" value="$db_data->{'start_date'}">
thru
<input type="text" size="10" name="END_DATE_$db_data->{'orig_version_id'}" value="$db_data->{'end_date'}"></td>
<td align="center"><input type="checkbox" name="ENABLED_$db_data->{'orig_version_id'}" $checked></td>
<td align="center"><input type="checkbox" name="RESET_$db_data->{'orig_version_id'}"></td>
<td align="center"><input type="checkbox" name="DELETE_$db_data->{'orig_version_id'}"></td>
</tr>

EOF
    ;
    }

    
    $sth->finish;
    
    
    print <<EOF;
</table>

<hr>

<b>$num_rows Athlete(s) Found</b>

<input type="hidden" name="OPERATION" value="MODIFY_ACCESS">
<p align="center"><input type="submit" value=" Update Athlete Access "></p>
<br>
</form>
EOF
    ;
}



sub modify_athlete_access
{
    print_html_header ("Query results", $BASE_HREF);

    print <<EOF;
<body bgcolor="#ffffff">
<h2 align="center">Modifying Athlete Access</h2>
EOF
;


    # First find all of the athlete ID's and the settings for each:
    my %athlete_ids = ();
    foreach my $key (keys (%$cgi_data)) {
	# Looking for format: {param name}_{athlete ID}
	if ($key !~ /^(\w+)_(\d+)$/) { next; }
	
	$athlete_ids{$2}->{$1} = $cgi_data->{$key};
    }

    # For each athlete ID submitted, set the access as specified:
    foreach my $id (keys (%athlete_ids)) {
	# Update the athlete access entry:
	$enabled = 'No';
	if ($athlete_ids{$id}->{'ENABLED'}) { $enabled = 'Yes'; }
	
	my $sql = '';
	
	# If athlete access entry is already there, then update it:
	if ($athlete_ids{$id}->{'ACCESS'}) {
	    if ($athlete_ids{$id}->{'DELETE'}) {
		$sql = "delete from athlete_access where athlete_id = $id";
		
	    } elsif ($athlete_ids{$id}->{'RESET'}) {
		# If "reset password" is checked, then generate a new ticket for the athlete:
		my $ticket = generate_ticket();
		
		$sql = "update athlete_access set ticket = '$ticket', enabled = '$enabled', start_date = TO_DATE('$athlete_ids{$id}->{'START_DATE'}', 'MM-DD-YYYY'), end_date = TO_DATE('$athlete_ids{$id}->{'END_DATE'}', 'MM-DD-YYYY'), updated_by = '$login_id', updated_on = now() where athlete_id = $id";

	    } else {
		$sql = "update athlete_access set enabled = '$enabled', start_date = TO_DATE('$athlete_ids{$id}->{'START_DATE'}', 'MM-DD-YYYY'), end_date = TO_DATE('$athlete_ids{$id}->{'END_DATE'}', 'MM-DD-YYYY'), updated_by = '$login_id', updated_on = now() where athlete_id = $id";
	    }
	    
	} else {  # Otherwise, need to create a new entry:
	    my $ticket = generate_ticket();
	    $sql = "insert into athlete_access (athlete_id, ticket, enabled, start_date, end_date, updated_by, updated_on) values ($id, '$ticket', '$enabled', TO_DATE('$athlete_ids{$id}->{'START_DATE'}', 'MM-DD-YYYY'), TO_DATE('$athlete_ids{$id}->{'END_DATE'}', 'MM-DD-YYYY'), '$login_id', now())";
	}

	print "SQL: $sql<br>\n";  # testing

	my $dbh = database_connect();                   # Establish connection to the database
	my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query
	database_disconnect ($dbh);                     # Disconnect from the database
    }

    print_html_trailer();
}



sub print_view
{
    my ($sth) = @_;

    # html header already printed
    
    print <<EOF;
<table border="1" cellpadding="10" class="dataTable" width="100%"><tr>
EOF
;
    
    my $db_data;
    my $n;

    # Foreach athlete record returned by the query, generate a login
    # ticket using the designated parameters:
    while ($db_data = $sth->fetchrow_hashref) {
	print <<EOF;
<td align="left" width="33%"><b>Name:</b> $db_data->{'last_name'}, $db_data->{'first_name'}<br>
<b>Access timeframe:</b> $db_data->{'start_date'} through $db_data->{'end_date'}<br>
<b>Username:</b> athlete<br>
<b>Password:</b> <font face="Courier">$db_data->{'ticket'}</font></td>
EOF
    ;

	$n++;
	if ($n % 18 == 0) {
	    print <<EOF;
</tr></table>

<br><br><br>

<table border="1" cellpadding="10" class="dataTable" width="100%"><tr>
EOF
;
	} elsif ($n % 3 == 0) { print "</tr><tr>\n"; }
    }
    
    $sth->finish;
			 
    print "</tr></table>\n";
}
