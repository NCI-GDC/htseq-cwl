cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: ScatterFeatureRequirement

inputs:
  bam_file: File[]
  gtf_file: File
  gene_lengths: File
  job_uuid: string
  
outputs:
  htseq_counts: 
    type: File
    outputSource: run_merge_counts/counts

  htseq_fpkm: 
    type: File
    outputSource: run_fpkm/fpkm

  htseq_fpkm_uq: 
    type: File
    outputSource: run_fpkm/fpkm_uq

steps:
  run_htseq_counts:
    run: ../../tools/htseq_count.cwl
    scatter: [ bam_file, output_filename ]
    scatterMethod: "dotproduct"
    in:
      bam_file: bam_file
      sort_order:
        default: "name" 
      output_filename:
        source: bam_file 
        valueFrom: $(self.nameroot + '.htseq_counts.txt')
      gtf_file: gtf_file
    out: [ counts ]

  run_merge_counts:
    run: ../../tools/merge_htseq.cwl
    in:
      htseq_file: run_htseq_counts/counts
      output_filename:
        source: job_uuid
        valueFrom: $(self + '.htseq_counts.txt.gz')
    out: [ counts ]

  run_fpkm:
    run: ../../tools/calculate_fpkm.cwl
    in:
      htseq_file: run_merge_counts/counts
      aggregate_length_file: gene_lengths
      output_prefix: job_uuid
    out: [ fpkm, fpkm_uq ]
