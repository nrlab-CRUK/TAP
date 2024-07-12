#!/usr/bin/env python3

import argparse
import io
import pysam
import sys
import gzip

from pysam import FastxRecord, FastxFile

class TagTrim2:
    STEM = 'GTAGCTCA'
    RSTEM = 'TGAGCTAC'

    UMI_LENGTH = 6
    STEM_LENGTH = len(STEM)
    ADDITIONAL_BASES = 3

    def __init__(self):
        self.parser = argparse.ArgumentParser(description="TagTrim2.py - Trimmer for ThruPLEX DNA-seq Dualindex pools.")
        self.parser.add_argument("--read1", help="Read one FASTQ file (input).", type=str, required=True)
        self.parser.add_argument("--read2", help="Read two FASTQ file (input).", type=str, required=True)
        self.parser.add_argument("--out1",  help="Read one FASTQ file (output).", type=str, required=True)
        self.parser.add_argument("--out2",  help="Read two FASTQ file (output).", type=str, required=True)

        self.compressionLevel = 1

        self.stems = set()
        self.stems.add(TagTrim2.STEM)
        self.stems.add(f"A{TagTrim2.STEM}")
        self.stems.add(f"CA{TagTrim2.STEM}")
        self.stems.add(f"TCA{TagTrim2.STEM}")

    def run(self):
        args = self.parser.parse_args()

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
        b1 = read1.sequence
        insert1Start = self.getInsertStart(b1)
        if insert1Start < 0:
            # The forward read doesn't have the stem in the usual position. Filter out.
            return

        b2 = read2.sequence
        insert2Start = self.getInsertStart(b2)
        if insert2Start < 0:
            # The reverse read doesn't have the stem in the usual position. Filter out.
            return

        rstem1Pos = b1.find(TagTrim2.RSTEM, insert1Start)
        rstem2Pos = b2.find(TagTrim2.RSTEM, insert2Start)
        insert1End = len(b1)
        insert2End = len(b2)

        if rstem1Pos >= 0 and rstem2Pos >= 0:
            # Stem in both reads. Looks like these are stems and should be trimmed.
            insert1End = rstem1Pos
            insert2End = rstem2Pos
        # else either the stem isn't present or if only present in one read, it might be DNA sequence.

        insert1 = b1[insert1Start:insert1End]
        insertQ1 = read1.quality[insert1Start:insert1End]
        umi1 = b1[0:TagTrim2.UMI_LENGTH]
        #umiQ1 = read1.quality[0:TagTrim2.UMI_LENGTH]

        insert2 = b2[insert2Start:insert2End]
        insertQ2 = read2.quality[insert2Start:insert2End]
        umi2 = b2[0:TagTrim2.UMI_LENGTH]
        #umiQ2 = read2.quality[0:TagTrim2.UMI_LENGTH]

        out1File.write(str(self.toRecord(read1, umi1, insert1, insertQ1)))
        out1File.write('\n')
        out2File.write(str(self.toRecord(read2, umi2, insert2, insertQ2)))
        out2File.write('\n')


    def toRecord(self, read: FastxRecord, umi: str, seq: str, qual: str) -> FastxRecord:
        record = FastxRecord()
        record.name = f"{read.name}:{umi}"
        record.comment = read.comment
        record.sequence = seq
        record.quality = qual
        return record


    def getInsertStart(self, read: FastxRecord) -> int:
        for tagOffset in range(0, TagTrim2.ADDITIONAL_BASES + 1): # Inclusive range
            stem = read[TagTrim2.UMI_LENGTH:TagTrim2.UMI_LENGTH + tagOffset + TagTrim2.STEM_LENGTH]
            if stem in self.stems:
                return TagTrim2.UMI_LENGTH + tagOffset + TagTrim2.STEM_LENGTH
        return -1


if __name__ == '__main__':
    TagTrim2().run()
