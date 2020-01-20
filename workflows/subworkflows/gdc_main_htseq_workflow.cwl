cwlVersion: v1.0
class: Workflow
id: gdc_main_htseq_wf
requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  threads: int?
  bam_file: File
  gtf_file: File
  gene_lengths: File
  job_uuid: string
  
outputs:
  htseq_counts:
    type: File
    outputSource: run_htseq_wf/htseq_counts_file

  htseq_fpkm: 
    type: File
    outputSource: run_htseq_wf/htseq_fpkm_file

  htseq_fpkm_uq: 
    type: File
    outputSource: run_htseq_wf/htseq_fpkm_uq_file

steps:
  run_split_bams:
    run: ./transform/split_bam_workflow.cwl
    in:
      threads: threads
      bam_file: bam_file
      job_uuid: job_uuid
    out: [ bam_list ]

  run_htseq_wf:
    run: ./transform/htseq_workflow.cwl
    in:
      bam_file: run_split_bams/bam_list
      gtf_file: gtf_file
      gene_lengths: gene_lengths
      job_uuid: job_uuid
    out: [ htseq_counts_file, htseq_fpkm_file, htseq_fpkm_uq_file ]
