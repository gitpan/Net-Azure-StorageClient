#!/usr/bin/perl -w
use strict;
use lib qw( lib );
use File::Temp qw( tempdir );
use Test::More;
my $res;
my $error = 0;

my $account_name = '';
my $primary_access_key = '';

if (! $account_name ) {
    diag 'Please enter your account name of Windows Azure Blob Storage:';
    $account_name = <STDIN>;
    chomp( $account_name );
}

if (! $primary_access_key ) {
    diag 'Please enter your primary access key of Windows Azure Blob Storage:';
    $primary_access_key = <STDIN>;
    chomp( $primary_access_key );
}

if ( (! $account_name ) || (! $primary_access_key ) ) {
    plan skip_all =>
    'Testing this module required account and primary access key of Windows Azure Blob Storage.';
} else {
    plan tests => 17;
}

use_ok( 'Net::Azure::StorageClient' );
use_ok( 'Net::Azure::StorageClient::Blob' );

if ( (! $account_name ) || (! $primary_access_key ) ) {
    die "account_name and primary_access_key are required."
}

my $tempdir = tempdir();
my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( time );
my $ts = sprintf( "%04d%02d%02d%02d%02d%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );
my $container = 'test-container-' . $ts;

my $client = Net::Azure::StorageClient->new(
                                             type => 'Blob',
                                             account_name => $account_name,
                                             primary_access_key => $primary_access_key,
                                            );

isa_ok $client, 'Net::Azure::StorageClient::Blob';

$res = $client->list_containers();
is $res->code, 200;

$res = $client->create_container( $container );
is $res->code, 201;

$res = $client->set_container_acl( $container, { public_access => 1 } );
is $res->code, 200;

$res = $client->list_blobs( $container );
is $res->code, 200;

my $blob_name = "${container}/hello.txt";
$res = $client->put_blob( $blob_name, 'Hello Azure.' );
is $res->code, 201;

$res = $client->get_blob( $blob_name );
is $res->code, 200;

my $filename = File::Spec->catfile( $tempdir, 'hello.txt' );
$res = $client->download_blob( $blob_name, $filename );
is -f $filename, 1;

$res = $client->download_container( $container, $tempdir );
is -f $filename, 1;

my $upload_path = "${container}/hello2.txt";
$res = $client->upload_blob( $upload_path, $filename );
is $res->code, 201;
unlink $filename;
rmdir $tempdir;

my $copy_path = "${container}/hello3.txt";
$res = $client->copy_blob( $blob_name, $copy_path );
is $res->code, 202;

$res = $client->delete_blob( $blob_name );
is $res->code, 202;

$res = $client->rename_blob( $copy_path, $blob_name );
is $res->code, 202;

$res = $client->snapshot_blob( $blob_name );
is $res->code, 201;

$res = $client->delete_container( $container );
is $res->code, 202;

done_testing;