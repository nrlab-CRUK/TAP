#!/usr/bin/env python3

import unittest

from collections import namedtuple

from pysam import FastxRecord

from KapaTrim import KapaTrim

class MockOutput:
    def __init__(self):
        self.output = []

    def write(self, thing):
        self.output.append(thing)

    def print(self, thing):
        self.output.append(thing)


class KapaTrimTest(unittest.TestCase):

    def setUp(self):
        self.umi1 = '1' * KapaTrim.UMI_LENGTH
        self.umi2 = '2' * KapaTrim.UMI_LENGTH
        self.dna = 'd' * 4
        self.umiQ = 'U' * KapaTrim.UMI_LENGTH
        self.dnaQ = 'D' * len(self.dna)

    def testTrim0(self):
        self.doTrim(0)

    def testTrim2(self):
        self.doTrim(2)

    def testTrim3(self):
        self.doTrim(3)

    def doTrim(self, spacerLength: int):
        self.spacer = 's' * spacerLength
        self.spacerQ = 'S' * spacerLength

        b1 = self.umi1 + self.spacer + self.dna
        b2 = self.umi2 + self.spacer + self.dna

        q1 = self.umiQ + self.spacerQ + self.dnaQ

        read1 = self.basesToRecord(1, b1, q1)
        read2 = self.basesToRecord(2, b2, q1)

        kapaTrim = KapaTrim()
        kapaTrim.spacer = spacerLength

        read1Out = MockOutput()
        read2Out = MockOutput()

        kapaTrim.processReads(read1, read2, read1Out, read2Out)

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
