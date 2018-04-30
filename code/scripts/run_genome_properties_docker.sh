#!/usr/bin/env bash

# Runs assign_genome_properties.pl in a docker container.
# Usage: ./run_genome_properties.pl

echo "Assigning genome properties for $1."
OUTNAME=$(echo "GENOME_PROPERTIES_$1" | sed 's/\..*//')

docker run --rm -v "$PWD:/root/run" leebergstrand/genome-properties:latest -matches ./run/$1 -outdir ./run/ -outfiles summary -name $OUTNAME
docker run --rm -v "$PWD:/root/run" leebergstrand/genome-properties:latest -matches ./run/$1 -outdir ./run/ -outfiles long -name $OUTNAME
