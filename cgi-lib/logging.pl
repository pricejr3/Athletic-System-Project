# logging.pl
#
# Copyright 1998, Melampus Enterprises, Inc.
# Author: Michael Duff
# Last modified: July 28, 1998
#
# Description: Logging utlities


require "file_locking.pl";
require "commands.pl";

    
# Description: Logs messages
sub print_log
{
    my $msg = shift;

    my $date;
    chop ($date = `$DATE '+%m/%d/%Y-%T %Z'`);

    umask ( 007 );

    open (LOG, ">>$LOGS_DIR/auth");
    flock (LOG, $LOCK_EX);
    seek (LOG, 0, 2);        # Set filehandle position to EOF
    print LOG "[$date] \"$msg\"\n";
    flock (LOG, $LOCK_UN);
    close (LOG);
}


1;
