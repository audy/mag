// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options    = initOptions(params.options)

process CAT {
    tag "${meta.assembler}-${meta.id}-${db_name}"

    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.assembler) }

    conda (params.enable_conda ? "bioconda::cat=4.6 bioconda::diamond=2.0.6" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/mulled-v2-75e2a26f10cbf3629edf2d1600db3fed5ebe6e04:eae321284604f7dabbdf121e3070bda907b91266-0"
    } else {
        container "quay.io/biocontainers/mulled-v2-75e2a26f10cbf3629edf2d1600db3fed5ebe6e04:eae321284604f7dabbdf121e3070bda907b91266-0"
    }

    input:
    tuple val(meta), path("bins/*")
    tuple val(db_name), path("database/*"), path("taxonomy/*")

    output:
    path("*.names.txt")
    path("raw/*.ORF2LCA.txt")
    path("raw/*.predicted_proteins.faa")
    path("raw/*.predicted_proteins.gff")
    path("raw/*.log")
    path("raw/*.bin2classification.txt")
    path '*.version.txt'                , emit: version

    script:
    def software = getSoftwareName(task.process)
    """
    CAT bins -b "bins/" -d database/ -t taxonomy/ -n "${task.cpus}" -s .fa --top 6 -o "${meta.assembler}-${meta.id}" --I_know_what_Im_doing
    CAT add_names -i "${meta.assembler}-${meta.id}.ORF2LCA.txt" -o "${meta.assembler}-${meta.id}.ORF2LCA.names.txt" -t taxonomy/
    CAT add_names -i "${meta.assembler}-${meta.id}.bin2classification.txt" -o "${meta.assembler}-${meta.id}.bin2classification.names.txt" -t taxonomy/
    mkdir raw
    mv *.ORF2LCA.txt *.predicted_proteins.faa *.predicted_proteins.gff *.log *.bin2classification.txt raw/

    CAT --version | sed "s/CAT v//; s/(.*//" > ${software}.version.txt
    """
}
