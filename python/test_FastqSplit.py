import gzip
import os
import unittest

from shutil import rmtree
from types import SimpleNamespace

from FastqSplit import FastqSplit
from pip._vendor.html5lib.constants import EOF

class TagTrim2Test(unittest.TestCase):
    def setUp(self):
        self.truncatedFile = 'testdata/truncated.fq.gz'
        self.outDir = 'FastqSplit_testout'
        if os.path.exists(self.outDir):
            rmtree(self.outDir)
        os.mkdir(self.outDir, 0o700)

    def tearDown(self):
        rmtree(self.outDir)

    def BROKENtestSplitTruncated(self):
        splitter = FastqSplit()
        args = SimpleNamespace(**{
            'source': self.truncatedFile,
            'out': self.outDir,
            'reads': 500,
            'prefix': 'trunctest'
        })

        splitter.run(args)

    def testReadTruncated(self):
        try:
            with gzip.open(self.truncatedFile, "rb") as fh:
                while (byte := fh.read(1)):
                    pass
            self.fail("Read truncated gzip file without EOFError.")
        except EOFError:
            # Expected
            pass
