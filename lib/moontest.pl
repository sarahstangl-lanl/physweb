#!/usr/bin/perl

use strict;
use warnings;

use lib '/home/admin/nick/git/physics/lib';
use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::Format::Strptime;
use Astro::Coord::ECI;
use Astro::Coord::ECI::Moon;
use Astro::Coord::ECI::Utils qw{deg2rad};

my $times;
my $data = "
       Jan.       Feb.       Mar.       Apr.       May        June       July       Aug.       Sept.      Oct.       Nov.       Dec.  
Day Rise  Set  Rise  Set  Rise  Set  Rise  Set  Rise  Set  Rise  Set  Rise  Set  Rise  Set  Rise  Set  Rise  Set  Rise  Set  Rise  Set
     h m  h m   h m  h m   h m  h m   h m  h m   h m  h m   h m  h m   h m  h m   h m  h m   h m  h m   h m  h m   h m  h m   h m  h m
01  1140 0036  1145 0223  1110 0202  1259 0244  1411 0213  1650 0212  1806 0219  1906 0431  1859 0651  1823 0749  1852 0931  1926 0943
02  1206 0137  1228 0320  1204 0251  1408 0316  1525 0241  1807 0252  1905 0319  1938 0543  1925 0756  1854 0850  1942 1020  2026 1019
03  1235 0238  1320 0413  1304 0335  1520 0346  1641 0310  1920 0339  1954 0427  2006 0653  1952 0859  1930 0949  2035 1104  2127 1051
04  1309 0338  1418 0501  1410 0414  1635 0415  1800 0342  2025 0436  2035 0540  2032 0801  2022 1001  2011 1045  2133 1143  2231 1120
05  1350 0437  1523 0543  1520 0449  1752 0444  1919 0419  2119 0541  2109 0653  2057 0907  2055 1102  2057 1138  2234 1218  2336 1147
06  1437 0532  1632 0621  1632 0520  1911 0515  2035 0504  2204 0652  2138 0805  2123 1011  2132 1200  2148 1225  2338 1249       1214
07  1532 0624  1743 0653  1747 0550  2030 0550  2143 0556  2240 0805  2205 0914  2151 1114  2215 1255  2244 1307       1318  0043 1242
08  1634 0709  1856 0723  1903 0619  2147 0630  2242 0657  2311 0916  2230 1020  2221 1215  2303 1346  2344 1345  0043 1346  0152 1311
09  1741 0749  2010 0752  2020 0648  2258 0717  2330 0805  2338 1025  2255 1124  2255 1315  2357 1432       1419  0151 1413  0305 1345
10  1850 0823  2125 0819  2138 0720       0812       0915       1131  2321 1226  2335 1412       1513  0048 1450  0302 1443  0419 1425
11  2001 0854  2240 0848  2254 0756  0000 0914  0009 1025  0003 1234  2349 1328       1505  0056 1550  0154 1519  0415 1516  0535 1513
12  2112 0922  2355 0920       0837  0052 1021  0042 1133  0027 1337       1428  0020 1555  0200 1623  0303 1548  0532 1553  0647 1610
13  2224 0949       0956  0007 0925  0135 1129  0110 1238  0052 1438  0021 1526  0112 1639  0306 1653  0414 1617  0649 1638  0752 1717
14  2337 1016  0108 1038  0112 1021  0210 1236  0135 1342  0118 1538  0057 1622  0209 1718  0415 1722  0528 1648  0803 1732  0847 1829
15       1044  0217 1128  0209 1123  0240 1342  0159 1444  0147 1637  0139 1714  0311 1753  0526 1750  0644 1724  0912 1834  0933 1944
16  0051 1116  0319 1225  0256 1229  0306 1446  0223 1545  0220 1735  0227 1802  0417 1825  0639 1820  0801 1804  1010 1943  1011 2057
17  0205 1154  0412 1329  0335 1336  0330 1549  0248 1646  0259 1830  0322 1844  0525 1854  0753 1852  0916 1853  1059 2054  1043 2208
18  0317 1238  0457 1436  0408 1443  0354 1651  0315 1746  0343 1920  0421 1921  0634 1922  0908 1929  1026 1949  1139 2206  1112 2316
19  0425 1331  0534 1545  0436 1549  0418 1752  0345 1845  0434 2005  0525 1954  0745 1950  1022 2011  1128 2052  1213 2315  1139     
20  0526 1433  0606 1653  0502 1653  0444 1852  0420 1941  0530 2045  0631 2024  0856 2019  1133 2100  1220 2159  1243       1205 0021
21  0617 1540  0633 1759  0526 1756  0512 1952  0500 2034  0631 2120  0738 2052  1009 2052  1238 2157  1303 2308  1309 0022  1232 0124
22  0700 1650  0658 1904  0550 1858  0544 2051  0547 2123  0735 2151  0847 2118  1122 2129  1335 2300  1340       1335 0127  1300 0226
23  0735 1800  0722 2007  0614 2000  0620 2147  0639 2206  0840 2220  0956 2146  1234 2212  1423       1411 0017  1401 0230  1331 0326
24  0805 1909  0746 2109  0640 2101  0702 2238  0737 2244  0947 2246  1107 2215  1343 2303  1503 0007  1439 0124  1428 0332  1407 0424
25  0832 2015  0811 2211  0709 2200  0750 2325  0838 2317  1055 2313  1219 2248  1445       1538 0116  1505 0230  1457 0433  1447 0520
26  0856 2119  0838 2311  0742 2258  0844       0942 2347  1205 2341  1332 2327  1539 0001  1608 0225  1531 0334  1530 0533  1533 0613
27  0919 2221  0908       0820 2353  0943 0006  1048       1317       1444       1625 0106  1635 0332  1557 0437  1607 0631  1624 0701
28  0943 2323  0942 0011  0904       1046 0043  1156 0015  1431 0011  1551 0012  1704 0215  1701 0438  1624 0539  1649 0726  1720 0743
29  1008       1023 0108  0955 0043  1152 0115  1306 0042  1545 0047  1652 0107  1737 0326  1727 0543  1655 0641  1737 0817  1819 0821
30  1036 0024             1051 0128  1300 0145  1418 0109  1658 0129  1745 0210  1806 0436  1754 0646  1729 0740  1830 0903  1920 0855
31  1107 0124             1153 0209             1533 0139             1829 0319  1833 0544             1808 0838             2023 0925
";
for (split("\n", $data)) {
    if ($_ =~ /^(\d{2})/) {
        my $day = $1 + 0;
        for (my $month = 1; $month < 13; $month++) {
            my $rise = substr($_, 4 + 11*($month-1), 4);
            my $set = substr($_, 9 + 11*($month-1), 4);
            $rise = undef if ($rise eq '    ');
            $set = undef if ($set eq '    ');
            $times->{given}->{$month}->{$day}->{rise} = $rise;
            $times->{given}->{$month}->{$day}->{set} = $set;
        }
#        printf "%2s  %4s %4s\n", $1, $2, $3;
    }
}
#print Dumper($times);
#exit;
my $lat = deg2rad (44.58);    # Radians
my $long = deg2rad (-93.16);  # Radians
my $alt = 259 / 1000;        # Kilometers
my $sta = Astro::Coord::ECI->new(refraction => 1)->geodetic($lat, $long, $alt);
my $hour_dur = DateTime::Duration->new(hours => 1);
my $sec_dur = DateTime::Duration->new(seconds => 30);
for (my $month = 1; $month < 13; $month++) {
    for (my $i = 1; $i <= 31; $i++) {
        my ($moon, $dt);
        eval {
            $dt = DateTime->new(year => 2012, month => $month, day => $i, time_zone => '-0600');
            $moon = Astro::Coord::ECI::Moon->new(station => $sta)->universal($dt->epoch);
        };
        if ($@) {
#            warn "$@";
            next;
        }
        my @alm = $moon->almanac_hash;
        my $rise = undef;
        my $set = undef;
        for (@alm) {
            next unless ($_->{almanac}->{event} eq 'horizon');
            my $event_dt = DateTime->from_epoch(time_zone => '-0600', epoch => $_->{time});
            if ($event_dt->is_dst) {
                $event_dt->subtract_duration($hour_dur);
            }
            if ($event_dt->sec > 0) {
                $event_dt->add_duration($sec_dur);
            }
            my $time = $event_dt->strftime("%H%M");
            if ($_->{almanac}->{detail} == 0) {
                $set = $time;
            }
            elsif ($_->{almanac}->{detail} == 1) {
                $rise = $time;
            }
        }
        $times->{calc}->{$month}->{$i}->{rise} = $rise;
        $times->{calc}->{$month}->{$i}->{set} = $set;
        printf "%02s%02s  %4s %4s %4s %4s\n", $dt->month, $dt->day, $rise || '', $times->{given}->{$month}->{$i}->{rise} || '', $set || '', $times->{given}->{$month}->{$i}->{set} || '';
    }
}
#print Dumper($times);
#exit;
my $strp = DateTime::Format::Strptime->new(pattern => '%H%M', time_zone => '-0600');
my $diffs;
my $diff = sub {
    my $type = shift;
    my $month = shift;
    my $day = shift;
#    warn Dumper({ "$day$month-$type: " => { given => $times->{given}->{$month}->{$day}->{$type}, calc => $times->{calc}->{$month}->{$day}->{$type} } });
    if ((! defined $times->{calc}->{$month}->{$day}->{$type} || $times->{calc}->{$month}->{$day}->{$type} eq '') && ! defined $times->{given}->{$month}->{$day}->{$type}) {
        $diffs->{0}++;
        return "OK";
    }
    elsif (! defined $times->{calc}->{$month}->{$day}->{$type} && defined $times->{given}->{$month}->{$day}->{$type}) {
        return '!Calc';
    }
    elsif (! defined $times->{given}->{$month}->{$day}->{$type} && defined $times->{calc}->{$month}->{$day}->{$type}) {
        return '!Given';
    }
    elsif ($times->{calc}->{$month}->{$day}->{$type} =~ /\d/ && $times->{given}->{$month}->{$day}->{$type} =~ /\d/) {
        my $calc = $strp->parse_datetime($times->{calc}->{$month}->{$day}->{$type});
        my $given = $strp->parse_datetime($times->{given}->{$month}->{$day}->{$type});
        my $diff = $calc->subtract_datetime($given);
        $diffs->{$diff->delta_minutes}++;
        return $diff->delta_minutes || 'OK';
    }
    else {
#        warn "Error for $month-$day $type";
#        warn Dumper({ given => $times->{given}->{$month}->{$day}->{$type}, calc => $times->{calc}->{$month}->{$day}->{$type} });
        return 'err';
    }
};
for (my $day = 1; $day <= 31; $day++) {
    printf "%02d  ", $day;
    for (my $month = 0; $month < 13; $month++) {
        printf "%6s %6s  ", $diff->('rise', $month, $day), $diff->('set', $month, $day);
    }
    print "\n";
}
warn Dumper($diffs);
#my ($time, $rise) = $sta->next_elevation ($moon);
#print "Moon @{[$rise ? 'rise' : 'set']} is ",
#scalar localtime $time, "\n";
