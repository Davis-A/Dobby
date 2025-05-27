package Dobby::Boxmate::App::Command::ssh;
use Dobby::Boxmate::App -command;

# ABSTRACT: ssh to a box

use v5.36.0;
use utf8;

sub abstract { 'ssh to a box' }

sub usage_desc {
  '%c ssh %o [IDENT]',
}

sub validate_args ($self, $opt, $args) {
  @$args >= 1 || $self->usage->die;
}

sub opt_spec {
  return (
    [ 'username=s', 'ssh to a box for this user', ],
    [ 'ssh-user=s', 'ssh as this user', { default => 'root' } ],
  );
}

sub execute ($self, $opt, $args) {
  my $config = $self->app->config;
  my $boxman = $self->boxman;

  my $username = $opt->username // $config->username;
  my $domain   = $config->box_domain;

  my $label;
  my @ssh_args;

  if (@$args) {
    ($label, @ssh_args) = @$args;
  } else {
    my @records = $boxman->dobby->get_all_domain_records_for_domain($domain)->get;
    my ($cname) = grep {; $_->{type} eq 'CNAME' && $_->{name} eq $username }
                  @records;

    unless ($cname) {
      die "No default box record for $username exists.\n";
    }

    my $name = $cname->{data};
    ($label) = $name =~ /\A([-_a-z0-9]+)\.\Q$username\E\.\Q$domain\E\z/;

    unless ($label) {
      die "The default box record for $username points to $name, which is not in the expected format.  Giving up.\n";
    }
  }

  my $droplet = $boxman->_get_droplet_for($username, $label)->get;

  unless ($droplet) {
    die "No droplet for $label.$username exists.\n";
  }

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
    @ssh_args,
  );

  exec @cmd;

  die "Couldn't exec ssh: $!\n";
}

1;
