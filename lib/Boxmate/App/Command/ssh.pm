package Boxmate::App::Command::ssh;
use Boxmate::App -command;

# ABSTRACT: ssh to a box

use v5.36.0;
use utf8;

sub abstract { 'ssh to a box' }

sub usage_desc {
  '%c %o BOXPREFIX',
}

sub validate_args ($self, $opt, $args) {
  @$args == 1 || $self->usage->die;
}

sub opt_spec {
  return (
    [ 'ssh-user=s', 'ssh as this user', { default => 'root' } ],
  );
}

sub execute ($self, $opt, $args) {
  my $config = $self->app->config;
  my $boxman = $self->boxman;

  my $droplet = $self->droplet_from_prefix($args->[0]);
  my $ssh_user = $opt->ssh_user;

  my $ip = $boxman->_ip_address_for_droplet($droplet);
  my @cmd = (
    qw(
      ssh
        -o UserKnownHostsFile=/dev/null
        -o StrictHostKeyChecking=no
        -o SendEnv=FM_*
    ),
    "$ssh_user\@$ip",
  );

  exec @cmd;

  die "Couldn't exec ssh: $!\n";
}

1;
