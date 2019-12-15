#!/usr/bin/perl
#    URL extractor
#    Copyright (C) 2019 Dale Glass <dale@daleglass.net>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

use warnings;
use strict;
use URI::Find;
use File::Slurp;
use File::Find;
use Getopt::Long;


my $scan_everything;
my $dir;
my $quiet;
my $help;
my $url_filter;
my $download;

sub msg {
	print STDERR shift unless ($quiet);
}


GetOptions(
	"scan-everything" => \$scan_everything,
	"quiet|q"         => \$quiet,
	"url_filter|u=s"  => \$url_filter,
	"download"        => \$download,
	"help|h"          => \$help
) or $help = 1;


if ( $help ) {
	print <<HELP;
$0 [options] [directory]
Extracts URLs from codebase
Copyright (C) Dale Glass <dale\@daleglass.net>


This tool is made specifically for the High Fidelity migration.

Options:
	--scan-everything: Scan every non-binary file. Otherwise only examines
	files used by CMake.

	--url_filter=name: Filter URLs using one of the predefined filters:
		hifi    : Anything with 'hifi' or 'highfidelity' in it that is
                          a file that can be downloaded
		content : hifi-content
		public  : hifi-public
		cmake   : files downloaded by CMake

	--quiet: Don't output progress info

	--download: Download selected files using wget

HELP
exit(1);
}



$| =1;
$dir = $ARGV[0] // ".";
my @file_list;
my $url_filters = {
	public => [
		qr/hifi-public/
	],
	content => [
		qr/hifi-content/
	],
	hifi => [
		qr/hifi|fidelity/,
		qr/^(?!(?s:.*)git:)/,
		qr/^(?!(?s:.*)(debian|docs|foo.bar|qa|wiki|metaverse|thunder|deployment|forums|ping|staging|thunder|orgs)\.highfidelity)/,
		qr/^(?!(?s:.*)(gitter.im|hifi-qa|hifi.place|atlassian|knowledge|hq-support|termsofservice|google.com|fogbugz|backtrace.io|auth|manuscript.com|testrail.net|\/user|\/api))/
	],
	cmake => [
		qr/public.highfidelity.com|hifi-public.s3.amazonaws.com/,
		qr/\.(zip|tar|tgz|tbz2)/
	]
};


msg "Finding files... ";
find(\&file_wanted, $dir);
msg "done, " . scalar(@file_list) . " files found\n";


msg "Parsing files...\n";
my $finder = URI::Find->new(\&uri_found);
my %found;
my @download_list;

my $num = 0;
foreach my $file (@file_list) {
	$num++;
	msg "\r$num of " . scalar(@file_list) . " ";

	my $contents = read_file($file, err_mode => 'croak');
	$finder->find(\$contents);
}
msg "\n";


foreach my $uri ( sort keys %found ) {
	my $failed=0;

	if ( $url_filter ) {
		# All filters must match
		foreach my $f ( @{ $url_filters->{$url_filter} } ) {
			if ( $uri !~ $f ) {
				$failed = 1;
				last;
			}
		}
	}

	if ( !$failed) {
		print "$uri\n";
		push @download_list, $uri;
	}
}

if ( $download ) {
	my @wget_args;

	foreach my $uri (@download_list) {
		push @wget_args, $uri;

		if ( length(join(' ', @wget_args)) >= 65535 ) {
			system("wget", "-4", "-c", "-x", @wget_args);
			@wget_args = ();
		}
	}

	system("wget", "-4", "-c", "-x", @wget_args);
}






sub file_wanted {
	my $continue=0;
#	print "F: $_\n";

	# We only care about files
	return unless ( -f "$_" );

	# Skip ctags files, these contain redundant data.
	return if /^tags$/;

	# Only check these files
	if ( $scan_everything ) {
		# Skip binary files
		return if ( -B "$_" );
	} else {
		return unless ( /(CMakeLists.txt|cmake|hifi_qt.py|hifi_vcpkg.py)$/ );
	}

	push @file_list, $File::Find::name;
}

sub uri_found {
	my ($uri) = @_;

	# Skip URLs to things we don't care about
	return "" if ( $uri =~ /^(file|data|urn|mailto|pop|ssh):/i );

	$found{$uri}++;
}


