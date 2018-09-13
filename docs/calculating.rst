Calculating Genome Properties
=============================


The presence or absence of genome properties (GPs) within a given genome or proteome, is calculated based on the matches to the relevant InterPro entries and their associated protein signatures. The evidence (HMM) for each constituent step is tested against the proteome in question, and each step defined as a hit or a miss. The total number of hits is then compared with the threshold level defined for the GP, to determine if the GP resolves to a YES (all required steps are present), NO (no/too few required steps are present) or PARTIAL (the number of required steps present is greater than the threshold, indicating that some evidence of the presence of the GP can be assumed).

The pipeline for how users can calculate GPs for their own data is described below.

Users begin with their own query "proteome" in the form of a list of FASTA format sequences. The InterProScan matches for this proteome must then be calcualted. This can either be done using EBI webservices, or by downloading InterProScan and running the calculation locally. By either method, the InterProScan matches can be output as TSV format. It is then possible to upload this TSV file to the GPs viewer available on the website. This allows the user to easily compare the pattern of assertions for the user-defined proteome, with the set of representative species provided on the webiste. For more information on how to use the viewer, see here #viewer.
