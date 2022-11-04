include { sampleIdGenerator } from '../functions/functions'

process recordRun
{
    executor 'local'
    memory   '64m'
    time     '2m'

    input:
        val(filenames)

    shell:
        """
        python3 "!{projectDir}/python/record_run.py" \
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
        
        recordRun(recordedFiles)
}
