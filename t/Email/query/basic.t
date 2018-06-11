use strict;
use warnings;
use Test::Routine;
use Test::Routine::Util;

with 'JMAP::TestSuite::Tester';

use JMAP::TestSuite::Util qw(batch_ok pristine_test);

use Test::Deep ':v1';
use Test::Deep::JType;
use Test::More;
use JSON qw(decode_json);
use JSON::Typist;
use Test::Abortable;

# XXX - Need test for cancalc

pristine_test "Email/query with no existing entities" => sub {
  my ($self) = @_;

  my $tester = $self->tester;

  subtest "No arguments" => sub {
    my $res = $tester->request({
      using => [ "ietf:jmapmail" ],
      methodCalls => [[
        "Email/query" => {},
      ]],
    });
    ok($res->is_success, "Email/query")
      or diag explain $res->http_response->as_string;

    jcmp_deeply(
      $res->single_sentence("Email/query")->arguments,
      superhashof({
        accountId => jstr($self->context->accountId),
        state     => jstr(),
        position  => jnum(0),
        total     => jnum(0),
        ids       => [],
        canCalculateChanges => jbool(),
      }),
      "No Emailes looks good",
    ) or diag explain $res->as_stripped_triples;
  };
};

sub ids_for {
  my %hash = @_;

  return [
    map {; $_->id, } values %hash
  ];
}

pristine_test "filtering" => sub {
  my ($self) = @_;

  my %mailboxes = (
    aaa => $self->context->create_mailbox({
      name => "aaa",
    }),
    bbb => $self->context->create_mailbox({
      name => "bbb",
    }),
    ccc => $self->context->create_mailbox({
      name => "ccc",
    }),
    ddd => $self->context->create_mailbox({
      name => "ddd",
    }),
  );

  my %in_aaa = (
    aaa_1 => $mailboxes{aaa}->add_message({ subject => 'aaa_1', }),
  );

  my %in_bbb = (
    bbb_1 => $mailboxes{bbb}->add_message({ subject => 'bbb_1', }),
  );

  my %in_ccc = (
    ccc_1 => $mailboxes{ccc}->add_message({ subject => 'ccc_1', }),
  );

  my %in_ddd = (
    ddd_1 => $mailboxes{ddd}->add_message({ subject => 'ddd_1', }),
  );

  my %emails = (%in_aaa, %in_bbb, %in_ccc, %in_ddd);

  my %emails_by_id = map {; $_->id => $_ } values %emails;

  my $describer_sub = $self->make_describer_sub(\%emails_by_id);

  # inMailbox
  $self->test_query("Email/query",
    { filter => { inMailbox => $mailboxes{aaa}->id }, },
    { ids => ids_for(%in_aaa), },
    $describer_sub,
    "inMailbox filter",
  );
};

sub make_describer_sub {
  my ($self, $emails_by_id) = @_;

  return sub {
    my ($self, $id) = @_;

    return    $emails_by_id->{$id}->{subject}
           || $emails_by_id->{$id}->subject;
  }
}


run_me;
done_testing;