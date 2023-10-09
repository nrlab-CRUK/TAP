#!/usr/bin/env python3

import argparse
import gzip
import logging
import os
import pysam
import re
import sys
import traceback

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
        self.parser.add_argument("--source", help="Source FASTQ file (input).", type=str, required=True)
        self.parser.add_argument("--out", help="Directory to write split files to. Default is the current directory.", type=str)
        self.parser.add_argument("--reads",  help="Number of reads per chunk. Default one million.", type=int, default=1000000)
        self.parser.add_argument("--prefix", help="File name prefix to use for output files. Default is the input file without .fq.gz", type=str)

        self.compressionLevel = 1

        self.openFileHandle = None

    def run(self, args = None):
        if not args:
            args = self.parser.parse_args()

        self.perChunk = args.reads

        self.outdir = args.out if args.out else os.getcwd()
        self.prefix = args.prefix if args.prefix else re.search(r"(?i)^(.+?)(\.(fq|fastq))?(\.gz)?$", os.path.basename(args.source)).group(1)

        print("FastqSplit")
        print("----------")
        print(f"source: {args.source}")
        print(f"out directory: {self.outdir}")
        print(f"out prefix: {self.prefix}")
        print(f"chunk size: {self.perChunk}")
        print(f"compression: {self.compressionLevel}")

        readCounter = 0
        try:
            with gzip.open(args.source, "rt") as readHandle:
                readIter = FastqGeneralIterator(readHandle)
                try:
                    while True:
                        read = next(readIter)

                        outFile = self.fileHandle(readCounter)

                        outFile.write('@')
                        outFile.write(read[0])
                        outFile.write('\n')
                        outFile.write(read[1])
                        outFile.write('\n')
                        outFile.write('+\n')
                        outFile.write(read[2])
                        outFile.write('\n')

                        readCounter = readCounter + 1
                finally:
                    if self.openFileHandle is not None:
                        self.openFileHandle.close()
                        self.openFileHandle = None
        except EOFError as e:
            raise CorruptedFileException(f"Looks like the file {args.source} is truncated or corrupted: \"{e.args[0]}\"")
        except StopIteration:
            if readCounter == 0:
                # No reads at all. In this case, write a single chunk with nothing in it.
                # Just open the file and close it.
                with self.fileHandle(0) as outFile:
                    pass

    def fileHandle(self, readCounter: int):
        if (readCounter % self.perChunk) == 0:
            if self.openFileHandle is not None:
                self.openFileHandle.close()

            chunkNumber = readCounter // self.perChunk
            filename = f"{self.prefix}-C{chunkNumber:06d}.fq.gz"
            filepath = os.path.join(self.outdir, filename)

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
