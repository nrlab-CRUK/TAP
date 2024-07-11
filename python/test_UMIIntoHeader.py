import gzip
import os
import unittest

from types import SimpleNamespace
from xopen import xopen

from UMIIntoHeader import UMIIntoHeader, CorruptedFileException

class UMIIntoHeaderTest(unittest.TestCase):
    def setUp(self):
        self.readFile = 'testdata/regular.fq'
        self.outFile = 'UMIIntoHeader_testout.fq.gz'
        if os.path.exists(self.outFile):
            os.remove(self.outFile)

    def tearDown(self):
        if os.path.exists(self.outFile):
            os.remove(self.outFile)
        pass

    def testSuccess(self):
        rewriter = UMIIntoHeader()
        args = SimpleNamespace(**{
            'read': self.readFile,
            'umi': 'testdata/umi.fq',
            'out': self.outFile
        })

        rewriter.run(args, quiet = True)

        self.assertTrue(os.path.exists(self.outFile), "Out file not written.")

        with xopen(self.outFile, 'rt') as file:  # 'rt' mode for text mode reading
            lines = [line.rstrip() for line in file]

        self.assertEqual("@M01686:2:000000000-DFTML:1:1101:14364:1532:ACTTTATGGT 1:N:0:GTCTGTCA", lines[0], "First read id wrong.");
        self.assertEqual("@M01686:2:000000000-DFTML:1:1101:17133:1546:TGTCGCGCGG 1:N:0:GTCTGTCA", lines[4], "Second read id wrong.");

    def testTooFewUMIs(self):
        rewriter = UMIIntoHeader()
        args = SimpleNamespace(**{
            'read': self.readFile,
            'umi': 'testdata/umi_short.fq',
            'out': self.outFile
        })

        try:
            rewriter.run(args, quiet = True)
            self.fail("Read too short UMI file without exception.")
        except CorruptedFileException:
            pass

    def testMismatchedReadIds(self):
        rewriter = UMIIntoHeader()
        args = SimpleNamespace(**{
            'read': self.readFile,
            'umi': 'testdata/umi_mismatch.fq',
            'out': self.outFile
        })

        try:
            rewriter.run(args, quiet = True)
            self.fail("Read mismatched read ids files without exception.")
        except CorruptedFileException:
            pass
