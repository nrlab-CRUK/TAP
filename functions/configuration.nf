import groovy.json.JsonOutput


def checkParameters(params)
{
    def errors = false

    if (params.GATK_BQSR && !params.GATK_KNOWN_SITES) {
        log.error "No known sites file(s) specified (GATK_KNOWN_SITES parameter)"
        errors = true
    }

    return !errors
}

def writePipelineInfo(infoFile, params)
{
    infoFile.withPrintWriter
    {
        writer ->

        info = [
            params: params,
            pipelineVersion: workflow.manifest.version
        ]

        def json = JsonOutput.toJson(info)
        json = JsonOutput.prettyPrint(json)
        writer.println(json)
    }
}
