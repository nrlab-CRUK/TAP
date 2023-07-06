#!/usr/bin/env python3

import argparse
import gzip
import logging
import os
import pysam
import re
import sys

from pysam import FastxRecord, FastxFile

class FastqSplit:
    def __init__(self):
        self.parser = argparse.ArgumentParser(description="FastqSplit.py - FASTQ file splitter into fixed size chunks.")
        self.parser.add_argument("--source", help="Source FASTQ file (input).", type=str, required=True)
        self.parser.add_argument("--out", help="Directory to write split files to. Default is the current directory.", type=str)
        self.parser.add_argument("--reads",  help="Number of reads per chunk. Default one million.", type=int, default=1000000)
        self.parser.add_argument("--prefix", help="File name prefix to use for output files. Default is the input file without .fq.gz", type=str)

        self.compressionLevel = 1

        self.openFileHandle = None

    def run(self, args = None) -> int:
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
            with FastxFile(args.source, "rb") as readFile:
                try:
                    readIter = iter(readFile)

                    while True:
                        read = next(readIter)

                        outFile = self.fileHandle(readCounter)

                        outFile.write(str(read))
                        outFile.write('\n')

                        readCounter = readCounter + 1
                finally:
                    if self.openFileHandle is not None:
                        self.openFileHandle.close()
                        self.openFileHandle = None
        except EOFError as e:
            logging.error(f"Looks like the file {args.source} is truncated or corrupted.")
            logging.error(e.args[0])
            return 1
        except StopIteration:
            if readCounter == 0:
                # No reads at all. In this case, write a single chunk with nothing in it.
                # Just open the file and close it.
                with self.fileHandle(0) as outFile:
                    pass
        return 0

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
    sys.exit(FastqSplit().run())
