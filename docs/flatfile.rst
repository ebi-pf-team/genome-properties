=====================
Genome Property Types
=====================

There are six different types of Genome Properties (GP) represented.

:PATHWAY: These represent groups of proteins that perform biochemical steps in order within a recognised enzymatic pathway.
:METAPATH: These represent a specific type of PATHWAY where one or more of the steps within the pathway are described by another Genome Property. For the purposes of calculation, METAPATHs are dependent on their respective GP steps.
:SYSTEM: These represent groups of proteins that work together to fulfil a role, but do not necessarily represent a traditional enzymatic pathway (for example, transport systems).
:COMPLEX: These represent stable macromolecular complexes.
:GUILD: These represent groups of proteins sharing overall function, but which do not represent a system.
:CATEGORY: These are organisational properties that allow the full set of genome properties to be arranged into a hierarchy. These properties are not calculated.


===============
Flatfile Format
===============

Each Genome Property is represented by up to three files

+ **DESC file** - a description of the GP and the constituent steps
+ **FASTA file** - a concatenation of fasta files that resolve to a yes for each of the constituent steps
+ **status file** - a record of binary flags recording whether the GP has been curated and is to be made public

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
| AU | Author                                             |
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
|\** | Private notes                                      |
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

The DESC file is formatted such that a single tag is included on each line, followed by 2 blank spaces, followed by the value of the field. 

In the case of the property description (CC) and private notes (**) fields, the information may stretch accross multiple lines. The line length is limited to 80 characters (including the tag) and so any subsequent lines used must also carry the tag. See the PATHWAY example below.


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


While the layout of the DESC file for CATEGORY type properties follows the same format, the steps do not refer to calculable evidence. In the case of CATEGORY, the steps define the properties (including other sub-categories) that exist as children of the CATEGORY. See the CATEGORY example below.

.. code-block:: none
  
  AC  GenProp0063
  DE  Biosynthesis
  TP  CATEGORY
  AU  Haft DH
  TH  0
  CC  The process of creating complex biomolecules from simpler starting
  CC  materials.
  --
  SN  1
  ID  Natural products biosynthesis
  RQ  0
  EV  GenProp0077;
  --
  SN  2
  ID  Amino acid biosynthesis
  RQ  0
  EV  GenProp0126;
  --
  SN  3
  ID  Cofactor biosynthesis
  RQ  0
  EV  GenProp0184;
  --
  SN  4
  ID  Nucleotide biosynthesis
  RQ  0
  EV  GenProp0185;
  --
  SN  5
  ID  Storage and structural polymer biosynthesis
  RQ  0
  EV  GenProp0186;
  //
  

----------
FASTA file
----------

The FASTA file includes fasta sequences that are a match for each constituent step of the property. GPs of type CATEGORY do not have associated FASTA files as they do not contain any calculable steps. Similarly, a METAPATH which contains only GPs as evidence for its steps, would not have an associated FASTA file.
The FASTA file is formatted such that each individual block of fasta sequence includes a descriptive header line, in the format provided by UniProt. The appropriate step number is then added to this header line in parenthesis, as shown below.

.. code-block:: none

  >sp|P0AB91|AROG_ECOLI (Step num: 1) Phospho-2-dehydro-3-deoxyheptonate aldolase, Phe-sensitive OS=Escherichia coli (strain K12) GN=aroG PE=1 SV=1  

An example FASTA file is shown here:

.. code-block:: none

  >sp|P0AB91|AROG_ECOLI (Step num: 1) Phospho-2-dehydro-3-deoxyheptonate aldolase, Phe-sensitive OS=Escherichia coli (strain   K12) GN=aroG PE=1 SV=1
  MNYQNDDLRIKEIKELLPPVALLEKFPATENAANTVAHARKAIHKILKGNDDRLLVVIGP
  CSIHDPVAAKEYATRLLALREELKDELEIVMRVYFEKPRTTVGWKGLINDPHMDNSFQIN
  DGLRIARKLLLDINDSGLPAAGEFLDMITPQYLADLMSWGAIGARTTESQVHRELASGLS
  CPVGFKNGTDGTIKVAIDAINAAGAPHCFLSVTKWGHSAIVNTSGNGDCHIILRGGKEPN
  YSAKHVAEVKEGLNKAGLPAQVMIDFSHANSSKQFKKQMDVCADVCQQIAGGEKAIIGVM
  VESHLVEGNQSLESGEPLAYGKSITDACIGWEDTDALLRQLANAVKARRG
  
  >sp|P07639|AROB_ECOLI (Step num: 2) 3-dehydroquinate synthase OS=Escherichia coli (strain K12) GN=aroB PE=1 SV=1
  MERIVVTLGERSYPITIASGLFNEPASFLPLKSGEQVMLVTNETLAPLYLDKVRGVLEQA
  GVNVDSVILPDGEQYKSLAVLDTVFTALLQKPHGRDTTLVALGGGVVGDLTGFAAASYQR
  GVRFIQVPTTLLSQVDSSVGGKTAVNHPLGKNMIGAFYQPASVVVDLDCLKTLPPRELAS
  GLAEVIKYGIILDGAFFNWLEENLDALLRLDGPAMAYCIRRCCELKAEVVAADERETGLR
  ALLNLGHTFGHAIEAEMGYGNWLHGEAVAAGMVMAARTSERLGQFSSAETQRIITLLKRA
  GLPVNGPREMSAQAYLPHMLRDKKVLAGEMRLILPLAIGKSEVRSGVSHELVLNAIADCQ
  SA
  
  >sp|P05194|AROD_ECOLI (Step num: 3) 3-dehydroquinate dehydratase OS=Escherichia coli (strain K12) GN=aroD PE=1 SV=2
  MKTVTVKDLVIGTGAPKIIVSLMAKDIASVKSEALAYREADFDILEWRVDHYADLSNVES
  VMAAAKILRETMPEKPLLFTFRSAKEGGEQAISTEAYIALNRAAIDSGLVDMIDLELFTG
  DDQVKETVAYAHAHDVKVVMSNHDFHKTPEAEEIIARLRKMQSFDADIPKIALMPQSTSD
  VLTLLAATLEMQEQYADRPIITMSMAKTGVISRLAGEVFGSAATFGAVKKASAPGQISVN
  DLRTVLTILHQA
  
  >sp|P15770|AROE_ECOLI (Step num: 4) Shikimate dehydrogenase (NADP(+)) OS=Escherichia coli (strain K12) GN=aroE PE=1 SV=1
  METYAVFGNPIAHSKSPFIHQQFAQQLNIEHPYGRVLAPINDFINTLNAFFSAGGKGANV
  TVPFKEEAFARADELTERAALAGAVNTLMRLEDGRLLGDNTDGVGLLSDLERLSFIRPGL
  RILLIGAGGASRGVLLPLLSLDCAVTITNRTVSRAEELAKLFAHTGSIQALSMDELEGHE
  FDLIINATSSGISGDIPAIPSSLIHPGIYCYDMFYQKGKTPFLAWCEQRGSKRNADGLGM
  LVAQAAHAFLLWHGVLPDVEPVIKQLQEELSA
  
  >sp|P0A6D7|AROK_ECOLI (Step num: 5) Shikimate kinase 1 OS=Escherichia coli (strain K12) GN=aroK PE=1 SV=2
  MAEKRNIFLVGPMGAGKSTIGRQLAQQLNMEFYDSDQEIEKRTGADVGWVFDLEGEEGFR
  DREEKVINELTEKQGIVLATGGGSVKSRETRNRLSARGVVVYLETTIEKQLARTQRDKKR
  PLLHVETPPREVLEALANERNPLYEEIADVTIRTDDQSAKVVANQIIHMLESN
  
  >sp|P0A6D3|AROA_ECOLI (Step num: 6) 3-phosphoshikimate 1-carboxyvinyltransferase OS=Escherichia coli (strain K12) GN=aroA   PE=1 SV=1
  MESLTLQPIARVDGTINLPGSKSVSNRALLLAALAHGKTVLTNLLDSDDVRHMLNALTAL
  GVSYTLSADRTRCEIIGNGGPLHAEGALELFLGNAGTAMRPLAAALCLGSNDIVLTGEPR
  MKERPIGHLVDALRLGGAKITYLEQENYPPLRLQGGFTGGNVDVDGSVSSQFLTALLMTA
  PLAPEDTVIRIKGDLVSKPYIDITLNLMKTFGVEIENQHYQQFVVKGGQSYQSPGTYLVE
  GDASSASYFLAAAAIKGGTVKVTGIGRNSMQGDIRFADVLEKMGATICWGDDYISCTRGE
  LNAIDMDMNHIPDAAMTIATAALFAKGTTTLRNIYNWRVKETDRLFAMATELRKVGAEVE
  EGHDYIRITPPEKLNFAEIATYNDHRMAMCFSLVALSDTPVTILDPKCTAKTFPDYFEQL
  ARISQAA
  
  >sp|P12008|AROC_ECOLI (Step num: 7) Chorismate synthase OS=Escherichia coli (strain K12) GN=aroC PE=1 SV=4
  MAGNTIGQLFRVTTFGESHGLALGCIVDGVPPGIPLTEADLQHDLDRRRPGTSRYTTQRR
  EPDQVKILSGVFEGVTTGTSIGLLIENTDQRSQDYSAIKDVFRPGHADYTYEQKYGLRDY
  RGGGRSSARETAMRVAAGAIAKKYLAEKFGIEIRGCLTQMGDIPLDIKDWSQVEQNPFFC
  PDPDKIDALDELMRALKKEGDSIGAKVTVVASGVPAGLGEPVFDRLDADIAHALMSINAV
  KGVEIGDGFDVVALRGSQNRDEITKDGFQSNHAGGILGGISSGQQIIAHMALKPTSSITV
  PGRTINRFGEEVEMITKGRHDPCVGIRAVPIAEAMLAIVLMDHLLRQRAQNADVKTDIPR
  W

-----------
Status file
-----------

Each GP has an associated 'status' file which records (using binary flags) whether the property has been curated, and whether it is to be made public. This file is edited by the curator as part of the curation process prior to release. Private curator notes can be included below the double hyphen. An example status file is shown here:

.. code-block:: none

  checked:  1
  public: 0
  --
  contains a dependent GP that is not yet public


