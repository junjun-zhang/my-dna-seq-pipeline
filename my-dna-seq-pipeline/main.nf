#!/usr/bin/env nextflow

/*
  Copyright (c) 2021, OICR

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

  Authors:
    Junjun Zhang
*/

nextflow.enable.dsl = 2
version = '0.2.0'

// universal params go here, change default value as needed
params.container = ""
params.container_registry = ""
params.container_version = ""
params.cpus = 1
params.mem = 1  // GB
params.publish_dir = ""  // set to empty string will disable publishDir

// tool specific parmas go here, add / change as needed
params.cleanup = true

params.ref_genome_fa = ""
params.metadata = "NO_FILE"
params.lane_bams = []

params.tempdir = "NO_DIR"
params.bwaMemAligner = [:]
params.bamMergeSortMarkdup = [:]

bwaMemAligner_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'publish_dir': params.publish_dir,
    'container_registry': params.container_registry,
    *:(params.bwaMemAligner ?: [:])
]

bamMergeSortMarkdup_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'publish_dir': params.publish_dir,
    'container_registry': params.container_registry,
    'output_format': 'cram',
    'markdup': true,
    'lossy': false,
    *:(params.bamMergeSortMarkdup ?: [:])
]



include { demoFastqc } from './wfpr_modules/github.com/junjun-zhang/qc-pkgs/demo-fastqc@0.1.0/main.nf' params([*:params, 'cleanup': false])
include { cleanupWorkdir; getSecondaryFiles; getBwaSecondaryFiles } from './wfpr_modules/github.com/icgc-argo/demo-wfpkgs/demo-utils@1.3.0/main.nf' params([*:params, 'cleanup': false])
include { DnaSeqProcess } from './wfpr_modules/github.com/icgc-argo/demo-wfpkgs/demo-dna-seq-processing-wf@1.7.2-1.4.0/main.nf' params([*:params, 'cleanup': false])


// please update workflow code as needed
workflow MyDnaSeqPipeline {
  take:  // update as needed
    ref_genome_fa
    metadata
    lane_bams
    tempdir

  main:  // update as needed
    lane_bams_ch = Channel.fromPath(lane_bams)
    demoFastqc(lane_bams_ch)

    DnaSeqProcess(
      ref_genome_fa,
      metadata,
      lane_bams,
      tempdir
    )

    if (params.cleanup) {
      cleanupWorkdir(
        demoFastqc.out.concat(DnaSeqProcess.out).collect(),
        true
      )
    }

  emit:  // update as needed
    fastqc_output = demoFastqc.out.output_file
    aligned_lane_bams = DnaSeqProcess.out.aligned_lane_bams
    merged_aligned_seq = DnaSeqProcess.out.merged_aligned_seq
    merged_aligned_seq_idx = DnaSeqProcess.out.merged_aligned_seq_idx
    aligned_seq_qc_metrics = DnaSeqProcess.out.aligned_seq_qc_metrics

}


// this provides an entry point for this main script, so it can be run directly without clone the repo
// using this command: nextflow run <git_acc>/<repo>/<pkg_name>/<main_script>.nf -r <pkg_name>.v<pkg_version> --params-file xxx
workflow {
  MyDnaSeqPipeline(
    params.ref_genome_fa,
    params.metadata,
    params.lane_bams,
    params.tempdir
  )
}
