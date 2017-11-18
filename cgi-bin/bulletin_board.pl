#!/usr/bin/perl

#
# bulletin_board
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: March 28, 1999
#
# Description:
#    Updates the bulletin board HTML page.
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "file_locking.pl";
require "commands.pl";



($login_id, $clearance) = auth_user ($CLEARANCE_STUDENT);

$BULLETIN_BOARD = "$INTRANET_BASE_DIR/share/bulletin_board.dat";

$cgi_data = parse_cgi_data();
$operation = $cgi_data->{'OPERATION'};


# Dispatch the request:
if    ($operation eq "DISPLAY")      { display_bulletin_board(); }
elsif ($operation eq "MODIFY")       { modify_bulletin_board(); }
elsif ($operation eq "SAVE_CHANGES") { save_changes(); }
else                                 { display_bulletin_board(); }

exit;


sub display_bulletin_board
{
    print_html_header ( "Bulletin Board", $BASE_HREF );

    my $last_updated;

    if ( open ( LAST_UPDATED, "$BULLETIN_BOARD.last_updated" ) ) {
	chop ( $last_updated = <LAST_UPDATED> );
	close ( LAST_UPDATED );
    } else {
	$last_updated = "Never updated";
    }

    print <<EOF;
<br>
<center><img src="Images/bulletin_board.gif"></center>
<br>

<center>Last Updated: $last_updated</center>

<br><br>

<p>
<center>
<table border="4" cellpadding="5" width="85%">
<tr bgcolor="#88aa99"><td><font size=+1><b>
EOF
    ;

    open ( BULLETIN_BOARD, $BULLETIN_BOARD );
    flock ( BULLETIN_BOARD, $LOCK_SH );
    seek ( BULLETIN_BOARD, 0, 0 );    # Rewind back to the beginning of the file
    while ( <BULLETIN_BOARD> ) { print "$_<br>\n"; }
    close ( BULLETIN_BOARD );


    print "</b></table><br><br>\n";

    if ( $clearance =~ /STAFF/ ) {
	print <<EOF;

<form method="post" action="/bin/bulletin_board.pl">
<input type="hidden" name="OPERATION" value="MODIFY">
<center><input type="submit" value=" Modify Bulletin Board "></center>
</form>
EOF
    ;
    }


    print_html_trailer();
}



sub modify_bulletin_board
{
    if ( $clearance !~ /STAFF/ ) { operation_not_permitted(); }

    print_html_header ( "Bulletin Board", $BASE_HREF );

    print <<EOF;
<br>
<center><img src="Images/modify_bulletin_board.gif"></center>
<br>
<br>

<form method="post" action="/bin/bulletin_board.pl">
<input type="hidden" name="OPERATION" value="SAVE_CHANGES">

<p>
<center>
<textarea rows=30 cols=60 name="BULLETIN_BOARD_CONTENT" wrap="physical">
EOF
    ;

    open ( BULLETIN_BOARD, $BULLETIN_BOARD );
    flock ( BULLETIN_BOARD, $LOCK_SH );
    seek ( BULLETIN_BOARD, 0, 0 );
    print <BULLETIN_BOARD>;
    close ( BULLETIN_BOARD );


    print <<EOF;
</textarea>

<p><input type="submit" value=" Save Changes "></p>
</center>

</form>
EOF
    ;

    print_html_trailer();
}



sub save_changes
{
    if ( $clearance !~ /STAFF/ ) { operation_not_permitted(); }
    
    open ( BULLETIN_BOARD, ">$BULLETIN_BOARD" );
    flock ( BULLETIN_BOARD, $LOCK_EX );
    seek ( BULLETIN_BOARD, 0, 0 );
    print BULLETIN_BOARD $cgi_data->{'BULLETIN_BOARD_CONTENT'};
    flock ( BULLETIN_BOARD, $LOCK_UN );
    close ( BULLETIN_BOARD );

    my $date = `$DATE '+%A, %B %d, %Y at %I:%M %p'`;

    open ( LAST_UPDATED, ">$BULLETIN_BOARD.last_updated" );
    print LAST_UPDATED "$date\n";
    close ( LAST_UPDATED );
 
    display_bulletin_board();
}



sub operation_not_permitted
{
    print_html_header ( "Bulletin Board", $BASE_HREF );

    print <<EOF;
<br><br>

<h1 align=center><u>Bulletin Board</u></h1>

<br><br>

<h1 align=center>Operation Not Permitted (need STAFF clearance)</h1>

EOF
    ;

    print_html_trailer();

    exit;
}
