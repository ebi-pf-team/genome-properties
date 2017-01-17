===============
Flatfile Format
===============

Each Genome Property is represented by two files

+ **DESC file** - is a description of the GP and the constituent steps
+ **FA file** - is a concatenation of fasta files that resolve to a yes for each of the constituent steps

---------
DESC file
---------

The tags used in the DESC file are listed below, along with the description of the field they relate to.

+----+----------------------------------------------------+
| AC | Accession ID                                       |
+----+----------------------------------------------------+
| DE | Description/name of Genome Property                |
+----+----------------------------------------------------+
| TP | Type                                               |
+----+----------------------------------------------------+
| TH | Threshold                                          |
+----+----------------------------------------------------+
| RN | Reference number                                   |
+----+----------------------------------------------------+
| RM | PMID of reference                                  |
+----+----------------------------------------------------+
| RT | Reference title                                    |
+----+----------------------------------------------------+
| RA | Reference author                                   |
+----+----------------------------------------------------+
| RL | Reference citation                                 |
+----+----------------------------------------------------+
| DC | Database title                                     |
+----+----------------------------------------------------+
| DR | Database link                                      |
+----+----------------------------------------------------+
| PN | Parent accession ID                                |
+----+----------------------------------------------------+
| CC | Property description                               |
+----+----------------------------------------------------+
| \** | Private notes                                      |
+----+----------------------------------------------------+
| -- | Separator                                          |
+----+----------------------------------------------------+
| SN | Step number                                        |
+----+----------------------------------------------------+
| ID | Step ID                                            |
+----+----------------------------------------------------+
| DN | Step display name (includes EC number if available)|
+----+----------------------------------------------------+
| RQ | Required step                                      |
+----+----------------------------------------------------+
| EV | Evidence (includes whether sufficient)             |
+----+----------------------------------------------------+
| TG | Gene Ontology (GO) ID                              |
+----+----------------------------------------------------+
| // | End                                                |
+----+----------------------------------------------------+

The DESC file is formatted such that a single tag is included on each line, followed by 2 blank spaces, followed by the value of the field. In the case of the property description (CC) and private notes (**) fields, the information may stretch accross multipe lines. The line length is limited to 75 characters (including the tag) and so any subsequent lines used must also carry the tag. See the example below.

.. code-block:: none

AC  GenProp0001  
DE  chorismate biosynthesis via shikimate  
TP  PATHWAY  
AU  Haft D  
TH  2  
RN  [1]  
RM  12636087  
RT  The biosynthesis of shikimate metabolites.
RA  Knaggs AR;
RL  Nat Prod Rep. 2003;20:119-136.
DC  Shikimate and Chorismate Biosynthesis
DR  IUBMB; misc; shikim;
DC  Phenylalanine, Tyrosine and Tryptophan Biosynthesis
DR  KEGG; map00400;
DC  Chorismate biosynthesis
DR  MetaCyc; ARO-PWY;
CC  Chorismate is the final common intermediate in the biosynthesis of
CC  phenylalanine, tyrosine and tryptophan (the aromatic amino acids) as
CC  well as menaquinone, ubiquinone, salicylate and phenazine.  Chorismate
CC  is synthesized via a seven-step pathway starting from the precursors
CC  D-erythrose 4-phosphate and phosphoenolpyruvate.  This pathway is
CC  widely distributed among microorganisms.  Certain methanogenic
CC  euarchaeota appear to be missing the first two steps of the pathway -
CC  these may be catalyzed by as of yet uncharacterized enzymes.
**  Archaea are hard to assign.  It would appear that the chorismate
**  pathway is at least partially present in archaea, since many synthesize
**  aromatic amino acids and contain some of the enzymes covered by the
**  present HMM-set.  In particular, shikimate kinase appears to be absent
**  in many archaea which contain the enzymes before and after it in the
**  pathway (Archaeoglobus, Methanobacterium, Methanococcus, Pyrococcus)
**  implying that there may be a non-orthologous enzyme.  Similarly, the
**  first two steps of the pathway appear to be missing in certain archaea
**  but are found in others.
--
SN  1
ID  phospho-2-dehydro-3-deoxyheptonate aldolase
DN  phospho-2-dehydro-3-deoxyheptonate aldolase (EC 2.5.1.54)
RQ  1
EV  IPR006219; TIGR00034; sufficient;
TG  GO:0009423;
EV  IPR002480; TIGR01358; sufficient;
TG  GO:0009423;
EV  IPR006268; TIGR01361; sufficient;
TG  GO:0009423;
EV  IPR010210; TIGR01949; sufficient;
TG  GO:0009423;
--
SN  2
ID  3-dehydroquinate synthase
DN  3-dehydroquinate synthase (EC 4.2.3.4)
RQ  1
EV  IPR016037; TIGR01357; sufficient;
TG  GO:0009423;
EV  IPR002812; PF01959; sufficient;
TG  GO:0009423;
--
SN  3
ID  3-dehydroquinate dehydratase
DN  3-dehydroquinate dehydratase (EC  4.2.1.10)
RQ  1
EV  IPR001874; TIGR01088; sufficient;
TG  GO:0009423;
EV  IPR001381; TIGR01093; sufficient;
TG  GO:0009423;
--
SN  4
ID  shikimate 5-dehydrogenase
DN  shikimate 5-dehydrogenase (EC  1.1.1.25)
RQ  1
EV  IPR011342; TIGR00507; sufficient;
TG  GO:0009423;
EV  IPR010110; TIGR01809; sufficient;
TG  GO:0009423;
--
SN  5
ID  shikimate kinase
DN  shikimate kinase (EC  2.7.1.71)
RQ  1
EV  IPR031322; PF01202; sufficient;
TG  GO:0009423;
EV  IPR010189; TIGR01920; sufficient;
TG  GO:0009423;
--
SN  6
ID  3-phosphoshikimate 1-carboxyvinyltransferase
DN  3-phosphoshikimate 1-carboxyvinyltransferase (EC  2.5.1.19)
RQ  1
EV  IPR006264; TIGR01356; sufficient;
TG  GO:0009423;
--
SN  7
ID  chorismate synthase
DN  chorismate synthase (EC  4.2.3.5)
RQ  1
EV  IPR000453; TIGR00033; sufficient;
TG  GO:0009423;
//


---------
FA file
---------

The FA file is formatted such that each individual block of fasta sequence includes a header line. This header line is comprised of the UniProt ID for the sequence, and the step number that the sequence relates to as evidence. An example FA file is shown below.


