@Grab("mysql:mysql-connector-java:8.0.28")
@Grab("org.codehaus.groovy:groovy-sql:3.0.13")

import groovy.sql.Sql

include { sampleIdGenerator } from '../functions/functions'

def recordRunGroovy()
{
    Sql.newInstance(
        'jdbc:mysql://10.20.14.24:3306/rosenfeld?zeroDateTimeBehavior=convertToNull&characterEncoding=utf8',
        'mysql', null, 'com.mysql.cj.jdbc.Driver').withCloseable
    {
        sql ->
        
        def params = [ 'runner': System.getProperty('user.name'),
                       'runtime': new Date(),
                       'runname': workflow.runName,
                       'runuuid': workflow.sessionId.toString() ]
            
        sql.executeInsert('INSERT INTO rosenfeld_TAPRun (runner, runtime, runname, runuuid) VALUES (:runner, :runtime, :runname, :runuuid)', params)
    }
}

def recordFileGroovy(sample, filename, slxIds)
{
    Sql.newInstance(
        'jdbc:mysql://10.20.14.24:3306/rosenfeld?zeroDateTimeBehavior=convertToNull&characterEncoding=utf8',
        'mysql', null, 'com.mysql.cj.jdbc.Driver').withCloseable
    {
        sql ->
        
        def runUUID = workflow.sessionId.toString()
        
        def params = [ 'runid': runUUID ]
        def runid = null
        
        while (!runid)
        {
            def runExists = sql.rows('SELECT id FROM rosenfeld_TAPRun WHERE runuuid = :runid', params)
            
            if (runExists.empty)
            {
                // Wait for the run to be recorded from another channel.
                // log.warn "Run ${runUUID} is not recorded."
                Thread.sleep(1000L);
            }
            else
            {
                runid = runExists[0]['id']
            }
        }

        params = [ 'runid': runid, 'filename': filename ]
                    
        def inserted = sql.executeInsert('INSERT INTO rosenfeld_TAPRunFile (runid, filename) VALUES (:runid, :filename)', params)
        def infoid = inserted[0][0]

        params = [ 'slxIds': new ArrayList(slxIds) ]
        
        def sequences = sql.rows('SELECT id FROM rosenfeld_Sequence WHERE SLX_id IN (:slxIds)', params)
        
        sequences.each
        {
            seq ->
            
            params = [ 'seqid': seq['id'], 'fileid': infoid ]
            
            sql.executeInsert('INSERT INTO rosenfeld_TAPRunFile_Sequence_Join (sequenceid, taprunfileid) VALUES (:seqid, :fileid)', params)
        }
    }
}

process recordRun
{
    errorStrategy 'finish'

    input:
        tuple val(sampleId), val(filename), val(slxIds)
    
    exec:
        recordRunGroovy()
}

process recordFile
{
    errorStrategy 'finish'

    input:
        tuple val(sampleId), val(filename), val(slxIds)

    exec:
        recordFileGroovy(sampleId, filename, slxIds)
}

/*
 * Main work flow.
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

        recordRun(recordedFiles.first())
            
        recordFile(recordedFiles)
}
