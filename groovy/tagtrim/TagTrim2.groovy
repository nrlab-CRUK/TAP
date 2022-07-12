@Grapes([
    @Grab("com.github.samtools:htsjdk:2.24.1"),
    @Grab("info.picocli:picocli:4.6.3"),
    @GrabExclude("commons-logging#commons-logging"),
    @Grab("org.slf4j:slf4j-api:1.7.36"),
    @Grab("org.apache.logging.log4j:log4j-slf4j-impl:2.17.2")
])

import java.util.concurrent.Callable

import htsjdk.samtools.fastq.FastqReader
import htsjdk.samtools.fastq.FastqRecord
import htsjdk.samtools.fastq.FastqWriter
import htsjdk.samtools.fastq.FastqWriterFactory
import picocli.CommandLine.Command
import picocli.CommandLine.ExitCode
import picocli.CommandLine.Option

@Command(name = "tagtrim2", mixinStandardHelpOptions = true)
public class TagTrim2 implements Callable<Integer>
{
    class Timing
    {
        long startTime
        long time
        int count
        
        void start()
        {
            startTime = System.nanoTime()
        }
        
        void end()
        {
            time += System.nanoTime() - startTime
            count++
        }
        
        double mean()
        {
            return (time as double) / count
        }
        
        String toString()
        {
            return Double.toString(mean())
        }
    }
    
    static final String STEM = 'GTAGCTCA'
    static final String RSTEM = 'TGAGCTAC'

    static final int UMI_LENGTH = 6
    static final int STEM_LENGTH = STEM.length()
    private static final int ADDITIONAL_BASES = 3

    private Set stems = []
    
    private Timing reading = new Timing()
    private Timing processing = new Timing()
    private Timing writing = new Timing()

    @Option(names = "--read1", required = true, description = "Read one FASTQ file (input).")
    File read1In

    @Option(names = "--read2", required = true, description = "Read two FASTQ file (input).")
    File read2In

    @Option(names = "--out1", required = true, description = "Read one FASTQ file (output).")
    File read1Out

    @Option(names = "--out2", required = true, description = "Read two FASTQ file (output).")
    File read2Out

    @Option(names = "--umi1", required = true, description = "UMI one FASTQ file (output).")
    File umi1Out

    @Option(names = "--umi2", required = true, description = "UMI two FASTQ file (output).")
    File umi2Out


    private FastqWriterFactory writerFactory

    public TagTrim2()
    {
        writerFactory = new FastqWriterFactory()
        writerFactory.useAsyncIo = false
        writerFactory.createMd5 = false

        stems << STEM
        stems << "A${STEM}".toString()
        stems << "CA${STEM}".toString()
        stems << "TCA${STEM}".toString()
    }

    @Override
    public Integer call() throws Exception
    {
        new FastqReader(read1In).withCloseable
        {
            reader1 ->
            
            new FastqReader(read2In).withCloseable
            {
                reader2 ->

                writerFactory.newWriter(read1Out).withCloseable
                {
                    writer1 ->
                    
                    writerFactory.newWriter(read2Out).withCloseable
                    {
                        writer2 ->
                        
                        writerFactory.newWriter(umi1Out).withCloseable
                        {
                            writerU1 ->
                            
                            writerFactory.newWriter(umi2Out).withCloseable
                            {
                                writerU2 ->
                                
                                doTrimming(reader1, reader2, writer1, writer2, writerU1, writerU2)
                            }
                        }
                    }
                }
            }
        }
        return ExitCode.OK
    }

    void doTrimming(FastqReader reader1, FastqReader reader2, FastqWriter writer1, FastqWriter writer2, FastqWriter writerU1, FastqWriter writerU2)
    {
        while (reader1.hasNext() && reader2.hasNext())
        {
            reading.start();
            FastqRecord r1 = reader1.next()
            FastqRecord r2 = reader2.next()
            reading.end();
            
            processing.start()
            
            def b1 = r1.readString
            int insert1Start = getInsertStart(b1)
            if (insert1Start < 0)
            {
                // The forward read doesn't have the stem in the usual position. Filter out.
                continue
            }

            String b2 = r2.readString
            int insert2Start = getInsertStart(b2)
            if (insert2Start < 0)
            {
                // The reverse read doesn't have the stem in the usual position. Filter out.
                continue
            }

            /*
            if (logger.isDebugEnabled())
            {
                logger.debug("In {}, found {} as {} in r1 and as {} in r2", getReadId(r1),
                        STEM, b1.substring(UMI_LENGTH, insert1Start),
                        b2.substring(UMI_LENGTH, insert2Start))
            }
            */

            // See if we can find the reverse stem.

            int rstem1Pos = b1.indexOf(RSTEM, insert1Start)
            int rstem2Pos = b2.indexOf(RSTEM, insert2Start)

            int insert1End = b1.length()
            int insert2End = b2.length()

            if (rstem1Pos >= 0 && rstem2Pos >= 0)
            {
                // Stem in both reads. Looks like these are stems and should be trimmed.

                insert1End = rstem1Pos
                insert2End = rstem2Pos

                // logger.debug("In {}, found {} in r1 and r2.", getReadId(r1), RSTEM)
            }
            // else either the stem isn't present or if only present in one read, it might be DNA sequence.

            String insert1 = b1[insert1Start..<insert1End]
            String insertQ1 = r1.baseQualityString[insert1Start..<insert1End]
            String umi1 = b1[0..<UMI_LENGTH]
            String umiQ1 = r1.baseQualityString[0..<UMI_LENGTH]

            String insert2 = b2[insert2Start..<insert2End]
            String insertQ2 = r2.baseQualityString[insert2Start..<insert2End]
            String umi2 = b2[0..<UMI_LENGTH]
            String umiQ2 = r2.baseQualityString[0..<UMI_LENGTH]

            processing.end()
            
            writing.start()
            writer1.write(new FastqRecord(r1.getReadName(), insert1, r1.baseQualityHeader, insertQ1))
            writerU1.write(new FastqRecord(r1.getReadName(), umi1, r1.baseQualityHeader, umiQ1))
            writer2.write(new FastqRecord(r2.getReadName(), insert2, r2.baseQualityHeader, insertQ2))
            writerU2.write(new FastqRecord(r2.getReadName(), umi2, r2.baseQualityHeader, umiQ2))
            writing.end()
        }
        
        System.err.println("Mean reading time: ${reading} ns")
        System.err.println("Mean processing time: ${processing} ns")
        System.err.println("Mean writing time: ${writing} ns")
    }

    private String getReadId(FastqRecord r)
    {
        String id = r.readName
        int space = id.indexOf(' ')
        if (space >= 0)
        {
            id = id[0..<space]
        }
        return id
    }

    private int getInsertStart(String read)
    {
        for (tagOffset in 0..ADDITIONAL_BASES)
        {
            String stem = read[UMI_LENGTH..<UMI_LENGTH + tagOffset + STEM_LENGTH].toString()
            if (stem in stems)
            {
                return UMI_LENGTH + tagOffset + STEM_LENGTH
            }
        }
        return -1
    }
}
