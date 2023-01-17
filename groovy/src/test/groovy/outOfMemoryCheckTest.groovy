import static org.junit.jupiter.api.Assertions.*

import org.junit.jupiter.api.*


/**
 * Unit tests for the {@code outOfMemoryCheck.groovy} script.
 * Run from the "groovy" directory using Maven:
 *
 * mvn test
 *
 * Groovy must be on the path.
 */
class OutOfMemoryCheckTest
{
    final def commandLogName = '.command.log'
    def baseDir
    def commandLog
    def command

    OutOfMemoryCheckTest()
    {
        baseDir = new File(System.getProperty('basedir'))
        commandLog = new File(baseDir, commandLogName)
    }

    @BeforeEach
    void setup()
    {
        command = [ 'groovy', 'outOfMemoryCheck.groovy' ]
    }

    @AfterEach
    void cleanUp()
    {
        commandLog.delete()
    }

    @Test
    void noArgumentNoLog()
    {
        def proc = run(command)
        assertEquals(0, proc.exitValue(), "Exit code with no param and no ${commandLogName} wrong")
    }

    @Test
    void zeroNoLog()
    {
        def inCode = '0'
        command << inCode

        def proc = run(command)
        assertEquals(0, proc.exitValue(), "Exit code with ${inCode} and no ${commandLogName} wrong")
    }

    @Test
    void oneNoLog()
    {
        def inCode = '1'
        command << inCode

        def proc = run(command)
        assertEquals(1, proc.exitValue(), "Exit code with ${inCode} and no ${commandLogName} wrong")
    }

    @Test
    void zeroWithLogNoMemoryFail()
    {
        def inCode = '0'
        command << inCode

        // Blank line is important as that has caused premature end of log scan.
        commandLog.withPrintWriter
        {
            pw ->
            pw.println("Failed for other reasons.")
            pw.println()
            pw.println("Same exit code")
        }

        def proc = run(command)
        assertEquals(0, proc.exitValue(), "Exit code with ${inCode} and ${commandLogName} without memory error wrong")
    }

    @Test
    void zeroWithLogAndMemoryFail()
    {
        def inCode = '0'
        command << inCode

        commandLog.withPrintWriter
        {
            pw ->
            pw.println("Failed because of memory.")
            pw.println()
            new OutOfMemoryError().printStackTrace(pw)
            pw.println("Exit code 104.")
        }

        def proc = run(command)
        assertEquals(104, proc.exitValue(), "Exit code with ${inCode} and ${commandLogName} with memory error wrong")
    }

    private Process run(command)
    {
        def pb = new ProcessBuilder(command)
        pb.directory(baseDir)
        def proc = pb.start()
        proc.waitFor()
        return proc
    }
}
