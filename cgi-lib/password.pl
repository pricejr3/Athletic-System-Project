# password.pl
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael Duff
# Last modified: March 16, 1999
#
# Description: Password utilities
#


require "encryption.pl";
require "database_utilities.pl";

use DBI;


sub verify_password
{
    my ($this_login_id, $this_password) = @_;

    my ($login_id, $password_hash, $clearance, $full_name) =
	get_passwd_fields ($this_login_id);

    my $password_hash2 = compute_hash ("$this_login_id:$this_password");

    if ($password_hash ne $password_hash2) {
	return 0;                                  # Incorrect password
    } else {
	return 1;                                  # Correct password
    }
}



sub verify_athlete_login_password
{
    my ($password) = @_;

    my $id = 0;  # false if not found

    # Search the athlete_login database table for a matching ticket string
    # (and verify that we're within the permitted login dates):
    my $sql = "select athlete_id from athlete_access" .
	" where ticket = '$password' and enabled = 'Yes'" .
	" and start_date < now() and now() < end_date";
    
    my $dbh = database_connect();                   # Establish connection to the database
    
    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query
    
    # If found, then return the associated athlete ID:
    # Query will return at most one row:
    # If returns more --> problem
    my $db_data = $sth->fetchrow_hashref;

    if ($db_data) { $id = $db_data->{'athlete_id'}; }

    $sth->finish;

    database_disconnect ($dbh);                     # Disconnect from the database

    return $id;
}



sub update_athlete_lastlog
{
    my ($athlete_id) = @_;

    my $sql = "update athlete_access set last_login = now()" .
	" where athlete_id = $athlete_id";
    
    my $dbh = database_connect();                   # Establish connection to the database
    
    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

    $sth->finish;

    database_disconnect ($dbh);                     # Disconnect from the database
}




# Try to "crack" password, check length, etc...
#
# "reason" need to remain a global variable
#
sub check_password_quality
{
    my ($login_id, $new_password) = @_;


    # Check length of the password:
    if (length ($new_password) < 8) {
	$reason = "Your password must be at least 8 characters in length";
	return 0;
    }

    
    # Check to make sure there is no whitespace in the password:
    if ($new_password =~ /\s/) {
	$reason = "No whitespace (space or tab) is permitted in passwords";
	return 0;
    }
    
    # Check for repeated characters (or substrings):
#    for ($window_size = 1; $window_size <= 4; $window_size++) {
#	for ($i = 0; $i < length ($new_password) - $window_size; $i++b) {
#	    # Grab $window_size characters from password beginning at index $i:
#	    $substring = substr ($new_password, $i, $window_size);
#	}
#    }
    
    # Check if username is substring of password:
    if ($new_password =~ /$login_id/i) {
	$reason = "Your password should not contain your username";
	return 0;
    }


    # Check if user's first name or last name is a substring of the password:
    if (open (PASSWD, "$AUTH_DIR/$login_id.passwd")) {
	my ($login_id2, $password_hash, $clearance, $full_name) =
	    get_passwd_fields ($login_id);
	
	my ($first_name, $x, $last_name) = split (/,/, $full_name);
	
	if (($first_name && $new_password =~ /$first_name/i) ||
	    ($last_name && $new_password =~ /$last_name/i)) {
	    $reason = "Your password should not contain any part of your real name ($first_name, $last_name)";
	    return 0;
	}
    }

    
    # Check if password is all upper or lower case letters:
    if ($new_password =~ /^[a-z]+$/ || $new_password =~ /^[A-Z]+$/) {
	$reason = "If you use only letters in your password, then you must use a combination of upper and lower case";
	return 0;
    }

    
    # Check if password is all digits:
    if ($new_password =~ /^[0-9]+$/) {
	$reason = "Be sure to use letters and/or symbols in your password - not just numbers";
	return 0;
    }

    
    # Check if password is a dictionary word:
    open (WORDS, "$CGI_LIB/words");     # changed from /usr/dict/words
    while (<WORDS>) {
	chop;
	
	# password matches a word in the dictionary:
	if ($_ =~ /$new_password/oi) {
	    $reason = "Do not use a word that would be found in a dictionary";
	    close (WORDS);
	    return 0;
	}
    }
    close (WORDS);
        
    return 1;
}



sub get_passwd_fields
{
    my ($this_login_id) = @_;

    # Open passwd file of user and extract the needed fields:
    open (PASSWD, "$AUTH_DIR/$this_login_id.passwd") || die "Password file not found";
    my $password_contents;
    chop ($passwd_contents = <PASSWD>);
    my ($login_id, $password_hash, $clearance, $full_name) =
	split (/:/, $passwd_contents);
    close (PASSWD);

    return ($login_id, $password_hash, $clearance, $full_name);
}



sub get_first_name
{
    my ($this_login_id) = @_;

    if ((my $athlete_id = is_athlete_login ($this_login_id))) {
	my $first_name = '';

	# Query database to get athlete's first name:
	my $sql = "select first_name from athlete_lv" .
	    " where athlete_id = $athlete_id";
	
	my $dbh = database_connect();                   # Establish connection to the database
	
	my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query
	
	# If found, then return the associated athlete ID:
	# Query will return at most one row:
	# If returns more --> problem
	my $db_data = $sth->fetchrow_hashref;
	
	if ($db_data) { $first_name = $db_data->{'first_name'}; }
	
	$sth->finish;
	
	database_disconnect ($dbh);                     # Disconnect from the database

	return $first_name;


    } else { # non-athlete login
	my ($login_id, $password_hash, $clearance, $full_name) =
	    get_passwd_fields ($this_login_id);
	
	my ($first_name, $x, $x) = split (/,/, $full_name);

	return $first_name;
    }
}



sub is_athlete_login
{
    my ($id) = @_;
    if ($id =~ /^$ATHLETE_LOGIN_ID_(\d+)$/) { return $1; }
    
    return 0;  # not an athlete login
}



sub update_passwd_file
{
    my ($login_id, $new_password_hash) = @_;

    open ( PASSWD, "$AUTH_DIR/$login_id.passwd" ) || die "Password file not found";
    chop ( $passwd_contents = <PASSWD> );
    my ($login_id, $password_hash, $clearance, $full_name) =
        split ( /:/, $passwd_contents );
    close ( PASSWD );

    # set umask for creating files and directories:
    # Want mode: 770 ==> 777-770 = 007
    umask (007);

    # Now write the new password to the passwd file:
    open (PASSWD, ">$AUTH_DIR/$login_id.passwd");
    print PASSWD "$login_id:$new_password_hash:$clearance:$full_name\n";
    close (PASSWD);
}


1;
