/*
1- fastqc
2- trimmomatic
3- bwa
4- samtools
*/

params.read = "$projectDir/data/ggal/gut_1.fq"
params.ref = "$projectDir/data/ref/mus_musculus.fa"
params.outdir = "$projectDir/results"
params.prefix = "mus_"

process FASTQC {
    conda 'fastqc'
    publishDir params.outdir + "/fastqc", mode:'copy'
    input:
    path read

    output:
    file "*.html"

    script:
    """
    fastqc $read
    """
}

process TRIMMOMATIC {
    conda 'trimmomatic'
    publishDir params.outdir + "/trimmomatic", mode:'copy'    
    input:
    path read

    output:
    file params.prefix + "read_trim.fastq.gz"

    script:
    """
    trimmomatic SE -phred33 $read "$params.prefix"read_trim.fastq.gz LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    """
}

process BWAINDEX {
    conda 'bwa'
    publishDir params.outdir + "/bwa", mode:'copy'
    input:
    path ref

    output:
    file params.prefix + "index.*"
    
    script:
    """
    bwa index $ref -p "$params.prefix"index
    """
}

process BWAMEM {
    conda 'bwa'
    publishDir params.outdir + "/bwa", mode:'copy'
    input:
    path trim
    path bwaIndex

    output:
    file params.prefix + "aligned.sam"

    script:
    """
    bwa mem "$params.prefix"index $trim > "$params.prefix"aligned.sam
    """
}

process SAMVIEW {
    conda 'samtools'
    publishDir params.outdir + "/samtools", mode:'copy'
    input:
    path bwaMem

    output:
    file params.prefix + "aligned.bam"

    script:
    """
    samtools view -bS $bwaMem -o "$params.prefix"aligned.bam
    """
}

process SAMSORT {
    conda 'samtools'
    publishDir params.outdir + "/samtools", mode:'copy'
    input:
    path samView

    output:
    file params.prefix + "sorted.bam"

    script:
    """
    samtools sort $samView -o "$params.prefix"sorted.bam
    """
}

process SAMINDEX {
    conda 'samtools' 
    publishDir params.outdir + "/samtools", mode:'copy'
    input:
    path samSort

    output:
    file params.prefix + "sorted.bam.bai"

    script:
    """
    samtools index $samSort -o "$params.prefix"sorted.bam.bai
    """
}

workflow {
    Channel
        .fromPath(params.read)
        .set { reads }

    Channel
        .fromPath(params.ref)
        .set { ref }

    FASTQC(reads)

    TRIMMOMATIC(reads)
       .set { trim }

    BWAINDEX(ref)
        .set { bwaIndex }

    BWAMEM(trim, bwaIndex)
        .set { bwaMem }

    SAMVIEW(bwaMem)
        .set { samView }

    SAMSORT(samView)
        .set { samSort }

    SAMINDEX(samSort)
}