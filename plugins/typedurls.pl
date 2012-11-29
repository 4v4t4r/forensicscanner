#! c:\perl\bin\perl.exe
#-----------------------------------------------------------
# typedurls.pl
# Plugin for Registry Ripper, NTUSER.DAT edition - gets the 
# TypedURLs values 
#
# Change history
#   20120925 - updated to RS format
#   20120827 - TLN version created
#   20080324 - created
#
# References
#   http://support.microsoft.com/kb/157729
#   http://msdn2.microsoft.com/en-us/library/aa908115.aspx
# 
# Notes:  Reportedly, only the last 20 entries are maintained;
#         Also, new entries aren't added to the key until the current
#         instance of IE is terminated.
# 
# copyright 2008 H. Carvey
#-----------------------------------------------------------
package typedurls;
use strict;

my %config = (hive          => "NTUSER\.DAT",
              hivemask      => 0x10,
              class         => 1,
              type          => "Reg",
              output        => "report",
              category      => "User Activity",
              hasShortDescr => 1,
              hasDescr      => 0,
              hasRefs       => 1,
              osmask        => 31, #XP-Win7
              version       => 20120925);

sub getConfig{return \%config}
sub getShortDescr {
	return "Returns contents of user's TypedURLs key.";	
}
sub getDescr{}
sub getRefs {
	my %refs = ("IESample Registry Settings" => 
	            "http://msdn2.microsoft.com/en-us/library/aa908115.aspx",
	            "How to clear History entries in IE" =>
	            "http://support.microsoft.com/kb/157729");
	return %refs;	
}
sub getHive {return $config{hive};}
sub getVersion {return $config{version};}

my $VERSION = getVersion();

sub pluginmain {
	my $class = shift;
	my $parent = ::getConfig();
	 
	::logMsg("typedpaths v.".$VERSION);
	::rptMsg("-" x 60);
	::rptMsg("typedpaths v.".$VERSION);
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
	
	my $key_path = 'Software\\Microsoft\\Internet Explorer\\TypedURLs';
	my $key;
	if ($key = $root_key->get_subkey($key_path)) {
		::rptMsg("TypedURLs");
		::rptMsg($key_path);
		::rptMsg("LastWrite Time ".gmtime($key->get_timestamp())." (UTC)");
		my @vals = $key->get_list_of_values();
		if (scalar(@vals) > 0) {
			my %urls;
# Retrieve values and load into a hash for sorting			
			foreach my $v (@vals) {
				my $val = $v->get_name();
				my $data = $v->get_data();
				my $tag = (split(/url/,$val))[1];
				$urls{$tag} = $val.":".$data;
			}
# Print sorted content to report file			
			foreach my $u (sort {$a <=> $b} keys %urls) {
				my ($val,$data) = split(/:/,$urls{$u},2);
				::rptMsg("  ".$val." -> ".$data);
			}
		}
		else {
			::rptMsg($key_path." has no values.");
			::logMsg($key_path." has no values.");
		}
	}
	else {
		::rptMsg($key_path." not found.");
		::logMsg($key_path." not found.");
	}
}

1;