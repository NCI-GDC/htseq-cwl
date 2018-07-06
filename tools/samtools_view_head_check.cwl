#!/usr/bin/env cwl-runner

cwlVersion: v1.0

requirements:
  - class: DockerRequirement
    dockerPull: quay.io/ncigdc/samtools:147bd4cc606a63c7435907d97fea6e94e9ea9ed58c18f390cab8bc40b1992df7
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
    expressionLib:
      $import: ./util_lib.cwl
  - class: ResourceRequirement
    coresMin: 1 
    ramMin: 100 
    tmpdirMin: $(file_size_multiplier(inputs.bam_file))
    outdirMin: $(file_size_multiplier(inputs.bam_file))

class: CommandLineTool

inputs:
  bam_file:
    type: File

outputs:
  counts:
    type: int 
    outputBinding:
      glob: "counts" 
      loadContents: true
      outputEval: |
        ${
           return parseInt(self[0].contents)
         }

stdout: "counts"

baseCommand: []

arguments:
  - valueFrom: |
      ${
          var curr = ["samtools", "view", inputs.bam_file, "|", "head", "|", "wc", "-l"]
          return curr
       }
    position: 0
    shellQuote: false
