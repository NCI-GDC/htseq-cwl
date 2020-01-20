cwlVersion: v1.0
class: Workflow
id: gdc_htseq_upload_results_wf
requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

inputs:
  htseq_counts_file: File
  htseq_fpkm_file: File
  htseq_fpkm_uq_file: File
  job_uuid: string
  bioclient_config: File
  upload_bucket: string

outputs:
  counts_uuid:
    type: string
    outputSource: upload_counts/uuid

  fpkm_uuid:
    type: string
    outputSource: upload_fpkm/uuid

  fpkm_uq_uuid:
    type: string
    outputSource: upload_fpkm_uq/uuid

steps:
  upload_counts:
    run: ../../../tools/bioclient_upload_pull_uuid.cwl
    in:
      config-file: bioclient_config
      upload-bucket: upload_bucket
      upload-key:
        source: [ job_uuid, htseq_counts_file ]
        valueFrom: $(self[0] + '/' + self[1].basename)
      input: htseq_counts_file 
    out: [ output, uuid ]

  upload_fpkm:
    run: ../../../tools/bioclient_upload_pull_uuid.cwl
    in:
      config-file: bioclient_config
      upload-bucket: upload_bucket
      upload-key:
        source: [ job_uuid, htseq_fpkm_file ]
        valueFrom: $(self[0] + '/' + self[1].basename)
      input: htseq_fpkm_file 
    out: [ output, uuid ]

  upload_fpkm_uq:
    run: ../../../tools/bioclient_upload_pull_uuid.cwl
    in:
      config-file: bioclient_config
      upload-bucket: upload_bucket
      upload-key:
        source: [ job_uuid, htseq_fpkm_uq_file ]
        valueFrom: $(self[0] + '/' + self[1].basename)
      input: htseq_fpkm_uq_file 
    out: [ output, uuid ]
