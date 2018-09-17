Calculating Genome Properties
=============================


The presence or absence of genome properties (GPs) within a given proteome, is calculated based on the matches to the relevant InterPro entries and their associated protein signatures. The evidence (HMM) for each constituent step is tested against the proteome in question, and each step defined as a hit or a miss. The total number of hits is then compared with the threshold level defined for the GP, to determine if the GP resolves to a YES (all required steps are present), NO (too few required steps are present) or PARTIAL (the number of required steps present is greater than the threshold, indicating that some evidence of the presence of the GP can be assumed).

Calculating Genome Properties for user-defined data
---------------------------------------------------

It is possible for users to calculate the GPs results for any novel proteome either using the website viewer, or by running the analysis locally using an available script. In either case, users begin with their own query "proteome" in the form of a list of sequences in FASTA format. The InterProScan matches for this proteome must then be calculated. This can either be done using EBI webservices, or by downloading InterProScan and running the calculation locally. By either method, the InterProScan matches must be output as TSV format.

Website/Viewer method
---------------------
Users simply need to upload the TSV file using the Browse/Choose File button on the viewer page. This loads the GPs results into the matrix (with the file name displayed in red) allowing easy comparison of the pattern of assertions for the user-defined proteome, with the set of representative species results. For more information on how to use the viewer, see here #viewer.

Local analysis method
---------------------
Users must first either clone, or download and uncompress a release bundle, from the GitHub repository (https://github.com/ebi-pf-team/genome-properties), and ensure that the perl modules are in the PERL5LIB (i.e ``$  export PERL5LIB=$PERL5LIB:<path to GPs clone>/code/modules``). It is then possible to run ``assign_genome_properties.pl`` using the TSV file as the input, and specifying the required output (outfiles) format. The various flags/options are described here:

== Sequence set ==
One or both of these two options:
matches <filename|TSV content> : TSV file of InterProScan5 output.
match_source <file|inline> : file or inline. Default is to assume file.

== Calculation options ==
One of the following three:
all                      : Calculate against all Genome Properties 
property <accession>     : Calculate against 
list     <filename>      : Filename containing a list of Genome Properties that need 
                         : to be evaluatated.

== Genome Properties files == 
Both of these are required: 
gpdir <directory name>   : Genome Properties release directory
gpff  <filename>         : Name of the flatfile  

Optional:
eval_order <filename>    : File containing an optimal evaluation order.

== Output options ==
name <name>              : Output file tag name (required). This will be prefixed 
                           depending on the outputs requested.
outdir <directory name>  : Name of the output directory (optional, default pwd).
outfiles <format>        : Format can be one of the following [summary|long|table|protein|web_json]
                         : To get multiple output files use option multiple times


Example command executed from within /code/scripts/ 
``$ ./assign_genome_properties.pl -matches INPUT_FILE.tsv -all -name OUTPUT_FILE -gpdir ../../flatfiles/ -gpff genomeProperties.txt -outdir ~user/analysis/ -outfiles summary``

   
Description of available output formats

+--------+------------------------------------------------------------------------------------------+
|summary | lists only GPs results (YES/NO)                                                          |
+--------+------------------------------------------------------------------------------------------+
|table   | includes individual step results (1/0) as well as GPs results (YES/NO)                   |
+--------+------------------------------------------------------------------------------------------+
|long    | includes individual step information and results (YES/NO) as well as GPs results (YES/NO)|
+--------+------------------------------------------------------------------------------------------+
|web_json| includes individual step results (1/0) as well as GPs results (YES/NO) in json format    |
+--------+------------------------------------------------------------------------------------------+
|protein | lists only those evidences and GPs with protein matches                                  |
+--------+------------------------------------------------------------------------------------------+
