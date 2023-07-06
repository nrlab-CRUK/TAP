import gzip
import os
import unittest

from shutil import rmtree
from types import SimpleNamespace

from FastqSplit import FastqSplit, CorruptedFileException

class TagTrim2Test(unittest.TestCase):
    def setUp(self):
        self.truncatedFile = 'testdata/truncated.fq.gz'
        self.outDir = 'FastqSplit_testout'
        if os.path.exists(self.outDir):
            rmtree(self.outDir)
        os.mkdir(self.outDir, 0o700)

    def tearDown(self):
        rmtree(self.outDir)
        pass

    def testSplitTruncated(self):
        splitter = FastqSplit()
        args = SimpleNamespace(**{
            'source': self.truncatedFile,
            'out': self.outDir,
            'reads': 5,
            'prefix': 'trunctest'
        })

        try:
            splitter.run(args)
            self.fail("Read corrupted file without getting an exception.")
        except CorruptedFileException:
            chunks = os.listdir(self.outDir)
            self.assertEqual(2, len(chunks), "Expect the corrupted file to have returned two chunks.")
            self.assertIn('trunctest-C000000.fq.gz', chunks, 'Missing chunk 0.')
            self.assertIn('trunctest-C000001.fq.gz', chunks, 'Missing chunk 1.')

    def testReadTruncated(self):
        try:
            with gzip.open(self.truncatedFile, "rb") as fh:
                while (byte := fh.read(1)):
                    pass
            self.fail("Read truncated gzip file without EOFError.")
        except EOFError:
            # Expected
            pass
