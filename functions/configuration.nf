def checkParameters(params)
{
    def errors = false

    if (!params.GATK_KNOWN_SITES) {
        log.error "No known sites file(s) specified (GATK_KNOWN_SITES parameter)"
        errors = true
    }

    return !errors
}
