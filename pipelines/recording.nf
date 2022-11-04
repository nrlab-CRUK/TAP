include { sampleIdGenerator } from '../functions/functions'

process recordRun
{
    executor 'local'
    memory   '64m'
    time     '2m'

    input:
        path(pipelineInfoFile)
        val(filenames)

    shell:
        """
        python3 "!{projectDir}/python/RecordRun.py" \
            --infofile "!{pipelineInfoFile}" \
            "!{filenames.join('" "')}"
        """
}

/*
 * Main work flow.
 */
workflow recording
{
    take:
        csvChannel
        bamChannel
        pipelineInfoFile

    main:
        slxChannel = csvChannel
            .map
            {
                unitId, row ->
                tuple sampleIdGenerator(params, row), row.SLXId
            }
            .groupTuple()

        slxChannel.view()

        recordedFiles = bamChannel
            .join(slxChannel)
            .map
            {
                sampleId, bamFile, bamIndex, slxIds ->
                def str = bamFile.name
                if (!slxIds.empty)
                {
                    str += '/' + slxIds.join('/')
                }
                return str
            }
            .toList()

        recordRun(pipelineInfoFile, recordedFiles)
}
