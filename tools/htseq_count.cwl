#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: DockerRequirement
    dockerPull: quay.io/ncigdc/htseq-tool:2a8b0bfec9dc52aaeac29ee8e7ff3284e79553c0
  - class: InlineJavascriptRequirement
    expressionLib:
      $import: ./util_lib.cwl
  - class: ResourceRequirement
    coresMin: 1
    ramMin: 1000
    tmpdirMin: $(sum_file_array_size([inputs.bam_file, inputs.gtf_file]) * 1.1)
    outdirMin: $(sum_file_array_size([inputs.bam_file, inputs.gtf_file]) * 1.1)

inputs:
  file_format:
    type: string
    default: "bam"
    inputBinding:
      prefix: -f
      position: 0

  sort_order:
    type: string
    default: "pos"
    inputBinding:
      prefix: -r
      position: 1

  stranded:
    type: string
    default: "no"
    inputBinding:
      prefix: -s
      position: 2

  min_qual:
    type: int
    default: 10
    inputBinding:
      prefix: -a
      position: 3

  feature_type:
    type: string
    default: "exon"
    inputBinding:
      prefix: -t
      position: 4

  id_attr:
    type: string
    default: "gene_id"
    inputBinding:
      prefix: -i
      position: 5

  mode:
    type: string
    default: "intersection-nonempty"
    inputBinding:
      prefix: -m
      position: 6

  bam_file:
    type: File
    inputBinding:
      position: 7

  gtf_file:
    type: File
    inputBinding:
      position: 8

  output_filename:
    type: string

outputs:
  counts:
    type: File
    doc: raw counts file
    outputBinding:
      glob: $(inputs.output_filename)    

stdout: $(inputs.output_filename)

baseCommand: [htseq-count]
