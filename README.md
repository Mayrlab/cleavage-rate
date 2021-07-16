## Cleavage Rate of 10X Chromium 3'-End Reads
This repository provides a pipeline for filtering and counting reads in a curated set 3' ends of transcripts.
Reads are then classified as *cleavage-site-traversing* if they

 - overlap with a region near the cleavage site
 - contain a soft-clipped 3' end (strand-specific)
 
## Requirements

System must have Conda installed. We strongly recommend [the MambaForge variant](https://github.com/conda-forge/miniforge#mambaforge).
The Conda environments use [the Bioconda channel](https://bioconda.github.io/), which currently only supports **osx-64** and **linux-64** platforms.

**Snakemake** is required. The version used in development and execution of this pipeline is archived in the `envs/` directory. 
For those interested in replication, one can fully recreate the Snakemake use with 

```bash
mamba env create -f envs/snakemake_5_31.full.yaml
```

## Running
1. **Clone the repository.**

       git clone git@github.com:mfansler/cleavage-rate.git
      
2. **Update `tmp_dir`.** Edit the `config.yaml` file to provide a temporary directory via the `tmp_dir` variable.

3. **Run snakemake in directory.**

       cd cleavage-rate
       snakemake

4. **CSV Output.** Final counts are generated (in long-format) in the `data/counts/summary_cleavage_counts.csv` file.

## Methodology

BAM files, specified as `samples` in the **config.yaml**, are downloaded. BAMs are filtered via `bedtools intersect` against a BED file specified by the `peaks_bed` parameter in the **config.yaml**. The peak set provided is a manually-curated set of 85 peaks at 3' ends of transcripts that have at least 500 nts upstream of the cleavage site free of A-rich stretches and alternative polyadenylation sites. The BED file is relative to the **mm10** genome. Reads overlapping any of these peaks (strand-specific) are counted and classified as *peak* in the **summary_cleavage_counts.csv**. A BED file of cleavage sites is generated using a radius (default 20 in **config.yaml**) around the 3' end of the entries in the peaks BED file. Reads that potentially traverse the cleavage site are identified by intersecting the with the cleavage sites BED, and then filtered by CIGAR string, retaining reads with softclipping at the 3' end. Reads are counted and classified as *cleavage* in the **summary_cleavage_counts.csv**.

## Parameters

The `radius` parameter defaults to 20 nts. Intuitively, smaller radii correspond to a more stringent definition of cleavage-traversing.

The `peaks_bed` parameter provides BED6 file that defines the peaks to be quantified. This must include strand.
