#!/usr/bin/env bash

# Runs assign_genome_properties.pl inside a docker container.
#
# Usage: assign_genome_properties_docker.sh InterProScan.tsv

echo "Assigning genome properties for $1."

FILE_DIR=$(dirname "${1}")
FILE_NAME=$(basename "${1}")

OUT_NAME=$(echo ${FILE_NAME} | sed 's/\..*//') # Strips off TSV file extension.

docker run --rm -v "${FILE_DIR}:/root/run" genome-properties -matches ./run/${FILE_NAME} -outdir ./run/ -outfiles long -name ${OUT_NAME}
