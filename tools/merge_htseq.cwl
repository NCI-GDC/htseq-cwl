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
    ramMin: 500
    tmpdirMin: $(sum_file_array_size(inputs.htseq_file) * 1.1)
    outdirMin: $(sum_file_array_size(inputs.htseq_file) * 1.1)

inputs:
  htseq_file:
    type: 
      type: array
      items: File
      inputBinding:
        prefix: --htseq_counts

  output_filename:
    type: string 
    inputBinding:
      prefix: --out_file 

outputs:
  counts:
    type: File
    doc: merged counts file
    outputBinding:
      glob: $(inputs.output_filename)

baseCommand: [/opt/htseq-tools/venv/bin/htseq-tools, merge_counts]
