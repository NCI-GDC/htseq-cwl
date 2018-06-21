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
  #gtf_uuid: string 
  #bam_uuid: string
  gtf_file: File
  bam_file: File

outputs:

steps:

  run_split_bam:
    run: ./subworkflows/split_bam_workflow.cwl
    
