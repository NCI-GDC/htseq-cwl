cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement

inputs:
  bam_file: File[]
  gtf_file: File
  job_uuid: string

outputs:
  htseq_counts: 
    type: File[]
    outputSource: run_htseq_counts/counts

steps:
  run_htseq_counts:
    run: ../../tools/htseq_count.cwl
    scatter: [ bam_file, output_filename ]
    scatterMethod: "dotproduct"
    in:
      bam_file: bam_file
      output_filename:
        source: bam_file 
        valueFrom: $(self.nameroot + '.htseq_counts.txt')
      gtf_file: gtf_file
    out: [ counts ]
