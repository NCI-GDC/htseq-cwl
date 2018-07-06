#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: DockerRequirement
    dockerPull: quay.io/ncigdc/htseq-tool:a7e2b399ff241bd874d0cfc793199eadb79519b4
  - class: InlineJavascriptRequirement
    expressionLib:
      $import: ./util_lib.cwl
  - class: ResourceRequirement
    coresMin: 1
    ramMin: 500
    tmpdirMin: $(sum_file_array_size([inputs.htseq_file, inputs.aggregate_length_file]) * 2)
    outdirMin: $(sum_file_array_size([inputs.htseq_file, inputs.aggregate_length_file]) * 2)

inputs:
  htseq_file:
    type: File
    inputBinding:
      prefix: --htseq_counts

  aggregate_length_file:
    type: File
    inputBinding:
      prefix: --aggregate_length_file

  output_prefix:
    type: string 
    inputBinding:
      prefix: --output_prefix

outputs:
  fpkm:
    type: File
    outputBinding:
      glob: $(inputs.output_prefix + '.FPKM.txt.gz')

  fpkm_uq:
    type: File
    outputBinding:
      glob: $(inputs.output_prefix + '.FPKM-UQ.txt.gz')

baseCommand: [/opt/htseq-tools/venv/bin/htseq-tools, fpkm]
