#!/usr/local/bin/perl

# create_admin_account.pl
#
# Copyright 1998, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: July 30, 1998
#
# Description: create_user_account is a tool for the system
#              administrator used for adding a new user account.


require "/home/mjduff/Miami/cgi-bin/global.pl";


print <<EOF;

Create Admin Account
--------------------
EOF
    ;

$username = 'admin';
$user_dir = "$USER_ACCOUNTS_DIR/$username";


if ( -e $user_dir ) {
    print "Home directory for $username already exists.\n";
    print "Choose another username and run create_admin_account.pl again.\n\n";
    exit(0);
}


# Check user name for length, format, etc...


print "Creating prototype user account...\n";

# set umask for creating files and directories:
# Want mode: 770 ==> 777-770 = 007
umask (007);


print "Creating home directory... ";
mkdir ( "$user_dir", 0770 );
print "done\n";

print "Account for \"$username\" has been created.\n";


if ( -e "$AUTH_DIR/$username.passwd" ) {
    print "Account for \"$username\" has already been activated.\n";
    print "Run deactivate_user.pl first.\n\n";
    exit(0);
}


print "1) Choose password, or 2) Generate password: ";
chop ( $answer = <STDIN> );

if ( $answer eq "1" ) {
    print "Enter desired password: ";
    chop ( $password = <STDIN> );
} else {
    $password = &generate_password();
}


# Encrypt password (use first two letters of username as the salt):
# Later: generate salt characters randomly
$salt = substr ($username, 0, 2);
$encrypted_password = crypt ( $password, $salt );


# set umask for creating files and directories:
# Want mode: 770 ==> 777-770 = 007
umask (007);

# Write $username.passwd file:
open (PASSWD, ">$AUTH_DIR/$username.passwd");
print PASSWD "$username:$encrypted_password:ADMIN:System Administrator,,\n";
# print PASSWD "$password_expiration_time\n";
close (PASSWD);

print "$AUTH_DIR/$username.passwd file has been created.\n\n";


exit (0);




sub generate_password
{
    # Seed random number generator for temporary password:
    # (Use bitwise XOR of system time and process ID)
    $time = time();
    srand ($time ^ $$);
    
    # Generate Radix64 character set:
    @radix64_chars = ('a'..'z', 'A'..'Z', '0'..'9', '.', '/');

    
    # Generate temporary password (temporary password is a
    # 10-character string):
    for ($i = 0; $i < 10; $i++) {
	$char = int (rand (64));
	if ($char == 64) { $char = 63; }
	push ( @temp_password_characters, $radix64_chars[$char] );
    }
    
    $temp_password = pack( "a" x 10, @temp_password_characters );
    
    
    print "The temporary password for \"$username\" is: $temp_password\n\n";
    
    return ( $temp_password );
}

