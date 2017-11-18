# file_locking.pl
#
# Copyright 1998, Melampus Enterprises, Inc.
# Author: Michael Duff
# Last modified: March 16, 1999
#
# Description:
#    Initializes global variables for use in file locking
#


$LOCK_SH = 1;
$LOCK_EX = 2;
$LOCK_NB = 4;
$LOCK_UN = 8;

1;
