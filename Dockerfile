# Copyright 2018 Lee Bergstrand

FROM perl:latest

MAINTAINER Lee Bergstrand

# Copy directories from the repository into the container.
COPY code /root/code
COPY data /root/data
COPY flatfiles /root/flatfiles

# Use cpanm to install all dependanices found in the "cpanfile".
RUN cpanm --installdeps ./code/

ENV PERL5LIB=/root/code/modules

ENTRYPOINT ["perl", \
            "/root/code/scripts/assign_genome_properties.pl", \
            "-all", \
            "-gpdir", "/root/flatfiles", \
            "-gpff", "genomeProperties.txt"]

CMD ["perl", "/root/code/scripts/assign_genome_properties.pl", "-help"]