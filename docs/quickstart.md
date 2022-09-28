# Quickstart guide to running the NRLAB_TAP pipeline

## Prerequisites

The NRLAB_TAP pipeline requires Nextflow and a Java 11 runtime to be installed.
All other software dependencies are installed in a Singularity container and a
set of reference data, both of which are available on the cluster.

### Install Nextflow

Nextflow is installed separately for each user. The only requirement is that a
Java runtime is installed. Nextflow requires that at least version 11 of Java is
installed but we recommend that you have version 17 of Java available to use the
`kickstart` utility for retrieving FASTQ files from the sequencing data server
(see later section).

Check which version (if any) of Java is available using the following command:

```
java -version
```

If this gives an error that 'java' could not be found or reports an older
version (lower than 17), you can add Java 17 to your environment on the CI
cluster using `spack`:

```
spack load openjdk@17
```

Nextflow can then be installed as follows:

```
curl -s https://get.nextflow.io | bash 
```

This will create a file called 'nextflow'. This is an executable file that is
used to run Nextflow pipelines. You may wish to move the 'nextflow' file to your
home directory or to the 'bin' subdirectory and add this to your PATH.

### Install the NRLAB_TAP workflow.

The NRLAB_TAP workflow is installed from GitHub using `nextflow pull`.

Currently, the GitHub repository is private and only available to GitHub account
holders that have been granted access. You will need to specify your username and
password (or GitHub token) in the file `$HOME/.nextflow/scm`:

```
providers {
  github {
    user = 'eldrid01'
    password = 'ghp_lkslkjs123l4js08jslkj208kjh0hkjh'
  }
}
```

Having configured your GitHub credentials, install the workflow as follows:

```
nextflow pull nrlab-CRUK/NRLAB_TAP
```

Note that while the pipeline is in active development it will be necessary to
re-run the `nextflow pull` command from time to time to obtain the latest
updates.

### Singularity container and reference data

The Singularity container packages various software tools used by the pipeline
including bwa-mem2, Picard, samtools, bedtools, Connor, GATK, TrimGalore, AGeNT
and ichorCNA. The container is available on the cluster in the following
location:

```
/home/bioinformatics/pipelinesoftware/nrlab_tap/nrlabtap-latest.sif
```

The workflow requires reference data including the reference genome sequence,
indexed for the bwa aligner, and sites of known variants from the dbSNP and
COSMIC databases. These are available on the cluster within directories for each
supported genome assembly (currently hg19 and hg38) in the following location:

```
/mnt/scratcha/bioinformatics/rosenfeld_references
```

The pipeline is configured to use both these locations by default.

## Retrieve FASTQ files for a given sequencing run

We recommend use of the `kickstart` tool, provided by the Bioinformatics Core as
part of the Genomic Sequencing service, for retrieving your FASTQ sequence data
files.

Note that `kickstart` is a Java tool that requires Java 17 or later.

Create or navigate to a directory in which the pipeline will be run and run the
following command to fetch the sequence data for a specified SLX pool ID:

```
/home/bioinformatics/software/pipelines/kickstart/current/bin/kickstart -m MiSeq -f "Library Type" -f "Index Type" -l SLX-21619
```

Note that we restricted the FASTQ files to just the MiSeq Nano QC run using the
`-m` flag as this is a small dataset that can be used for a quick test of the
pipeline. You wouldn't normally want to do this and for sequencing projects in
which a MiSeq QC run was carried out, you may wish to specify `-m NovaSeq`
instead.

The `kickstart` utility also produces a CSV file, `alignment.csv`, that lists
the FASTQ files, normally one for each library in the pool, and contains some
metadata about each library including the library type and index type, as
requested with the `-f` flag. The FASTQ files are transferred to a subdirectory
named `fastq`. The CSV file and `fastq` directory are the inputs for the
pipeline.

## Configuring the pipeline

The pipeline can be configured with a number of parameters. Default settings
for many of these parameters will be appropriate for many runs and only the
parameters that need to be changed have to be specified in a configuration
file named `nrlab_tap.config` in your run directory.

Here is an example configuration file:

```
// nrlab_tap.config
params {
    ASSEMBLY = "hg38"

    // trim sequences, e.g. with TrimGalore
    // note that FASTQ files for libraries with the type 'ThruPLEX DNA-seq dual
    // index' will be trimmed using TagTrim regardless of this parameter
    // setting, similarly FASTQ files for 'SureSelectXT HS2' libraries will by
    // trimmed using AGeNT Trimmer regardless of the TRIM_FASTQ parameter
    TRIM_FASTQ = true

    // mark duplicates with Picard
    MARK_DUPLICATES = true

    // GATK base quality score recalibration
    GATK_BQSR = true

    // filter unmapped and low-mapping quality reads, duplicates, secondary and
    // supplementary alignments
    // also filters reads aligning to blacklisted regions specified by the BED
    // file configured using the BLACKLIST parameter (using default BED file in
    // the reference data directory in this case)
    FILTER = true

    // run FASTQC to generate quality control metrics on the filtered BAM files
    FASTQC = true

    // further selection of reads based on the template length (fragment size)
    READ_SELECTION = "Length"
    TEMPLATE_MINIMUM = 90
    TEMPLATE_MAXIMUM = 150
}
```

## Run the pipeline

The pipeline can be run using a shell script that can be submitted as a job to
the cluster such as the following:

```
#!/bin/bash
#SBATCH --job-name=nrlab_tap
#SBATCH --output=nrlab_tap.%J.out
#SBATCH --time=1440
#SBATCH --mem=4G

nextflow run nrlab-CRUK/NRLAB_TAP \
	-config nrlab_tap.config \
	-profile slurm
```

Note that we have specified an upper limit on the time for the pipeline run and
the memory of the Nextflow job that will run the pipeline using `SBATCH`
directives. This job will submit further jobs to the cluster with their own CPU,
memory and time requirements as specified by the pipeline.

Assuming the script was called `run_nrlab_tap.sh` this can be submitted to the
cluster using `sbatch`:

```
sbatch run_nrlab_tap.sh
```

## Workflow overview

The following diagram gives an overview of the workflow with some notes on the
various steps, many of which are optional.

![Workflow](workflow.drawio.svg)