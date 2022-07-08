@Grab("info.picocli:picocli:4.6.3")

import picocli.CommandLine

// Load the class. See https://stackoverflow.com/a/1169196 and https://stackoverflow.com/a/9006034

def scriptDir = new File(getClass().protectionDomain.codeSource.location.path).parentFile
def tagTrim2Script = new File(scriptDir, "TagTrim2.groovy")
def tagTrim2Class = getClass().classLoader.parseClass(tagTrim2Script.absoluteFile)

// Can't seem to use the class directly (compile problems).
// Sorry this is a bit messy, but it's easier than packaging into a JAR or similar.

def tagtrim = tagTrim2Class.newInstance()
int exitCode = new CommandLine(tagtrim).execute(args)
System.exit(exitCode)
