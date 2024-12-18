import java.nio.file.Files
import org.apache.commons.collections4.bag.CollectionBag
import org.apache.commons.collections4.bag.TreeBag
import org.apache.commons.csv.*
import groovy.json.JsonOutput

include { logException } from '../modules/nextflow-support/debugging'
include { referenceFasta; bwamem2Index; gatkKnownSites } from './references'

/*
 * Check the parameters are set and valid.
 */
def checkParameters(params)
{
    def errors = false

    def refFasta = referenceFasta()
    def refBwamem = bwamem2Index()
    def knownSites = gatkKnownSites()

    params.with
    {
        if (!file(INPUTS_CSV).exists())
        {
            log.error "INPUTS_CSV file ${INPUTS_CSV} does not exist."
            errors = true
        }
        if (!file(FASTQ_DIR).isDirectory())
        {
            log.error "FASTQ_DIR directory ${FASTQ_DIR} does not exist, or is not a directory."
            errors = true
        }
        if (!file(refFasta).exists())
        {
            log.error "REFERENCE_FASTA file ${refFasta} does not exist."
            errors = true
        }
        if (file("${refBwamem}*").empty)
        {
            log.error "BWAMEM2_INDEX does not exist as ${refBwamem}*"
            errors = true
        }
        if (params.GATK_BQSR)
        {
            for (def gatkFile in knownSites)
            {
                if (!file(gatkFile).exists())
                {
                    log.error "GATK_KNOWN_SITES known sites file ${gatkFile} does not exist."
                    errors = true
                }
            }
        }
    }

    return !errors
}

/*
 * Check the driver CSV file has the necessary minimum columns to run
 * in the configured mode and that each line in the file has those mandatory
 * values set.
 */
def checkDriverCSV(params)
{
    def ok = true
    try
    {
        def unitIds = new TreeBag()

        def driverFile = file(params.INPUTS_CSV)
        driverFile.withReader('UTF-8')
        {
            stream ->
            def parser = CSVParser.parse(stream, CSVFormat.DEFAULT.withHeader())
            def first = true

            for (def record in parser)
            {
                if (first)
                {
                    if (!record.isMapped('Read1'))
                    {
                        log.error "${params.INPUTS_CSV} must contain a column 'Read1'."
                        ok = false
                    }
                    if (!record.isMapped('Read2'))
                    {
                        log.error "${params.INPUTS_CSV} must contain a column 'Read2'."
                        ok = false
                    }

                    def missingUnitCols = []
                    for (def col in params.UNIT_ID_PARTS)
                    {
                        if (!record.isMapped(col))
                        {
                            missingUnitCols << col
                        }
                    }
                    if (!missingUnitCols.empty)
                    {
                        log.error "${params.INPUTS_CSV} is missing one or more columns defined by the UNIT_ID_PARTS parameter: {}", missingUnitCols.join(', ')
                        ok = false
                    }

                    def missingSampleCols = []
                    for (def col in params.SAMPLE_ID_PARTS)
                    {
                        if (!record.isMapped(col))
                        {
                            missingSampleCols << col
                        }
                    }
                    if (!missingSampleCols.empty)
                    {
                        log.error "${params.INPUTS_CSV} is missing one or more columns defined by the SAMPLE_ID_PARTS parameter: ${missingSampleCols.join(', ')}"
                        ok = false
                    }

                    first = false
                    if (!ok)
                    {
                        break
                    }
                }

                def rowNum = parser.recordNumber + 1
                if (!record.get('Read1'))
                {
                    log.error "No 'Read1' file name set on line ${rowNum}."
                    ok = false
                }
                if (!record.get('Read2'))
                {
                    log.error "No 'Read2' file name set on line ${rowNum}."
                    ok = false
                }
                if (record.get('SequencingDate'))
                {
                    if (!(record.get('SequencingDate') ==~ /\d{4}-\d{2}-\d{2}/))
                    {
                        log.error "'SequencingDate' is in the wrong format on line ${rowNum}. Must be ISO 8601 (yyyy-mm-dd)."
                        ok = false
                    }
                }

                unitIds << params.UNIT_ID_PARTS.collect { record.get(it) }.join(params.UNIT_ID_SEPARATOR)
            }
        }

        def nonUniqueUnits = unitIds.findAll { unitIds.getCount(it) > 1 }

        if (!nonUniqueUnits.empty)
        {
            log.error "Using the columns \"${params.UNIT_ID_PARTS.join(', ')}\" for the unit fields results in some duplicate unit ids from ${driverFile.name}:\n${nonUniqueUnits.join('\n')}"
            ok = false
        }
    }
    catch (Exception e)
    {
        logException(e)
        ok = false
    }

    return ok
}

def writePipelineInfo(infoFile, params)
{
    infoFile.withPrintWriter
    {
        writer ->

        info = [
            params: params,
            pipelineVersion: workflow.manifest.version,
            runName: workflow.runName,
            runUUID: workflow.sessionId
        ]

        def json = JsonOutput.toJson(info)
        json = JsonOutput.prettyPrint(json)
        writer.println(json)
    }
}
