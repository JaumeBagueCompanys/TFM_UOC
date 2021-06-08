#!/bin/bash



conda activate qiime2-2020.2


###################################################################################################

# Import sequences in qiime2

mkdir demux

qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path manif_RUN4 \
--output-path demux/paired-end-demux_RUN4.qza \
--input-format PairedEndFastqManifestPhred33V2 


qiime demux summarize \
  --i-data demux/paired-end-demux_RUN4.qza \
  --o-visualization demux/paired-end-demux_RUN4.qzv


qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path manif_RUN5 \
--output-path demux/paired-end-demux_RUN5.qza \
--input-format PairedEndFastqManifestPhred33V2 


qiime demux summarize \
  --i-data demux/paired-end-demux_RUN5.qza \
  --o-visualization demux/paired-end-demux_RUN5.qzv


qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path manif_RUN6 \
--output-path demux/paired-end-demux_RUN6.qza \
--input-format PairedEndFastqManifestPhred33V2 


qiime demux summarize \
  --i-data demux/paired-end-demux_RUN6.qza \
  --o-visualization demux/paired-end-demux_RUN6.qzv

###################################################################################

mkdir DADA2
#DADA2 = Denoise and quality control

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux/paired-end-demux_RUN4.qza \
  --p-trim-left-f 9 \
  --p-trim-left-r 9 \
  --p-trunc-len-f 250 \
  --p-trunc-len-r 240 \
  --p-n-threads 0 \
  --o-table DADA2/table_RUN4.qza \
  --o-representative-sequences DADA2/rep-seqs_R4.qza \
  --o-denoising-stats DADA2/denoising-stats_R4.qza
##output
#tabla de frecuencias
#secuencias a alinear
#calidad del denoising = fijarse en non-chimeric para tener una estima de la profundidad a la que se puede bajar

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux/paired-end-demux_RUN5.qza \
  --p-trim-left-f 9 \
  --p-trim-left-r 9 \
  --p-trunc-len-f 250 \
  --p-trunc-len-r 240 \
  --p-n-threads 0 \
  --o-table DADA2/table_RUN5.qza \
  --o-representative-sequences DADA2/rep-seqs_R5.qza \
  --o-denoising-stats DADA2/denoising-stats_R5.qza  

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux/paired-end-demux_RUN6.qza \
  --p-trim-left-f 9 \
  --p-trim-left-r 9 \
  --p-trunc-len-f 250 \
  --p-trunc-len-r 240 \
  --p-n-threads 0 \
  --o-table DADA2/table_RUN6.qza \
  --o-representative-sequences DADA2/rep-seqs_R6.qza \
  --o-denoising-stats DADA2/denoising-stats_R6.qza  

 ###################################################################################################
#DIFFERENT RUN MERGING + RAREFACTION CURVE
#Rarefaction curve is to set an appropiate sampling depth for downstream analysis



# 1. Dada2 outputs merging
 qiime feature-table merge \
  --i-tables DADA2/table_RUN4.qza \
  --i-tables DADA2/table_RUN5.qza \
  --i-tables DADA2/table_RUN6.qza \
  --o-merged-table DADA2/table-merged.qza

 qiime feature-table summarize \
  --i-table DADA2/table-merged.qza \
  --o-visualization DADA2/table-merged.qzv \
  --m-sample-metadata-file metadata_RUN456.tsv

cd DADA2 
# 1b. Merge Representative sequences

qiime feature-table merge-seqs \
  --i-data rep-seqs_R4.qza \
  --i-data rep-seqs_R5.qza \
  --i-data rep-seqs_R6.qza \
  --o-merged-data rep-seqs-merged.qza
  
qiime feature-table tabulate-seqs \
  --i-data rep-seqs-merged.qza \
  --o-visualization rep-seqs-merged.qzv


# 1c. Denoising stats study

qiime metadata tabulate \
  --m-input-file denoising-stats_R4.qza \
  --o-visualization denoising-stats_R4.qzv

qiime metadata tabulate \
  --m-input-file denoising-stats_R5.qza \
  --o-visualization denoising-stats_R5.qzv
 
 qiime metadata tabulate \
  --m-input-file denoising-stats_R6.qza \
  --o-visualization denoising-stats_R6.qzv 
 
 cd ..
 
# 1d. Quality filter  


#### Prueba 99otu
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path references/99_otus.fasta \
  --output-path references/99_otus.qza

qiime quality-control exclude-seqs \
  --i-query-sequences DADA2/rep-seqs-merged.qza \
  --i-reference-sequences references/99_otus.qza \
  --p-method vsearch \
  --p-perc-identity 0.65 \
  --p-perc-query-aligned 0.5 \
  --p-threads 16 \
  --o-sequence-hits DADA2/rep-seqs-merged-hits99.qza \
  --o-sequence-misses DADA2/rep-seqs-merged-misses99.qza

qiime feature-table tabulate-seqs \
  --i-data DADA2/rep-seqs-merged-hits99.qza \
  --o-visualization DADA2/rep-seqs-merged-hits99.qzv 
  
qiime feature-table tabulate-seqs \
  --i-data DADA2/rep-seqs-merged-misses99.qza \
  --o-visualization DADA2/rep-seqs-merged-misses99.qzv 

qiime feature-table filter-features \
  --i-table DADA2/table-merged.qza \
  --m-metadata-file DADA2/rep-seqs-merged-hits99.qza \
  --o-filtered-table DADA2/final-table-merged99.qza
  
qiime feature-table summarize \
  --i-table DADA2/final-table-merged99.qza  \
  --o-visualization DADA2/final-table-merged99.qzv

#### Prueba con 88otu
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path references/88_otus.fasta \
  --output-path references/88_otus.qza

qiime quality-control exclude-seqs \
  --i-query-sequences DADA2/rep-seqs-merged.qza \
  --i-reference-sequences references/88_otus.qza \
  --p-method vsearch \
  --p-perc-identity 0.65 \
  --p-perc-query-aligned 0.5 \
  --p-threads 16 \
  --o-sequence-hits DADA2/rep-seqs-merged-hits88.qza \
  --o-sequence-misses DADA2/rep-seqs-merged-misses88.qza


qiime feature-table tabulate-seqs \
  --i-data DADA2/rep-seqs-merged-hits88.qza \
  --o-visualization DADA2/rep-seqs-merged-hits88.qzv 
  
qiime feature-table tabulate-seqs \
  --i-data DADA2/rep-seqs-merged-misses88.qza \
  --o-visualization DADA2/rep-seqs-merged-misses88.qzv 
 
 qiime feature-table filter-features \
  --i-table DADA2/table-merged.qza \
  --m-metadata-file DADA2/rep-seqs-merged-hits88.qza \
  --o-filtered-table DADA2/final-table-merged88.qza
  
qiime feature-table summarize \
  --i-table DADA2/final-table-merged88.qza  \
  --o-visualization DADA2/final-table-merged88.qzv


###################################################################################################

mkdir tree

# 2. Tree generation

# 2.1. Multiple sequence alignment with MAFFT
qiime alignment mafft \
--i-sequences DADA2/rep-seqs-merged-hits88.qza  \
--p-n-threads 'auto' \
--o-alignment tree/aligned-rep-seqs.qza 

cd tree

# 2.2. Masking the hypevariable positions in the alignement
qiime alignment mask \
  --i-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza
  
# 2.3. Build phylogenetic tree with FastTree
qiime phylogeny fasttree \
  --i-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --p-n-threads 'auto'

# 2.4. Tree rooting
qiime phylogeny midpoint-root \
  --i-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

cd ..

###################################################################################################



mkdir calculos
   
# 3. CALCULOS
###################################################################################

#3.1. Fitering the table
qiime feature-table filter-samples \
  --i-table DADA2/final-table-merged88.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --o-filtered-table calculos/table.qza
 
 qiime metadata tabulate \
  --m-input-file calculos/table.qza \
  --o-visualization calculos/table.qzv

depht=500000
#En este apartado se usará el valor máximo
#de depht que se pueda obtener de denoising stats
#puesto que la rarefaction posterior se quiere ver
# cuando se satura la curva

#3.2. Alpha rarefaction calculation

qiime diversity alpha-rarefaction \
  --i-table calculos/table.qza \
  --i-phylogeny tree/rooted-tree.qza \
  --p-max-depth $depht \
  --m-metadata-file metadata_RUN456.tsv \
  --o-visualization calculos/alpha-rarefaction.qzv ;

depht=38000 
#3.3. core-metrics-phylogenetic

qiime diversity core-metrics-phylogenetic \
  --i-phylogeny tree/rooted-tree.qza \
  --i-table calculos/table.qza \
  --p-sampling-depth $depht \
  --m-metadata-file metadata_RUN456.tsv \
  --output-dir core-metrics-results \
  --p-n-jobs 16


#3.4. Alpha rarefaction calculation full

qiime diversity alpha-rarefaction \
  --i-table calculos/table.qza \
  --i-phylogeny tree/rooted-tree.qza \
  --p-max-depth $depht \
  --p-steps 20 \
  --m-metadata-file metadata_RUN456.tsv \
  --p-metrics goods_coverage \
  --p-metrics chao1 \
  --p-metrics shannon \
  --p-metrics observed_otus \
  --p-metrics faith_pd \
  --o-visualization core-metrics-results/alpha-rarefaction_full.qzv ;

#Since the artifacts to Vector of Faith PD values, observed-otus-vector y shannon-vector are already outputs from qiime diversity core-metrics-phylogenetic, here are only included the missing vectors


#3.5 Alpha Diversity 

qiime diversity alpha \
  --i-table calculos/table.qza \
  --p-metric goods_coverage \
  --output-dir core-metrics-results/goods-coverage_vector.qza ;

qiime diversity alpha \
  --i-table calculos/table.qza \
  --p-metric chao1 \
  --output-dir core-metrics-results/chao1_vector.qza ;

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/observed_otus_vector.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --o-visualization core-metrics-results/observed-otus-group-significance.qzv ;

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --o-visualization core-metrics-results/evenness-group-significance.qzv ;

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/shannon_vector.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --o-visualization core-metrics-results/shannon-group-significance.qzv ;

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/goods-coverage_vector.qza/alpha_diversity.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --o-visualization core-metrics-results/goods_coverage-group-significance.qzv ;

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/chao1_vector.qza/alpha_diversity.qza  \
  --m-metadata-file metadata_RUN456.tsv \
  --o-visualization core-metrics-results/chao1-group-significance.qzv ;


# 3.6 Beta diversity
#you will need to change the field you want to analyze
#automatically takes field1 variable

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column 'Condition' \
  --o-visualization core-metrics-results/unweighted_unifrac_Condition-significance.qzv \
  --p-pairwise 

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column 'Condition' \
  --o-visualization core-metrics-results/weighted_unifrac_Condition-significance.qzv \
  --p-pairwise 

qiime diversity adonis \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --p-formula 'Condition' \
  --o-visualization core-metrics-results/unweighted_unifrac_ADONIS-significance_Condition.qzv 


##Probamos


qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column 'Day_Status' \
  --o-visualization core-metrics-results/unweighted_unifrac_DayStatus-significance.qzv \
  --p-pairwise 

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column 'Day_Status' \
  --o-visualization core-metrics-results/weighted_unifrac_DayStatus-significance.qzv \
  --p-pairwise 

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/bray_curtis_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column 'Day_Status' \
  --o-visualization core-metrics-results/bray_curtis_DayStatus-significance.qzv \
  --p-pairwise 

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/jaccard_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column 'Day_Status' \
  --o-visualization core-metrics-results/jaccard_DayStatus-significance.qzv \
  --p-pairwise 

qiime diversity adonis \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --p-formula 'Day_Status' \
  --o-visualization core-metrics-results/unweighted_unifrac_ADONIS-significance_DayStatus.qzv 

qiime diversity adonis \
  --i-distance-matrix core-metrics-results/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --p-formula 'Day_Status' \
  --o-visualization core-metrics-results/weighted_unifrac_ADONIS-significance_DayStatus.qzv 



qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column 'Group_Day' \
  --o-visualization core-metrics-results/unweighted_unifrac_Group_Day-significance.qzv \
  --p-pairwise 

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column 'Group_Day' \
  --o-visualization core-metrics-results/weighted_unifrac_Group_Day-significance.qzv \
  --p-pairwise 

qiime diversity adonis \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --p-formula 'Group_Day' \
  --o-visualization core-metrics-results/unweighted_unifrac_ADONIS-significance_Group_Day.qzv 


# 4. Training feature classifiers with q2-feature-classifier Greengenes

mkdir training-feature-classifiers
  

# 4.1 

qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path references/99_otus.fasta \
  --output-path training-feature-classifiers/99_otus.qza

qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path references/99_otu_taxonomy.txt \
  --output-path training-feature-classifiers/ref-taxonomy.qza
    
cd training-feature-classifiers

qiime feature-classifier extract-reads \
  --i-sequences 99_otus.qza \
  --p-f-primer CCTACGGGNGGCWGCAG \
  --p-r-primer GACTACHVGGGTATCTAATCC \
  --p-trunc-len 0 \
  --p-min-length 100 \
  --p-max-length 480 \
  --o-reads ref-classif-seqs.qza \
  --p-n-jobs 16

qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads ref-classif-seqs.qza \
  --i-reference-taxonomy ref-taxonomy.qza \
  --o-classifier classifier.qza

qiime feature-classifier classify-sklearn \
  --i-classifier classifier.qza \
  --i-reads ref-classif-seqs.qza \
  --o-classification taxonomy.qza \
  --p-n-jobs 16

qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv 

cd .. 
# 4.2

  qiime feature-classifier classify-sklearn \
  --i-classifier training-feature-classifiers/classifier.qza \
  --i-reads DADA2/rep-seqs-merged-hits88.qza \
  --o-classification training-feature-classifiers/taxonomy_prova.qza \
  --p-n-jobs 16

qiime metadata tabulate \
  --m-input-file training-feature-classifiers/taxonomy_prova.qza \
  --o-visualization training-feature-classifiers/taxonomy_prova.qzv
  
  
qiime taxa barplot \
  --i-table DADA2/final-table-merged88.qza \
  --i-taxonomy training-feature-classifiers/taxonomy_prova.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --o-visualization training-feature-classifiers/taxa-bar-plots.qzv  


### 6. ANCOM

mkdir ancom

qiime feature-table filter-features \
  --i-table calculos/table.qza \
  --p-min-frequency 10 \
  --o-filtered-table ancom/table_filtered.qza


#ancon lvl_2

 
 qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 2 \
--o-collapsed-table ancom/table_filtered-l2.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l2.qza \
  --o-composition-table ancom/comp-filtered-table-2.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-2.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Group_Day \
  --o-visualization ancom/ancom-lvl2.qzv 
 
 #ancom lvl_3
  qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 3 \
--o-collapsed-table ancom/table_filtered-l3.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l3.qza \
  --o-composition-table ancom/comp-filtered-table-3.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-3.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Group_Day \
  --o-visualization ancom/ancom-lvl3.qzv 
 
 #ancom lvl_4
 
qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 4 \
--o-collapsed-table ancom/table_filtered-l4.qza
 
qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l4.qza \
  --o-composition-table ancom/comp-filtered-table-4.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-4.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Group_Day \
  --o-visualization ancom/ancom-lvl4.qzv 
 
 
 #ancom lvl_5
 
 qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 5 \
--o-collapsed-table ancom/table_filtered-l5.qza
 
qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l5.qza \
  --o-composition-table ancom/comp-filtered-table-5.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-5.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Group_Day \
  --o-visualization ancom/ancom-lvl5.qzv 
 
#ancom lvl_6
 
 qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 6 \
--o-collapsed-table ancom/table_filtered-l6.qza
 
qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l6.qza \
  --o-composition-table ancom/comp-filtered-table-6.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-6.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Group_Day \
  --o-visualization ancom/ancom-lvl6.qzv 
 
#ancom lvl_7 
 
qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 7 \
--o-collapsed-table ancom/table_filtered-l7.qza
 
qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l7.qza \
  --o-composition-table ancom/comp-filtered-table-7.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-7.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Group_Day \
  --o-visualization ancom/ancom-lvl7.qzv 
 
 
#ensayo con condition

mkdir ancom/prueba


#### sin filtraje
#ancon lvl_2
 
 qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 2 \
--o-collapsed-table ancom/table_filtered-l2.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l2.qza \
  --o-composition-table ancom/comp-filtered-table-2.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-2.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl2.qzv 
 
 #ancom lvl_3
  qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 3 \
--o-collapsed-table ancom/table_filtered-l3.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l3.qza \
  --o-composition-table ancom/comp-filtered-table-3.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-3.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl3.qzv 
 
 #ancom lvl_4
 
qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 4 \
--o-collapsed-table ancom/table_filtered-l4.qza
 
qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l4.qza \
  --o-composition-table ancom/comp-filtered-table-4.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-4.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl4.qzv 
 
 
 #ancom lvl_5
 
 qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 5 \
--o-collapsed-table ancom/table_filtered-l5.qza
 
qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l5.qza \
  --o-composition-table ancom/comp-filtered-table-5.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-5.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl5.qzv 
 
#ancom lvl_6
 
 qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 6 \
--o-collapsed-table ancom/table_filtered-l6.qza
 
qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l6.qza \
  --o-composition-table ancom/comp-filtered-table-6.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-6.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl6.qzv 

#ancom lvl7_condition

 
qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 7 \
--o-collapsed-table ancom/table_filtered-l7.qza
 
qiime composition add-pseudocount \
  --i-table ancom/table_filtered-l7.qza \
  --o-composition-table ancom/comp-filtered-table-7.qza
 
qiime composition ancom \
  --i-table ancom/comp-filtered-table-7.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl7.qzv 
  
 
 ###con filtraje por día
 
qiime feature-table filter-features \
  --i-table calculos/table.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --p-min-frequency 10 \
  --p-where "[Group_Day] IN ('30days')" \
  --o-filtered-table ancom/prueba/table_filtered_30.qza
 
qiime feature-table filter-features \
  --i-table calculos/table.qza \
  --p-min-frequency 10 \
  --m-metadata-file metadata_day_0.tsv \
  --o-filtered-table ancom/prueba/table_filtered_d0.qza
 
   qiime feature-table filter-features \
  --i-table calculos/table.qza \
  --p-min-frequency 10 \
  --m-metadata-file metadata_RUN456.tsv \
  --p-where "[Day_Status] IN ('0_D', '0_H')" \
  --o-filtered-table ancom/prueba/table_filtered_0.qza
 
 
 
qiime feature-table filter-features \
  --i-table calculos/table.qza \
  --p-min-frequency 10 \
  --o-filtered-table ancom/prueba/table_filtered.qza


 
 
 qiime feature-table summarize \
 --i-table ancom/prueba/table_filtered_30.qza \
 --o-visualization ancom/prueba/filtered_otu_table.qzv 

 
 
#ancon lvl_2
 
qiime taxa collapse \
--i-table ancom/table_filtered.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 2 \
--o-collapsed-table ancom/prueba/table_filtered-ls2.qza
 
qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-ls2.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s2.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s2.qza \
  --m-metadata-file metadata_day_0.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl2_d0.qzv 
 
  qiime taxa collapse \
--i-table ancom/prueba/table_filtered_60 \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 2 \
--o-collapsed-table ancom/prueba/table_filtered-ls2.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-sl2.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s2.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s2.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl2_d60.qzv 
 
 qiime taxa collapse \
--i-table ancom/prueba/table_filtered_0.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 2 \
--o-collapsed-table ancom/prueba/table_filtered-ls2.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-l2.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s2.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s2.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl2_d0.qzv 

 #ancom lvl_3
 
qiime taxa collapse \
--i-table ancom/prueba/table_filtered_30.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 3 \
--o-collapsed-table ancom/prueba/table_filtered-ls3.qza
 
qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-ls3.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s3.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s3.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl3_d30.qzv 
 
  qiime taxa collapse \
--i-table ancom/prueba/table_filtered_60 \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 3 \
--o-collapsed-table ancom/prueba/table_filtered-ls3.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-sl3.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s3.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s3.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl3_d60.qzv 
 
 qiime taxa collapse \
--i-table ancom/prueba/table_filtered_0.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 3 \
--o-collapsed-table ancom/prueba/table_filtered-ls3.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-l3.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s3.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s3.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl3_d0.qzv 


 #ancom lvl_4
 
qiime taxa collapse \
--i-table ancom/prueba/table_filtered_30.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 4 \
--o-collapsed-table ancom/prueba/table_filtered-ls4.qza
 
qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-ls4.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s4.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s4.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl4_d30.qzv 
 
  qiime taxa collapse \
--i-table ancom/prueba/table_filtered_60 \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 4 \
--o-collapsed-table ancom/prueba/table_filtered-ls4.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-sl4.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s4.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s4.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl4_d60.qzv 
 
 qiime taxa collapse \
--i-table ancom/prueba/table_filtered_0.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 4 \
--o-collapsed-table ancom/prueba/table_filtered-ls4.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-l4.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s4.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s4.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl4_d0.qzv 
  
  
 #ancom lvl_5
 
qiime taxa collapse \
--i-table ancom/prueba/table_filtered_30.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 5 \
--o-collapsed-table ancom/prueba/table_filtered-ls5.qza
 
qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-ls5.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s5.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s5.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl5_d30.qzv 
 
  qiime taxa collapse \
--i-table ancom/prueba/table_filtered_60 \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 5 \
--o-collapsed-table ancom/prueba/table_filtered-ls5.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-sl5.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s5.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s5.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl5_d60.qzv 
 
 qiime taxa collapse \
--i-table ancom/prueba/table_filtered_0.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 5 \
--o-collapsed-table ancom/prueba/table_filtered-ls5.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-l5.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s5.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s5.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl5_d0.qzv 


#ancom lvl_6
 
qiime taxa collapse \
--i-table ancom/prueba/table_filtered_30.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 6 \
--o-collapsed-table ancom/prueba/table_filtered-ls6.qza
 
qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-ls6.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s6.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s6.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl6_d30.qzv 
 
  qiime taxa collapse \
--i-table ancom/prueba/table_filtered_60 \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 6 \
--o-collapsed-table ancom/prueba/table_filtered-ls6.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-sl6.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s6.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s6.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl6_d60.qzv 
 
 qiime taxa collapse \
--i-table ancom/prueba/table_filtered_0.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 6 \
--o-collapsed-table ancom/prueba/table_filtered-ls6.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-l6.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s6.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s6.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl6_d0.qzv 
 

#ancom lvl_7
 
qiime taxa collapse \
--i-table ancom/prueba/table_filtered_30.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 7 \
--o-collapsed-table ancom/prueba/table_filtered-ls7.qza
 
qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-ls7.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s7.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s7.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl7_d30.qzv 
 
  qiime taxa collapse \
--i-table ancom/prueba/table_filtered_60 \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 7 \
--o-collapsed-table ancom/prueba/table_filtered-ls7.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-sl7.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s7.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s7.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl7_d60.qzv 
 
 qiime taxa collapse \
--i-table ancom/prueba/table_filtered_0.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 7 \
--o-collapsed-table ancom/prueba/table_filtered-ls7.qza
 
 qiime composition add-pseudocount \
  --i-table ancom/prueba/table_filtered-l7.qza \
  --o-composition-table ancom/prueba/comp-filtered-table-s7.qza
 
qiime composition ancom \
  --i-table ancom/prueba/comp-filtered-table-s7.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-column Condition \
  --o-visualization ancom/prueba/ancom-lvl7_d0.qzv 
  
 
 
 ### 7. Longitudinal
 
 mkdir longitudinal
 

 ## Volatility
 qiime longitudinal volatility \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-file core-metrics-results/shannon_vector.qza \
  --m-metadata-file core-metrics-results/chao1_vector.qza/alpha_diversity.qza \
  --p-default-metric chao1 \
  --p-default-group-column Group_Day \
  --p-state-column Longitudinal \
  --p-individual-id-column Rectal_ID \
  --o-visualization longitudinal/volatility.qzv


 ## Feature Volatility Analysis
 qiime longitudinal feature-volatility \
  --i-table DADA2/final-table-merged88.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --p-state-column Longitudinal \
  --p-individual-id-column Rectal_ID \
  --p-n-estimators 10 \
  --p-random-state 17 \
  --p-n-jobs 16 \
  --output-dir longitudinal/ecam-feat-volatility
 
 
 ## Longitudinal_sin_30D
 
 mkdir longitudinal/Lsin30D
 
  qiime longitudinal volatility \
  --m-metadata-file metadata_sin_30D.tsv \
  --m-metadata-file core-metrics-results/shannon_vector.qza \
  --m-metadata-file core-metrics-results/chao1_vector.qza/alpha_diversity.qza \
  --p-default-metric chao1 \
  --p-default-group-column Group_Day \
  --p-state-column Longitudinal \
  --p-individual-id-column Rectal_ID \
  --o-visualization longitudinal/Lsin30D/volatility.qzv


 ## Feature Volatility Analysis ## No funciona ##
 qiime longitudinal feature-volatility \
  --i-table DADA2/final-table-merged88.qza \
  --m-metadata-file metadata_sin_30D.tsv \
  --p-state-column Longitudinal \
  --p-individual-id-column Rectal_ID \
  --p-n-estimators 10 \
  --p-random-state 17 \
  --p-n-jobs 16 \
  --output-dir longitudinal/Lsin30D/ecam-feat-volatility
 
 
 
 ## First differencing to track rate of change
 

qiime longitudinal first-differences \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-file core-metrics-results/shannon_vector.qza \
  --p-state-column Group \
  --p-metric shannon \
  --p-individual-id-column Animal \
  --p-replicate-handling random \
  --o-first-differences longitudinal/shannon-differences.qza

 qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata_RUN456.tsv \
  --m-metadata-file longitudinal/shannon-differences.qza \
  --p-metric Difference \
  --p-state-column Group \
  --p-individual-id-column Animal \
  --p-group-columns Condition \
  --o-visualization longitudinal/first-differences-LME.qzv 
 

 qiime longitudinal first-distances \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --p-state-column Group \
  --p-individual-id-column Animal \
  --p-replicate-handling random \
  --o-first-distances longitudinal/first-distances.qza
  
 qiime longitudinal linear-mixed-effects \
  --m-metadata-file longitudinal/first-distances.qza \
  --m-metadata-file metadata_RUN456.tsv \
  --p-metric Distance \
  --p-state-column Group \
  --p-individual-id-column Animal \
  --p-group-columns Condition \
  --o-visualization longitudinal/first-distances-LME.qzv    
 
 

 
 ### 9. Abundance relative #
 

 #### 9.1 Frecuencias relativas
 
qiime taxa collapse \
--i-table calculos/table.qza \
--i-taxonomy training-feature-classifiers/taxonomy_prova.qza  \
--p-level 7 \
--o-collapsed-table abundance/tabla_collap.qza
 
qiime feature-table relative-frequency \
--i-table abundance/tabla_collap.qza \
--output-dir abundance/tabla_2_collap

qiime tools export \
--input-path abundance/tabla_2_collap/relative_frequency_table.qza \
--output-path abundance/tabla_2_collap


 #### 9.2 Anotacions
 
 ####### R script
 
 
 
 ### 10. 
 
 mkdir core-taxa
 
 # Core taxa generally
 qiime feature-table core-features \
 --i-table calculos/table.qza \
 --p-min-fraction 0.1 \
 --p-steps 10 \
 --o-visualization core-taxa/cores-samples-taxa.qzv 
 
 # Core taxa split groups
 
qiime feature-table filter-samples \
 --i-table calculos/table.qza \
 --m-metadata-file metadata_RUN456.tsv \
 --p-where "[Day_Status] IN ('30_D')" \
 --o-filtered-table core-taxa/table_core_30_D.qza
 
qiime feature-table core-features \
 --i-table core-taxa/table_core_30_D.qza \
 --p-min-fraction 0.1 \
 --p-steps 10 \
 --o-visualization core-taxa/cores-30_D-taxa.qzv 
 
qiime feature-table filter-samples \
 --i-table calculos/table.qza \
 --m-metadata-file metadata_RUN456.tsv \
 --p-where "[Day_Status] IN ('30_H')" \
 --o-filtered-table core-taxa/table_core_30_H.qza
 
qiime feature-table core-features \
 --i-table core-taxa/table_core_30_H.qza \
 --p-min-fraction 0.1 \
 --p-steps 10 \
 --o-visualization core-taxa/cores-30_H-taxa.qzv 
 
 
qiime feature-table filter-samples \
 --i-table calculos/table.qza \
 --m-metadata-file metadata_RUN456.tsv \
 --p-where "[Day_Status] IN ('30_FP')" \
 --o-filtered-table core-taxa/table_core_30_FP.qza
 
 
qiime feature-table core-features \
 --i-table core-taxa/table_core_30_FP.qza \
 --p-min-fraction 0.1 \
 --p-steps 10 \
 --o-visualization core-taxa/cores-30_FP-taxa.qzv 
 
 
qiime feature-table filter-samples \
 --i-table calculos/table.qza \
 --m-metadata-file metadata_RUN456.tsv \
 --p-where "[Day_Status] IN ('0_D')" \
 --o-filtered-table core-taxa/table_core_0_D.qza
 
qiime feature-table core-features \
 --i-table core-taxa/table_core_0_D.qza \
 --p-min-fraction 0.1 \
 --p-steps 10 \
 --o-visualization core-taxa/cores-0_D-taxa.qzv 
 
qiime feature-table filter-samples \
 --i-table calculos/table.qza \
 --m-metadata-file metadata_RUN456.tsv \
 --p-where "[Day_Status] IN ('60_D')" \
 --o-filtered-table core-taxa/table_core_60_D.qza
 
qiime feature-table core-features \
 --i-table core-taxa/table_core_60_D.qza \
 --p-min-fraction 0.1 \
 --p-steps 10 \
 --o-visualization core-taxa/cores-60_D-taxa.qzv 
 
qiime feature-table filter-samples \
 --i-table calculos/table.qza \
 --m-metadata-file metadata_RUN456.tsv \
 --p-where "[Day_Status] IN ('0_H')" \
 --o-filtered-table core-taxa/table_core_0_H.qza
 
qiime feature-table core-features \
 --i-table core-taxa/table_core_0_H.qza \
 --p-min-fraction 0.1 \
 --p-steps 10 \
 --o-visualization core-taxa/cores-0_H-taxa.qzv 
 
qiime feature-table filter-samples \
 --i-table calculos/table.qza \
 --m-metadata-file metadata_RUN456.tsv \
 --p-where "[Day_Status] IN ('60_H')" \
 --o-filtered-table core-taxa/table_core_60_H.qza
 
qiime feature-table core-features \
 --i-table core-taxa/table_core_60_H.qza \
 --p-min-fraction 0.1 \
 --p-steps 10 \
 --o-visualization core-taxa/cores-60_H-taxa.qzv 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
