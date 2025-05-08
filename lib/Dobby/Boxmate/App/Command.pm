package Dobby::Boxmate::App::Command;
use parent 'App::Cmd::Command';

# ABSTRACT: the base class for box commands

use v5.36.0;

sub boxman ($self) {
  $self->app->boxman;
}

sub maybe_droplet_from_prefix ($self, $boxprefix) {
  length $boxprefix
    || $self->usage->die({ pre_text => "No box prefix provided.\n\n" });

  my $boxman = $self->boxman;

  my $username = $self->app->config->username;
  my $droplets = $boxman->get_droplets_for($username)->get;

  my $want_name = join q{.}, $boxprefix, $username, $boxman->box_domain;
  my ($droplet) = grep {; $_->{name} eq $want_name } @$droplets;

  return $droplet;
}

sub droplet_from_prefix ($self, $boxprefix) {
  my $droplet = $self->maybe_droplet_from_prefix($boxprefix);

  unless ($droplet) {
    die "Couldn't find box for $boxprefix\n";
  }

  return $droplet;
}

1;
