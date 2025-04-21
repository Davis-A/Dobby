package Boxmate::App;
use App::Cmd::Setup -app => {};

# ABSTRACT: the App::Cmd that powers Boxmate

use v5.36.0;
use utf8;

sub config ($self) {
  return $self->{_config} if $self->{_config};

  require Boxmate::Config;
  $self->{_config} //= Boxmate::Config->load;
}

sub _loop ($self) {
  return $self->{_loop} if $self->{_loop};
  $self->{_loop} //= IO::Async::Loop->new;
}

sub boxman ($self) {
  return $self->{_boxman} if $self->{_boxman};

  require Dobby::Client;
  require IO::Async::Loop;
  require String::Flogger;
  require Synergy::BoxManager;

  my $token = $ENV{DIGITALOCEAN_TOKEN};
  unless ($token) {
    die "\$DIGITALOCEAN_TOKEN isn't set. It should contain your API token or an opcli: URI\n";
  }

  if ($token =~ m{^opcli:}) {
    require Password::OnePassword::OPCLI;
    my $actual_token = Password::OnePassword::OPCLI->new->get_field($token);
    $token = $actual_token;
  }

  my $dobby = Dobby::Client->new(bearer_token => $token);

  $self->_loop->add($dobby);

  my $config = $self->config;
  $self->{_boxman} = Synergy::BoxManager->new({
    error_cb    => sub ($err) { die "❌ $err" },
    log_cb      => sub ($log) { say "🔸 " . String::Flogger->flog($log) },
    message_cb  => sub ($msg) { say "🔹 $msg" },
    snippet_cb  => sub ($arg) { return undef },

    dobby       => $dobby,

    box_domain  => $config->box_domain,
  });
}

1;
