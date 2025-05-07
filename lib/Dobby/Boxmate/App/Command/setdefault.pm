package Dobby::Boxmate::App::Command::setdefault;
use Dobby::Boxmate::App -command;

# ABSTRACT: pick a box as your default

use v5.36.0;
use utf8;

sub command_names { qw(setdefault set-default) }

sub abstract { 'pick a box as your default' }

sub usage_desc {
  '%c setdefault %o [IDENT]',
}

sub opt_spec {
  return (
    [ 'clear', "don't pick any box, clear your default" ],
  );
}

sub validate_args ($self, $opt, $args) {
  if ($opt->clear && @$args) {
    die "You can't supply a box label with --clear.\n";
  }

  if (!$opt->clear && !@$args) {
    $self->usage->die;
  }
}

sub execute ($self, $opt, $args) {
  if ($opt->clear) {
    return $self->_clear_default_box;
  }

  return $self->_set_default_box_to($args->[0]);
}

sub _clear_default_box ($self) {
  my $config = $self->app->config;
  my $boxman = $self->boxman;

  my $username = $config->username;
  my $domain   = $config->box_domain;

  my @records = $boxman->dobby->get_all_domain_records_for_domain($domain)->get;
  my ($cname) = grep {; $_->{type} eq 'CNAME' && $_->{name} eq $username }
                @records;

  unless ($cname) {
    say "No default found, so nothing to do.";
    return;
  }

  my @sequence = [ DELETE => "/domains/$domain/records/$cname->{id}" ];
  $boxman->dobby->_execute_http_sequence(\@sequence)->get;

  say "Default cleared.";
  return;
}

sub _set_default_box_to ($self, $label) {
  my $config = $self->app->config;
  my $boxman = $self->boxman;

  my $username = $config->username;
  my $domain   = $config->box_domain;

  my $droplet = $boxman->_get_droplet_for($username, $label)->get;
  my $name    = "$label.$username.$domain";

  unless ($droplet) {
    die "Can't find a box named $name.\n";
  }

  $droplet->{name} eq $name
    || die "Internal expectations violated in droplet naming! Giving up, sorry!\n";

  $boxman->dobby->point_domain_record_at_name($domain, $username, "$name.")->get;
  say "\N{SPARKLES} Default box updated.";
}

1;
