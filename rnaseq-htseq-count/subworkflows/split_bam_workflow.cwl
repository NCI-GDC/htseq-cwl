cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  threads: int? 
  bam_file: File
  job_uuid: string

outputs:
  bam_list:
    type: File[]
    outputSource: run_inputs_decider/bam_files 

steps:
  run_namesort_bam:
    run: ../../tools/samtools_namesort_bam.cwl
    in:
      threads: threads
      output_filename:
        source: job_uuid
        valueFrom: $(self + '.namesort.bam') 
      tmp_prefix: job_uuid
      bam_file: bam_file
    out: [ output ]

  run_get_pe:
    run: ../../tools/samtools_filter_bam.cwl
    in:
      threads: threads
      bam_file: run_namesort_bam/output
      output_filename:
        source: job_uuid
        valueFrom: $(self + '.paired.bam') 
      exclude_flag:
        default: 4
      include_flag:
        default: 1
    out: [ output ]

  run_pe_check:
    run: ../../tools/samtools_view_head_check.cwl
    in:
      bam_file: run_get_pe/output
    out: [ counts ]

  run_get_se:
    run: ../../tools/samtools_filter_bam.cwl
    in:
      threads: threads
      bam_file: run_namesort_bam/output 
      output_filename:
        source: job_uuid
        valueFrom: $(self + '.unpaired.bam') 
      exclude_flag:
        default: 5
    out: [ output ]

  run_se_check:
    run: ../../tools/samtools_view_head_check.cwl
    in:
      bam_file: run_get_se/output
    out: [ counts ]

  run_inputs_decider:
    run: ../../tools/bam_inputs_decider.cwl
    in:
      pe_bam_file: run_get_pe/output
      pe_counts: run_pe_check/counts
      se_bam_file: run_get_se/output
      se_counts: run_se_check/counts
    out: [ bam_files ]
