#!/usr/bin/perl
#
#  1000genomes_vcf_load.pl - parsing metadata from 1000 Genomes Project vcf files into MySQL
#                 - EOB - Mar 12 2019
#
# usage: 1000genomes_vcf_load.pl
#
########################################

use DBI;
use DBD::mysql;
use WWW::Mechanize;
use LWP::Simple;

# connect to local database

my $dsn = 'dbi:mysql:genomes_metadata:localhost:3306';
my $user = 'emmet';
my $password = 'neuro';
my $dbh = DBI->connect($dsn, $user, $password) or die ("Can't connect to database");

# initialise resource-level constants

$species_name         = "Homo sapiens";
$project_name         = "1000 Genomes Project";
$thousandgenomes_URL  = "https://datahub-khvul4ng.udes.genap.ca";
$local_data_space     = "/var/tmp";

# $testfile = "t";

# open(T, ">$testfile") || die "Can't open $testfile to write debug information\n"; 

# use spider to crawl static index page

my $spider   = WWW::Mechanize->new();
my $response = $spider->get($thousandgenomes_URL);
if ($response->is_success) {
	$index_page  = $spider->content;
	@index_lines = split(/\n/,$index_page);
	$index_count = scalar @index_lines;
}
else {
	die $response->status_line;
}

# parse list of target files from page

$retrieve_lines = ();
$i_counter = $r_counter = 0;
while ($i_counter < $index_count) {
	if ($index_lines[$i_counter] =~ /a href=\"(ALL\.chr.*?gz)\"/) { # a file containing a chromosome
		$retrieve_lines[$r_counter] = $1;
		print "$r_counter ### $retrieve_lines[$r_counter] \n";
		++$r_counter;
	}
	++$i_counter; 
}

# retrieve data file

# the data files here are in the high tens of GB range, so rather than loop through
# them, it proved more practical to run this program repeatedly for each target file,
# editing the line immediately below each time

$target_file = $retrieve_lines[22];

$target_URL     = $thousandgenomes_URL."/".$target_file; #testing on a single file first
$local_filename = $local_data_space."/".$target_file;

print "Downloading from $target_URL to $local_filename... \n";

getstore($target_URL, $local_filename) || die "Could not download $target_url\n"; 

$local_filename =~ /^(.*)\.gz/;
$input_vcf_filename = $1;

print "Unzipping $input_vcf_filename... \n";

system("gunzip $local_filename");

if ($input_vcf_filename =~ /ALL\.(chr.*?)\./) {
	$chromosome = $1;
	$chromosome =~ /chr(.*)/;
	$chr_label  = $1;
}
else {
	die('Cannot read chromosome identifier from filename '.$input_vcf_filename."\n");
}

# adjust search pattern because different chromosome files format rows slightly differently

if (($chr_label eq 'Y') || ($chr_label eq 'MT')) {
	$terminator = ';';
}
else {
	$terminator = "\t";
}

if ($chr_label eq 'MT') {
	$snp_match   = "S";
	$indel_match = "I";
}
else {
	$snp_match   = "SNP";
	$indel_match = "INDEL";
}


# read in data from .vcf file 

open (INPUT_VCF, $input_vcf_filename) || die "Can't open $input_vcf_filename to read\n";

$snp_count        = 0;
$indel_count      = 0;
while (($intake_line = <INPUT_VCF>)) {
	chomp($intake_line);

	# extract date and reference link from header lines

	if ($intake_line =~ /^\#\#/){  # two # characters mark a header line in .vcf
		if ($intake_line =~ /fileDate=(.*)$/) { $project_date = $1 };
		if ($intake_line =~ /reference=(.*)$/) { $reference_seq_link = $1 };
	}
	else {

	# parse each line in the file body for SNPs and indels

		if ($intake_line =~ /^$chr_label.*VT=(.*?)$terminator/) {
			$variant_type = $1;
			if ($variant_type eq $snp_match)    { ++$snp_count };
                        if ($variant_type eq $indel_match)  { ++$indel_count };
                        if (($snp_count % 50000) == 0) {  # indicate progress of program
				print "SNPs $snp_count INDELS $indel_count\n";
			}
		}
	}
}
close(INPUT_VCF);

print ("Deleting .vcf file $input_vcf_filename\n");  # saving space
system ("rm $input_vcf_filename");

insert_row(); 

# close(T);
exit();


# functions

# add row to 1000genomes table
       
sub insert_row {

  $sql_insert_genome  = "INSERT INTO 1000genomes (project_name, project_date, species_of_origin, chromosome, resource_link, reference_sequence_link, number_of_SNPs, number_of_indels) "; 
  $sql_insert_genome .= "VALUES ('$project_name','$project_date','$species_name','$chromosome','$target_URL', '$reference_seq_link', $snp_count, $indel_count)";
 
#  print "$sql_insert_genome\n";
 
  $exec_update = $dbh->prepare($sql_insert_genome);
  $exec_update->execute();
}

exit();
