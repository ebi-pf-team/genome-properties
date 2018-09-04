#!/usr/bin/env bash

echo 'Databases used for all genome properties:'
find ../.. -name 'DESC' | parallel cat {} | egrep "^EV" | egrep -oh '[a-zA-Z]+[0-9]+;' | grep -v 'IPR' | grep -v 'GenProp' | egrep -v '^SF' | sed -E 's/[0-9]+;//' | sort | uniq -c


echo 'Databases used for released genome properties:'
cat ../../flatfiles/genomeProperties.txt | egrep "^EV" | egrep -oh '[a-zA-Z]+[0-9]+;' | grep -v 'IPR' | grep -v 'GenProp' | egrep -v '^SF' | sed -E 's/[0-9]+;//' | sort | uniq -c
