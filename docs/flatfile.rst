===============
Flatfile Format
===============

Each Genome Property is represented by two files. The first (the DESC file) is a description of the 
GP and the constituent steps. The second (the FA file) is a concatenation of fasta files that resolve 
to a yes for each of the constituent steps.

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
| ** | Private notes                                      |
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




