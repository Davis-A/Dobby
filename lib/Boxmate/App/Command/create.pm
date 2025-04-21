package Boxmate::App::Command::create;
use Boxmate::App -command;

use v5.36.0;
use utf8;

sub abstract { 'create a box' }

sub opt_spec {
  return (
    [ 'region=s',     'what region to create the box in' ],
    [ 'size|s=s',     'DigitalOcean slug for the Droplet size' ],
    [ 'version|v=s',  'image version to use' ],
    [ 'tag|t=s',      'box tag (in user-foo, the "foo")' ],
    [],
    [ 'debian',       "don't make a Fastmail-in-a-box, just Debian" ],
    [],
    [ 'make-default|D', 'make this your default box in DNS' ],
  );

  # [ 'username|u=s'    => (is => 'ro', isa => 'Str',     required => 1);
  # [ project_id  => (is => 'ro', isa => 'Maybe[Str]');

  # has is_default_box   => (is => 'ro', isa => 'Bool', default => 0);
  # has run_custom_setup => (is => 'ro', isa => 'Bool', default => 0);
  # has setup_switches   => (is => 'ro', isa => 'Maybe[ArrayRef]');
}

my %INABOX_SPEC = (
  project_id => q{d733cd68-8069-4815-ad49-e557a870ac0a},
  extra_tags => [ 'fminabox' ],
);

sub execute ($self, $opt, $args) {
  my $config = $self->app->config;
  my $boxman = $self->boxman;

  my $spec = Synergy::BoxManager::ProvisionRequest->new({
    version   => $opt->version // $config->version,
    tag       => $opt->tag,
    size      => $opt->size // $config->size,
    username  => $config->username,
    region    => $opt->region // $config->region,

    ($opt->debian
      ? (run_standard_setup => 0, run_custom_setup => 0, image_id => 'debian-12-x64')
      : (%INABOX_SPEC)),

    ssh_key_id  => $config->ssh_key_id,
    digitalocean_ssh_key_name => $config->digitalocean_ssh_key_name,

    is_default_box   => $opt->make_default,
  });

  my $droplet = $boxman->create_droplet($spec)->get;
}

1;
