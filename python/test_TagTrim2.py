#!/usr/bin/env python3

import unittest

from collections import namedtuple

from pysam import FastxRecord

from TagTrim2 import TagTrim2

class MockOutput:
    def __init__(self):
        self.output = []

    def write(self, thing):
        self.output.append(thing)

    def print(self, thing):
        self.output.append(thing)


class TagTrim2Test(unittest.TestCase):

    def setUp(self):
        self.umi1 = '1' * TagTrim2.UMI_LENGTH
        self.umi2 = '2' * TagTrim2.UMI_LENGTH
        self.dna = 'd' * 4
        self.noStem = 'X' * TagTrim2.STEM_LENGTH
        self.umiQ = 'U' * len(self.umi1)
        self.dnaQ = '@' * len(self.dna)
        self.stemQ = 'x' * TagTrim2.STEM_LENGTH

    def testTrim0(self):
        self.doTrim("", "")

    def testTrim1(self):
        self.doTrim("A", "T")

    def testTrim2(self):
        self.doTrim("CA", "TG")

    def testTrim3(self):
        self.doTrim("TCA", "TGA")

    def doTrim(self, insert1, insert2):
        b1 = self.umi1 + insert1 + TagTrim2.STEM + self.dna
        b2 = self.umi2 + insert1 + TagTrim2.STEM + self.dna

        q1 = self.umiQ + '.' * (len(insert1) + TagTrim2.STEM_LENGTH) + self.dnaQ

        read1 = self.basesToRecord(1, b1, q1)
        read2 = self.basesToRecord(2, b2, q1)

        tagtrim = TagTrim2()

        read1Out = MockOutput()
        read2Out = MockOutput()

        tagtrim.processReads(read1, read2, read1Out, read2Out)

        r1 = read1Out.output[0].split('\n')

        self.assertEqual(r1[0], f"@r1:{self.umi1}+{self.umi2} c1", "Read one name wrong.")
        self.assertEqual(r1[1], self.dna, "Read one read wrong.")
        self.assertEqual(r1[3], self.dnaQ, "Read one base quality wrong.")

        r2 = read2Out.output[0].split('\n')

        self.assertEqual(r2[0], f"@r2:{self.umi1}+{self.umi2} c2", "Read two name wrong.")
        self.assertEqual(r2[1], self.dna, "Read two read wrong.")
        self.assertEqual(r2[3], self.dnaQ, "Read two base quality wrong.")


    def testNonOverlappingReadOne(self):
        self.nonOverlapping(1)

    def testNonOverlappingReadTwo(self):
        self.nonOverlapping(2)

    def nonOverlapping(self, read):
        stemIn1 = read == 1

        b1 = self.umi1 + TagTrim2.STEM + self.dna + (TagTrim2.RSTEM if stemIn1 else self.noStem) + self.dna

        q1 = self.umiQ + self.stemQ + self.dnaQ + self.stemQ + self.dnaQ

        b2 = self.umi2 + TagTrim2.STEM + self.dna + (self.noStem if stemIn1 else TagTrim2.RSTEM) + self.dna + self.dna

        q2 = self.umiQ + self.stemQ + self.dnaQ + self.stemQ + self.dnaQ + self.dnaQ

        read1 = self.basesToRecord(1, b1, q1)
        read2 = self.basesToRecord(2, b2, q2)

        tagtrim = TagTrim2()

        read1Out = MockOutput()
        read2Out = MockOutput()

        tagtrim.processReads(read1, read2, read1Out, read2Out)

        r1 = read1Out.output[0].split('\n')

        self.assertEqual(r1[0], f"@r1:{self.umi1}+{self.umi2} c1", "Read one name wrong.")
        self.assertEqual(r1[1], self.dna + (TagTrim2.RSTEM if stemIn1 else self.noStem) + self.dna, "Read one read wrong.")
        self.assertEqual(r1[3], self.dnaQ + self.stemQ + self.dnaQ, "Read one base quality wrong.")

        r2 = read2Out.output[0].split('\n')

        self.assertEqual(r2[0], f"@r2:{self.umi1}+{self.umi2} c2", "Read two name wrong.")
        self.assertEqual(r2[1], self.dna + (self.noStem if stemIn1 else TagTrim2.RSTEM) + self.dna + self.dna, "Read two read wrong.")
        self.assertEqual(r2[3], self.dnaQ + self.stemQ + self.dnaQ + self.dnaQ, "Read two base quality wrong.")

    def testOverlapping(self):

        b1 = self.umi1 + TagTrim2.STEM + self.dna + TagTrim2.RSTEM + self.dna

        q1 = self.umiQ + self.stemQ + self.dnaQ + self.stemQ + self.dnaQ

        b2 = self.umi2 + TagTrim2.STEM + self.dna + TagTrim2.RSTEM + self.dna + self.dna

        q2 = self.umiQ + self.stemQ + self.dnaQ + self.stemQ + self.dnaQ + self.dnaQ

        read1 = self.basesToRecord(1, b1, q1)
        read2 = self.basesToRecord(2, b2, q2)

        tagtrim = TagTrim2()

        read1Out = MockOutput()
        read2Out = MockOutput()

        tagtrim.processReads(read1, read2, read1Out, read2Out)

        r1 = read1Out.output[0].split('\n')

        self.assertEqual(r1[0], f"@r1:{self.umi1}+{self.umi2} c1", "Read one name wrong.")
        self.assertEqual(r1[1], self.dna, "Read one read wrong.")
        self.assertEqual(r1[3], self.dnaQ, "Read one base quality wrong.")

        r2 = read2Out.output[0].split('\n')

        self.assertEqual(r2[0], f"@r2:{self.umi1}+{self.umi2} c2", "Read two name wrong.")
        self.assertEqual(r2[1], self.dna, "Read two read wrong.")
        self.assertEqual(r2[3], self.dnaQ, "Read two base quality wrong.")


    def basesToRecord(self, read, b, q):
        record = FastxRecord()
        record.name = f"r{read}"
        record.comment = f"c{read}"
        record.sequence = b
        record.quality = q
        return record
