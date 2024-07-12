import gzip
import hashlib
import os
import unittest

from pathlib import Path
from shutil import rmtree
from types import SimpleNamespace
from xopen import xopen

from PrependUMI import PrependUMI

class PrependUMITest(unittest.TestCase):
    def setUp(self):
        self.outDir = Path('PrependUMI_testout')

        if self.outDir.exists():
            rmtree(self.outDir)
        self.outDir.mkdir(mode = 0o700)

    def tearDown(self):
        rmtree(self.outDir)
        pass

    def md5For(self, file: Path) -> str:
        with xopen(file, 'rt') as fh:
            content = fh.read()
            return hashlib.md5(content.encode('utf-8')).hexdigest()

    def testShouldProcessNoUmi(self):
        prepender = PrependUMI()

        source = Path('testdata/regular_50.fq')

        self.assertFalse(prepender.shouldProcess(source), "Told to process a file with no UMI.")

    def testShouldProcessWithUmi(self):
        prepender = PrependUMI()

        source = Path('testdata/regular_with_umi_50.fq')

        self.assertTrue(prepender.shouldProcess(source), "Not processing a file with UMI.")

    def testPrependWithoutUmi(self):
        prepender = PrependUMI()
        args = SimpleNamespace(**{
            'source': Path('testdata/regular_50.fq'),
            'output': self.outDir / 'noumi.fq'
        })

        prepender.run(args, quiet = True)

        self.assertTrue(args.output.exists(), "Output file not created.")

        # Should be a link to the original.

        refMd5 = self.md5For(args.source)
        outMd5 = self.md5For(args.output)

        self.assertEqual(refMd5, outMd5, "Files are not the same.")

    def testPrependWithUmi(self):
        prepender = PrependUMI()
        args = SimpleNamespace(**{
            'source': Path('testdata/regular_with_umi_50.fq'),
            'output': self.outDir / 'withumi.fq.gz'
        })

        prepender.run(args, quiet = True)

        self.assertTrue(args.output.exists(), "Output file not created.")

        with xopen(args.output, 'rt') as handle:
            idLine = handle.readline().strip()
            self.assertEqual("@M01686:2:000000000-DFTML:1:1101:18140:1563:rGGGGCAAGAT 1:N:0:AGCAGGAA", idLine,
                             "id of the first read is wrong.")
            seqLine = handle.readline().strip()
            self.assertEqual("GGGGCAAGATCTGACCCTTTCAGCACCTCCTTGTCCCTGCGGTCCTAATTTGGGGGTAAGACTTGGCTCCCTTCAGGCCGTCTATCAATCATTTTTGCTCCTTATGCAAACACAGACAGTTTTGTCATTATTCTAAAAATAAGTGCTTTTAAGGAGGCTG", seqLine,
                             "sequence of the first read is wrong.")
            handle.readline()
            qualLine = handle.readline().strip()
            self.assertEqual("@@@@@@@@@@3AAABFFFFFFFGGGGGGFCGGGHFAAF4422AA2B55DFG55222A1335ABA333AA1AFFE353310>>F1F@44@E3BGFHH?DGFCGGBG3BEBFFCCE03?22FGGH0FE4FGBGGEGE4B2?FD33G33FGGH3C22<//BGE", qualLine,
                             "quality of the first read is wrong.")
