# genome-properties

This GitHub repo represents the repository of data relating to the Genome Properties resource as hosted by EMBL-EBI. The data can be viewed at the following website https://www.ebi.ac.uk/interpro/genomeproperties/
This repo also functions as the curation area for the data, and as such not all data should be considered as curated and 'public-ready'. For more information about the Genome Properties resource please see docs/background.rst

The repo is divided into four main directories:
+  code
+  data
+  docs
+  flatfiles

The data directory contains a folder for each genome property, which in turn contains the files relating to that property. There can be up to 3 files (DESC, FASTA and status). The contents of the status file determine whether the data for that property is considered 'public-ready' and so can be included in the website.

The code directory contains all modules and scripts pertaining to the creation and curation of the data, as well as all code required to perform a release.

The flatfiles directory contains the various flatfiles relating to the current release. These are updated with each release.

The docs directory contains all the static documents used in the website and the documentation which can be found at readthedocs: http://genome-properties.readthedocs.io/en/latest/index.html
