#!/usr/bin/perl

#
# functional_movement_screen_view
#
# Copyright 2000, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: May 9, 2007
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "form_utilities.pl";
require "database_utilities.pl";

use DBI;


($login_id, $clearance) = auth_user ($CLEARANCE_STUDENT);

$cgi_data = parse_cgi_data();

prepare_cgi_data ($cgi_data);

print_html_header ("Query results", $BASE_HREF);

my $sql = build_sql_statement ();               # First build the SQL statement

my $dbh = database_connect();                   # Establish connection to the database

my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

display_results ($sth);                         # Display the results

database_disconnect ($dbh);                     # Disconnect from the database

print_html_trailer();

exit;

sub build_sql_statement
{
  $sport_specified = 0;
  $date_specified = 0;

  my $sql;

  # Build SQL statement:
  $sql = "
  SELECT * FROM (
  SELECT DISTINCT on (ALV.ATHLETE_ID) ALV.ATHLETE_ID, ALV.LAST_NAME, ALV.FIRST_NAME, ALV.MIDDLE_NAME, ALV.SEX,
  ALV.SPORT, RTLV.ds_score, RTLV.ihs_score_right, RTLV.ihs_score_left,
  RTLV.sm_score_right, RTLV.sm_score_left, RTLV.tspu_score, RTLV.ri_score_right,
  RTLV.ri_score_left, RTLV.aslr_score_right, RTLV.aslr_score_left, RTLV.il_score_right,
  RTLV.il_score_left

  FROM   ATHLETE_LV as ALV, functional_movement_screen_lv as RTLV
  WHERE  ALV.ORIG_VERSION_ID = RTLV.ATHLETE_ID
  ";

  if ($cgi_data->{'SPORT'}) {
    $sql .= " and ALV.SPORT = '$cgi_data->{'SPORT'}'";
    $sport_specified = 1;
  }

  if ($cgi_data->{'FORM_DATE1'}) {
    $sql .= " and FORM_DATE >= TO_DATE('$cgi_data->{'FORM_DATE1'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'FORM_DATE2'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE2'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'SEX'}) {
    $sql .= " and ALV.SEX = '$cgi_data->{'SEX'}'";
  }

  $sql .= " ORDER BY ALV.ATHLETE_ID, ALV.LAST_NAME, ALV.FIRST_NAME, ALV.ORIG_VERSION_ID, FORM_DATE desc, ALV.ORIG_VERSION_ID desc)
  AS sub_query
  ORDER BY sub_query.LAST_NAME asc";

  $sql = format_sql_statement ($sql);

  return $sql;
}

sub display_results
{
  my $sth = shift;
  my $sum_ds_score = 0;
  my $sum_ihs_score = 0;
  my $sum_il_score = 0;
  my $sum_sm_score = 0;
  my $sum_aslr_score = 0;
  my $sum_tspu_score = 0;
  my $sum_ri_score = 0;
  my $sum_total_score = 0;

print <<EOF;
  <br>
  <table border=2 width="100%">
  <tr>
  <td><b>Athlete</b>
  <td><b>Deep Squat</b>
  <td><b>Hurdle Step (Right)</b>
  <td><b>Hurdle Step (Left)</b>
  <td></td>
  <td><b>In-Line Lunge (Right)</b>
  <td><b>In-Line Lunge (Left)</b>
  <td></td>
  <td><b>Shoulder Mobility (Right)</b>
  <td><b>Shoulder Mobility (Left)</b>
  <td></td>
  <td><b>Active Straight Leg Raise (Right)</b>
  <td><b>Active Straight Leg Raise (Left)</b>
  <td></td>
  <td><b>Trunk Stability Push Up</b>
  <td><b>Rotary Stability (Right)</b>
  <td><b>Rotary Stability (Left)</b>
  <td></td>
  <td><b>Total Score</b>


EOF
  ;

  my $num_rows = 0;
  my $db_data;

  while ($db_data = $sth->fetchrow_hashref) {
    $num_rows++;

print <<EOF;
    <tr>
    <td>$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</td>

EOF
    ;

    if ($db_data->{'ds_score'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'ds_score'}</td>
EOF
      ;
    } elsif ($db_data->{'ds_score'} == 1 || $db_data->{'ds_score'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'ds_score'}</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'ds_score'}</td>
EOF
      ;
    }

    $sum_ds_score += $db_data->{'ds_score'};

    if ($db_data->{'ds_score'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'ihs_score_right'}</td>
EOF
      ;
    } elsif ($db_data->{'ihs_score_right'} == 1 || $db_data->{'ihs_score_right'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'ihs_score_right'}</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'ihs_score_right'}</td>
EOF
      ;
    }

    if ($db_data->{'ihs_score_left'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'ihs_score_left'}</td>
EOF
      ;
    } elsif ($db_data->{'ihs_score_left'} == 1 || $db_data->{'ihs_score_left'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'ihs_score_left'}</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'ihs_score_left'}</td>
EOF
      ;
    }

    my $min_ihs_score = 0;
    if ($db_data->{'ihs_score_right'} < $db_data->{'ihs_score_left'}) { $min_ihs_score = $db_data->{'ihs_score_right'} } else { $min_ihs_score = $db_data->{'ihs_score_left'} }

    if ($min_ihs_score == 3) {
print <<EOF;
      <td bgcolor="green">$min_ihs_score</td>
EOF
      ;
    } elsif ($min_ihs_score == 1 || $min_ihs_score == 2) {
print <<EOF;
      <td bgcolor="yellow">$min_ihs_score</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$min_ihs_score</td>
EOF
      ;
    }

    $sum_ihs_score += $min_ihs_score;

    if ($db_data->{'il_score_right'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'il_score_right'}</td>
EOF
      ;
    } elsif ($db_data->{'il_score_right'} == 1 || $db_data->{'il_score_right'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'il_score_right'}</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'il_score_right'}</td>
EOF
      ;
    }

    if ($db_data->{'il_score_left'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'il_score_left'}</td>
EOF
      ;
    } elsif ($db_data->{'il_score_left'} == 1 || $db_data->{'il_score_left'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'il_score_left'}</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'il_score_left'}</td>
EOF
      ;
    }

    my $min_il_score = 0;
    if ($db_data->{'il_score_right'} < $db_data->{'il_score_left'}) { $min_il_score = $db_data->{'il_score_right'} } else { $min_il_score = $db_data->{'il_score_left'} }

    if ($min_il_score == 3) {
print <<EOF;
      <td bgcolor="green">$min_il_score</td>
EOF
      ;
    } elsif ($min_il_score == 1 || $min_il_score == 2) {
print <<EOF;
      <td bgcolor="yellow">$min_il_score</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$min_il_score</td>
EOF
      ;
    }

    $sum_il_score += $min_il_score;

    if ($db_data->{'sm_score_right'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'sm_score_right'}</td>
EOF
  ;
    } elsif ($db_data->{'sm_score_right'} == 1 || $db_data->{'sm_score_right'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'sm_score_right'}</td>
EOF
  ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'sm_score_right'}</td>
EOF
  ;
    }

    if ($db_data->{'sm_score_left'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'sm_score_left'}</td>
EOF
  ;
} elsif ($db_data->{'sm_score_left'} == 1 || $db_data->{'sm_score_left'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'sm_score_left'}</td>
EOF
  ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'sm_score_left'}</td>
EOF
  ;
    }

    my $min_sm_score = 0;
    if ($db_data->{'sm_score_right'} < $db_data->{'sm_score_left'}) { $min_sm_score = $db_data->{'sm_score_right'} } else { $min_sm_score = $db_data->{'sm_score_left'} }

    if ($min_sm_score == 3) {
print <<EOF;
      <td bgcolor="green">$min_sm_score</td>
EOF
  ;
    } elsif ($min_sm_score == 1 || $min_sm_score == 2) {
print <<EOF;
      <td bgcolor="yellow">$min_sm_score</td>
EOF
  ;
    } else {
print <<EOF;
      <td bgcolor="red">$min_sm_score</td>
EOF
  ;
    }

    $sum_sm_score += $min_sm_score;

    if ($db_data->{'aslr_score_right'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'aslr_score_right'}</td>
EOF
      ;
    } elsif ($db_data->{'aslr_score_right'} == 1 || $db_data->{'aslr_score_right'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'aslr_score_right'}</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'aslr_score_right'}</td>
EOF
      ;
    }

    if ($db_data->{'aslr_score_left'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'aslr_score_left'}</td>
EOF
      ;
    } elsif ($db_data->{'aslr_score_left'} == 1 || $db_data->{'aslr_score_left'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'aslr_score_left'}</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'aslr_score_left'}</td>
EOF
      ;
    }

    my $min_aslr_score = 0;
    if ($db_data->{'aslr_score_right'} < $db_data->{'aslr_score_left'}) { $min_aslr_score = $db_data->{'aslr_score_right'} } else { $min_aslr_score = $db_data->{'aslr_score_left'} }

    if ($min_aslr_score == 3) {
print <<EOF;
      <td bgcolor="green">$min_aslr_score</td>
EOF
      ;
    } elsif ($min_aslr_score == 1 || $min_aslr_score == 2) {
print <<EOF;
      <td bgcolor="yellow">$min_aslr_score</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$min_aslr_score</td>
EOF
      ;
    }

    $sum_aslr_score += $min_aslr_score;

    if ($db_data->{'tspu_score'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'tspu_score'}</td>
EOF
      ;
    } elsif ($db_data->{'tspu_score'} == 1 || $db_data->{'tspu_score'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'tspu_score'}</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'tspu_score'}</td>
EOF
      ;
    }

    $sum_tspu_score += $db_data->{'tspu_score'};

    if ($db_data->{'ri_score_right'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'ri_score_right'}</td>
EOF
      ;
    } elsif ($db_data->{'ri_score_right'} == 1 || $db_data->{'ri_score_right'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'ri_score_right'}</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'ri_score_right'}</td>
EOF
      ;
    }

    if ($db_data->{'ri_score_left'} == 3) {
print <<EOF;
      <td bgcolor="green">$db_data->{'ri_score_left'}</td>
EOF
      ;
    } elsif ($db_data->{'ri_score_left'} == 1 || $db_data->{'ri_score_left'} == 2) {
print <<EOF;
      <td bgcolor="yellow">$db_data->{'ri_score_left'}</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$db_data->{'ri_score_left'}</td>
EOF
      ;
    }

    my $min_ri_score = 0;
    if ($db_data->{'ri_score_right'} < $db_data->{'ri_score_left'}) { $min_ri_score = $db_data->{'ri_score_right'} } else { $min_ri_score = $db_data->{'ri_score_left'} }

    if ($min_ri_score == 3) {
print <<EOF;
      <td bgcolor="green">$min_ri_score</td>
EOF
      ;
    } elsif ($min_ri_score == 1 || $min_ri_score == 2) {
print <<EOF;
      <td bgcolor="yellow">$min_ri_score</td>
EOF
      ;
    } else {
print <<EOF;
      <td bgcolor="red">$min_ri_score</td>
EOF
      ;
    }

    $sum_ri_score += $min_ri_score;

    my $total_score = 0;
    $total_score += $db_data->{'ds_score'};
    $total_score += $min_ihs_score;
    $total_score += $min_il_score;
    $total_score += $min_sm_score;
    $total_score += $min_aslr_score;
    $total_score += $min_ri_score;
    $total_score += $db_data->{'tspu_score'};

    if ($total_score < 15) {
print <<EOF;

      <td bgcolor="red">$total_score</td>

EOF
      ;
    } else {
      print <<EOF;

      <td bgcolor="green">$total_score</td>

EOF
      ;
    }

    $sum_total_score += $total_score;

  }


  $sth->finish;

print <<EOF;

  <br>

  </table>
  <table border=2 width="100%">
  <tr>
  <th>Deep Squat Average</th>
  <th>Hurdle Step Average</th>
  <th>In-Line Lunge Average</th>
  <th>Shoulder Mobility Average</th>
  <th>Active Straight Leg Raise Average</th>
  <th>Trunk Stability Push Up Average</th>
  <th>Rotary Stability Average</th>
  <th>Total Score Average</th>
  </tr>
  <tr>

EOF
  ;

  my $avg_ds_score = $sum_ds_score / $num_rows;
  my $avg_ihs_score = $sum_ihs_score / $num_rows;
  my $avg_il_score = $sum_il_score / $num_rows;
  my $avg_sm_score = $sum_sm_score / $num_rows;
  my $avg_aslr_score = $sum_aslr_score / $num_rows;
  my $avg_tspu_score = $sum_tspu_score / $num_rows;
  my $avg_ri_score = $sum_ri_score / $num_rows;
  my $avg_total_score = $sum_total_score / $num_rows;

  if ($avg_ds_score == 3) {
print <<EOF;
    <td bgcolor="green">$avg_ds_score</td>
EOF
    ;
  } elsif ($avg_ds_score >= 1 && $avg_ds_score <= 2) {
print <<EOF;
    <td bgcolor="yellow">$avg_ds_score</td>
EOF
    ;
  } else {
print <<EOF;
    <td bgcolor="red">$avg_ds_score</td>
EOF
    ;
  }

  if ($avg_ihs_score == 3) {
print <<EOF;
    <td bgcolor="green">$avg_ihs_score</td>
EOF
    ;
  } elsif ($avg_ihs_score >= 1 && $avg_ihs_score <= 2) {
print <<EOF;
    <td bgcolor="yellow">$avg_ihs_score</td>
EOF
    ;
  } else {
print <<EOF;
    <td bgcolor="red">$avg_ihs_score</td>
EOF
    ;
  }

  if ($avg_il_score == 3) {
print <<EOF;
    <td bgcolor="green">$avg_il_score</td>
EOF
    ;
  } elsif ($avg_il_score >= 1 && $avg_il_score <= 2) {
print <<EOF;
    <td bgcolor="yellow">$avg_il_score</td>
EOF
    ;
  } else {
print <<EOF;
    <td bgcolor="red">$avg_il_score</td>
EOF
    ;
  }

  if ($avg_sm_score == 3) {
print <<EOF;
    <td bgcolor="green">$avg_sm_score</td>
EOF
    ;
  } elsif ($avg_sm_score >= 1 && $avg_sm_score <= 2) {
print <<EOF;
    <td bgcolor="yellow">$avg_sm_score</td>
EOF
    ;
  } else {
print <<EOF;
    <td bgcolor="red">$avg_sm_score</td>
EOF
    ;
  }

  if ($avg_aslr_score == 3) {
print <<EOF;
    <td bgcolor="green">$avg_aslr_score</td>
EOF
    ;
  } elsif ($avg_aslr_score >= 1 && $avg_aslr_score <= 2) {
print <<EOF;
    <td bgcolor="yellow">$avg_aslr_score</td>
EOF
    ;
  } else {
print <<EOF;
    <td bgcolor="red">$avg_aslr_score</td>
EOF
    ;
  }

  if ($avg_tspu_score == 3) {
print <<EOF;
    <td bgcolor="green">$avg_tspu_score</td>
EOF
    ;
  } elsif ($avg_tspu_score >= 1 && $avg_tspu_score <= 2) {
print <<EOF;
    <td bgcolor="yellow">$avg_tspu_score</td>
EOF
    ;
  } else {
print <<EOF;
    <td bgcolor="red">$avg_tspu_score</td>
EOF
    ;
  }

  if ($avg_ri_score == 3) {
print <<EOF;
    <td bgcolor="green">$avg_ri_score</td>
EOF
    ;
  } elsif ($avg_ri_score >= 1 && $avg_ri_score <= 2) {
print <<EOF;
    <td bgcolor="yellow">$avg_ri_score</td>
EOF
    ;
  } else {
print <<EOF;
    <td bgcolor="red">$avg_ri_score</td>
EOF
    ;
  }

  if ($avg_total_score < 15) {
print <<EOF;

    <td bgcolor="red">$avg_total_score</td>

EOF
    ;
  } else {
print <<EOF;

    <td bgcolor="green">$avg_total_score</td>

EOF
    ;
  }

print <<EOF
  </tr>
  </table>

  <hr>

  <b>$num_rows Report(s) Found</b>
EOF
  ;
}
