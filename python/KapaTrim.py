#!/usr/bin/env python3

import argparse
import io
import pysam
import sys
import gzip

from pysam import FastxRecord, FastxFile

class KapaTrim:

    def __init__(self):
        self.parser = argparse.ArgumentParser(description="KapaTrim.py - Moves the Kapa UMI from the start of reads into the read header.")
        self.parser.add_argument("--read1", help="Read one FASTQ file (input).", type=str, required=True)
        self.parser.add_argument("--read2", help="Read two FASTQ file (input).", type=str, required=True)
        self.parser.add_argument("--out1", help="Read one FASTQ file (output).", type=str, required=True)
        self.parser.add_argument("--out2", help="Read two FASTQ file (output).", type=str, required=True)
        self.parser.add_argument("--umi", help="The number of bases in the UMI.", type=int, required=True)
        self.parser.add_argument("--spacer", help="The number of bases between the UMI and the read proper.", type=int, default=0)

        self.compressionLevel = 1
        self.umiLength = 0
        self.spacer = 0

    def run(self):
        args = self.parser.parse_args()

        self.umiLength = args.umi
        self.spacer = args.spacer

        # print(f"Reading {args.read1} and {args.read2}")

        try:
            with FastxFile(args.read1, "rb") as read1File, FastxFile(args.read2, "rb") as read2File, \
                 gzip.open(args.out1, "wt", compresslevel = self.compressionLevel, newline = '\n') as out1File, \
                 gzip.open(args.out2, "wt", compresslevel = self.compressionLevel, newline = '\n') as out2File:

                read1Iter = iter(read1File)
                read2Iter = iter(read2File)

                while True:
                    read1 = next(read1Iter)
                    read2 = next(read2Iter)

                    self.processReads(read1, read2, out1File, out2File)

        except StopIteration:
            pass

    def processReads(self, read1: FastxRecord, read2: FastxRecord, out1File, out2File):
        umi1 = read1.sequence[0:self.umiLength]
        insert1 = read1.sequence[self.umiLength + self.spacer:]
        insertQ1 = read1.quality[self.umiLength + self.spacer:]

        umi2 = read2.sequence[0:self.umiLength]
        insert2 = read2.sequence[self.umiLength + self.spacer:]
        insertQ2 = read2.quality[self.umiLength + self.spacer:]

        wholeUMI = f"{umi1}+{umi2}"

        out1File.write(str(self.toRecord(read1, wholeUMI, insert1, insertQ1)))
        out1File.write('\n')
        out2File.write(str(self.toRecord(read2, wholeUMI, insert2, insertQ2)))
        out2File.write('\n')


    def toRecord(self, read: FastxRecord, umi: str, seq: str, qual: str) -> FastxRecord:
        record = FastxRecord()
        record.name = f"{read.name}:{umi}"
        record.comment = read.comment
        record.sequence = seq
        record.quality = qual
        return record


if __name__ == '__main__':
    KapaTrim().run()
