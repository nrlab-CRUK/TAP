#!/usr/bin/env python3

import sys
import argparse
import gzip
import pysam

from pysam import FastxRecord

parser = argparse.ArgumentParser(description="prepend_xths2_umi.py - prepend unique molecular tags from RX:Z tags added to FASTQ read headers by AGeNT trimmer utility (SureSelect XT HS2)")
parser.add_argument("fastq1", help = "The read 1 FASTQ file")
parser.add_argument("fastq2", help = "The read 2 FASTQ file")
parser.add_argument("output1", help = "The output FASTQ file for read 1 with UMI sequences pre-pended")
parser.add_argument("output2", help = "The output FASTQ file for read 2 with UMI sequences pre-pended")

args = parser.parse_args()


def extract_umi(record: FastxRecord):
    sequence = None
    quality = None
    for value in record.comment.split("\t"):
        # removeprefix requires Python 3.9, which would do this work.
        if value.startswith("RX:Z:"):
            sequence = value[5:]
        elif value.startswith("QX:Z:"):
            quality = value[5:]
    if sequence is None:
        sys.exit("UMI sequence not found for record: " + record.name + " " + record.comment)
    if quality is None:
        sys.exit("UMI quality not found for record: " + record.name + " " + record.comment)
    return (sequence, quality)


count = 0

with pysam.FastxFile(args.fastq1) as in1, pysam.FastxFile(args.fastq2) as in2, gzip.open(args.output1, "wt", compresslevel = 4) as out1, gzip.open(args.output2, "wt", compresslevel = 4) as out2:
    for record1, record2 in zip(in1, in2):
        count += 1

        if record1.name != record2.name:
            sys.exit("Names do not match in reads 1 and 2 for record " + str(count) + ": " + record1.name + ", " + record2.name)

        sequence1, quality1 = extract_umi(record1)
        sequence2, quality2 = extract_umi(record2)
        if sequence1 != sequence2 or quality1 != quality2:
            sys.exit("Mismatching UMI sequences and qualities in reads 1 and 2 for record " + str(count) + ": " + record1.name)

        sequences = sequence1.split("-")
        if len(sequences) != 2:
            sys.exit("Unexpected UMI sequence string (expecting 2 tags separated by a hyphen) for record " + str(count) + ": " + record1.name)
        qualities = quality1.split(" ")
        if len(sequences) != 2:
            sys.exit("Unexpected UMI sequence string (expecting 2 tags separated by a space) for record " + str(count) + ": " + record1.name)

        combined_umi_sequence = sequences[0] + sequences[1]
        combined_umi_quality = qualities[0] + qualities[1]

        record1.comment = None
        record1.sequence = combined_umi_sequence + record1.sequence
        record1.quality = combined_umi_quality + record1.quality

        record2.comment = None
        record2.sequence = combined_umi_sequence + record2.sequence
        record2.quality = combined_umi_quality + record2.quality

        out1.write(str(record1))
        out1.write("\n")

        out2.write(str(record2))
        out2.write("\n")

