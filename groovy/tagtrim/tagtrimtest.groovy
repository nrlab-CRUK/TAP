@Grapes([
    @Grab("org.apache.commons:commons-lang3:3.12.0"),
    @Grab("org.junit.jupiter:junit-jupiter-api:5.8.2"),
    @Grab("org.junit.jupiter:junit-jupiter-params:5.8.2"),
    @Grab("org.mockito:mockito-core:4.5.1"),
    @Grab("org.mockito:mockito-junit-jupiter:4.5.1")
])

import static org.apache.commons.lang3.StringUtils.EMPTY
import static org.apache.commons.lang3.StringUtils.repeat
import static TagTrim2.STEM
import static TagTrim2.RSTEM
import static TagTrim2.STEM_LENGTH
import static TagTrim2.UMI_LENGTH
import static org.junit.jupiter.api.Assertions.assertEquals
import static org.mockito.Mockito.mock
import static org.mockito.Mockito.times
import static org.mockito.Mockito.verify
import static org.mockito.Mockito.verifyNoMoreInteractions
import static org.mockito.Mockito.when

import TagTrim2

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.ArgumentCaptor
import org.mockito.Captor
import org.mockito.Mock
import org.mockito.junit.jupiter.MockitoExtension

import htsjdk.samtools.fastq.FastqReader
import htsjdk.samtools.fastq.FastqRecord
import htsjdk.samtools.fastq.FastqWriter

@ExtendWith(MockitoExtension.class)
public class TagTrim2Test
{
    @Mock
    FastqWriter writer1

    @Mock
    FastqWriter writer2

    @Mock
    FastqWriter writerU1

    @Mock
    FastqWriter writerU2

    @Captor
    ArgumentCaptor<FastqRecord> captor1

    @Captor
    ArgumentCaptor<FastqRecord> captor2

    @Captor
    ArgumentCaptor<FastqRecord> captorU1

    @Captor
    ArgumentCaptor<FastqRecord> captorU2

    String umi = 'u' * UMI_LENGTH
    String dna = 'd' * 4
    String noStem = 'X' * STEM_LENGTH
    
    String umiQ = 'U' * umi.length()
    String dnaQ = '@' * dna.length()
    String stemQ = 'x' * STEM_LENGTH

    public TagTrim2Test()
    {
    }

    @Test
    public void testTrim0()
    {
        testTrim("", "")
    }

    @Test
    public void testTrim1()
    {
        testTrim("A", "T")
    }

    @Test
    public void testTrim2()
    {
        testTrim("CA", "TG")
    }

    @Test
    public void testTrim3()
    {
        testTrim("TCA", "TGA")
    }

    private void testTrim(String insert1, String insert2)
    {
        def b1 = new StringBuilder(150)
        b1 << umi << insert1 << STEM << dna

        def q1 = new StringBuilder(150)
        q1 << umiQ << '.' * (insert1.length() + STEM_LENGTH) << dnaQ

        FastqReader reader1 = mock(FastqReader.class)
        when(reader1.hasNext()).thenReturn(true, false)
        when(reader1.next()).thenReturn(basesToRecord(1, b1, q1))

        FastqReader reader2 = mock(FastqReader.class)
        when(reader2.hasNext()).thenReturn(true, false)
        when(reader2.next()).thenReturn(basesToRecord(2, b1, q1))

        TagTrim2 tagtrim = new TagTrim2()

        tagtrim.doTrimming(reader1, reader2, writer1, writer2, writerU1, writerU2)

        verifyNoMoreInteractions(reader1, reader2)
        verify(writer1, times(1)).write(captor1.capture())
        verify(writer2, times(1)).write(captor2.capture())
        verify(writerU1, times(1)).write(captorU1.capture())
        verify(writerU2, times(1)).write(captorU2.capture())

        FastqRecord r1 = captor1.value

        assertEquals("r1", r1.readName, "Read one name wrong.")
        assertEquals(dna, r1.readString, "Read one read wrong.")
        assertEquals(dnaQ, r1.baseQualityString, "Read one base quality wrong.")

        FastqRecord r2 = captor2.value

        assertEquals("r2", r2.readName, "Read two name wrong.")
        assertEquals(dna, r2.readString, "Read two read wrong.")
        assertEquals(dnaQ, r2.baseQualityString, "Read two base quality wrong.")

        FastqRecord u1 = captorU1.value

        assertEquals("r1", u1.readName, "UMI one name wrong.")
        assertEquals(umi, u1.readString, "UMI one read wrong.")
        assertEquals(umiQ, u1.baseQualityString, "UMI one base quality wrong.")

        FastqRecord u2 = captorU2.value

        assertEquals("r2", u2.readName, "UMI two name wrong.")
        assertEquals(umi, u2.readString, "UMI two read wrong.")
        assertEquals(umiQ, u2.baseQualityString, "UMI two base quality wrong.")
    }

    private FastqRecord basesToRecord(read, b, q)
    {
        return new FastqRecord("r" + read, b as String, EMPTY, q as String)
    }

    @Test
    public void testNonOverlappingReadOne()
    {
        testNonOverlapping(1)
    }

    @Test
    public void testNonOverlappingReadTwo()
    {
        testNonOverlapping(2)
    }

    private void testNonOverlapping(int read)
    {
        def stemIn1 = read == 1

        def b1 = new StringBuilder(150)
        b1 << umi << STEM << dna << (stemIn1 ? RSTEM : noStem) << dna

        StringBuilder q1 = new StringBuilder(150)
        q1 << umiQ << stemQ << dnaQ << stemQ << dnaQ

        StringBuilder b2 = new StringBuilder(150)
        b2 << umi << STEM << dna << (stemIn1 ? noStem : RSTEM) << dna << dna

        StringBuilder q2 = new StringBuilder(150)
        q2 << umiQ << stemQ << dnaQ << stemQ << dnaQ << dnaQ

        FastqReader reader1 = mock(FastqReader.class)
        when(reader1.hasNext()).thenReturn(true, false)
        when(reader1.next()).thenReturn(basesToRecord(1, b1, q1))

        FastqReader reader2 = mock(FastqReader.class)
        when(reader2.hasNext()).thenReturn(true, false)
        when(reader2.next()).thenReturn(basesToRecord(2, b2, q2))

        TagTrim2 tagtrim = new TagTrim2()

        tagtrim.doTrimming(reader1, reader2, writer1, writer2, writerU1, writerU2)

        verifyNoMoreInteractions(reader1, reader2)
        verify(writer1, times(1)).write(captor1.capture())
        verify(writer2, times(1)).write(captor2.capture())
        verify(writerU1, times(1)).write(captorU1.capture())
        verify(writerU2, times(1)).write(captorU2.capture())

        FastqRecord r1 = captor1.value

        assertEquals(dna + (stemIn1 ? RSTEM : noStem) + dna, r1.readString, "Read one read wrong.")
        assertEquals(dnaQ + stemQ + dnaQ, r1.baseQualityString, "Read one base quality wrong.")

        FastqRecord r2 = captor2.value

        assertEquals(dna + (stemIn1 ? noStem : RSTEM) + dna + dna, r2.readString, "Read two read wrong.")
        assertEquals(dnaQ + stemQ + dnaQ + dnaQ, r2.baseQualityString, "Read two base quality wrong.")

        FastqRecord u1 = captorU1.value

        assertEquals(umi, u1.readString, "UMI one read wrong.")
        assertEquals(umiQ, u1.baseQualityString, "UMI one base quality wrong.")

        FastqRecord u2 = captorU2.value

        assertEquals(umi, u2.readString, "UMI two read wrong.")
        assertEquals(umiQ, u2.baseQualityString, "UMI two base quality wrong.")
    }

    @Test
    public void testOverlapping()
    {
        StringBuilder b1 = new StringBuilder(150)
        b1 << umi << STEM << dna << RSTEM << dna

        StringBuilder q1 = new StringBuilder(150)
        q1 << umiQ << stemQ << dnaQ << stemQ << dnaQ

        StringBuilder b2 = new StringBuilder(150)
        b2 << umi << STEM << dna << RSTEM << dna << dna

        StringBuilder q2 = new StringBuilder(150)
        q2 << umiQ << stemQ << dnaQ << stemQ << dnaQ << dnaQ

        FastqReader reader1 = mock(FastqReader.class)
        when(reader1.hasNext()).thenReturn(true, false)
        when(reader1.next()).thenReturn(basesToRecord(1, b1, q1))

        FastqReader reader2 = mock(FastqReader.class)
        when(reader2.hasNext()).thenReturn(true, false)
        when(reader2.next()).thenReturn(basesToRecord(2, b2, q2))

        TagTrim2 tagtrim = new TagTrim2()

        tagtrim.doTrimming(reader1, reader2, writer1, writer2, writerU1, writerU2)

        verifyNoMoreInteractions(reader1, reader2)
        verify(writer1, times(1)).write(captor1.capture())
        verify(writer2, times(1)).write(captor2.capture())
        verify(writerU1, times(1)).write(captorU1.capture())
        verify(writerU2, times(1)).write(captorU2.capture())

        FastqRecord r1 = captor1.value

        assertEquals(dna, r1.readString, "Read one read wrong.")
        assertEquals(dnaQ, r1.baseQualityString, "Read one base quality wrong.")

        FastqRecord r2 = captor2.value

        assertEquals(dna, r2.readString, "Read two read wrong.")
        assertEquals(dnaQ, r2.baseQualityString, "Read two base quality wrong.")

        FastqRecord u1 = captorU1.value

        assertEquals(umi, u1.readString, "UMI one read wrong.")
        assertEquals(umiQ, u1.baseQualityString, "UMI one base quality wrong.")

        FastqRecord u2 = captorU2.value

        assertEquals(umi, u2.readString, "UMI two read wrong.")
        assertEquals(umiQ, u2.baseQualityString, "UMI two base quality wrong.")
    }
}
