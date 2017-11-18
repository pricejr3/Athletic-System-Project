#!/usr/bin/perl

#
# freeform_query
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: March 20, 1999
#
# Description:
#
#    Performs a query on the database.
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "database_utilities.pl";

use DBI;


($login_id, $clearance) = auth_user ($CLEARANCE_STUDENT);

$cgi_data = parse_cgi_data();

check_clearance_level ($clearance);


print_html_header ("Query results", $BASE_HREF);

$sql = format_sql_statement ($cgi_data->{'SQL_QUERY'});

if ($sql) {
    if (! ($sql =~ /^select/i)) {
	print "<br><br><br><br><br><h1 align=center>Must be a SELECT statement!</h1>\n";
	print_html_trailer();
	exit;
    }

    my $dbh = database_connect();                   # Establish connection to the database

    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

    print "<center><font size=+1><b>$sql</b></font></center><br><br>\n";
    print "<hr noshade><br>\n";

    display_results ($sth);                         # Display the results
    
    database_disconnect ($dbh);                     # Disconnect from the database
}

print_html_trailer();

exit;




sub check_clearance_level
{
    my $clearance = shift;

    
    # First check clearance level:
    if ($clearance !~ /STAFF/i) {
	print_html_header ("Query results", $BASE_HREF);

	print <<EOF;
<br><br><br>
<font color="#ff0000">
<h1 align=center><b>Access not permitted!<br><br>
You need STAFF clearance to use this utility.<br>
(You currently have $clearance clearance.)</b></h1>
</font>
EOF
    ;

    print_html_trailer();
    exit;
    }
}



sub display_results
{
    my $sth = shift;

    my $column_name;
    my $num_rows = 0;

    if ($sth->{NUM_OF_FIELDS} > 0) {
	print "<center>\n";
	print "<table border=2>\n";

	# Print out column names:
	foreach $column_name (@ {$sth->{NAME}}) {
	    print "<th><b><u>$column_name</u></b>\n";
	}
	
	while (@fields = $sth->fetchrow_array) {
	    $num_rows++;
	    print "<tr>\n";
	    foreach (@fields) { print "<td>$_ <br>\n"; }
	}

	print "</table><br>\n";
	print "<b>$num_rows row(s) were returned</b>\n";
	print "</center>\n";
    }

    $sth->finish;

    print "<br><br>\n";
}
