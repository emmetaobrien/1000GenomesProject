This directory contains the following files:

24 files with names of the format '1KGP_chrnn.vcf.gz', each of which should connect to the gzipped .vcf file containing 1000 Genome Project sequence variation files for the appropriate chromosome, hosted at the Canadian Centre for Computational Genomics.

4 files in the sub-directory scripts:

1000genomes_table.txt: Text file containing the SQL create statement used to generate a table for containing .vcf data. Has been used only in MySQL.

1000genomes_vcf_read.pl: perl script that retrieves a zipped .vcf file, unzips it locally, and reads headers and a couple of summaries of the contents of the file body into the table specified above.

1000genomes_output_json.pl: perl script that reads from that table and writes DATS-format 1KGP JSON files as uploaded to conp-dataset/metadata/example on April 1 2019.

1000genomes_validate_json.pl: perl script that validates user-specified JSON files against a user-specified schema, which has been used to validate all the 1KGP JSON files against the DATS dataset_schema.json.



