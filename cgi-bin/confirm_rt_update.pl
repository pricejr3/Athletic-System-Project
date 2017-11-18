#!/usr/bin/perl

#
# confirm_rt_update
#
# Author: Dakota M Brown
# Last modified: April 11, 2016
#
# Description:
#    Updates specified recommended treatments
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

print_html_header ("Update Recommended Treatment", $BASE_HREF);

my $sql = build_sql_statement();                # First build the SQL statement

#my $dbh = database_connect();                   # Establish connection to the database

#my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

display_results ($sth);                         # Display the results


#database_disconnect ($dbh);                     # Disconnect from the database

print_html_trailer();

exit;

sub build_sql_statement 
{

    # my $sql = $cgi_data->{'sqls'};
	# print $sql;
   	# $sql = "UPDATE RECOMMENDED_TREATMENT_LV SET RECOMMENDED_TREATMENT='dmb 2012' WHERE RECOMMENDED_TREATMENT_ID=3";
	# $sql = format_sql_statement ($sql);
	
	my $term = $cgi_data->{'EDIT_IDS'};
	my $new = $cgi_data->{'NEW_RT'};
	my @new_RT = split(',', $new);
	my @values = split(',', $term);
	my $N = @values;
	my $out = "";
	my $tid = "";
	my $did = "";
	my $quickvar = "";
	my $i = 0;
	my $sql_commands = "";
	my $sql_count = 0;
	my $sql_getter = "";
	for ($i=0; $i<$N; $i++) {
		$quickvar = "" . $values[$i] . "";
		$tid = "rt_id_" . $quickvar;
		$did = "rt_date_" . $quickvar;
		if ($cgi_data->{$quickvar} == "on") {
			if ($quickvar ~~ @new_RT) {
				
				#to create a new recommended treatment entirely
				#$sql_commands = getter($quickvar, $tid, $did);
				
				#or just to update the date on the existing treatment
				$sql_commands = "UPDATE RECOMMENDED_TREATMENT_LV SET RECOMMENDED_TREATMENT='" . $cgi_data->{$tid} . "', TREATMENT_DATE='" . $cgi_data->{$did} . "' WHERE RECOMMENDED_TREATMENT_ID=" . $quickvar . ";"; 
				
				
				#print "<br /><br />Made it back to original subroutine!<br /><br />";
				
				#$sql_commands= "UPDATE RECOMMENDED_TREATMENT_LV SET RECOMMENDED_TREATMENT='" . $cgi_data->{$tid} . "' WHERE RECOMMENDED_TREATMENT_ID=" . $quickvar . ";"; 
				#print $sql_commands;

				my $dbh = database_connect();
				#print $sql_commands;
				$sql_commands = format_sql_statement ($sql_commands);
				#print $sql_commands;
				my $sth = execute_sql_statement ($dbh, $sql_commands);
				database_disconnect ($dbh);
			
			} else {
				my $dbh = database_connect();
				$sql_commands="UPDATE RECOMMENDED_TREATMENT_LV SET RECOMMENDED_TREATMENT='" . $cgi_data->{$tid} . "' WHERE RECOMMENDED_TREATMENT_ID=" . $quickvar . ";"; 
				$sql_commands = format_sql_statement ($sql_commands);
				my $sth = execute_sql_statement ($dbh, $sql_commands);
				database_disconnect ($dbh);
			}
		}
	}
	
	#print $sql_commands;
	#my $sql = format_sql_statement ($sql_commands);
	
    return $sql_commands;


}
sub getter {

	my $dbh = database_connect();

	my $ret = "";
	my $id = $_[0];
	my $tid = $_[1];
	my $did = $_[2];
	my $sql_get = "SELECT * FROM RECOMMENDED_TREATMENT_LV WHERE RECOMMENDED_TREATMENT_ID=" . $id . ";";
	
	$sql_get = format_sql_statement ($sql_get);

	my $sth = execute_sql_statement ($dbh, $sql_get);
	while ($db_data = $sth->fetchrow_hashref) {

		#print "<br />execute select<br />athlete id: " . $db_data->{'athlete_id'} . "<br /><br />";
		
		
		my $ret ="INSERT INTO RECOMMENDED_TREATMENT_LV (RECOMMENDED_TREATMENT_ID, ORIG_VERSION_ID, ATHLETE_ID, SPORT, FORM_DATE, TREATMENT_FACILITY, TREATMENT_DATE, TREATMENT_TIME, INJURY, RECOMMENDED_TREATMENT, REVIEW_REQUIRED, FORM_SIGN_USER_ID, FORM_SIGN_DATE, FORM_SIGNATURE, PARTICIPATION_STATUS, ASSOCIATED_INJURIES) VALUES ('" . $id ."', '". $db_data->{'orig_version_id'} ."', '". $db_data->{'athlete_id'} ."', '". $db_data->{'sport'} ."', '". $db_data->{'form_date'} ."', '". $db_data->{'treatment_facility'} ."', '". $cgi_data->{$did} ."', '". $db_data->{'treatment_time'} ."', '". $db_data->{'injury'} ."', '". $cgi_data->{$tid} ."', '". $db_data->{'review_required'} ."', '". $db_data->{'form_sign_user_id'} ."', '". $db_data->{'form_sign_date'} ."', '". $db_data->{'form_signature'} ."', '". $db_data->{'participation_status'} ."', '". $db_data->{'associated_injuries'} ."');";
		#print "in the getter<br />" . $ret . "<br />";
		database_disconnect ($dbh);	
		return $ret;
	}
    $sth->finish;

	database_disconnect ($dbh);	
	return $ret;
}


sub display_results 
{

	#my $sql = $cgi_data->{'sqls'};
	#print $sql;

		
	print <<EOF;
	
Update Confirmed!

EOF
	;

}
