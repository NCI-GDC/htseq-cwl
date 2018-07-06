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
  run_get_pe:
    run: ../../tools/samtools_filter_bam.cwl
    in:
      threads: threads
      bam_file: bam_file
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
      bam_file: bam_file
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
    run:
      class: ExpressionTool
      inputs:
        pe_bam_file: File
        pe_counts: int
        se_bam_file: File
        se_counts: int
      outputs: 
        bam_files:
          type: File[]
      expression: |
        ${
           var curr = [];
           if(inputs.pe_counts > 0) {
             curr.push(inputs.pe_bam_file)
           }

           if(inputs.se_counts > 0) {
             curr.push(inputs.se_bam_file)
           }
           return {"bam_files": curr}
         }
    in:
      pe_bam_file: run_get_pe/output
      pe_counts: run_pe_check/counts
      se_bam_file: run_get_se/output
      se_counts: run_se_check/counts
    out: [ bam_files ]
