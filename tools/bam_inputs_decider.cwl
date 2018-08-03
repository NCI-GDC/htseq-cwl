#!/usr/bin/env cwl-runner

cwlVersion: v1.0

requirements:
  - class: InlineJavascriptRequirement

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
