import static org.junit.jupiter.api.Assertions.*
import static java.nio.file.LinkOption.NOFOLLOW_LINKS

import java.nio.file.Path
import java.nio.file.Files

import org.junit.jupiter.api.*
import org.apache.commons.io.FileUtils


/**
 * Unit tests for the {@code removeInput.groovy} script.
 * Run from the "groovy" directory using Maven:
 *
 * mvn test
 *
 * Groovy must be on the path.
 */
class RemoveInputTest
{
    def baseDir
    def testDir

    def paths
    def command

    RemoveInputTest()
    {
        baseDir = new File(System.getProperty('basedir'))
        def targetDir = new File(baseDir, "target")
        testDir = new File(targetDir, "removeInputTest")

        paths = []
        paths << new File(testDir, "file").toPath()
        paths << new File(testDir, "filelink").toPath()
        paths << new File(testDir, "secondlink").toPath()
        paths << new File(testDir, "dir").toPath()
        paths << new File(testDir, "dirlink").toPath()
        paths << new File(testDir, "brokenlink").toPath()
    }

    @BeforeEach
    void setup()
    {
        command = [ 'groovy', 'removeInput.groovy', 'true', '0' ]

        FileUtils.deleteQuietly(testDir)
        FileUtils.forceMkdir(testDir)

        Path testPath = testDir.toPath()

        Files.createFile(paths[0])
        Files.createSymbolicLink(paths[1], testPath.relativize(paths[0]))
        Files.createSymbolicLink(paths[2], testPath.relativize(paths[1]))

        Files.createDirectory(paths[3])
        Files.createSymbolicLink(paths[4], testPath.relativize(paths[3]))

        Path broken = new File(testDir, "broken").toPath()
        Files.createSymbolicLink(paths[5], testPath.relativize(broken))
    }

    @AfterEach
    void cleanUp()
    {
        FileUtils.deleteQuietly(testDir)
    }

    /**
     * Shouldn't remove anything.
     */
    @Test
    void removeNothing()
    {
        run(command)

        testPaths(true, true, true, true, true, true)
    }

    /**
     * Remove the file link and the file itself.
     */
    @Test
    void removeFileOnly()
    {
        run(command, paths[1])

        testPaths(false, false, true, true, true, true)
    }

    /**
     * Remove the link to the first file link, the first file link and the file itself.
     */
    @Test
    void removeFileSecondLink()
    {
        run(command, paths[2])

        testPaths(false, false, false, true, true, true)
    }

    /**
     * Remove nothing as the link is to a directory.
     */
    @Test
    void removeDirOnly()
    {
        run(command, paths[4])

        testPaths(true, true, true, true, true, true)
    }

    /**
     * Remove the broken link.
     */
    @Test
    void removeBrokenOnly()
    {
        run(command, paths[5])

        testPaths(true, true, true, true, true, false)
    }

    /**
     * Remove the file and links to it plus the broken link.
     * The directory and its link stay.
     */
    @Test
    void removeAll()
    {
        run(command, paths[2], paths[4], paths[5])

        testPaths(false, false, false, true, true, false)
    }

    /**
     * Delete where there is no path before the files.
     */
    @Test
    void deleteFromFileDirectory()
    {
        command = [ 'groovy', '../../removeInput.groovy', 'true', '0' ]

        run(command, testDir, paths[2], paths[4], paths[5])

        testPaths(false, false, false, true, true, false)
    }

    // Helpers

    private Process run(command, Path... delPaths)
    {
        return run(command, baseDir, delPaths)
    }

    private Process run(command, File workingDir, Path... delPaths)
    {
        def basePath = workingDir.toPath()

        def relPaths = delPaths.collect { basePath.relativize(it).toString() }
        command.addAll(relPaths)

        def pb = new ProcessBuilder(command)
        pb.directory(workingDir)
        def proc = pb.start()
        proc.waitFor()
        return proc
    }

    private void testPaths(p0, p1, p2, p3, p4, p5)
    {
        testExists(paths[0], p0)
        testExists(paths[1], p1)
        testExists(paths[2], p2)
        testExists(paths[3], p3)
        testExists(paths[4], p4)
        testExists(paths[5], p5)
    }

    private void testExists(path, shouldExist)
    {
        if (shouldExist)
        {
            assertTrue(Files.exists(path, NOFOLLOW_LINKS), "${path} removed.")
        }
        else
        {
            assertFalse(Files.exists(path, NOFOLLOW_LINKS), "${path} not removed.")
        }
    }
}
