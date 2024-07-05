/*
 * Preprocessing processes.
 */

@Grab('org.apache.commons:commons-lang3:3.12.0')
 
import static org.apache.commons.lang3.StringUtils.isNotBlank
 
include { toBCLConvertStyle as toBCLConvertStyle1; toBCLConvertStyle as toBCLConvertStyle2 } from "../processes/preprocessing"

workflow preprocessingWF
{
    take:
        csvChannel
    
    main:
        // Branch into two channels for UMI preprocessing:
        // with and without a UMI file.

        umiChannels = csvChannel
            .branch
            {
                unitId, info ->
                oldStyleUMI: isNotBlank(info.UmiRead)
                newOrNone:   true
            }

        read1Channel = umiChannels.oldStyleUMI
            .map
            {
                unitId, info ->
                tuple unitId, 1, file("${params.FASTQ_DIR}/${info.Read1}", checkIfExists: true), file("${params.FASTQ_DIR}/${info.UmiRead}", checkIfExists: true)
            }
        
        read2Channel = umiChannels.oldStyleUMI
            .map
            {
                unitId, info ->
                tuple unitId, 2, file("${params.FASTQ_DIR}/${info.Read2}", checkIfExists: true), file("${params.FASTQ_DIR}/${info.UmiRead}", checkIfExists: true)
            }
        
        toBCLConvertStyle1(read1Channel)
        toBCLConvertStyle2(read2Channel)
        
        combinedChannel = toBCLConvertStyle1.out.join(toBCLConvertStyle2.out)
        
        otherReadChannel = umiChannels.newOrNone.map
            {
                unitId, info ->
                tuple unitId, file("${params.FASTQ_DIR}/${info.Read1}", checkIfExists: true), file("${params.FASTQ_DIR}/${info.Read2}", checkIfExists: true)
            }
        
        preppedChannel = otherReadChannel.mix(combinedChannel)
    
    emit:
        preppedChannel
}
