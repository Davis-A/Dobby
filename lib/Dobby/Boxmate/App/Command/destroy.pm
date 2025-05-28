package Dobby::Boxmate::App::Command::destroy;
use Dobby::Boxmate::App -command;

# ABSTRACT: destroy a box

use v5.36.0;
use utf8;

sub abstract { 'destroy a box' }

sub opt_spec {
  return (
    [ finder => hidden => {
      default  => 'by_prefix',
      one_of   => [
        [ 'by-prefix' => 'find box by prefix of default domain' ],
        [ 'by-id|I'   => 'find box by Droplet id' ],
        [ 'by-name|N' => 'find box by Droplet name' ],
      ],
    } ],
    [],
    [ 'ip=s',  'only destroy if the public IP is this' ],
    [ 'force', 'destroy without consulting the mollyguard' ],
  );
}

sub usage_desc {
  '%c destroy %o BOXPREFIX',
}

sub validate_args ($self, $opt, $args) {
  @$args == 1 || $self->usage->die;
}

sub execute ($self, $opt, $args) {
  my $boxman  = $self->boxman;
  my $locator = $args->[0];

  my $method = "_find_" . $opt->finder;

  my @droplets = $self->$method($opt, $locator);

  if ($opt->ip) {
    @droplets = grep {
      $opt->ip eq $self->boxman->_ip_address_for_droplet($_) # XXX _method
    } @droplets;
  }

  unless (@droplets) {
    die "I couldn't find the box you want to destroy.\n";
  }

  if (@droplets > 1) {
    $self->print_droplet_list(\@droplets, undef);
    say "";

    die "More than one box matched your criteria.\n";
  }

  my $droplet = $droplets[0];

  unless ($opt->force) {
    my $ok = $boxman->check_mollyguard($droplet)->get;

    unless ($ok) {
      die qq{Refusing to destroy box because "fmdev mollyguard" objected.\n}
        . qq{You can use --force to bypass this, or fix mollyguard's complaints.\n};
    }
  }

  $boxman->destroy_droplet($droplet, { force => 1 })->get;
}

sub _find_by_prefix ($self, $opt, $locator) {
  return grep {; defined } $self->maybe_droplet_from_prefix($locator);
}

sub _find_by_id ($self, $opt, $locator) {
  $opt->ip || die "You can't destroy a box by id without --ip for safety.\n";
  return grep {; defined } $self->boxman->dobby->get_droplet_by_id($locator)->get;
}

sub _find_by_name ($self, $opt, $locator) {
  my @droplets = $self->boxman->dobby->get_droplets_by_name($locator)->get;
  return @droplets;
}

1;
