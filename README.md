# Introduction to Variants Annotation and Discovery
***By Robert Eveleigh, MSc.***

In this workshop, we will present the main steps involved in variant annotation using the Gemini framework. We will focus on pedigree CEPH 1463 derived from Illumina PCR-free Platinum whole genome data and provide command lines to annotation and query the Gemini database to explore and extract variants of interest. 

We will be working with the CEPH 1463 pedigree found on Illumina's baseSpace or EMBL repositories:
http://www.1000genomes.org/data

![pedigree](img/pedigree.jpg)

Due to time and resource restraints, 1000 variants around a known variant of interest from chromosome 10 was extracted.

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/deed.en_US). This means that you are able to copy, share and modify the work, as long as the result is distributed under the same license.

## Original Setup

The initial structure of your folders should look like this:
```
<ROOT>
|-- variants/                # processed variants from the center (specific region)
    `-- ceph_pedigree        # CEPH pedigree directory. Contains the vcf file
    
```

### Cheat file
* You can find all the unix command lines of this practical in the file: commands.sh

### Environment setup
```
cd $HOME
rsync -avP /home/reveleigh/cleanCopy/variants $HOME/workshop
cd $HOME/workshop

cd $HOME/workshop/bin
source var_ann_config.sh

cat var_ann_config.sh:
    export VT_HOME=
    export SNPEFF_HOME=/usr/local/src/snpEff/
    export GEMINI_HOME=
    export GEMINI_LIBS=
    
        
```

### Software requirements
These are all already installed, but here are the original links.

    * [VT](http://genome.sph.umich.edu/wiki/Vt)
    * [SnpEff](http://snpeff.sourceforge.net/)
    * [Gemini](http://gemini.readthedocs.org/en/latest/index.html)


#Variant exploration and discovery    
Three samples from the CEPH pedigree have been sequenced and processed.  The raw data has been trimmed, quality read pairs mapped to the reference genome and the resulting bam files have been further processed using indel realigner, fixmates, and base recalibration. Variants were called with GATK haplotype caller in GVCF mode, and soft filtered using variant recalibration (VQSR)

![Data processing diagram](img/dnaseq_pipeline.jpg)

[CEPH1463 report](report/index.html)
    
### VCF file
Exploring the vcf format.

Try these commands:

**Explore the header**
```
zcat cephPedigree.vqsr.vcf.gz | grep "^##"
``` 
***What is the vcf format version?***

***What genome build was used for variant calling?***

***What version of GATK Haplotype caller was used?***

[solutions](solutions/_vcf_header.md)

**Explore the body of the vcf**
```
zcat cephPedigree.vqsr.vcf.gz | grep -w -A1 "^#CHROM" 
```

***How many samples are in this pedigree?***

[solutions](solutions/_vcf_body.md)

```
zcat cephPedigree.vqsr.vcf.gz | grep -v "#" | wc -l 
```

***How many variants are in this vcf file?***

[solutions](solutions/_vcf_variants.md)

#Preprocessing vcf file for Gemini (OPTIONAL)
For best results, the vcf file requires further processing before loading and annotation with Gemini

Additionally, since we are working with a pedigree we can also provide a ped file to represent the metadata 

###Decompose and Normalize vcf with vt

Try command:
```
zcat x.gz | sed 's/ID=AD,Number=./ID=AD,Number=R/' | $VT_HOME decompose -s - | $VT_HOME normalize -r $GENOME_FASTA - | bgzip -cf > cephPedigree.vqsr.vt.vcf.gz
```

***How many variants were decomposed and normalized?***

### snpEff

Try command:
```
java -Xmx4G -jar $SNPEFF_HOME/snpeff.jar GRCh37.75 -formatEff -classic -lof 
```    

###Loading variants in Gemini

**Examine ped file**

Try command:
```
less ceph.ped
```
 
Try command:
```
gemini load -v cephPedigree.vqsr.vt.snpeff.vcf.gz -p ceph.ped -t snpEff cephPedigree.gemini.18.2.db
```

#SQL basics
Let's briefly go over some basic SQL syntax which will be used

Required:
  * SELECT statement: fetch data and view from a table. Columns can be a list of comma-separated columns or an asterisk (*) to return all columns
  * FROM clause: specifics the table to query from

Optional:  
  * WHERE clause: filter rows in the result set

For more information about SQL see [sqlzoo](http://sqlzoo.net/)
  
#Explore Gemini

##Gemini syntax basics


###Explore Gemini tables

Try command: 

```
gemini db_info cephPedigree.gemini.18.2.db
```

Output: (For more information see [column descriptions](http://gemini.readthedocs.org/en/latest/content/database_schema.html))

```
    table_name column shows whether information stored applies to:
        * variants
        * variant_impacts
        * samples
        * gene_detailed
        * gene_summary
        
    Note: each of these tables are connected to one or more tables using unique identifiers    
    
    types columns shows the type of information
        * text - just plain text (e.g. "indels" or "SNP")
        * integer - a whole number (e.g. "start" position)
        * float - a number with decimal places (e.g. "call_rate")
        * blob - special data type interpreted by Gemini (genotype data)
        * bool - can be true or false
```

###Explore variants in Gemini (and data check)

First let us check to database to make sure all variants are imported and the samples information is correct.

Check the number of variants matches the number in of variants in the vcf

Try command:
```
gemini stats --gts-by-sample cephPedigree.gemini.18.2.db | column -t 
```        

Check that the sample information is correct

```
gemini query --header -q "SELECT * FROM samples" cephPedigree.gemini.18.2.db | column -t
```

```
gemini query -q "SELECT count(*) FROM samples WHERE gene = 'CYP2C19'" cephPedigree.gemini.18.2.db
```
        
###Summarize variants in Gemini

Summarize genotype counts for variants in CYP2C19 gene and have GATK VQSR PASS filter

Try command:
```
gemini stats --summarize "SELECT * FROM variants WHERE \ 
    filter is NULL \
    AND gene = 'CYP2C19'" \
    cephPedigree.gemini.18.2.db | column -t
```

Note: 
    - WHERE is a conditional statement. In this instance, we would like to find variants that PASS GATK VQSR filters AND found in CYP2C19 gene
    - filter is NULL i.e. does not contain VQSR descriptor
    
###Gemini querying - associations to a phenotype

To identify variants that are associated or causal for a disease we can utilize the Clinvar database

Try command:
```
gemini query --header -q "SELECT * FROM variants WHERE \
    clinvar_disease_name is not NULL \
    AND filter is NULL" \
    cephPedigree.gemini.18.2.db | column -t
```    
***Note:*** addition of clinvar_disease_name is not NULL, meaning to look for variants with a clinvar annotation
    
Two variants are found with Clinvar annotations: [rs4244285](http://www.snpedia.com/index.php/Rs4244285) found in CYP2C19 and [rs1799853](https://www.snpedia.com/index.php/Rs1799853) found in CYP2C9 another p450 gene. 
    
This generates a lot of columns let's focus the analysis to a specific set of columns related to dbsnp, the [ExAC](http://exac.broadinstitute.org/) control database, and clinvar

```
gemini query --header --show-samples -q "SELECT rs_ids, aaf_adj_exac_afr, aaf_adj_exac_amr, aaf_adj_exac_eas, aaf_adj_exac_sas, clinvar_disease_name, clinvar_sig \
    FROM variants WHERE \ 
    clinvar_disease_name is not NULL \
    AND filter is NULL \
    AND gene = 'CYP2C19'" \
    cephPedigree.gemini.18.2.db | column -t 

```

***Note:*** --show-samples argument generates columns displaying which samples have a variants and what type of variants

***For this variant in which population(s) is this variant more frequent in?***

```
    afr = African
    amr = American
    eas = East Asian
    sas = South Asian
```

[solutions](solutions/_population.md)

***What are the genotypes for the three samples?***

[solutions](solutions/_sample_genotypes.md)

###Variant discovery and Exploration 
With a prior knowledge of the variant of interest, it is easy to find and validate the present of rs4244285

However, in cases where the answer is unknown, variant prioritization is not trivial. Study design and initial hypotheses will guide the exploration of the results.

Gemini provides tools and annotations to investigate these types of scenarios, but still in caution must be taken in the prioritization of the variants.

    Study design e.g.
        * Pedigrees :     de novo, autosomal recessive, autosomal dominant, compound heterozygotes
        * Case-control :  burden/non-burden test

    Hypotheses e.g. :
        * Complex disease : pathway analysis, protein interaction
        * Rare disease: presence and low frequency in known population databases 

    Some guidelines:
        * Variants of interest should contain good sample based depth of coverage (default >10x and more important in exome data)
        * Start with high impact variants or variants with high CADD scores(variants predicted functional, deleterious and pathogentic variants)
        * Genomic features: if found within or near repeat regions, segmental duplications, etc.  Variant could be a false positive.

####Advanced Gemini querying

For each individual, Gemini gives access to genotype, depth, genotype quality and genotype likelihood at each variant.

    gt_type.sampleID
        * HOM_REF
        * HET
        * HOM_ALT
        
    gt_qual.sampleID
        * genotype quality
        
    gt_depths.sampleID
        * Total number of reads in this sample at position x
    
    gt_ref_depths.sampleID
        * number of **reference allele** reads in this sample at position x
        
    gt_alt_depths.sampleID
        * number of **alternate allele** reads in this sample at position x
        
Subsequently the per sample genotype information can be also be filtered upon using the --gt-filter option

Examples:
Instead of listing 100 threshold filters on depth like below 

```
gemini query -q "SELECT * FROM variants" \
                    --gt-filter "gt_depths.sample1 >= 20 AND \
                                  gt_depths.sample2 >= 20 AND \
                                  gt_depths.sample3 >= 20 AND \
                                  ...
                                  gt_depths.sample100 >= 20" \
                     extended_ped.db
```

Use wildcard implementation
    --gt-filters is (COLUMN).(SAMPLE_WILDCARD).(SAMPLE_WILDCARD_RULE).(RULE_ENFORCEMENT)
                     
The previous command will be condensed down to:

```
gemini query -q "SELECT * FROM variants" \
                    --gt-filter "(gt_depths).(*).(>=20).(all)"
                    extended_ped.db
```                 

For more complex examples see: [Wildcard](http://gemini.readthedocs.org/en/latest/content/querying.html#gt-filter-wildcard-filtering-on-genotype-columns) section

Try command:
```
gemini query --header --show-samples -q "SELECT chrom, start, end, gene, rs_ids, impact, impact_severity, cadd_scaled, aaf_adj_exac_all, clinvar_disease_name, clinvar_sig, rmsk, in_cpg_island, in_segdup FROM variants \
                WHERE filter is NULL AND impact_severity <> 'LOW'"
                --gt-filter "(gt_depths).(*).(>=10).(all)" test.db | column -t
    
```       


