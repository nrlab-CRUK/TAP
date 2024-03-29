/*
 * Functions that give the path to reference data structure.
 * In each case, if the specific parameter is set explicitly use that,
 * otherwise provide the standard under REFERENCE_DATA_ROOT.
 */

include { makeCollection } from "../modules/nextflow-support/functions"

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

def bowtie2Index()
{
    params.with
    {
        if (BOWTIE2_INDEX)
        {
            return BOWTIE2_INDEX
        }

        checkRoot()
        return "${REFERENCE_ROOT}/${ASSEMBLY}/bowtie2-2.5.1/${ASSEMBLY}"
    }
}

def bwamethIndex()
{
    params.with
    {
        if (BWAMETH_INDEX)
        {
            return BWAMETH_INDEX
        }

        checkRoot()
        return "${REFERENCE_ROOT}/${ASSEMBLY}/bwameth-0.2.6/${ASSEMBLY}"
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
