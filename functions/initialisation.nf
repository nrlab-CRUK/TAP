import groovy.grape.Grape

def groovyMajor()
{
    def version = GroovySystem.shortVersion as float
    return version as int
}

// Grab the necessary grapes for Groovy here, so make sure they are available
// before the pipeline starts and multiple processes try to get them.
def grabGrapes()
{
    // log.info("Groovy version is ${GroovySystem.version}")

    def groovyGroup = groovyMajor() >= 4 ? 'org.apache.groovy' : 'org.codehaus.groovy'

    log.debug("Fetching Groovy dependencies.")

    def classLoader = nextflow.Nextflow.classLoader

    Grape.grab([group:'org.apache.commons', artifact:'commons-lang3', version:'3.12.0', noExceptions:true, classLoader: classLoader])
    Grape.grab([group:'com.github.samtools', artifact:'htsjdk', version:'2.24.1', noExceptions:true, classLoader: classLoader])
    Grape.grab([group:'info.picocli', artifact:'picocli', version:'4.6.3', classLoader: classLoader])
    Grape.grab([group:'org.apache.logging.log4j', artifact:'log4j-api', version:'2.17.2', classLoader: classLoader])
    Grape.grab([group:'org.apache.logging.log4j', artifact:'log4j-core', version:'2.17.2', classLoader: classLoader])
}
