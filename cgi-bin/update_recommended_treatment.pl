#!/usr/bin/perl

#
# update_recommended_treatment
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

#my $sql = build_sql_statement();                # First build the SQL statement

#my $dbh = database_connect();                   # Establish connection to the database

#my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

display_results ($sth);                         # Display the results


#database_disconnect ($dbh);                     # Disconnect from the database

print_html_trailer();

exit;

sub build_sql_statement 
{




}

sub display_results 
{
		my $rt2update = $cgi_data->{'EDIT_IDS'};
		my $tid = "";
		my $did = "";
		
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
		my $sql_commands;
		my $sql_count = 0;
		my $inputs = "";
		my $out = "";
		for ($i=0; $i<$N; $i++) {
			$quickvar = "" . $values[$i] . "";
			$tid = "rt_id_" . $quickvar;
			$did = "rt_date_" . $quickvar;
			if ($cgi_data->{$quickvar} == "on") {
				if ($quickvar ~~ @new_RT) {
					#$sql_commands = $sql_commands . 'INSERT INTO RECOMMENDED_TREATMENT_LV ' . $cgi_data->{$tid} . ' :: date: ' . $cgi_data->{$did} . '<br />';
					$inputs = $inputs . "<input name='$tid' value='$cgi_data->{$tid}' style='visibility:hidden;'>";
					$inputs = $inputs . "<input name='$did' value='$cgi_data->{$did}' style='visibility:hidden;'>";
					$out = $out . "Update recommended treatment to: '" . $cgi_data->{$tid} ."' with the new treatment date of: " . $cgi_data->{$did} . "<br />";
				} else {
					$inputs = $inputs . "<input name='$tid' value='$cgi_data->{$tid}' style='visibility:hidden;'>";
					$out = $out . "Update recommended treatment to: '" . $cgi_data->{$tid} ."'<br />";
					
				}
			}
		}
		print <<EOF;
<div id="page_cont">
<form method="GET" action="/bin/confirm_rt_update.pl" target="recommended_treatments_view_results" >		
<input name='EDIT_IDS' value='$cgi_data->{'EDIT_IDS'}' style='visibility:hidden;'>
<input name='NEW_RT' value='$cgi_data->{'NEW_RT'}' style='visibility:hidden;'>
$inputs
<script>
function cancel() {
	document.getElementById("page_cont").innerHTML= "";
}
</script>
<br />Are you sure you want to update recommended treatment(s)? <br />
<br /><br />
$out
<br /><br />
<center><input type="submit" value="Confirm"><input type="button" value="Cancel" onclick="cancel()"></center>

</form>

</div>
EOF
	;

}







