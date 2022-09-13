#!/usr/bin/python3

import sys
import pysam
import argparse

parser = argparse.ArgumentParser(description="read_selection_tools.py - collection of tools for selecting specific reads from a BAM file")
parser.add_argument("tool",           help="The selection tool to apply - choose from [length, bqual])")
parser.add_argument("input_bam",      help="Input bam file to select reads from")
parser.add_argument("output_bam",     help="Output bam filename to contain selected reads")
parser.add_argument("--template_min", help="Minimum tlen length", type=int, default=90)
parser.add_argument("--template_max", help="Maximum tlen length", type=int, default=150)
parser.add_argument("--bqual_mean_min",    help="Minimum read base quality mean", type=int, default=30)
parser.add_argument("--bqual_first_bases",   help="Ignore the first N bases of the read before calulating the base quality mean", type=int, default=10)
parser.add_argument("--bqual_last_bases",    help="Ignore the last N bases of the read before calulating the base quality mean", type=int, default=10)

args = parser.parse_args()

print(f"Processing {args.input_bam}")
selectedReads   = 0
readsCount      = 0

with pysam.AlignmentFile(args.input_bam, "rb") as samFile: 
    with pysam.AlignmentFile(args.output_bam, "wb", template=samFile) as selectedSamFile:
        if (args.tool == "length"):
            print(f"Selecting reads between {args.template_min} bp and {args.template_max} bp")
            
            ## test that fetch() returns the number of reads expected
            for read in samFile.fetch():
                readsCount = readsCount + 1
                if abs(read.template_length) >= args.template_min and abs(read.template_length) <= args.template_max:
                    selectedSamFile.write(read)
                    selectedReads = selectedReads + 1
        
        if (args.tool == "bqual"):
            print(f"Selecting reads based on average base quality greater than or equal to {args.bqual_mean_min}")
            
            min_read_length = args.bqual_first_bases + args.bqual_last_bases
            
            ## test that fetch() returns the number of reads expected
            for read in samFile.fetch():
                readsCount = readsCount + 1
                bquals = read.query_qualities
                if len(bquals) > min_read_length:
                    mean = sum(bquals[args.bqual_first_bases:-args.bqual_last_bases]) / len(bquals[args.bqual_first_bases:-args.bqual_last_bases])
                    if mean >= args.bqual_mean_min:
                        selectedSamFile.write(read)
                        selectedReads = selectedReads + 1
                else:
                    print(f"Warning: read discarded on length({len(bquals)}), less than or equal to {min_read_length}")

discardedReads = readsCount - selectedReads
discardedRatio = 0 if readsCount == 0 else discardedReads / readsCount

print(f"Selected {selectedReads} reads")
print(f"Discarded {discardedReads} reads")
print(f"Discarded {discardedRatio} ratio")

# print(f"Indexing {args.output_bam}")
# pysam.index(args.output_bam)
print("Selection complete")
