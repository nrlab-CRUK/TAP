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

// def tag = "OUTOFMEMORYCHECK"

// println("${tag}: status = ${status}")
// println("${tag}: log file exists = ${log.exists()}")

if (log.exists())
{
    def ranOutOfMemory = false
    log.withReader
    {
        reader ->
        def line
        
        // != null is important, as without it the emtpy string is also interpreted as false.
        while (!ranOutOfMemory && (line = reader.readLine()) != null)
        {
            ranOutOfMemory = line.contains(outOfMemoryClass)
        }
    }
    // println("${tag}: out of memory = ${ranOutOfMemory}")
    status = ranOutOfMemory ? 104 : status
}

System.exit(status)
