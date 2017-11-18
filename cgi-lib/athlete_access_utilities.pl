# athlete_login.pl
#
# Copyright 2007, Michael Duff-Xu
# Author: Michael J. Duff-Xu
# Last modified: May 10, 2007
#
# Description: Functions needed for athlete logins
#

use Digest::MD5 qw( md5_base64 );

require 'global.pl';


sub is_athlete_login
{
    my ($login_id) = @_;
    return ($login_id =~ /^athlete_\d+$/);
}


sub get_athlete_id
{
    my ($login_id) = @_;
    if ($login_id =~ /^athlete_(\d+)$/) { return $1; }
    else                                { return 0; }
}


sub generate_ticket
{
    my $data = time();  # begin with the time
    $data .= $$;        # process ID

    # Gather entropy:
    srand (time() ^ $$);
    for (my $i = 0; $i < 10; $i++) {  $data .= rand(); }

    $data .= `$PS_CMD`;
    $data .= `$NETSTAT_CMD`;
    $data .= `$VMSTAT_CMD`;

    # Now generate a hash of the data:
    my $ticket = md5_base64 ($data);  # [a-zA-Z0-9/+]

    $ticket =~ s/\//\#/g; # convert /'s to #'s
    $ticket =~ s/\+/\./g; # convert +'s to .'s
    $ticket =~ s/1/\$/g;  # convert 1's to $'s
    $ticket =~ s/l/\%/g;  # convert l's to %'s
    $ticket =~ s/I/\]/g;  # convert I's to ]'s
    $ticket =~ s/0/\*/g;  # convert 0's to *'s
    $ticket =~ s/O/\@/g;  # convert O's to @'s

    return substr ($ticket, 0, 10);
}



sub set_ticket
{
    my ($athlete_id, $ticket) = @_;

    my $sql = "INSERT into athlete_login (athlete_id, ticket) " .
	"values ($athlete_id, '$ticket')";

    # Write the generated ticket into the database:
    my $dbh = database_connect();                   # Establish connection to the database

    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

    # Check for success:
    
    database_disconnect ($dbh);                     # Disconnect from the database
}



sub clear_ticket
{
    my ($athlete_id) = @_;

    # Remove the specified athlete's ticket
    my $sql = "delete from athlete_login where athlete_id = $athlete_id";

    # Write the generated ticket into the database:
    my $dbh = database_connect();                   # Establish connection to the database

    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

    # Check for success:
    
    database_disconnect ($dbh);                     # Disconnect from the database
}



sub check_ticket
{
    my ($ticket) = @_;

    # Find the corresponding athlete ID (if any):
    my $athlete_id = '';

    return $athlete_id;
}



1;
