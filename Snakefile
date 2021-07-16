configfile: "config.yaml"

import pandas as pd
import os
from glob import glob

# make sure the tmp directory exists
os.makedirs(config['tmp_dir'], exist_ok=True)

print("Parsing sample data...")
samples = pd.DataFrame(config['samples']).set_index('sample_id')
print("Found %d samples." % len(samples.index))


rule all:
    input: "data/counts/summary_cleavage_counts.csv"
        
rule download_sample:
    output: temp("data/bam/raw/{sample_id}.bam")
    params:
        url=lambda wcs: samples.url[wcs.sample_id]
    conda: "envs/bedtools.yaml"
    shell:
        """
        wget -O {output} {params.url}
        """

rule index_sample:
    input: "data/bam/{mode}/{sample_id}.bam"
    output: "data/bam/{mode}/{sample_id}.bam.bai"
    conda: "envs/bedtools.yaml"
    wildcard_constraints:
        mode="(raw|peak|cleavage)"
    shell:
        """
        samtools index {input}
        """

rule filter_peaks:
    input:
        bam="data/bam/raw/{sample_id}.bam",
        bai="data/bam/raw/{sample_id}.bam.bai",
        bed=config['peaks_bed']
    output:
        bam="data/bam/peak/{sample_id}.bam",
        csv="data/counts/peak/{sample_id}.csv"
    conda: "envs/bedtools.yaml"
    shell:
        """
        bedtools intersect -s -a {input.bam} -b {input.bed} > {output.bam}
        count=$(samtools view -c {output.bam})
        echo \"{wildcards.sample_id},peak,$count\" > {output.csv}
        """

rule generate_cleavage_bed:
    input:
        bed=config['peaks_bed'],
        awk="scripts/bed_to_cleavage.awk"
    output: "data/bed/cleavage.bed"
    params:
        radius=config['cleavage_radius']
    conda: "envs/bedtools.yaml"
    shell:
        """
        awk -f {input.awk} -v radius={params.radius} {input.bed} > {output}
        """

rule filter_cleavage:
    input:
        bed="data/bed/cleavage.bed",
        bam="data/bam/peak/{sample_id}.bam",
        bai="data/bam/peak/{sample_id}.bam.bai",
        awk="scripts/filter_sam_softclip_end.awk"
    output:
        bam="data/bam/cleavage/{sample_id}.bam",
        csv="data/counts/cleavage/{sample_id}.csv"
    conda: "envs/bedtools.yaml"
    shell:
        """
        bedtools intersect -s -a {input.bam} -b {input.bed} |\\
          samtools view -h |\\
          awk -f {input.awk} |\\
          samtools view -b > {output.bam}
        count=$(samtools view -c {output.bam})
        echo \"{wildcards.sample_id},cleavage,$count\" > {output.csv}
        """

rule summarize_counts:
    input:
        expand("data/counts/{mode}/{sample_id}.csv",
               mode=["peak", "cleavage"], sample_id=samples.index.values)
    output: "data/counts/summary_cleavage_counts.csv"
    shell:
        """
        cat {input} > {output}
        """
