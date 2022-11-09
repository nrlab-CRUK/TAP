/*
 * Functions that give the path to reference data structure.
 * In each case, if the specific parameter is set explicitly use that,
 * otherwise provide the standard under REFERENCE_DATA_ROOT.
 */

include { makeCollection } from './functions'

def checkRoot()
{
    if (!params.REFERENCE_ROOT)
    {
        throw new Exception("REFERENCE_ROOT is not defined in your profile or nextflow.config.")
    }
}

def referenceFasta()
{
    params.with
    {
        if (REFERENCE_FASTA)
        {
            return REFERENCE_FASTA
        }

        checkRoot()
        return "${REFERENCE_ROOT}/${ASSEMBLY}/fasta/${ASSEMBLY}.fa"
    }
}

def bwamem2Index()
{
    params.with
    {
        if (BWAMEM2_INDEX)
        {
            return BWAMEM2_INDEX
        }

        checkRoot()
        return "${REFERENCE_ROOT}/${ASSEMBLY}/bwamem2-2.2.1/${ASSEMBLY}"
    }
}

def gatkKnownSites()
{
    def sites = null

    params.with
    {
        if (GATK_KNOWN_SITES)
        {
            sites = GATK_KNOWN_SITES
        }
        else
        {
            checkRoot()
            sites = "${REFERENCE_ROOT}/${ASSEMBLY}/dbsnp/${ASSEMBLY}.snps.vcf.gz"
        }
    }

    return makeCollection(sites)
}
