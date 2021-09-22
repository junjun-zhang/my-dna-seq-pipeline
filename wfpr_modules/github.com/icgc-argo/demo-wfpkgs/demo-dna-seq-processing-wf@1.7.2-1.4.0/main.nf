#!/usr/bin/env nextflow

/*
 * Copyright (c) 2019-2021, Ontario Institute for Cancer Research (OICR).
 *                                                                                                               
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * Contributors:
 *   Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.enable.dsl = 2
name = 'dna-seq-processing'
version = '1.7.2-1.4.0'


params.ref_genome_fa = ""
params.metadata = "NO_FILE"
params.lane_bams = []

params.cleanup = true
params.cpus = 1
params.mem = 1
params.tempdir = "NO_DIR"
params.publish_dir = ""
params.container_registry = ""

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

DnaAln_params = [
    'cleanup': false,  // very important to set this to 'false', so this current workflow can control when to perform cleanup
    'bwaMemAligner': bwaMemAligner_params,
    'bamMergeSortMarkdup': bamMergeSortMarkdup_params
]


include {
    getSecondaryFiles;
    cleanupWorkdir as cleanup
} from './wfpr_modules/github.com/icgc-argo/demo-wfpkgs/demo-utils@1.2.0/main.nf'
include { DnaAln } from './wfpr_modules/github.com/icgc-argo/demo-wfpkgs/demo-dna-seq-alignment-wf@1.7.2/main.nf' params(DnaAln_params)
include { alignedSeqQC } from './wfpr_modules/github.com/icgc-argo/demo-wfpkgs/demo-aligned-seq-qc@1.1.0/aligned-seq-qc.nf' params(params)


workflow DnaSeqProcess {
    take:
        ref_genome_fa
        metadata
        lane_bams
        tempdir

    main:
        // alignment and markduplicate
        DnaAln(
            ref_genome_fa,
            metadata,
            lane_bams,
            tempdir
        )

        // QC aligned sequence
        alignedSeqQC(
            DnaAln.out.merged_aligned_seq,
            Channel.fromPath(ref_genome_fa + '.gz', checkIfExists: true).collect(),
            Channel.fromPath(getSecondaryFiles(ref_genome_fa + '.gz', ['fai', 'gzi']), checkIfExists: true).collect(),
            true  // no need to wait for additional process other than getting the aligned seq
        )

        // cleanup workdirs
        if (params.cleanup) {
            cleanup(
                DnaAln.out.aligned_lane_bams.concat(
                    DnaAln.out.merged_aligned_seq,
                    alignedSeqQC.out
                ).collect(),
                true
            )
        }

    emit:
        aligned_lane_bams = DnaAln.out.aligned_lane_bams
        merged_aligned_seq = DnaAln.out.merged_aligned_seq
        merged_aligned_seq_idx = DnaAln.out.merged_aligned_seq_idx
        aligned_seq_qc_metrics = alignedSeqQC.out.metrics
}


workflow {
    DnaSeqProcess(
        params.ref_genome_fa,
        params.metadata,
        params.lane_bams,
        params.tempdir
    )
}
