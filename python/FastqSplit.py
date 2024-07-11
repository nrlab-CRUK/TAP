#!/usr/bin/env python3

import argparse
import gzip
import logging
import os
import pysam
import re
import sys
import traceback

from pathlib import Path
from xopen import xopen

from Bio.SeqIO.QualityIO import FastqGeneralIterator

class CorruptedFileException(Exception):
    pass

class FastqSplit:
    '''
    Note that we're using BioPython for reading the FASTQ files.
    I've found that pysam just hangs when reading a truncated or corrupted gzip file,
    whereas with biopython we get the EOFError expected from just reading the
    bytes of the file without any interpretation of their meaning.
    '''

    def __init__(self):
        self.parser = argparse.ArgumentParser(description="FastqSplit.py - FASTQ file splitter into fixed size chunks.")
        self.parser.add_argument("--source", help="Source FASTQ file (input).", type=Path, required=True)
        self.parser.add_argument("--umi", help="The UMI read FASTQ file (input, optional).", type=Path, default=None)
        self.parser.add_argument("--out", help="Directory to write split files to. Default is the current directory.", type=Path)
        self.parser.add_argument("--reads",  help="Number of reads per chunk. Default one million.", type=int, default=1000000)
        self.parser.add_argument("--prefix", help="File name prefix to use for output files. Default is the input file without .fq.gz", type=str)

        self.compressionLevel = 1

        self.openFileHandle = None

    def run(self, args = None, quiet = False):
        if not args:
            args = self.parser.parse_args()

        self.perChunk = args.reads

        self.outdir = args.out if args.out else os.getcwd()
        self.prefix = args.prefix if args.prefix else re.search(r"(?i)^(.+?)(\.(fq|fastq))?(\.gz)?$", os.path.basename(args.source)).group(1)

        if not quiet:
            print("FastqSplit")
            print("----------")
            print(f"source file: {args.source}")
            if args.umi:
                print(f"umi file: {args.umi}")
            print(f"out directory: {self.outdir}")
            print(f"out prefix: {self.prefix}")
            print(f"chunk size: {self.perChunk}")
            print(f"compression: {self.compressionLevel}")

        try:
            if args.umi:
                readCounter = self.withUmi(args.source, args.umi)
            else:
                readCounter = self.noUmi(args.source)

            if readCounter == 0:
                # No reads at all. In this case, write a single chunk with nothing in it.
                # Just open the file and close it.
                with self.fileHandle(0) as outFile:
                    pass
        finally:
            if self.openFileHandle is not None:
                self.openFileHandle.close()
                self.openFileHandle = None

    def noUmi(self, source):
        readCounter = 0
        try:
            with xopen(source, 'rt') as readHandle:  # 'rt' mode for text mode reading
                readIter = FastqGeneralIterator(readHandle)
                for (id, seq, qual) in readIter:
                    self.writeRecord(readCounter, id, seq, qual)
                    readCounter += 1
        except EOFError as e:
            raise CorruptedFileException(f"Looks like the file {source} is truncated or corrupted: \"{e.args[0]}\"")
        return readCounter

    def withUmi(self, source, umiSource):
        readCounter = 0
        try:
            with xopen(source, 'rt') as readHandle:  # 'rt' mode for text mode reading
                with xopen(umiSource, 'rt') as umiHandle:
                    readIter = FastqGeneralIterator(readHandle)
                    umiIter = FastqGeneralIterator(umiHandle)

                    for (readId, readSeq, readQual) in readIter:
                        try:
                            (umiId, umiSeq, umiQual) = next(umiIter)
                        except StopIteration:
                            raise CorruptedFileException(f"Looks like {umiSource} has fewer reads than {source}")

                        readIdParts = readId.split()
                        assert len(readIdParts) == 2, "Expect the read id to have two parts when split by white space."

                        umiIdParts = umiId.split()
                        assert len(umiIdParts) == 2, "Expect the UMI read id to have two parts when split by white space."

                        if readIdParts[0] != umiIdParts[0]:
                            raise CorruptedFileException(f"Have mismatched reads on line {readCounter * 4 + 1} of the two read files.")

                        self.writeRecord(readCounter, f"{readIdParts[0]}:{umiSeq} {readIdParts[1]}", readSeq, readQual)
                        readCounter += 1
        except EOFError as e:
            raise CorruptedFileException(f"Looks like one of the files {source} or {umiSource} is truncated or corrupted: \"{e.args[0]}\"")
        return readCounter

    def writeRecord(self, readCounter, id, seq, qual):
        outFile = self.fileHandle(readCounter)

        outFile.write('@')
        outFile.write(id)
        outFile.write('\n')
        outFile.write(seq)
        outFile.write('\n')
        outFile.write('+\n')
        outFile.write(qual)
        outFile.write('\n')

    def fileHandle(self, readCounter: int):
        if (readCounter % self.perChunk) == 0:
            if self.openFileHandle is not None:
                self.openFileHandle.close()

            chunkNumber = readCounter // self.perChunk
            filename = f"{self.prefix}-C{chunkNumber:06d}.fq.gz"
            filepath = Path(self.outdir, filename)

            self.openFileHandle = gzip.open(filepath, "wt", compresslevel = self.compressionLevel, newline = '\n')

        return self.openFileHandle


if __name__ == '__main__':
    exitCode = 1
    try:
        FastqSplit().run()
        exitCode = 0
    except CorruptedFileException as e:
        print(e.args[0], file = sys.stderr)
    except BaseException as e:
        traceback.print_exc(file = sys.stderr)
    finally:
        sys.exit(exitCode)
