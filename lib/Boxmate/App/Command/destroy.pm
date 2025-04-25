package Boxmate::App::Command::destroy;
use Boxmate::App -command;

# ABSTRACT: destroy a box

use v5.36.0;
use utf8;

sub abstract { 'destroy a box' }

sub usage_desc {
  '%c destroy %o BOXPREFIX',
}

sub validate_args ($self, $opt, $args) {
  @$args == 1 || $self->usage->die;
}

sub execute ($self, $opt, $args) {
  my $boxman  = $self->boxman;
  my $droplet = $self->droplet_from_prefix($args->[0]);

  $boxman->destroy_droplet($droplet, { force => 1 })->get;
}

1;
