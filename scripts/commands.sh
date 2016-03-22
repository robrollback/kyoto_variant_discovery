##Setup

cd $HOME
rsync -avP /home/reveleigh/cleanCopy/workshop_variants $HOME/workshop_variants
cd $HOME/workshop_variants

ls -lhtr $HOME/workshop_variants

cd $HOME/workshop_variants

source bin/var_ann_config.sh

cd ceph

##VCF format

zcat cephPedigree.vqsr.vcf.gz | grep "^##"

zcat cephPedigree.vqsr.vcf.gz | grep -w -A2 "^#CHROM"

zcat cephPedigree.vqsr.vcf.gz | grep -v "#" | wc -l 

##Gemini preprocessing

zcat cephPedigree.vqsr.vcf.gz | sed 's/ID=AD,Number=./ID=AD,Number=R/' | $VT_HOME decompose -s - | $VT_HOME normalize -r $GENOME_FASTA - | bgzip -cf > cephPedigree.vqsr.vt.vcf.gz

java -Xmx4G -jar $SNPEFF_HOME/snpeff.jar GRCh37.75 -classic -lof -i vcf  -o vcf GRCh37.75 cephPedigree.vqsr.vt.vcf.gz | bgzip -cf > cephPedigree.vqsr.vt.snpeff.vcf.gz

##Gemini loading

gemini load -v cephPedigree.vqsr.vt.snpeff.vcf.gz -p ceph.ped -t snpEff cephPedigree.gemini.18.2.db

##Exploring Gemini

gemini db_info cephPedigree.gemini.18.2.db | column -t | less

gemini stats --gts-by-sample cephPedigree.gemini.18.2.db | column -t 

gemini query --header -q "SELECT * FROM samples" cephPedigree.gemini.18.2.db | column -t

gemini query -q "SELECT count(*) FROM samples WHERE gene = 'CYP2C19'" cephPedigree.gemini.18.2.db

gemini query -q "SELECT count(*) FROM samples WHERE filter is NULL AND gene = 'CYP2C19'" cephPedigree.gemini.18.2.db

gemini stats --summarize "SELECT * FROM variants WHERE filter is NULL AND gene = 'CYP2C19'" cephPedigree.gemini.18.2.db | column -t

gemini query --header -q "SELECT * FROM variants WHERE clinvar_disease_name is not NULL AND filter is NULL" cephPedigree.gemini.18.2.db | column -t

gemini query --header --show-samples -q "SELECT rs_ids, aaf_adj_exac_afr, aaf_adj_exac_amr, aaf_adj_exac_eas, aaf_adj_exac_sas, clinvar_disease_name, clinvar_sig FROM variants WHERE clinvar_disease_name is not NULL AND filter is NULL AND gene = 'CYP2C19'" cephPedigree.gemini.18.2.db | column -t

gemini query --header --show-samples -q "SELECT chrom, start, end, gene, rs_ids, impact, impact_severity, cadd_scaled, aaf_adj_exac_all, clinvar_disease_name, clinvar_sig, rmsk, in_cpg_island, in_segdup FROM variants WHERE filter is NULL AND impact_severity <> 'LOW'" --gt-filter "(gt_depths).(*).(>=10).(all)" test.db | column -t