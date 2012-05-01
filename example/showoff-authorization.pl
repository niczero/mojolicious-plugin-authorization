#!/usr/bin/env perl
use strict;
use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;
# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }
use Mojolicious::Lite;
=pod
=head1 Title
  showoff-authorization.pl --- an example of the Mojolicious::Plugin::Authorization module by John Scoles
=head1 Invocation
  $ perl showoff-authorization.pl daemon
=head1 Notes
My first crack at a Mojo plugin a steal from Ben van Staveren's Authentication so I owe him and some others
a great note of thanks
Like Authentication this is a very a simple application. It supplies the framwork and you have to give it
the guts which this little progam shows.
I did not add in any Authentication as that is up to you to build. In this test I just assume you are
autnticated on the session ans that session has a role hash on it.
=head1 Versions
  0.0: Apr 24 2012
=cut
################################################################
### miniauthorfile.pm lays out basic functionality for the miniauthorfile
use miniauthorfile;
my $roles = miniauthorfile->new('miniauthorfile.txt');
################################################################
plugin 'authorization', {
			  has_priv => sub {
			     my $self = shift;
			     my ($priv, $extradata) = @_;
			     return 0
			       unless($self->session('role'));
			     my $role  = $self->session('role');
			     my $privs = $roles->{$role};
			     return 1
			       if exists($privs->{$priv});
			     return 0;
			  },
			  is_role => sub {
			    my $self = shift;
			    my ($role, $extradata) = @_;
			    return 1;
			  },
			  user_privs => sub {
			    my $self = shift;
			    my ($extradata) = @_;
			    return $self->session('role');
			  },
			  user_role => sub {
			    my $self = shift;
			    my ($extradata) = @_;
			    return $self->session('role');
			  },
			 };
################################################################
get '/' => sub {
  my $self = shift;
  unless($self->session('role')){
    $self->session('role'=>'guest');
  }
  $self->render('index');  ## index needs to be named to match '/'
};
get '/dogshow' => sub {
  my $self = shift;
  unless ($self->has_priv('view')) {
     $self->render('index');
  }
  else{
    warn("dogshow 3\n");
     $self->stash('role_name'=> $self->role());
     $self->render('dogshow');
  }
};
get '/change/:role' => sub {
  my $self = shift;
  my $role =  $self->param('role');
  $roles->set_role($self->session,$role);
  $self->stash('role_name'=> $self->role());
  $self->render('dogshow');
 # $self->render(template);  ## this is called automatically
};
get '/view' => sub {
  my $self = shift;
  unless ($self->has_priv('view')) {
     $self->render('index');
  }
 # $self->render(template);  ## this is called automatically
};
get '/herd' => sub {
  my $self = shift;
  unless ($self->has_priv('herd')) {
     $self->render('not_allowed');
  }
};
get '/judge' => sub {
  my $self = shift;
};
############ these two subs can show you what you can do now, based on authenticated status
get '/role/:new_role' => sub {
  my $self = shift;
};
## /condition/authonly exists as a webpage ONLY after authentication
app->secret('All GLORY to the Hypnotoad!!');  # used for cookies and persistence
app->start();
################################################################
__DATA__
@@ index.html.ep
% layout 'default';
% title 'Root';
<h2> Top Index Page</h2>
<p>The purpose of this little web app is to show an example of <a href="http://mojolicio.us/">Mojolicious</a> and its <a href="http://search.cpan.org/~madcat/Mojolicious-Plugin-Authorization/">Mojolicious::Authorization module</a> by John Scoles.</p>
<p>Start by browsing to the trials as a <a href="/change/gues">Guest</a>.</p>
<p>Start by browsing to the trials as a <a href="/change/dog">Dog</a>.</p>
<p>Start by browsing to the trials as a <a href="/change/judge">Dog Show as a Judge</a>.</p>
<p>Start by browsing to the trials as a <a href="/change/hypnotoad">Dog Show as the Hypnotoad</a>.</p>
@@ dogshow.html.ep
% layout 'default';
% title 'Pan Galatic Sheep Dog Trials';
<p>Welcome "<%= $role_name %>" to the the Pan Galatic Sheep Dog Trials.</p>
<a href="/">Go home</a><br>
<a href="/view">View a Trial</a><br>
<a href="/herd">Herd some Sheep</a><br>
<a href="/judge">Judge a trial</a>
@@ view.html.ep
% layout 'default';
% title 'View Trials';
<h1>Enjoy the Trials</h1>
<p>He's good.</p>
<p>But our real compition is the Hypnotoad</p>
@@ herd.html.ep
% layout 'default';
% title 'Herd Some Sheep';
<h1>Heard Some Sheep</h1>
@@ judge.html.ep
% layout 'default';
% title 'Judge a Dog';
<h1>Judge a Dog</h1>
@@ not_allowed.html.ep
% layout 'default';
% title 'Page Unavailable';
<h1>I am sorry do to interferance from suicide booths on 'Eminiar VII' you cannot get to this page</h1>
@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
  </head>
  <body>
    <hr />
    <h1> Mojolicious: <%= $0 %>: <%= title %> </h1>
    <hr />
    <%= content %>
    <hr />
  </body>
</html>
