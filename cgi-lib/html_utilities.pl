#
# html_utilities.pl
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: April 1, 1999
#



sub print_http_header
{
    print "Content-type: text/html", "\n";
    print "Pragma: no-cache", "\n\n";
}


sub print_html_header
{
    my ($title, $base_href, $background) = @_;

    print "Content-type: text/html", "\n";
    print "Pragma: no-cache", "\n\n";
    
    print <<HERE;
<!-- Copyright 1998, Melampus Enterprises, Inc. -->

<html>

<head>
  <title>$title</title>
HERE

    if (defined ($base_href)) {
	print "  <base href=\"$base_href\">", "\n";
    }

    print <<HERE;
  <link rel="stylesheet" type="text/css" href="/www/common.css"/>
</head>

HERE
    ;
    
    if (defined ($background)) {
	print "<body background=\"$background\">\n\n";
    } else {
	print "<body background=\"/www/background.gif\">\n\n";
    }
}



sub print_frame_cookie_header
{
    my ($title, $base_href, $login_id, $session_key) = @_;
    
    print "Content-type: text/html\n";
    print "Pragma: no-cache\n";
    print "Set-Cookie: LOGIN_ID=$login_id\n";
    print "Set-Cookie: SESSION_KEY=$session_key\n";
    print "\n";
    
    print <<HERE;
<!-- Copyright 1998, Melampus Enterprises, Inc. -->

<html>
<head>
  <title>$title</title>
HERE

    if ($base_href) {
	print "  <base href=\"$base_href\">\n";
    }

    print <<HERE;
  <link rel="stylesheet" type="text/css" href="/www/common.css"/>
</head>
HERE
}


sub print_refresh_header
{
    my ($title, $base_href, $content) = @_;

    print "Content-type: text/html", "\n";
    print "Pragma: no-cache", "\n\n";

    print <<HERE;
<!-- Copyright 1998, Melampus Enterprises, Inc. -->

<html>

<head>
  <meta http-equiv="refresh" content="$content">
  <title>$title</title>
HERE

    if ($base_href) {
        print "  <base href=\"$base_href\">", "\n";
    }

    print <<HERE;
  <link rel="stylesheet" type="text/css" href="/www/common.css"/>
</head>

<body background="/www/background.gif" text="#000000" link="#0000ff">

HERE
}




sub print_html_trailer
{
    print "</body>\n";
    print "</html>\n";
}




sub html_header_and_die
{
    my $error_message = shift;

    print_html_header ("General Error Handler", $BASE_HREF);

    print <<EOF;

<br><br>
<h1 align=center><b>Error:</b></h1>

<br>
<h2 align=center><b>$error_message</b></h2>
EOF
    ;

    print_html_trailer();

    exit;
}



sub html_die
{
    my $error_message = shift;

    print <<EOF;

<br><br>
<h1 align=center><b>Error:</b></h1>

<br>
<b>$error_message</b>
EOF
    ;

    print_html_trailer();

    exit;
}

1;




