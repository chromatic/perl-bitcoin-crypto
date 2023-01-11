package Bitcoin::Crypto::Role::Key;

use v5.10;
use strict;
use warnings;
use Crypt::PK::ECC;
use Scalar::Util qw(blessed);
use Mooish::AttributeBuilder -standard;

use Bitcoin::Crypto::Types qw(InstanceOf BIP44Purpose);
use Bitcoin::Crypto::Config;
use Bitcoin::Crypto::Util qw(get_key_type);
use Bitcoin::Crypto::Helpers qw(ensure_length);
use Bitcoin::Crypto::Exception;
use Moo::Role;

has param "key_instance" => (
	isa => InstanceOf ["Crypt::PK::ECC"],
	coerce => sub { __create_key($_[0]) },
);

has option 'purpose' => (
	isa => BIP44Purpose,
	writer => -hidden,
	clearer => 1,
);

with qw(Bitcoin::Crypto::Role::Network);

requires qw(
	_is_private
);

sub BUILD
{
	my ($self) = @_;

	Bitcoin::Crypto::Exception::KeyCreate->raise(
		"trying to create key from unknown key data"
	) unless $self->key_instance->is_private == $self->_is_private;
}

sub __create_key
{
	my ($entropy) = @_;

	return $entropy
		if blessed($entropy) && $entropy->isa("Crypt::PK::ECC");

	my $is_private = get_key_type $entropy;

	Bitcoin::Crypto::Exception::KeyCreate->raise(
		"invalid entropy data passed to key creation method"
	) unless defined $is_private;

	$entropy = ensure_length $entropy, Bitcoin::Crypto::Config::key_max_length
		if $is_private;

	my $key = Crypt::PK::ECC->new();

	Bitcoin::Crypto::Exception::KeyCreate->trap_into(
		sub {
			$key->import_key_raw($entropy, Bitcoin::Crypto::Config::curve_name);
		}
	);

	return $key;
}

# __create_key for object usage
sub _create_key
{
	shift;
	goto \&__create_key;
}

sub set_purpose
{
	my ($self, $purpose) = @_;
	$self->_set_purpose($purpose)
		if $purpose;
}

sub raw_key
{
	my ($self, $type) = @_;

	unless (defined $type) {
		$type = "public_compressed";
		if ($self->_is_private) {
			$type = "private";
		}
		elsif ($self->does("Bitcoin::Crypto::Role::Compressed") && !$self->compressed) {
			$type = "public";
		}
	}
	return $self->key_instance->export_key_raw($type);
}

1;

