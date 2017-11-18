#!/usr/bin/perl

#
# athlete_homepage
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: April 3, 1999
#
# Description:
#    Displays athlete homepage
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";


auth_user ($CLEARANCE_STUDENT);


$cgi_data = parse_cgi_data();

$operation       = $cgi_data->{'OPERATION'};
$orig_athlete_id = $cgi_data->{'ORIG_ATHLETE_ID'};


# Dispatch request:

if ($operation eq "ATHLETE_RECORDS") {
    display_athlete_records ($orig_athlete_id);

} elsif ($operation eq "RECORDS_TABS") {
    display_records_tab ($orig_athlete_id);

} else {  # ALL
    display_athlete_info_and_records ($orig_athlete_id);
}

exit;



sub display_athlete_info_and_records
{
    my $orig_athlete_id = shift;

    print_http_header();
    

    print <<EOF;
<html>
<head>
<base href="$BASE_HREF">
</head>

 <frameset framespacing="0" frameborder="1" cols="200,*">
  <frameset rows="40,92%" framespacing="0" frameborder="1">
    <frame name="contents" src="Athlete_Records/athlete_info_tab.html" scrolling="no" marginwidth="0" marginheight="0">
    <frame name="contents1" src="/bin/process_form?OPERATION=VIEW_FORM&VIEW_LATEST=1&FORM_NAME=ATHLETE&ORIG_VERSION_ID=$orig_athlete_id" scrolling="auto">
  </frameset>
  <frame name="main" src="/bin/athlete_homepage.pl?OPERATION=ATHLETE_RECORDS&ORIG_ATHLETE_ID=$orig_athlete_id">
  <body>
  <p>This page uses frames, but your browser does not support them.</p>
  </body>
  </frameset>
</html>
EOF
    ;

    exit;
}



sub display_athlete_records
{
    my $orig_athlete_id = shift;

    # dispatch
    my $tab = $cgi_data->{'TAB'};

    if ($tab eq "PERSONAL") {
	display_personal_records ($orig_athlete_id);

    } elsif ($tab eq "INJURY") {
	display_injury_records ($orig_athlete_id);

    } elsif ($tab eq "TREATMENT_REHAB") {
	display_treatment_rehab_records ($orig_athlete_id);
	
    } elsif ($tab eq "INSURANCE") {
	display_insurance_records ($orig_athlete_id);

    } else {  # tab eq ATHLETE
	display_athlete_cover ($orig_athlete_id);
    }

    exit;
}



sub display_athlete_cover
{
    my $orig_athlete_id = shift;

    print_http_header();    

    print <<EOF;
<html>
<head>
<base href="$BASE_HREF">
</head>

<frameset framespacing="0" border="false" rows="40,*" frameborder="0">
  <frame name="records_tabs" scrolling="no" src="/bin/athlete_homepage.pl?OPERATION=RECORDS_TABS&TAB=ATHLETE&ORIG_ATHLETE_ID=$orig_athlete_id" marginwidth="0" marginheight="0">

  <frame name="records_body" src="Athlete_Records/athlete_info_cover.html" scrolling="auto" marginwidth="0" marginheight="0">

  <noframes>
  <body>
  <p>This page uses frames, but your browser does not support them.</p>
  </body>
  </noframes>
</frameset>
</html>
EOF
    ;

    exit;
}




sub display_personal_records
{
    my $orig_athlete_id = shift;

    print_http_header();

    print <<EOF;
<html>
<head>
<base href="$BASE_HREF">
</head>

<frameset framespacing="0" rows="40,*" frameborder="0">
  <frame name="records_tabs" scrolling="no" noresize src="/bin/athlete_homepage.pl?OPERATION=RECORDS_TABS&TAB=PERSONAL&ORIG_ATHLETE_ID=$orig_athlete_id" marginwidth="0" marginheight="0">

  <frameset framespacing="0" rows="30%,70%" frameborder="1">
  <frame name="personal_list" src="/bin/personal_list.pl?ORIG_ATHLETE_ID=$orig_athlete_id" scrolling="auto">

  <frame name="personal_body" src="/www/blank.html" scrolling="auto">
  </frameset>

  <noframes>
  <body>
  <p>This page uses frames, but your browser does not support them.</p>
  </body>
  </noframes>
</frameset>
</html>

EOF
    ;

    exit;
}




sub display_injury_records
{
    my $orig_athlete_id = shift;

    print_http_header();

    print <<EOF;
<html>
<head>
<base href="$BASE_HREF">
</head>

<frameset framespacing="0" rows="40,*" frameborder="0">
  <frame name="records_tabs" scrolling="no" noresize src="/bin/athlete_homepage.pl?OPERATION=RECORDS_TABS&TAB=INJURY&ORIG_ATHLETE_ID=$orig_athlete_id" marginwidth="0" marginheight="0">

  <frameset framespacing="0" rows="30%,70%" frameborder="1">
  <frame name="injury_list" src="/bin/injury_list.pl?ORIG_ATHLETE_ID=$orig_athlete_id" scrolling="auto">

  <frame name="injury_body" src="/www/blank.html" scrolling="auto">
  </frameset>

  <noframes>
  <body>
  <p>This page uses frames, but your browser does not support them.</p>
  </body>
  </noframes>
</frameset>
</html>

EOF
    ;

    exit;
}




sub display_treatment_rehab_records
{
    my $orig_athlete_id = shift;

    print_http_header();

    print <<EOF;
<html>
<head>
<base href="$BASE_HREF">
</head>

<frameset framespacing="0" rows="40,*" frameborder="0">
  <frame name="records_tabs" scrolling="no" noresize src="/bin/athlete_homepage.pl?OPERATION=RECORDS_TABS&TAB=TREATMENT_REHAB&ORIG_ATHLETE_ID=$orig_athlete_id" marginwidth="0" marginheight="0">

   <frameset framespacing="0" rows="30%,70%" frameborder="1">
   <frame name="treatment_rehab_list" src="/bin/treatment_rehab_list.pl?ORIG_ATHLETE_ID=$orig_athlete_id" scrolling="auto">

   <frame name="treatment_rehab_body" src="/www/blank.html" scrolling="auto">
   </frameset>

  <noframes>
  <body>
  <p>This page uses frames, but your browser does not support them.</p>
  </body>
  </noframes>
</frameset>
</html>

EOF
    ;

    exit;
}



sub display_insurance_records
{
    my $orig_athlete_id = shift;

    print_http_header();

    print <<EOF;
<html>
<head>
<base href="$BASE_HREF">
</head>

<frameset framespacing="0" rows="40,*" frameborder="0">
  <frame name="records_tabs" scrolling="no" noresize src="/bin/athlete_homepage.pl?OPERATION=RECORDS_TABS&TAB=INSURANCE&ORIG_ATHLETE_ID=$orig_athlete_id" marginwidth="0" marginheight="0">

  <frameset framespacing="0" rows="30%,70%" frameborder="1">
    <frame name="insurance_worksheet_list" src="/bin/insurance_worksheet_list.pl?ORIG_ATHLETE_ID=$orig_athlete_id" scrolling="auto">
    <frame name="insurance_worksheet" src="/www/blank.html" scrolling="auto">
  </frameset>

  <noframes>
  <body>
  <p>This page uses frames, but your browser does not support them.</p>
  </body>
  </noframes>
</frameset>
</html>

EOF
    ;

    exit;
}



sub display_records_tab
{
    my $orig_athlete_id = shift;

    my $tab = $cgi_data->{'TAB'};
    my $tab_gif;

    print_http_header();
    print <<EOF;
<html>

<head>
<base href="$BASE_HREF">
<title></title>
</head>

<body topmargin="0" leftmargin="0">
<form>
<input type="button" value=" Personal " style="background-color: #95d45a;  font-weight: bold;  padding: 5px;  margin: 5px;  border: 1px solid #000000;" onClick="parent.location.href='/bin/athlete_homepage.pl?OPERATION=ATHLETE_RECORDS&TAB=PERSONAL&ORIG_ATHLETE_ID=$orig_athlete_id';  return false;" />

<input type="button" value=" Injury " style="background-color: #73b5ef;  font-weight: bold;  padding: 5px;  margin: 5px;  border: 1px solid #000000;" onClick="parent.location.href='/bin/athlete_homepage.pl?OPERATION=ATHLETE_RECORDS&TAB=INJURY&ORIG_ATHLETE_ID=$orig_athlete_id';  return false;" />

<input type="button" value=" Treatment / Rehab " style="background-color: #ffd46b;  font-weight: bold;  padding: 5px;  margin: 5px;  border: 1px solid #000000;" onClick="parent.location.href='/bin/athlete_homepage.pl?OPERATION=ATHLETE_RECORDS&TAB=TREATMENT_REHAB&ORIG_ATHLETE_ID=$orig_athlete_id';  return false;" />

<input type="button" value=" Insurance " style="background-color: #d0a0f0;  font-weight: bold;  padding: 5px;  margin: 5px;  border: 1px solid #000000;" onClick="parent.location.href='/bin/athlete_homepage.pl?OPERATION=ATHLETE_RECORDS&TAB=INSURANCE&ORIG_ATHLETE_ID=$orig_athlete_id';  return false;" />
</form>
</body>
</html>

EOF
    ;

    exit(0);
}


