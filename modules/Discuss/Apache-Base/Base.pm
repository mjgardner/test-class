package Discuss::Apache::Base;
use strict;
use warnings;

use Template;
use Discuss::Exceptions qw(throw_template_error);
use Apache::Constants qw(:common);
use File::Spec;
use Apache::Log;

our $VERSION = '0.13';

sub plugin_base { 'Discuss::Plugin::User' };

my %Template;
sub template {
	my ($class, $r) = @_;
	$Template{$class->plugin_base} ||= Template->new(
		TRIM			=>	1,
		INCLUDE_PATH	=>	$r->document_root . "/",
		COMPILE_EXT		=>	'.ttc',
		COMPILE_DIR		=>	"/tmp/ttc-$>",
		PLUGIN_BASE		=>	$class->plugin_base,
		DEBUG			=>	0,
	) or throw_template_error error => Template->error;
};

sub handler($$) {
	my ($class, $r) = @_;
	eval {
		$r->no_cache(1);
		$r->content_type('text/html');
		my $output;
		unless ($r->header_only) {
			local $Discuss::Base::Escape_html = 1;
			my $tt = $class->template($r);
			my $relative_path =
				File::Spec->abs2rel($r->filename, $r->document_root);
			$r->log->info('processing template ' . $r->filename);
			$tt->process(
				$relative_path, 
				{ _request => $r },
				\$output
			) or throw_template_error 
				template => $relative_path, error => $tt->error;
		};
		$r->send_http_header;
		$r->print( $output ) if defined($output);
	}; if ($@) {
		$r->log_reason($@, $r->filename);
		return SERVER_ERROR;
	};	
	return OK;
};

1;
