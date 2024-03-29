cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  bioclient_config: File
  upload_bucket: string
  job_uuid: string
  gtf_uuid: string 
  bam_uuid: string
  gene_lengths_uuid: string
  threads: int?

outputs:
  htseq_counts_uuid:
    type: string
    outputSource: run_upload_workflow/counts_uuid

  htseq_fpkm_uuid:
    type: string
    outputSource: run_upload_workflow/fpkm_uuid

  htseq_fpkm_uq_uuid:
    type: string
    outputSource: run_upload_workflow/fpkm_uq_uuid

steps:
  run_stage_workflow:
    run: ./subworkflows/stage_data_workflow.cwl
    in:
      bioclient_config: bioclient_config 
      gtf_uuid: gtf_uuid
      gene_lengths_uuid: gene_lengths_uuid
      bam_uuid: bam_uuid 
    out: [ gtf, gene_lengths, bam ]

  run_split_bam:
    run: ./subworkflows/split_bam_workflow.cwl
    in:
      threads: threads
      bam_file: run_stage_workflow/bam
      job_uuid: job_uuid
    out: [ bam_list ] 

  run_htseq_workflow:
    run: ./subworkflows/htseq_workflow.cwl
    in:
      bam_file: run_split_bam/bam_list
      gtf_file: run_stage_workflow/gtf
      job_uuid: job_uuid
      gene_lengths: run_stage_workflow/gene_lengths
    out: [ htseq_counts, htseq_fpkm, htseq_fpkm_uq ]

  run_upload_workflow:
    run: ./subworkflows/upload_results_workflow.cwl
    in:
      htseq_counts_file: run_htseq_workflow/htseq_counts
      htseq_fpkm_file: run_htseq_workflow/htseq_fpkm
      htseq_fpkm_uq_file: run_htseq_workflow/htseq_fpkm_uq
      job_uuid: job_uuid
      bioclient_config: bioclient_config
      upload_bucket: upload_bucket
    out: [ counts_uuid, fpkm_uuid, fpkm_uq_uuid ]
