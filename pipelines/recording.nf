@Grab("mysql:mysql-connector-java:8.0.28")
@Grab("org.codehaus.groovy:groovy-sql:3.0.13")

import groovy.sql.Sql

include { sampleIdGenerator } from '../functions/functions'

/**
 * Record the run information in the database for this pipeline.
 *
 * Records a row in rosenfeld_TAPRun if it doesn't already exist for
 * this run and links it to any experiments whose layout includes any
 * of the SLX ids passed in.
 *
 * @param filesInfo A list of (sample, filename, [slxid]) tuples.
 */
def recordFiles(filesInfo)
{
    Sql.withInstance(
        "jdbc:mysql://${params.DB_HOST}:${params.DB_PORT}/${params.DB_NAME}?zeroDateTimeBehavior=convertToNull&characterEncoding=utf8",
        params.DB_USER, params.DB_PASS, 'com.mysql.cj.jdbc.Driver')
    {
        sql ->
        sql.withTransaction
        {
            def runUUID = workflow.sessionId.toString()

            def params = [ 'runid': runUUID ]

            // See if a run is recorded with the UUID. If so, just exit.

            def runExists = sql.rows('SELECT id FROM rosenfeld_TAPRun WHERE runuuid = :runid', params)

            if (!runExists.empty)
            {
                // log.warn "A run for ${runUUID} has already been recorded."
                //runid = runExists[0]['id']
                return
            }

            // New record, so record the run first.

            params = [ 'runner': System.getProperty('user.name'),
                       'runtime': new Date(),
                       'runname': workflow.runName,
                       'runuuid': workflow.sessionId.toString() ]

            def inserted = sql.executeInsert('INSERT INTO rosenfeld_TAPRun (runner, runtime, runname, runuuid) VALUES (:runner, :runtime, :runname, :runuuid)', params)
            final def runId = inserted[0][0]

            // Find all experiments whose layouts mention any of the SLX ids given.

            def slxIds = filesInfo.collect { sample, filename, slxIds -> slxIds }.flatten().unique()

            def placeholders = (['?'] * slxIds.size()).join(',')
            def query = """
                    SELECT DISTINCT e.idx, e.expid
                    FROM rosenfeld_Experiment e
                    INNER JOIN rosenfeld_DNASeq_layout l ON e.expid = l.expid
                    WHERE l.SLX_ID IN (${placeholders})
                    """

            def experiments = sql.rows(query, slxIds)

            // Create entries in the rosenfeld_TAPRun_Experiment_Join table to join the experiments
            // to the newly created run record.

            sql.withBatch('INSERT INTO rosenfeld_TAPRun_Experiment_Join (experimentid, taprunid) VALUES (?, ?)')
            {
                preparedQuery ->
                experiments.each { preparedQuery.addBatch(it.idx, runId) }
            }
        }
    }
}

/*
 * Process to record run and file information. Simply defers to the function
 * recordFiles above.
 */
process recordRun
{
    errorStrategy 'ignore'
    executor 'local'

    input:
        val(filesInfo)

    exec:
        recordFiles(filesInfo)
}

/*
 * Record info work flow. Links the file generated for a sample to the
 * SLX ids that are in the file and calls recordRun to put them in the
 * database.
 */
workflow recording
{
    take:
        csvChannel
        bamChannel

    main:
        slxChannel = csvChannel
            .map
            {
                unitId, row ->
                tuple sampleIdGenerator(params, row), row.SLXId
            }
            .groupTuple()

        recordedFiles = bamChannel
            .join(slxChannel)
            .map
            {
                sampleId, bamFile, bamIndex, slxIds ->
                tuple sampleId, bamFile.name, slxIds
            }
            .toList()

        recordRun(recordedFiles)
}
