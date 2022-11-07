@Grab("mysql:mysql-connector-java:8.0.28")
@Grab("org.codehaus.groovy:groovy-sql:3.0.13")

import groovy.sql.Sql

include { sampleIdGenerator } from '../functions/functions'

/**
 * Record the run information in the database for this pipeline.
 *
 * @param filesInfo A list of (sample, filename, [slxid]) tuples.
 */
def recordFiles(filesInfo)
{
    Sql.withInstance(
        'jdbc:mysql://10.20.14.24:3306/rosenfeld?zeroDateTimeBehavior=convertToNull&characterEncoding=utf8',
        'mysql', null, 'com.mysql.cj.jdbc.Driver')
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

            // List all entries in the rosenfeld_Sequence table to form a map of SLX id to database id.

            def sequenceMap = [:]
            sql.rows('SELECT id, SLX_id FROM rosenfeld_Sequence').each { sequenceMap[it[1]] = it[0] }

            filesInfo.each
            {
                sample, filename, slxIds ->

                // Save a record for this file.

                params = [ 'runid': runId, 'filename': filename ]

                def inserted = sql.executeInsert('INSERT INTO rosenfeld_TAPRunFile (runid, filename) VALUES (:runid, :filename)', params)

                params = [ 'fileid': inserted[0][0] ]

                // Link the file record to the SLX ids in the file.

                slxIds.each
                {
                    slx ->
                    def sequenceId = sequenceMap[slx]

                    if (sequenceId)
                    {
                        params['seqid'] = sequenceId
                        sql.executeInsert('INSERT INTO rosenfeld_TAPRunFile_Sequence_Join (sequenceid, taprunfileid) VALUES (:seqid, :fileid)', params)
                    }
                }
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
