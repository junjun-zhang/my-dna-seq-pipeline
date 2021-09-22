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
 * Contributors
 *   Junjun Zhang <junjun.zhang@oicr.on.ca>
 *   Linda Xiang <linda.xiang@oicr.on.ca>
 */

/********************************************************************/
/* this block is auto-generated based on info from pkg.json where   */
/* changes can be made if needed, do NOT modify this block manually */
nextflow.enable.dsl = 2
name = 'demo-aligned-seq-qc'
version = '1.1.0'
container = [
    'ghcr.io': 'ghcr.io/icgc-argo/demo-wfpkgs.demo-aligned-seq-qc',
    'quay.io': 'quay.io/icgc-argo/demo-wfpkgs.demo-aligned-seq-qc'
]
default_container_registry = 'ghcr.io'
/********************************************************************/

params.seq = ""
params.container_version = ""
params.ref_genome_gz = ""

params.container_registry = default_container_registry
params.publish_dir = ""
params.cpus = 1
params.mem = 2  // in GB


process alignedSeqQC {
  container "${container[params.container_registry]}:${params.container_version ?: version}"
  publishDir "${params.publish_dir}/${task.process.replaceAll(':', '_')}",
    mode: "copy",
    enabled: "${params.publish_dir ? true : ''}"

  cpus params.cpus
  memory "${params.mem} GB"

  input:
    path seq
    path ref_genome_gz
    path ref_genome_gz_secondary_file
    val dependencies

  output:
    path "*.qc_metrics.tgz", emit: metrics

  script:
    """
    aligned-seq-qc.py -s ${seq} \
                      -r ${ref_genome_gz} \
                      -n ${params.cpus}
    """
}
