package JMAP::TestSuite::Entity::Mailbox;
use Moose;
use Carp ();
with 'JMAP::TestSuite::Entity' => {
  singular_noun => 'mailbox',
  properties  => [ qw(
    id
    name
    parentId
    role
    sortOrder
    mustBeOnlyMailbox
    myRights
    totalEmails
    unreadEmails
    totalThreads
    unreadThreads
    shareWith
  ) ],
};

for my $f (qw(
  mayReadItems
  mayAddItems
  mayRemoveItems
  maySetSeen
  maySetKeywords
  mayCreateChild
  mayRename
  mayDelete
  maySubmit
  mayAdmin
)) {
  no strict 'refs';

  *{$f} = sub {
    Carp::croak("Cannot assign a value to a read-only accessor") if @_ > 1;
    return $_[0]->_props->{myRights}{$f};
  };
}

sub add_message {
  my ($self, $arg) = @_;

  $arg ||= {};

  $self->account->add_message_to_mailboxes($arg, $self->id);
}

sub add_mailbox {
  my ($self, $arg) = @_;

  $arg ||= {};


  $self->account->create_mailbox({
    %$arg,
    parentId => $self->id,
  });
}

no Moose;
__PACKAGE__->meta->make_immutable;
