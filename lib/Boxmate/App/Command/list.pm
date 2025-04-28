package Boxmate::App::Command::list;
use Boxmate::App -command;

# ABSTRACT: list your boxes

use v5.36.0;
use utf8;

no experimental 'builtin';

sub abstract { "list your boxes" }

sub opt_spec {
  return (
    [ 'username|u=s',  'boxes for some other user' ],
    [ 'everything',    'get every single droplet' ],
    [ 'name=s',        'only the named box' ],
    [],
    [ 'with-tag|T=s@', 'only boxes with this tag' ],
  );
}

sub validate_args ($self, $opt, $args) {
  my @exclusives;
  push @exclusives, grep {; $opt->$_ } qw(username everything name);

  if (@exclusives > 1) {
    die "These options are mutually exclusive: "
      . (join q{, }, map {; "--$_" } @exclusives)
      . "\n";
  }
}

sub execute ($self, $opt, $args) {
  my $config = $self->app->config;
  my $boxman = $self->boxman;

  my $username = $opt->username // $config->username;

  my $droplets;
  if ($opt->everything) {
    my @droplets = $boxman->dobby->get_all_droplets->get;
    @droplets = grep {; $_->{name} eq $opt->name } @droplets if $opt->name;
    $droplets = \@droplets;
  } else {
    $droplets = $boxman->get_droplets_for($username)->get;
  }

  if ($opt->with_tag) {
    my %want_tag = map {; $_ => 1 } $opt->with_tag->@*;

    @$droplets = grep {; my @tags = ($_->{tags} // [])->@*;
                         grep {; $want_tag{$_} } @tags } @$droplets;
  }

  unless (@$droplets) {
    say "📦 No boxes.";
    return;
  }

  require DateTime::Format::RFC3339;
  require Term::ANSIColor;
  require Text::Table;
  require Time::Duration;

  my $parser = DateTime::Format::RFC3339->new;

  # Ugh, should sort out the ME:: table formatter for general use.
  my $table = Text::Table->new(
    '', # Status
    'region',
    '  ', # Type
    '  ', # Default
    'name',
    'ip',
    { title => 'age', align => 'right' },
    { title => 'cost', align => 'right' },
    { title => 'img age', align => 'right', align_title => 'right' },
  );

  my $default;
  unless ($opt->everything) {
    my ($rec) = grep {; $_->{type} eq 'CNAME' && $_->{name} eq $username }
                $boxman->dobby->get_all_domain_records_for_domain($boxman->box_domain)->get;

    $default = $rec->{data};
  }

  for my $droplet (@$droplets) {
    my $name   = $droplet->{name};
    my $status = $droplet->{status};
    my $ip     = $self->boxman->_ip_address_for_droplet($droplet); # XXX _method
    my $image  = $droplet->{image};

    my $created  = $parser->parse_datetime($droplet->{created_at});
    my $age_secs = time - $created->epoch;

    my $img_created  = $parser->parse_datetime($image->{created_at});
    my $img_age_secs = time - $img_created->epoch;

    my $cost = sprintf '%4s',
      '$' .  builtin::ceil($droplet->{size}{price_hourly} * $age_secs / 3600);

    my $icon = ($image->{slug} && $image->{slug} =~ /^debian/) ? "\N{CYCLONE}"
             : (($image->{description}//'') =~ /^Debian/)      ? "\N{CYCLONE}" # Deb 11
             : ($image->{name} =~ /\Afminabox/               ) ? "\N{PACKAGE}"
             :                                                   "\N{BLACK QUESTION MARK ORNAMENT}";

    my $default = $default && $default eq $name
                ? "\N{SPARKLES}"
                : "\N{IDEOGRAPHIC SPACE}";

    $table->add(
      ($status eq 'active' ? "\N{LARGE GREEN CIRCLE}" : "\N{HEAVY MINUS SIGN}"),
      $droplet->{region}{slug},
      "$icon\N{INVISIBLE SEPARATOR}",
      "$default\N{INVISIBLE SEPARATOR}",
      $name,
      $ip,
      Time::Duration::concise(Time::Duration::duration($age_secs, 1)),
      $cost,
      Time::Duration::concise(Time::Duration::duration($img_age_secs, 1)),
    );
  }

  # This leading space is *bananas* and is here because Text::Table will think
  # about LARGE GREEN CIRCLE as being one wide, but it's two.
  print Term::ANSIColor::colored(['bold', 'bright_white'], qq{ $_}) for $table->title;
  print qq{$_}  for $table->body;
}

1;
