#!/usr/bin/perl
#
#  1000genomes_output_DATS_json.pl - writing 1000 Genomes Project metadata from MySQL
#                                    as JSON files in DATS format
#                                  - EOB - Apr 08 2019
#
# usage: 1000genomes_output_DATS_json.pl $home_directory
#
########################################

use DBI;
use DBD::mysql;

# connect to local database

my $dsn = 'dbi:mysql:genomes_metadata:localhost:3306';
my $user = 'emmet';
my $password = 'neuro';
my $dbh = DBI->connect($dsn, $user, $password) or die ("Can't connect to database");

# initialise project-level constants

# and remember to spell organisation with a 'z' in this context !

$home_directory       = $ARGV[0];
$species_name         = "Homo sapiens";
$species_id           = "9606";   # NCBI taxonomic identifier for H. sapiens
$species_URL          = "https://www.ncbi.nlm.nih.gov/taxonomy/$species_id";
$project_name         = "1000 Genomes Project";
$project_abbr         = "1KGP";
# $data_host            = "Canadian Centre for Computational Genomics";  # temporary change
$data_host            = "European Bioinformatics Institute";

$publication_doi      = "https://doi.org/10.1038/nature15393";
$publication_title    = "A global reference for human genetic variation";
$publication_date     = "2015-10-01 00:00:00";
$input_distribution_URL     = "https://datahub-khvul4ng.udes.genap.ca";  # temporary change

# lines marked 'temporary change' to be removed when http-client 0.6.4 is integrated into git-annex and we can go back to the C3G server

$distribution_URL     = "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502";
$master_filename      = "$home_directory/1000genomes_data/DATS.json";
$project_desc         = "The 1000 Genomes Project provides a comprehensive description of common human ";
$project_desc        .= "variation by applying a combination of whole-genome sequencing, deep exome ";
$project_desc        .= "sequencing and dense microarray genotyping to a diverse set of 2504 individuals ";
$project_desc        .= "from 26 populations.  Over 88 million variants are characterised, including >99% ";
$project_desc        .= "of SNP variants with a frequency of >1% for a variety of ancestries.";
$contact_text         = "Jennifer Tremblay-Mercier, Research Co-ordinator, ";
$contact_text        .= "jennifer.tremblay-mercier".'@'."douglas.mcgill.ca, 514-761-6131 #3329";

@dataset_keyword    = ();
$dataset_keyword[0] = "genomics";

# retrieve each row from database and write dataset-level JSON
# for now we are selecting only the columns that contain data in the 1KGP dataset

@dataset_id_array    = ();
@dataset_name_array  = ();
@dataset_text_array  = ();
$dataset_array_count = 0;

$sql_retrieve_genome  = "SELECT chromosome, project_date, resource_link,";
$sql_retrieve_genome .=       " reference_sequence_link, number_of_SNPs, number_of_indels";
$sql_retrieve_genome .=  " FROM 1000genomes ORDER BY chromosome";  
$exec_select = $dbh->prepare($sql_retrieve_genome);
$exec_select->execute();
while (@row = $exec_select->fetchrow_array) {
	write_dataset(@row);
	$chromosome = $row[0];
	$dataset_id_array[$dataset_array_count]   = $project_abbr."_".$chromosome.".json";
	$dataset_name_array[$dataset_array_count] = $chr_name;
	++$dataset_array_count;
}


# write master dataset 

write_master();

exit();

# functions

# write_dataset : write a dataset JSON entry for a 1000 Genomes chromosome file 

sub write_dataset {
	
	my ($chromosome, $date, $resource_link, $refseq_link, $SNP_count, $indel_count) = @_;

	my $dataset_text = "";

	$resource_link =~ s/$input_distribution_URL/$distribution_URL/; # temporary change

	# generate a human-friendly name from the 1KGP chromosome file ID

	$chromosome =~/chr(.*)/;
	$chr_significant = $1;
	if ($chr_significant eq 'MT') {
		$chr_name = "Mitochondrial genome";
	}
	else {
		$chr_name = "Chromosome $chr_significant";
	}
	
	# date

	$dataset_text .= "\t\t\t\"dates\": [\n";
	$dataset_text .= "\t\t\t\t{\n";
	$dataset_text .= "\t\t\t\t\t\"type\": {\n";
	$dataset_text .= "\t\t\t\t\t\t\"value\":\"source .vcf file creation date\"\n";
	$dataset_text .= "\t\t\t\t\t},\n";
	$dataset_text .= "\t\t\t\t\t\"date\": \"$date\"\n";
	$dataset_text .= "\t\t\t\t}\n";
	$dataset_text .= "\t\t\t],\n";

	# reference links

	$dataset_text .= "\t\t\t\"storedIn\": {\n";
	$dataset_text .= "\t\t\t\t\"name\": \"$resource_link\",\n";
	$dataset_text .= "\t\t\t\t\"description\": \"Gzipped .vcf file containing sequence variations\"\n";
	$dataset_text .= "\t\t\t},\n";

	# dimensions

	$dataset_text .= "\t\t\t\"dimensions\": [\n";
	$dataset_text .= "\t\t\t\t{\n"; 
	$dataset_text .= "\t\t\t\t\t\"name\": {\n";
	$dataset_text .= "\t\t\t\t\t\t\"value\": \"Count of Single Nucleotide Polymorphism variants\"\n";
	$dataset_text .= "\t\t\t\t\t},\n";
	$dataset_text .= "\t\t\t\t\t\"values\": [\n";
	$dataset_text .= "\t\t\t\t\t\t\"$SNP_count\"\n";
	$dataset_text .= "\t\t\t\t\t]\n";
	$dataset_text .= "\t\t\t\t},\n"; 
	$dataset_text .= "\t\t\t\t{\n"; 
	$dataset_text .= "\t\t\t\t\t\"name\": {\n";
	$dataset_text .= "\t\t\t\t\t\t\"value\": \"Count of single-nucleotide insertion and deletion events\"\n";
	$dataset_text .= "\t\t\t\t\t},\n";
	$dataset_text .= "\t\t\t\t\t\"values\": [\n";
	$dataset_text .= "\t\t\t\t\t\t\"$indel_count\"\n";
	$dataset_text .= "\t\t\t\t\t]\n";
	$dataset_text .= "\t\t\t\t}\n";
	$dataset_text .= "\t\t\t],\n";

	# and add the link to the ftp file containing the reference sequence as an extra property

	$dataset_text .= "\t\t\t\"extraProperties\": [\n";
	$dataset_text .= "\t\t\t\t{\n";
	$dataset_text .= "\t\t\t\t\t\"category\": \"FTP link to gzipped FASTA file containing reference DNA sequence\",\n";
	$dataset_text .= "\t\t\t\t\t\"values\": [\n";
	$dataset_text .= "\t\t\t\t\t\t{\n";
	$dataset_text .= "\t\t\t\t\t\t\t\"value\": \"$refseq_link\"\n";
	$dataset_text .= "\t\t\t\t\t\t}\n";
	$dataset_text .= "\t\t\t\t\t]\n";
	$dataset_text .= "\t\t\t\t}\n";
	$dataset_text .= "\t\t\t]\n";

	$dataset_text_array[$dataset_array_count] = $dataset_text;
}

# write_master: write a master JSON file for the whole dataset

sub write_master {
	
	my $master_text = "{\n";

	open (MAST_JSON, ">$master_filename")|| die "Cannot open $master_filename for write\n";

	# dummy DOI: this will be replaced when one is assigned (e.g. reserved at Zenodo)

	$master_text .= "\t\"identifier\": {\n";
	$master_text .= "\t\t\"identifier\": \"dummy\",\n";
	$master_text .= "\t\t\"identifierSource\": \"DOI\"\n";
	$master_text .= "\t},\n";


	$master_text .= "\t\"version\": \"1.0\",\n";
	$master_text .= "\t\"privacy\": \"public open\",\n";
	$master_text .= "\t\"licenses\": [\n";
	$master_text .= "\t\t{\n";
	$master_text .= "\t\t\t\"name\": \"BY-NC-SA\"\n";
	$master_text .= "\t\t}\n";
	$master_text .= "\t],\n";


	$master_text .= "\t\"creators\": [\n";
	$master_text .= "\t\t{\n";
	$master_text .= "\t\t\t\"name\": \"$project_name\"\n";
	$master_text .= "\t\t}\n";
	$master_text .= "\t],\n";

	# data type

	$master_text .= "\t\"types\": [\n";
	$master_text .= "\t\t{\n";
	$master_text .= "\t\t\t\"information\": {\n";
	$master_text .= "\t\t\t\t\"value\": \"genomics\"\n";
	$master_text .= "\t\t\t}\n";
	$master_text .= "\t\t}\n";
	$master_text .= "\t],\n";

	# title

	$master_text .= "\t\"title\": \"$project_name\",\n";

	# description

	$master_text .= "\t\"description\": \"$project_desc\",\n";

	# location of resources

	$master_text .= "\t\"storedIn\": {\n";
	$master_text .= "\t\t\"name\" : \"$data_host\"\n";
	$master_text .= "\t},\n";

	# publication info

	$master_text .= "\t\"primaryPublications\" : [\n";
	$master_text .= "\t\t{\n";
	$master_text .= "\t\t\t\"identifier\": {\n";
	$master_text .= "\t\t\t\t\"identifier\": \"$publication_doi\"\n";
	$master_text .= "\t\t\t},\n";
	$master_text .= "\t\t\t\"title\": \"$publication_title\",\n";

	$master_text .= "\t\t\t\"dates\": [\n";
	$master_text .= "\t\t\t\t{\n";
	$master_text .= "\t\t\t\t\t\"type\": {\n";
	$master_text .= "\t\t\t\t\t\t\"value\":\"Primary reference publication date\"\n";
	$master_text .= "\t\t\t\t\t},\n",
	$master_text .= "\t\t\t\t\t\"date\": \"$publication_date\"\n";
	$master_text .= "\t\t\t\t}\n";
	$master_text .= "\t\t\t],\n";

	$master_text .= "\t\t\t\"authors\": [\n";
	$master_text .= "\t\t\t\t{\n";
	$master_text .= "\t\t\t\t\"name\":\"$project_name\"\n";
	$master_text .= "\t\t\t\t}\n";
	$master_text .= "\t\t\t]\n";
	$master_text .= "\t\t}\n";
	$master_text .= "\t],\n";

	# isAbout; setting this to taxonomic information for the moment

	$master_text .= "\t\"isAbout\": [\n";
	$master_text .= "\t\t{\n";
	$master_text .= "\t\t\t\"identifier\": {\n";
	$master_text .= "\t\t\t\t\"identifier\": \"$species_id\",\n";
	$master_text .= "\t\t\t\t\"identifierSource\":\"$species_URL\"\n";
	$master_text .= "\t\t\t},\n";
	$master_text .= "\t\t\t\"name\":\"$species_name\"\n";
	$master_text .= "\t\t}\n";
	$master_text .= "\t],\n";

	# JSON fileset creation date

	$master_text .= "\t\"dates\": [\n";
	$master_text .= "\t\t{\n";
	$master_text .= "\t\t\t\"type\": {\n";
	$master_text .= "\t\t\t\t\"value\":\"CONP DATS JSON fileset creation date\"\n";
	$master_text .= "\t\t\t},\n",
	@date_now     = localtime(); # reformat this to a date format JSON likes:
	$date_out     = ($date_now[5]+1900)."-".sprintf("%02d",$date_now[4]+1);
	$date_out    .=  "-".sprintf("%02d",$date_now[3])." ";  # YYYY-MM-DD
	$date_out    .= sprintf("%02d",$date_now[2]).":";
	$date_out    .= sprintf("%02d",$date_now[1]).":";
	$date_out    .= sprintf("%02d",$date_now[0]);      # hh:mm:ss
	$master_text .= "\t\t\t\"date\": \"$date_out\"\n";
	$master_text .= "\t\t}\n";
	$master_text .= "\t],\n";
	
	# keywords

	$master_text .= "\t\"keywords\": [\n";
        $keyword_count = 0;
	while($dataset_keyword[$keyword_count]) {
		$master_text .= "\t\t{\n";
		$master_text .= "\t\t\t\"value\" : \"$dataset_keyword[$keyword_count]\"\n";
		$master_text .= "\t\t},\n";
		++$keyword_count;
	}

        chop($master_text); chop($master_text); $master_text .= "\n"; # remove the comma after the last entry
	$master_text .= "\t],\n";
	
	# hasPart: list subdatasets of this one, with required fields

	$master_text .= "\t\"hasPart\": [\n";
	$temp_counter = 0;
	while ($temp_counter < ($dataset_array_count)) {
		$master_text .= "\t\t{\n";

		# title

		$master_text .= "\t\t\t\"title\":\"$dataset_name_array[$temp_counter]\",\n";

		# creators

		$master_text .= "\t\t\t\"creators\": [\n";
		$master_text .= "\t\t\t\t{\n";
		$master_text .= "\t\t\t\t\t\"name\": \"$project_name\"\n";
		$master_text .= "\t\t\t\t}\n";
		$master_text .= "\t\t\t],\n";

		# data type

		$master_text .= "\t\t\t\"types\": [\n";
		$master_text .= "\t\t\t\t{\n";
		$master_text .= "\t\t\t\t\t\"information\": {\n";
		$master_text .= "\t\t\t\t\t\t\"value\": \"genomics\"\n";
		$master_text .= "\t\t\t\t\t}\n";
		$master_text .= "\t\t\t\t}\n";
		$master_text .= "\t\t\t],\n";

		# include the JSON for each individual chromosome

		$master_text .= $dataset_text_array[$temp_counter];

		$master_text .= "\t\t}";
		unless ($temp_counter == $dataset_array_count - 1) {
			$master_text .= ",";  # comma needed after every entry except the last
		}
		$master_text .= "\n";

		++$temp_counter;
	}

	$master_text .= "\t],\n";

	$master_text .= "\t\"extraProperties\": [\n";
	$master_text .= "\t\t{\n";
	$master_text .= "\t\t\t\"category\": \"contact\",\n";
	$master_text .= "\t\t\t\"values\": [\n";
	$master_text .= "\t\t\t\t{\n";
	$master_text .= "\t\t\t\t\t\"value\": \"$contact_text\"\n";
	$master_text .= "\t\t\t\t}\n";
	$master_text .= "\t\t\t]\n";
	$master_text .= "\t\t}\n";
	$master_text .= "\t]\n";
	$master_text .= "}\n";
	print MAST_JSON $master_text;
	close MAST_JSON;

}

