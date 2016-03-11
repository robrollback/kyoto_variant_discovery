### Read Trimming and Clipping of Adapters

Reads are trimmed from the 3' end to have a phred score of at least **30**. Illumina sequencing adapters are removed from the reads, and all reads are required to have a length of at least **50** bp. Trimming and clipping are performed using [Trimmomatic]\ [@trimmomatic].

Table: Trimming Statistics per Readset ([download full table](trimReadsetTable.tsv))

Sample|Readset|Raw Paired Reads #|Surviving Paired Reads #|Surviving Paired Reads %
-----|-----|-----:|-----:|-----:
NA12878|NA12878_S1_L001|199,926,151|197,274,901|98.7
NA12878|NA12878_S1_L002|196,779,406|194,265,429|98.7
NA12878|NA12878_S1_L003|198,734,315|196,196,656|98.7
NA12878|NA12878_S1_L004|197,606,617|195,013,207|98.7
NA12891|NA12891_S1_L005|196,621,011|194,797,306|99.1
NA12891|NA12891_S1_L006|195,733,015|193,809,658|99.0
NA12891|NA12891_S1_L007|196,193,135|194,326,013|99.0
NA12891|NA12891_S1_L008|197,254,871|195,367,422|99.0
NA12892|NA12892_S1_L004|214,461,918|212,659,602|99.2
NA12892|NA12892_S1_L005|213,955,162|212,160,320|99.2
NA12892|NA12892_S1_L006|210,836,604|208,934,117|99.1
NA12892|NA12892_S1_L007|212,240,533|210,569,426|99.2

* Raw Paired Reads #: number of Paired Reads obtained from the sequencer
* Surviving Paired Reads #: number of Remaining Paired Reads after the trimming step
* Surviving Paired Reads %: percentage of Surviving Paired Reads / Raw Paired Reads
