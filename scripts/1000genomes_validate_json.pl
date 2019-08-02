#!/usr/bin/perl
#
#  1000genomes_validate_json.pl - validates JSON output from 1000genomes_output_json.pl
#                                 against DATS schemata
#                 - EOB - Mar 25 2019
#
# usage: 1000genomes_validate_json.pl $metadata_filename $schema_filename
# 
# Apr 01 2019: currently should be run in the directory containing $schema_filename 
#              with relative path to $metadata_filename explicitly specified
#
########################################

use JSON;
use JSON::Validator;

my $validator = JSON::Validator->new();

# connect to

$metadata_filename = $ARGV[0];
$schema_filename   = $ARGV[1];
$output_filename   = "test_DATS_JSON_validator_output.txt";

open (METADATA, "$metadata_filename") || die "Can't open $metadata_filename to read\n";
open (SCHEMA, "$schema_filename")     || die "Can't open $schema_filename to read\n";

# read in JSON files

my $metadata_json_string;

{
	local $/;  # undefine newline marker so file reads all at once ("slurp mode")
	$metadata_json_string = <METADATA>;
}

my $metadata_json_object = decode_json($metadata_json_string);

my $schema_json_string;

{
	local $/;
	$schema_json_string = <SCHEMA>;
}

my $schema_json_object = decode_json($schema_json_string);

close METADATA;
close SCHEMA;

# load schema into validator

my $validator = $validator->schema($schema_json_object) || die ("Cannot read $schema_filename");

# and use it to validate metadata

my @errors = $validator->validate($metadata_json_object, $schema_json_object);

# show errors if any

die "@errors" if @errors;

exit();
