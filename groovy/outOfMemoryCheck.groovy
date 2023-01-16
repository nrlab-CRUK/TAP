/**
 * Script that takes the given exit code from a Java or Groovy process
 * and looks at the .command.log file created by Nextflow. If it
 * contains the text "java.lang.OutOfMemoryError" then the exit
 * code is changed to 104 to signify this. Otherwise the exit
 * code passed into the script is returned.
 */

def status = args.length > 0 ? Integer.parseInt(args[0]) : 0

def log = new File(".command.log")
def outOfMemoryClass = OutOfMemoryError.class.name

if (log.exists())
{
    def ranOutOfMemory = false
    log.withReader
    {
        reader ->
        def line
        while (!ranOutOfMemory && (line = reader.readLine()))
        {
            ranOutOfMemory = line.contains(outOfMemoryClass)
        }
    }
    status = ranOutOfMemory ? 104 : status
}

System.exit(status)
