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
 *   Linda Xiang <linda.xiang@oicr.on.ca>
 */


nextflow.enable.dsl = 2
name = 'demo-dna-seq-alignment-wf'
version = '1.7.2'


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


// Include all modules and pass params
include {
    getBwaSecondaryFiles;
    getSecondaryFiles;
    cleanupWorkdir as cleanup
} from './wfpr_modules/github.com/icgc-argo/demo-wfpkgs/demo-utils@1.2.0/main.nf'

include { bwaMemAligner as bwaMem } from './wfpr_modules/github.com/icgc-argo/demo-wfpkgs/demo-bwa-mem-aligner@1.22.0/bwa-mem-aligner.nf' params(bwaMemAligner_params)
include { bamMergeSortMarkdup as merSorMkdup } from './wfpr_modules/github.com/icgc-argo/demo-wfpkgs/demo-bam-merge-sort-markdup@1.12.1/bam-merge-sort-markdup.nf' params(bamMergeSortMarkdup_params)


workflow DnaAln {
    take:
        ref_genome_fa
        metadata
        lane_bams  // aka uBAM
        tempdir

    main:
        // use scatter to run BWA alignment for each lane_bams (aka uBAM) in parallel
        bwaMem(
            Channel.fromPath(lane_bams, checkIfExists: true).flatten(),
            Channel.fromPath(ref_genome_fa + '.gz', checkIfExists: true).collect(),
            Channel.fromPath(getBwaSecondaryFiles(ref_genome_fa + '.gz'), checkIfExists: true).collect(),
            Channel.fromPath(metadata, checkIfExists: true).collect(),
            Channel.fromPath(tempdir).collect(),
            true  // no need to wait for other process, so give it a true rightaway
        )

        // collect aligned lane bams for merge and markdup
        merSorMkdup(
            bwaMem.out.aligned_bam.collect(),
            Channel.fromPath(ref_genome_fa + '.gz', checkIfExists: true).collect(),
            Channel.fromPath(getSecondaryFiles(ref_genome_fa + '.gz', ['fai', 'gzi']), checkIfExists: true).collect(),
            Channel.fromPath(tempdir).collect(),
        )

        if (params.cleanup) {
            cleanup(
                bwaMem.out.concat(merSorMkdup.out).collect(),
                true  // we don't need to wait for any other process, so just give it a true here
            )
        }

    emit:
        aligned_lane_bams = bwaMem.out.aligned_bam
        merged_aligned_seq = merSorMkdup.out.merged_seq
        merged_aligned_seq_idx = merSorMkdup.out.merged_seq_idx
}


workflow {
    DnaAln(
        params.ref_genome_fa,
        params.metadata,
        params.lane_bams,
        params.tempdir
    )
}
