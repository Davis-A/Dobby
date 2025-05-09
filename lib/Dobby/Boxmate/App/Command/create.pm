package Dobby::Boxmate::App::Command::create;
use Dobby::Boxmate::App -command;

# ABSTRACT: create a box

use v5.36.0;
use utf8;

sub abstract { 'create a box' }

sub opt_spec {
  return (
    [ 'region=s',     'what region to create the box in' ],
    [ 'size|s=s',     'DigitalOcean slug for the Droplet size' ],
    [ 'version|v=s',  'image version to use' ],
    [ 'label|l=s',    'box label (the part before username)', { required => 1 } ],
    [],
    [ 'type' => 'hidden' => {
        default => 'inabox',
        one_of  => [
          [ 'inabox',       "create a Fastmail-in-a-box (default behavior)" ],
          [ 'debian',       "don't make a Fastmail-in-a-box, just Debian" ],
          [ 'docker',       "don't make a Fastmail-in-a-box, just Docker" ],
        ]
      }
    ],
    [],
    [ 'make-default|D', 'make this your default box in DNS' ],
    [],
    [ 'custom-setup!', 'run per-user setup on inabox; default on inabox' ],
  );
}

sub validate_args ($self, $opt, $args) {
  unless (defined $opt->custom_setup) {
    # Okay, this is a bit underhanded, but it's gonna work.  I know the author
    # of the library…
    $opt->{custom_setup} = $opt->type eq 'inabox' ? 1 : 0;
  }

  if ($opt->custom_setup && $opt->type ne 'inabox') {
    die "You can only use --custom-setup with --inabox.\n";
  }

  if (@$args && ! $opt->custom_setup) {
    die "You provided args for custom setup, but custom setup isn't enabled.\n";
  }
}

my %INABOX_SPEC = (
  project_id => q{d733cd68-8069-4815-ad49-e557a870ac0a},
  extra_tags => [ 'fminabox' ],
);

sub execute ($self, $opt, $args) {
  my $config = $self->app->config;
  my $boxman = $self->boxman;

  my $spec = Dobby::BoxManager::ProvisionRequest->new({
    version   => $opt->version // $config->version,
    label     => $opt->label,
    size      => $opt->size // $config->size,
    username  => $config->username,
    region    => $opt->region // $config->region,

    ($opt->debian ? (run_standard_setup => 0, image_id => 'debian-12-x64')
    :$opt->docker ? (run_standard_setup => 0, image_id => 'docker-20-04')
    :               (%INABOX_SPEC)),

    run_custom_setup => $opt->custom_setup,
    setup_switches   => [ @$args ],

    ssh_key_id  => $config->ssh_key_id,
    digitalocean_ssh_key_name => $config->digitalocean_ssh_key_name,

    is_default_box   => $opt->make_default,
  });

  my $droplet = $boxman->create_droplet($spec)->get;
}

1;
