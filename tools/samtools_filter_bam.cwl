#!/usr/bin/env cwl-runner

cwlVersion: v1.0

requirements:
  - class: DockerRequirement
    dockerPull: quay.io/ncigdc/samtools:147bd4cc606a63c7435907d97fea6e94e9ea9ed58c18f390cab8bc40b1992df7
  - class: InlineJavascriptRequirement
  #  expressionLib:
  #    $import: ./util_lib.cwl
  #- class: ResourceRequirement
  #  coresMin: "$(inputs.threads ? inputs.threads : 1)"
  #  ramMin: 1000
  #  tmpdirMin: $(file_size_multiplier(inputs.input_sam, 1.5))
  #  outdirMin: $(file_size_multiplier(inputs.input_sam, 1.5))

class: CommandLineTool

inputs:

  threads:
    type: int?
    inputBinding:
      position: 0
      prefix: -@

  output_filename:
    type: string
    inputBinding:
      position: 1
      prefix: -o

  include_flag:
    type: int?
    inputBinding:
      position: 2
      prefix: -f

  exclude_flag:
    type: int?
    inputBinding:
      position: 3
      prefix: -F

  bam_file:
    type: File
    inputBinding:
      position: 4

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.output_filename)

baseCommand: [samtools, view, -b]
