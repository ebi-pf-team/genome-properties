# Copyright 2018 Genome Properties (GPLv3)

# Description:  This is a Dockerfile for building a genome properties assignment container.
#               It allows users to rapidly determine an organism's genome properties when
#               provided InterProScan output TSV in a isolated enviroment.
#
# Building:     docker build -t genome-properties .
#
# Usage:        docker run --rm -v $PWD:/root/run genome-propertie
#               -matches ./run/ecoli_k12.tsv
#               -outdir ./run/
#               -outfiles summary
#               -name out_file_prefix
#
#               The Docker container calls the ```assign_genome_properties.pl``` script by default.

FROM perl:latest

MAINTAINER Genome Properties Team (GenProp@ebi.ac.uk)

# Copy directories from the repository into the container.
COPY code /root/code
COPY data /root/data
COPY flatfiles /root/flatfiles

# Use cpanm to install all dependanices found in the "cpanfile" in the ./code/directory.
RUN cpanm --installdeps ./code/

# Add custom perl modules (GenomeProperties.pm etc.) to the path.
ENV PERL5LIB=/root/code/modules

ENTRYPOINT ["perl", \
            "/root/code/scripts/assign_genome_properties.pl", \
            "-all", \
            "-gpdir", "/root/flatfiles", \
            "-gpff", "genomeProperties.txt"]

CMD ["perl", "/root/code/scripts/assign_genome_properties.pl", "-help"]