#-----------------------------------------------------------
# sysinternals.pl
# When a user installs and runs the SysInternals tools from MS,
# they have to accept a EULA in order to run the tools.  When they
# do, this creates a Registry key for the tool, with a value indicating
# that the EULA was accepted.
#
# Change history
#   20120925 - updated to RS format
#   20120608 - created
#
# References
#
# 
# copyright 2012 Quantum Analytics Research, LLC
# Author: H. Carvey, keydet89@yahoo.com
#-----------------------------------------------------------
package sysinternals;
use strict;

my %config = (hive          => "NTUSER\.DAT",
              hivemask      => 0x10,
              type          => "Reg",
              category      => "User Activity",
              class         => 1,
              output        => "report",
              hasShortDescr => 1,
              hasDescr      => 0,
              hasRefs       => 0,
              osmask        => 63,#XP - Win8
              version       => 20120925);

sub getConfig{return \%config}
sub getShortDescr {
	return "Checks for SysInternals apps keys";	
}
sub getDescr{}
sub getRefs {}
sub getHive {return $config{hive};}
sub getVersion {return $config{version};}

my $VERSION = getVersion();

sub pluginmain {
	my $class = shift;
	my $parent = ::getConfig();
	::logMsg("sysinternals v.".$VERSION);
	::rptMsg("-" x 60);
	::rptMsg("sysinternals v.".$VERSION);
	::rptMsg(getShortDescr());
	::rptMsg("Category: ".$config{category});
	::rptMsg("");
		
	my $profile = $parent->{userprofile};
	::rptMsg("Profile: ".$profile);
#	my @u = split(/\\/,$profile);
#	my $n = scalar(@u) - 1;
#	my $user = $u[$n];
	
	$profile .= "\\" unless ($profile =~ m/\\$/);	
	my $hive = $profile."NTUSER\.DAT";
	my $reg = Parse::Win32Registry->new($hive);
	my $root_key = $reg->get_root_key;

	my $key_path = 'Software\\SysInternals';
	my $key;
	if ($key = $root_key->get_subkey($key_path)) {
		::rptMsg("SysInternals");
		::rptMsg($key_path);
		::rptMsg("LastWrite Time ".gmtime($key->get_timestamp())." (UTC)");
		my @subkeys = $key->get_list_of_subkeys();
		if (scalar(@subkeys) > 0) {
			foreach my $s (@subkeys) { 
				::rptMsg($s->get_name()." [".gmtime($s->get_timestamp())." (UTC)]");
				
				my $eula;
				eval {
					$eula = $s->get_value("EulaAccepted")->get_data();
				};
				if ($@) {
					::rptMsg("  EulaAccepted value not found.");
				}
				else {
					::rptMsg("  EulaAccepted: ".$eula);
				}
				::rptMsg("");
			}
		}
		else {
			::rptMsg($key_path." has no subkeys.");
		}
	}
	else {
		::rptMsg($key_path." not found.");
	}
}

1;