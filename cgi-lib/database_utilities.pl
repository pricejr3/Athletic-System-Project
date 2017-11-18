#
# database_utilities
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: April 4, 1999
#
# Description:
#    Useful routines for interacting with the database.
#

require "global.pl";


sub database_connect
{
    my $dbh = DBI->connect( "dbi:Pg:$DATABASE", $DATABASE_USERID, $DATABASE_PASSWORD ) ||
	html_die ( "Unable to connect to $DATABASE:<br><br> $DBI::errstr" );

    #$dbh->{LongReadLen} = 20000;   # 20000 character max for reading long fields
    #$dbh->{LongTruncOk} = 1;       # Permit truncation of long field if necessary

    return $dbh;
}


sub database_purge_connect
{
    my $dbh = DBI->connect( "dbi:Pg:$DATABASE", $PURGE_USERID, $PURGE_PASSWORD ) ||
	html_die ( "Unable to connect to $DATABASE:<br><br> $DBI::errstr" );

    #$dbh->{LongReadLen} = 20000;   # 20000 character max for reading long fields
    #$dbh->{LongTruncOk} = 1;       # Permit truncation of long field if necessary

    return $dbh;
}


sub database_disconnect
{
    my $dbh = shift;

    $dbh->disconnect;
}



sub prepare_cgi_data
{
    my $cgi_data = shift;

    # clean up supplied fields:
    foreach (keys (%$cgi_data)) {
	$cgi_data->{$_} =~ s/^(\s*)//;
	$cgi_data->{$_} =~ s/(\s*)$//;
	$cgi_data->{$_} =~ s/\'/\'\'/g;   # Prepare single quotes for database
	$cgi_data->{$_} =~ s/\\/\\\\/g;   # Prepare backslashes for database
    }
}



sub format_sql_statement
{
    my $sql = shift;

    $sql =~ s/\n/ /g;       # replace newlines with spaces
    $sql =~ s/^\s*//;       # remove leading whitespace
    $sql =~ s/\s*$//;       # remove trailing whitespace
    $sql =~ s/;$//;         # remove trailing semicolon if present

    return $sql;
}



sub execute_sql_statement
{
    my ($dbh, $sql) = @_;
    my $errstr;

    my $sth;
    if (! ($sth = $dbh->prepare ($sql))) {
	$errstr = $sth->errstr;
	database_disconnect ($dbh);
	html_die ("Unable to prepare statement:<br><hr noshade>$sql<hr noshade><br> $errstr");
    }
    
    my $rc;
    if (! ($rc = $sth->execute)) {
	$errstr = $sth->errstr;
	$sth->finish;
	database_disconnect ($dbh);
	html_die ("Unable to execute statement:<br><hr noshade>$sql<hr noshade><br> $errstr");
    }

    return $sth;
}



