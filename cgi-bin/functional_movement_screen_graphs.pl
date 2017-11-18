#!/usr/bin/perl

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "form_utilities.pl";
require "database_utilities.pl";

use DBI;
use warnings;

use GD::Graph;


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
  $date_specified_one = 0;
  $date_specified_two = 0;
  $date_specified_three = 0;
  $date_specified_four = 0;
  $date_specified_five = 0;
  $date_specified_six = 0;

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

  if ($cgi_data->{'FORM_DATE3'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE3'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'FORM_DATE4'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE4'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'FORM_DATE5'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE5'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'FORM_DATE6'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE6'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'FORM_DATE7'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE7'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'FORM_DATE8'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE8'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'FORM_DATE9'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE9'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'FORM_DATE10'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE10'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'FORM_DATE11'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE11'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'FORM_DATE12'}) {
    $sql .= " and FORM_DATE <= TO_DATE('$cgi_data->{'FORM_DATE12'}', 'MM-DD-YYYY')";
  }

  if ($cgi_data->{'SEX'}) {
    $sql .= " and ALV.SEX = '$cgi_data->{'SEX'}'";
  }

  $sql .= " ORDER BY ALV.ATHLETE_ID, ALV.LAST_NAME, ALV.FIRST_NAME, ALV.ORIG_VERSION_ID, FORM_DATE desc, ALV.ORIG_VERSION_ID desc)
  AS sub_query
  ORDER BY sub_query.LAST_NAME asc";

  if ($cgi_data->{'FORM_DATE1'} && $cgi_data->{'FORM_DATE2'} &&
  ($cgi_data->{'FORM_DATE1'} eq $cgi_data->{'FORM_DATE2'})) {
    $date_specified_one = 1;
  }

  if ($cgi_data->{'FORM_DATE3'} && $cgi_data->{'FORM_DATE4'} &&
  ($cgi_data->{'FORM_DATE3'} eq $cgi_data->{'FORM_DATE4'})) {
    $date_specified_two = 1;
  }

  if ($cgi_data->{'FORM_DATE5'} && $cgi_data->{'FORM_DATE6'} &&
  ($cgi_data->{'FORM_DATE5'} eq $cgi_data->{'FORM_DATE6'})) {
    $date_specified_three = 1;
  }

  if ($cgi_data->{'FORM_DATE7'} && $cgi_data->{'FORM_DATE8'} &&
  ($cgi_data->{'FORM_DATE7'} eq $cgi_data->{'FORM_DATE8'})) {
    $date_specified_four = 1;
  }

  if ($cgi_data->{'FORM_DATE9'} && $cgi_data->{'FORM_DATE10'} &&
  ($cgi_data->{'FORM_DATE9'} eq $cgi_data->{'FORM_DATE10'})) {
    $date_specified_five = 1;
  }

  if ($cgi_data->{'FORM_DATE11'} && $cgi_data->{'FORM_DATE12'} &&
  ($cgi_data->{'FORM_DATE11'} eq $cgi_data->{'FORM_DATE12'})) {
    $date_specified_six = 1;
  }

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

  my $avg_ds_score = 0;
  my $avg_ihs_score = 0;
  my $avg_il_score = 0;
  my $avg_sm_score = 0;
  my $avg_aslr_score = 0;
  my $avg_tspu_score = 0;
  my $avg_ri_score = 0;
  my $avg_total_score = 0;

  my @ds_data_list;
  my @ihs_data_list;
  my @il_data_list;
  my @sm_data_list;
  my @aslr_data_list;
  my @tspu_data_list;
  my @ri_data_list;
  my @total_data_list;
  my @date_data_list;

  if ($cgi_data->{'FORM_DATE1'}) {
    if ($cgi_data->{'FORM_DATE2'} && $date_specified_one) {
      push(@date_data_list, $cgi_data->{'FORM_DATE1'} . "-" . $cgi_data->{'FORM_DATE2'});
    } else {
      push(@date_data_list, $cgi_data->{'FORM_DATE1'});
    }
  }
  if ($cgi_data->{'FORM_DATE3'}) {
    if ($cgi_data->{'FORM_DATE4'} && $date_specified_two) {
      push(@date_data_list, $cgi_data->{'FORM_DATE3'} . "-" . $cgi_data->{'FORM_DATE4'});
    } else {
      push(@date_data_list, $cgi_data->{'FORM_DATE3'});
    }
  }
  if ($cgi_data->{'FORM_DATE5'}) {
    if ($cgi_data->{'FORM_DATE6'} && $date_specified_three) {
      push(@date_data_list, $cgi_data->{'FORM_DATE5'} . "-" . $cgi_data->{'FORM_DATE6'});
    } else {
      push(@date_data_list, $cgi_data->{'FORM_DATE5'});
    }
  }
  if ($cgi_data->{'FORM_DATE7'}) {
    if ($cgi_data->{'FORM_DATE8'} && $date_specified_four) {
      push(@date_data_list, $cgi_data->{'FORM_DATE7'} . "-" . $cgi_data->{'FORM_DATE8'});
    } else {
      push(@date_data_list, $cgi_data->{'FORM_DATE7'});
    }
  }
  if ($cgi_data->{'FORM_DATE9'}) {
    if ($cgi_data->{'FORM_DATE10'} && $date_specified_five) {
      push(@date_data_list, $cgi_data->{'FORM_DATE9'} . "-" . $cgi_data->{'FORM_DATE10'});
    } else {
      push(@date_data_list, $cgi_data->{'FORM_DATE9'});
    }
  }
  if ($cgi_data->{'FORM_DATE11'}) {
    if ($cgi_data->{'FORM_DATE12'} && $date_specified_six) {
      push(@date_data_list, $cgi_data->{'FORM_DATE11'} . "-" . $cgi_data->{'FORM_DATE12'});
    } else {
      push(@date_data_list, $cgi_data->{'FORM_DATE11'});
    }
  }

print <<EOF;
  <br>

  <table border=2 width="100%">
  <tr>
  <th><b>Date</b>
  <th><b>Deep Squat</b>
  <th><b>Hurdle Step</b>
  <th><b>In-Line Lunge</b>
  <th><b>Shoulder Mobility</b>
  <th><b>Active Straight Leg Raise</b>
  <th><b>Trunk Stability Push Up</b>
  <th><b>Rotary Stability</b>
  <th><b>Total Score</b>
  </tr>

EOF
  ;

  my $num_rows = 0;
  my $db_data;

  while ($db_data = $sth->fetchrow_hashref) {
    $num_rows++;
    $sum_ds_score += $db_data->{'ds_score'};
    my $min_ihs_score = 0;
    if ($db_data->{'ihs_score_right'} < $db_data->{'ihs_score_left'}) { $min_ihs_score = $db_data->{'ihs_score_right'}; } else { $min_ihs_score = $db_data->{'ihs_score_left'}; }
    $sum_ihs_score += $min_ihs_score;
    my $min_il_score = 0;
    if ($db_data->{'il_score_right'} < $db_data->{'il_score_left'}) { $min_il_score = $db_data->{'il_score_right'}; } else { $min_il_score = $db_data->{'il_score_left'}; }
    $sum_il_score += $min_il_score;
    my $min_sm_score = 0;
    if ($db_data->{'sm_score_right'} < $db_data->{'sm_score_left'}) { $min_sm_score = $db_data->{'sm_score_right'}; } else { $min_sm_score = $db_data->{'sm_score_left'}; }
    $sum_sm_score += $min_sm_score;
    my $min_aslr_score = 0;
    if ($db_data->{'aslr_score_right'} < $db_data->{'aslr_score_left'}) { $min_aslr_score = $db_data->{'aslr_score_right'}; } else { $min_aslr_score = $db_data->{'aslr_score_left'}; }
    $sum_aslr_score += $min_aslr_score;
    $sum_tspu_score += $db_data->{'tspu_score'};
    my $min_ri_score = 0;
    if ($db_data->{'ri_score_right'} < $db_data->{'ri_score_left'}) { $min_ri_score = $db_data->{'ri_score_right'}; } else { $min_ri_score = $db_data->{'ri_score_left'}; }
    $sum_ri_score += $min_ri_score;

    my $total_score = 0;
    $total_score += $db_data->{'ds_score'};
    $total_score += $min_ihs_score;
    $total_score += $min_il_score;
    $total_score += $min_sm_score;
    $total_score += $min_aslr_score;
    $total_score += $min_ri_score;
    $total_score += $db_data->{'tspu_score'};

    $sum_total_score += $total_score;

    $avg_ds_score = $sum_ds_score / $num_rows;
    $avg_ihs_score = $sum_ihs_score / $num_rows;
    $avg_il_score = $sum_il_score / $num_rows;
    $avg_sm_score = $sum_sm_score / $num_rows;
    $avg_aslr_score = $sum_aslr_score / $num_rows;
    $avg_tspu_score = $sum_tspu_score / $num_rows;
    $avg_ri_score = $sum_ri_score / $num_rows;
    $avg_total_score = $sum_total_score / $num_rows;

    push(@ds_data_list, $avg_ds_score);
    push(@ihs_data_list, $avg_ihs_score);
    push(@il_data_list, $avg_il_score);
    push(@sm_data_list, $avg_sm_score);
    push(@aslr_data_list, $avg_aslr_score);
    push(@tspu_data_list, $avg_tspu_score);
    push(@ri_data_list, $avg_ri_score);
    push(@total_data_list, $avg_total_score);

  }

  for (my $i = 0; $i < @date_data_list; $i++) {
print <<EOF;
    <tr>
    <td>$date_data_list[$i]</td>
    <td>$ds_data_list[$i]</td>
    <td>$ihs_data_list[$i]</td>
    <td>$il_data_list[$i]</td>
    <td>$sm_data_list[$i]</td>
    <td>$aslr_data_list[$i]</td>
    <td>$tspu_data_list[$i]</td>
    <td>$ri_data_list[$i]</td>
    <td>$total_data_list[$i]</td>
    </tr>
EOF
    ;
  }

  my $ds_data = join (',', @ds_data_list);   $ds_data =~ s/ /+/g;  # HTTPize
  my $ihs_data = join (',', @ihs_data_list);   $ihs_data =~ s/ /+/g;  # HTTPize
  my $il_data = join (',', @il_data_list);   $il_data =~ s/ /+/g;  # HTTPize
  my $sm_data = join (',', @sm_data_list);   $sm_data =~ s/ /+/g;  # HTTPize
  my $aslr_data = join (',', @aslr_data_list);   $aslr_data =~ s/ /+/g;  # HTTPize
  my $tspu_data = join (',', @tspu_data_list);   $tspu_data =~ s/ /+/g;  # HTTPize
  my $ri_data = join (',', @ri_data_list);   $ri_data =~ s/ /+/g;  # HTTPize
  my $total_data = join (',', @total_data_list);   $total_data =~ s/ /+/g;  # HTTPize
  my $date_data = join (',', @date_data_list);   $date_data =~ s/ /+/g;  # HTTPize

  my $graph_type;

  if ((@date_data_list) == 1) {
    $graph_type = "BAR";
  } else {
    $graph_type = "LINE";
  }

print <<EOF;

  </table>

  <br><br>

  <div align="center">
  Deep Squat Score<br><img src="/bin/graph2.pl?GRAPH_TYPE=$graph_type&XDATA=$date_data&YDATA=$ds_data" width="600" height="450"><br><br>
  Hurdle Step Score<br><img src="/bin/graph2.pl?GRAPH_TYPE=$graph_type&XDATA=$date_data&YDATA=$ihs_data" width="600" height="450"><br><br>
  In-Line Lunge Score<br><img src="/bin/graph2.pl?GRAPH_TYPE=$graph_type&XDATA=$date_data&YDATA=$il_data" width="600" height="450"><br><br>
  Shoulder Mobility Score<br><img src="/bin/graph2.pl?GRAPH_TYPE=$graph_type&XDATA=$date_data&YDATA=$sm_data" width="600" height="450"><br><br>
  Active Straight Leg Raise Score<br><img src="/bin/graph2.pl?GRAPH_TYPE=$graph_type&XDATA=$date_data&YDATA=$aslr_data" width="600" height="450"><br><br>
  Trunk Stability Push Up Score<br><img src="/bin/graph2.pl?GRAPH_TYPE=$graph_type&XDATA=$date_data&YDATA=$tspu_data" width="600" height="450"><br><br>
  Rotary Stability Score<br><img src="/bin/graph2.pl?GRAPH_TYPE=$graph_type&XDATA=$date_data&YDATA=$ri_data" width="600" height="450"><br><br>
  Total Score<br><img src="/bin/graph2.pl?GRAPH_TYPE=$graph_type&XDATA=$date_data&YDATA=$total_data" width="600" height="450"><br>
  </div>

  <br>

  <hr>

  </center>

EOF
  ;

  $sth->finish;

}
