# commands.pl
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: March 16, 1999
#
# Description:
#    These are commands that are used by various scripts.  Note that
#    these may be system-dependent, and therefore need to be modified
#    depending on the operating system.
#

$DATE = '/bin/date';
$DF = '/bin/df -k';
$LS = '/bin/ls -la';
$PROCINFO = '/usr/bin/vmstat';
$PS = '/bin/ps';
$PS_ARGS = '-elf';
$TAIL = '/usr/bin/tail';

1;
