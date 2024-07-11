import gzip
import os
import unittest

from pathlib import Path
from shutil import rmtree
from types import SimpleNamespace
from xopen import xopen

from FastqSplit import FastqSplit, CorruptedFileException

class FastqSplitTest(unittest.TestCase):
    def setUp(self):
        self.outDir = Path('FastqSplit_testout')

        if self.outDir.exists():
            rmtree(self.outDir)
        self.outDir.mkdir(mode = 0o700)

    def tearDown(self):
        rmtree(self.outDir)
        pass

    def testSplitWithoutUmi(self):
        splitter = FastqSplit()
        args = SimpleNamespace(**{
            'source': Path('testdata/regular_50.fq'),
            'umi': None,
            'out': self.outDir,
            'reads': 10,
            'prefix': 'noUmiTest'
        })

        splitter.run(args, quiet = True)

        chunks = list(self.outDir.iterdir())
        chunkNames = [ f.name for f in chunks ]
        self.assertEqual(5, len(chunks), "Expect the read file to have returned five chunks.")
        self.assertIn('noUmiTest-C000000.fq.gz', chunkNames, 'Missing chunk 0.')
        self.assertIn('noUmiTest-C000001.fq.gz', chunkNames, 'Missing chunk 1.')
        self.assertIn('noUmiTest-C000002.fq.gz', chunkNames, 'Missing chunk 2.')
        self.assertIn('noUmiTest-C000003.fq.gz', chunkNames, 'Missing chunk 3.')
        self.assertIn('noUmiTest-C000004.fq.gz', chunkNames, 'Missing chunk 4.')

        with xopen(chunks[1], 'rt') as handle:
            idLine = handle.readline().strip()
            self.assertEqual("@M01686:2:000000000-DFTML:1:1101:16873:1631 1:N:0:AGCAGGAA", idLine,
                             "id of the first line of the second chunk (read 11) is wrong.")

    def testSplitWithUmi(self):
        splitter = FastqSplit()
        args = SimpleNamespace(**{
            'source': Path('testdata/regular_50.fq'),
            'umi': Path('testdata/umi_50.fq'),
            'out': self.outDir,
            'reads': 10,
            'prefix': 'withUmiTest'
        })

        splitter.run(args, quiet = True)

        chunks = list(self.outDir.iterdir())
        chunkNames = [ f.name for f in chunks ]
        self.assertEqual(5, len(chunks), "Expect the read file to have returned five chunks.")
        self.assertIn('withUmiTest-C000000.fq.gz', chunkNames, 'Missing chunk 0.')
        self.assertIn('withUmiTest-C000001.fq.gz', chunkNames, 'Missing chunk 1.')
        self.assertIn('withUmiTest-C000002.fq.gz', chunkNames, 'Missing chunk 2.')
        self.assertIn('withUmiTest-C000003.fq.gz', chunkNames, 'Missing chunk 3.')
        self.assertIn('withUmiTest-C000004.fq.gz', chunkNames, 'Missing chunk 4.')

        with xopen(chunks[1], 'rt') as handle:
            idLine = handle.readline().strip()
            self.assertEqual("@M01686:2:000000000-DFTML:1:1101:16873:1631:TGTTCTACGT 1:N:0:AGCAGGAA", idLine,
                             "id of the first line of the second chunk (read 11) is wrong.")

    # Just to make sure reading the truncated file with raw gzip handling
    # raises the expected exception.
    def testReadTruncated(self):
        try:
            with gzip.open('testdata/truncated.fq.gz', "rb") as fh:
                while (byte := fh.read(1)):
                    pass
            self.fail("Read truncated gzip file without EOFError.")
        except EOFError:
            # Expected
            pass

    def testSplitTruncated(self):
        splitter = FastqSplit()
        args = SimpleNamespace(**{
            'source': Path('testdata/truncated.fq.gz'),
            'umi': None,
            'out': self.outDir,
            'reads': 5,
            'prefix': 'trunctest'
        })

        try:
            splitter.run(args, quiet = True)
            self.fail("Read corrupted file without getting an exception.")
        except CorruptedFileException:
            pass
            #chunks = os.listdir(self.outDir)
            #self.assertEqual(2, len(chunks), "Expect the corrupted file to have returned two chunks.")
            #self.assertIn('trunctest-C000000.fq.gz', chunks, 'Missing chunk 0.')
            #self.assertIn('trunctest-C000001.fq.gz', chunks, 'Missing chunk 1.')

    def testTooFewUMIs(self):
        splitter = FastqSplit()
        args = SimpleNamespace(**{
            'source': Path('testdata/regular.fq'),
            'umi': Path('testdata/umi_short.fq'),
            'out': self.outDir,
            'reads': 10,
            'prefix': 'tooFewUmiTest'
        })

        try:
            splitter.run(args, quiet = True)
            self.fail("Read too short UMI file without exception.")
        except CorruptedFileException:
            pass

    def testMismatchedReadIds(self):
        splitter = FastqSplit()
        args = SimpleNamespace(**{
            'source': Path('testdata/regular.fq'),
            'umi': Path('testdata/umi_mismatch.fq'),
            'out': self.outDir,
            'reads': 10,
            'prefix': 'mismatchedIdTest'
        })

        try:
            splitter.run(args, quiet = True)
            self.fail("Read mismatched read ids files without exception.")
        except CorruptedFileException:
            pass
