cwlVersion: v1.0

class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

inputs:
  bioclient_config: File
  gtf_uuid: string
  gene_lengths_uuid: string
  bam_uuid: string

outputs:
  gtf:
    type: File
    outputSource: extract_gtf/output

  gene_lengths:
    type: File
    outputSource: extract_gene_lengths/output

  bam:
    type: File
    outputSource: extract_bam/output

steps:
  extract_gtf:
    run: ../../tools/bioclient_download.cwl
    in:
      config-file: bioclient_config
      download_handle: gtf_uuid 
    out: [ output ]

  extract_gene_lengths:
    run: ../../tools/bioclient_download.cwl
    in:
      config-file: bioclient_config
      download_handle: gene_lengths_uuid 
    out: [ output ]

  extract_bam:
    run: ../../tools/bioclient_download.cwl
    in:
      config-file: bioclient_config
      download_handle: bam_uuid 
    out: [ output ]
