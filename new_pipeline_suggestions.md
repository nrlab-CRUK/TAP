Feedback:

1. merge bams from same sample but sequenced in different lanes . Is this already implemented? (Haichao, Paulius)

2. To run the Pipeline, kickstarter must create a .csv file of the fastq files per sample. 
A wrapper would be a quick solution to generate a similar .csv file when using demultiplexed or pre-existing fastqs. (Paulius)


3. haichao: the alignment.csv is quoted csv, would it be useful to make the pipelien compatible with unquoted csv? which is useful for user-made csv files. 


4. haichao: parameter configureation file,  need to clarify how to set other parameters not shown in the example config, e.g. how to set BED file for filtering. 


5. haichao: `[ISSUE]` The **MarkDuplicates** step, job failed due to `java.lang.OutOfMemoryError: java heap space`, and this happened randomly in my test run with 900 bam files. Resume the pipeline will resolve it.   Need to increase the default Mem settings for the java? 


![image](https://user-images.githubusercontent.com/15274940/205628415-7546b150-64f1-4ddc-a309-77e3e3e10bc6.png)
![image](https://user-images.githubusercontent.com/15274940/205628428-ed82f52f-3bd4-4623-aaed-4ee0e9d22a97.png)


6. haichao: `[Minor]` Add spack load openjdf@17 to the run file?  ![image](https://user-images.githubusercontent.com/15274940/205628620-ffabf7ab-c650-4bf2-bb49-6850c03dda07.png)


7. haichao: `[Minor]` in the config file:   `nrlab_tap.config` → `alignment.config` <img width="1222" alt="image" src="https://user-images.githubusercontent.com/15274940/205628766-5e980e90-7848-455a-810a-a4317d7e86b5.png">


8. haichao:  `[Minor]` In the documentation, need to clarify that user need to copy the `/home/bioinformatics/pipelinesoftware/nrlab_tap/nrlabtap-latest.sif` file to assets folder, otherwise the job won't run: <img width="813" alt="image" src="https://user-images.githubusercontent.com/15274940/205629071-80590768-210b-4ace-8865-a476be773ac9.png">



9. haichao: what is this recordRun error? seems not big issue:

![image](https://user-images.githubusercontent.com/15274940/205629811-07429b70-96ed-446d-baa2-dcdf947a46eb.png)



10. haichao: compulsory requirement for the SequencingData format in the aligment.csv file, error occurs when I made my own csv file to for external fq files. 
 ![image](https://user-images.githubusercontent.com/15274940/206854001-6866d8a2-1adc-49be-ae60-e1d26fe02c56.png)
 
11.  Markduplicates process CANCELLED due to time limit, maybe make the Markdup step time limit longer? 

![image](https://user-images.githubusercontent.com/15274940/206878806-f059e18c-4af7-48b5-8667-cd2890becad4.png)

12. Important issue!: missing essential ref files in bioinformatics folders:/mnt/scratcha/bioinformatics/rosenfeld_references

