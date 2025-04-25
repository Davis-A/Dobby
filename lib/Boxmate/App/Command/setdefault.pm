package Boxmate::App::Command::setdefault;
use Boxmate::App -command;

# ABSTRACT: pick a box as your default

use v5.36.0;
use utf8;

sub abstract { 'pick a box as your default' }

sub usage_desc {
  '%c %o [IDENT]',
}

sub validate_args ($self, $opt, $args) {
  @$args == 1 || $self->usage->die;
}

sub execute ($self, $opt, $args) {
  my $config = $self->app->config;
  my $boxman = $self->boxman;

  my $username = $config->username;
  my $domain   = $config->box_domain;

  my $ident = $args->[0];

  my $droplet = $boxman->_get_droplet_for($username, $ident)->get;
  my $name    = "$ident.$username.$domain";

  unless ($droplet) {
    die "Can't find a box named $name.\n";
  }

  $droplet->{name} eq $name
    || die "Internal expectations violated in droplet naming! Giving up, sorry!\n";

  $boxman->dobby->point_domain_record_at_name($domain, $username, "$name.")->get;
  say "\N{SPARKLES} Default box updated.";
}

1;
