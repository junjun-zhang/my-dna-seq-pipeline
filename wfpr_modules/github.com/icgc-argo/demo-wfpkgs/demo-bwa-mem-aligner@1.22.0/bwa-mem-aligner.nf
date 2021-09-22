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

/********************************************************************/
/* this block is auto-generated based on info from pkg.json where   */
/* changes can be made if needed, do NOT modify this block manually */
nextflow.enable.dsl = 2
name = 'demo-bwa-mem-aligner'
version = '1.22.0'
container = [
    'ghcr.io': 'ghcr.io/icgc-argo/demo-wfpkgs.demo-bwa-mem-aligner',
    'quay.io': 'quay.io/icgc-argo/demo-wfpkgs.demo-bwa-mem-aligner'
]
default_container_registry = 'quay.io'
/********************************************************************/


params.input_bam = "tests/input/?????_?.lane.bam"
params.aligned_lane_prefix = 'grch38-aligned'
params.ref_genome_gz = "tests/reference/tiny-grch38-chr11-530001-537000.fa.gz"
params.sequencing_experiment_analysis = "NO_FILE"
params.tempdir = "NO_DIR"

params.container_registry = default_container_registry
params.container_version = ""
params.cpus = 1
params.mem = 1  // GB
params.publish_dir = ""


process bwaMemAligner {
  container "${container[params.container_registry]}:${params.container_version ?: version}"
  publishDir "${params.publish_dir}/${task.process.replaceAll(':', '_')}", mode: "copy", enabled: "${params.publish_dir ? true : ''}"

  cpus params.cpus
  memory "${params.mem} GB"

  input:
    path input_bam
    path ref_genome_gz
    path ref_genome_gz_secondary_files
    path sequencing_experiment_analysis
    path tempdir
    val dependencies

  output:
    path "${params.aligned_lane_prefix}.${input_bam.baseName}.bam", emit: aligned_bam

  script:
    metadata = sequencing_experiment_analysis ? "-m " + sequencing_experiment_analysis : ""
    arg_tempdir = tempdir.name != 'NO_DIR' ? "-t ${tempdir}": ""
    """
    bwa-mem-aligner.py \
      -i ${input_bam} \
      -r ${ref_genome_gz} \
      -o ${params.aligned_lane_prefix} \
      -n ${task.cpus} ${metadata} ${arg_tempdir}
    """
}
