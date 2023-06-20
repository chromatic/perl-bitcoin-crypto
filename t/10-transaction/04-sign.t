use v5.10;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use Bitcoin::Crypto qw(btc_script btc_transaction btc_prv);
use Bitcoin::Crypto::Transaction::UTXO;
use Bitcoin::Crypto::Util qw(to_format);

my $tx;
my $prv = btc_prv->from_str("\x12" x 32);

subtest 'should sign transactions (P2PK)' => sub {
	$tx = btc_transaction->new;

	Bitcoin::Crypto::Transaction::UTXO->new(
		txid => [hex => '0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9'],
		output_index => 0,
		output => {
			locking_script => [P2PK => $prv->get_public_key->to_str],
			value => 50_00000000,
		},
	)->register;

	$tx->add_input(
		utxo => [[hex => '0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9'], 0],
		signature_script => btc_script->new
	);

	$tx->add_output(
		value => 10_00000000,
		locking_script => [
			P2PK => [
				hex =>
					'04ae1a62fe09c5f51b13905f07f06b99a2f7159b2225f374cd378d71302fa28414e7aab37397f554a7df5f142c21c1b7303b8a0626f1baded5c72a704f7e6cd84c'
			]
		],
	);

	$tx->add_output(
		value => 40_00000000,
		locking_script => [
			P2PK => [
				hex =>
					'0411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3'
			]
		],
	);

	$prv->sign_transaction($tx);
	lives_ok { $tx->verify } 'input verification ok';
};

subtest 'should sign transactions (P2PKH)' => sub {
	$tx = btc_transaction->new;

	Bitcoin::Crypto::Transaction::UTXO->new(
		txid => [hex => '5fb32a2b34f497274419100cfa8f79c21029e8a415936366b2b058b992f55fdf'],
		output_index => 5,
		output => {
			locking_script => [P2PKH => $prv->get_public_key->get_legacy_address],
			value => 139615,
		},
	)->register;

	$tx->add_input(
		utxo => [[hex => '5fb32a2b34f497274419100cfa8f79c21029e8a415936366b2b058b992f55fdf'], 5],
		signature_script => btc_script->new
	);

	$tx->add_output(
		value => 137615,
		locking_script => [P2PKH => '12s4mjQcz6rLpF8EyVGxFEFrgVKmNiPXxg'],
	);

	$prv->sign_transaction($tx);
	lives_ok { $tx->verify } 'input verification ok';
};

done_testing;

