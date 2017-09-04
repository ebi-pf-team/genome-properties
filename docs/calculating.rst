Calculating Genome Properties
=============================


The presence or absence of genome properties (GPs) within a given genome or proteome, is calculated based on the hits to the relevant InterPro entries and their associated protein signatures. The evidence for each constituent step is tested against the genome in question, and each step defined as a hit or a miss. The total number of hits is then compared with the threshold level defined for the GP, to determine if the GP resolves to a YES (all required steps are present), NO (no required steps are present) or PARTIAL (the number of required steps present is greater that the threshold, and so some evidence of the presence of the GP can be assumed).

The pipeline for how users can calculate GPs for there own data is shown in the figure below.

.. |calc| image::  _static/images/calculation_fig.jpg

|calc|


Description of workflow.
