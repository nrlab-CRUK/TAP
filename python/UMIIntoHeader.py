#!/usr/bin/env python3

import argparse
import gzip
import logging
import os
import pysam
import re
import sys
import traceback

from xopen import xopen

from Bio.SeqIO.QualityIO import FastqGeneralIterator

class CorruptedFileException(Exception):
    pass

class UMIIntoHeader:
    '''
    Note that we're using BioPython for reading the FASTQ files.
    I've found that pysam just hangs when reading a truncated or corrupted gzip file,
    whereas with biopython we get the EOFError expected from just reading the
    bytes of the file without any interpretation of their meaning.
    '''

    def __init__(self):
        self.parser = argparse.ArgumentParser(description="UMIIntoHeader.py - Put UMI reads into regular read headers (Illumina BCL Convert style).")
        self.parser.add_argument("--read", help="The main read FASTQ file (input).", type=str, required=True)
        self.parser.add_argument("--umi", help="The UMI read FASTQ file (input).", type=str, required=True)
        self.parser.add_argument("--out", help="The combined FASTQ file (output).", type=str, required=True)

        self.compressionLevel = 1

        self.openFileHandle = None

    def run(self, args = None, quiet = False):
        if not args:
            args = self.parser.parse_args()

        if not quiet:
            print("UMIIntoHeader")
            print("-------------")
            print(f"read: {args.read}")
            print(f"umi: {args.umi}")
            print(f"out: {args.out}")
            print(f"compression: {self.compressionLevel}")

        lineCounter = 0
        try:
            with xopen(args.read, 'rt') as readHandle:  # 'rt' mode for text mode reading
                with xopen(args.umi, 'rt') as umiHandle:
                    with gzip.open(args.out, "wt", compresslevel = self.compressionLevel, newline = '\n') as outFile:
                        readIter = FastqGeneralIterator(readHandle)
                        umiIter = FastqGeneralIterator(umiHandle)

                        for (readId, readSeq, readQual) in readIter:
                            (umiId, umiSeq, umiQual) = next(umiIter)

                            readIdParts = readId.split()
                            assert len(readIdParts) == 2, "Expect the read id to have two parts when split by white space."

                            umiIdParts = umiId.split()
                            assert len(umiIdParts) == 2, "Expect the UMI read id to have two parts when split by white space."

                            if readIdParts[0] != umiIdParts[0]:
                                raise CorruptedFileException(f"Have mismatched reads on line {lineCounter + 1} of the two read files.")

                            outFile.write(f"@{readIdParts[0]}:{umiSeq} {readIdParts[1]}\n")
                            outFile.write(readSeq)
                            outFile.write('\n')
                            outFile.write('+\n')
                            outFile.write(readQual)
                            outFile.write('\n')

                            lineCounter += 4

        except EOFError as e:
            raise CorruptedFileException(f"Looks like the file {args.read} or {args.umi} is truncated or corrupted: \"{e.args[0]}\"")
        except StopIteration:
            raise CorruptedFileException(f"Looks like {args.umi} has fewer reads than {args.read}")

if __name__ == '__main__':
    exitCode = 1
    try:
        UMIIntoHeader().run()
        exitCode = 0
    except CorruptedFileException as e:
        print(e.args[0], file = sys.stderr)
    except BaseException as e:
        traceback.print_exc(file = sys.stderr)
    finally:
        sys.exit(exitCode)
