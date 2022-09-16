#!/usr/bin/env python3

import sys
import argparse
import gzip
import pysam

parser = argparse.ArgumentParser(description="concat_fastq.py - concatenate FASTQ records from two files (read IDs must match)")
parser.add_argument("fastq1", help = "The first FASTQ file")
parser.add_argument("fastq2", help = "The second FASTQ file")
parser.add_argument("output", help = "The output FASTQ file that concatenates sequences from the two input FASTQ files")

args = parser.parse_args()

count = 0

with pysam.FastxFile(args.fastq1) as f1, pysam.FastxFile(args.fastq2) as f2, gzip.open(args.output, "wt", compresslevel = 4) as fo: 
    for record1, record2 in zip(f1, f2):
        count += 1
        if record1.name != record2.name:
            sys.exit("Names do not match for record " + str(count) + ": " + record1.name + ", " + record2.name)
        fo.write("@" + record1.name + "\n")
        fo.write(record1.sequence + record2.sequence + "\n")
        fo.write("+\n")
        fo.write(record1.quality + record2.quality + "\n")

