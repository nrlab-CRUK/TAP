#!/usr/bin/env python3

import argparse
import gzip
import os
import re
import sys

from pathlib import Path
from xopen import xopen

from Bio.SeqIO.QualityIO import FastqGeneralIterator

class PrependUMI:

    UMI_PATTERN = r'r?([ACGT]+)(\+r?([ACGT]+))?'

    '''
    Take any UMI from the read name (Illumina style) and put it into the read sequence.
    Tests the first read to ensure that there is a UMI to take. If not, there's no need
    to reprocess the file and a link is made to the source file instead.
    '''
    def __init__(self):
        self.parser = argparse.ArgumentParser(description="PrependUMI.py - prepend any UMI from the read id to the read sequence")
        self.parser.add_argument("--source", type = Path, help = "The source FASTQ file.")
        self.parser.add_argument("--output", type = Path, help = "The output FASTQ file.")
        self.parser.add_argument("--read", type = int, help = "The regular read number (1 or 2).")

        self.compressionLevel = 1

    def run(self, args = None, quiet = False):
        if not args:
            args = self.parser.parse_args()

        if args.read not in [1, 2]:
            raise argparse.ArgumentError("--read", "read must be either 1 or 2.")

        if not quiet:
            print("PrependUMI")
            print("----------")
            print(f"source file: {args.source}")
            print(f"output file: {args.output}")
            print(f"read: {args.read}")
            print(f"compression: {self.compressionLevel}")

        if self.shouldProcess(args.source):
            self.prependUmis(args.source, args.output, args.read)
        else:
            print()
            print(f"{args.source} does not have UMIs in its reads.")

            # Pathlib 3.10 has hardlink_to, but it's not yet widely available.
            # args.output.hardlink_to(args.source.resolve(True))
            # os.link(args.source.resolve(), args.output)

            args.output.symlink_to(args.source.resolve())

    def shouldProcess(self, source: Path) -> bool:
        process = False
        with xopen(source, 'rt') as readHandle:
            reader = FastqGeneralIterator(readHandle)
            try:
                (readId, readSeq, readQual) = next(reader)
                segments = re.split(r'[:\s]+', readId)
                process = len(segments) >= 8 and re.match(PrependUMI.UMI_PATTERN, segments[7])
            except StopIteration:
                # No records.
                process = False
        return process

    def prependUmis(self, source: Path, out: Path, readNumber: int):
        count = 0

        with xopen(source, 'rt') as readHandle, \
             gzip.open(out, "wt", compresslevel = self.compressionLevel) as writer:

            reader = FastqGeneralIterator(readHandle)

            for (readId, readSeq, readQual) in reader:
                segments = re.split(r'[:\s]+', readId)
                assert len(segments) >= 8, f"UMIs exist in {source.name} but the record on line {count * 4 + 1} has too few elements."

                umi = re.search(PrependUMI.UMI_PATTERN, segments[7])
                assert umi, f"UMI field doesn't match the expected pattern on line {count * 4 + 1} of {source.name}"
                umi1 = umi.group(1)
                umi2 = umi.group(3)

                # UMI is from the first capture group. If we are processing the second read file of a pair
                # and there is a second UMI, we'll prepend the second UMI.
                umi = umi1
                if readNumber == 2 and umi2:
                    umi = umi2

                readSeq = umi + readSeq
                readQual = ('@' * len(umi)) + readQual

                writer.write('@')
                writer.write(readId)
                writer.write('\n')
                writer.write(readSeq)
                writer.write('\n')
                writer.write('+\n')
                writer.write(readQual)
                writer.write('\n')

                count += 1

        if not out.exists():
            # Write an empty file
            with gzip.open(out, "wt", compresslevel = self.compressionLevel, newline = '\n') as out1File:
                pass


if __name__ == '__main__':
    exitCode = 1
    try:
        PrependUMI().run()
        exitCode = 0
    except EOFError as e:
        print(e.args[0], file = sys.stderr)
    except BaseException as e:
        traceback.print_exc(file = sys.stderr)
    finally:
        sys.exit(exitCode)
