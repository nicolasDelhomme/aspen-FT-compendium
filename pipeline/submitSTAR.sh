#!/bin/bash -l

# safe
set -eu -o pipefail

# args
star_container=$(realpath ../singularity/kogia/star_2.7.10a.sif)
samtools_container=$(realpath ../singularity/kogia/samtools_1.16.sif)
genome_dir=$(realpath ../reference)/Populus-tremula/v2.2/indices/star/Potra02_STAR_v2.7.9a
genome_fasta=$(realpath ../reference)/Populus-tremula/v2.2/fasta/Potra02_genome.fasta
indir=$(realpath ../data/backup/trimmomatic)
outdir=$(realpath ../data/backup)/STAR
account=u2018015

# setup
[[ ! -d "${outdir}" ]] && mkdir "${outdir}"

# env var
export SINGULARITY_BINDPATH="/mnt:/mnt"

# find the files
# shellcheck disable=SC2044
for f in $(find "${indir}" -type l -name "*_trimmomatic_1.fq.gz"); do
    nam=$(basename "${f/_trimmomatic_1.fq.gz/}")
    sbatch -A ${account} -o "${outdir}/${nam}".out -e "${outdir}/${nam}".err -J "${nam}"\
    runSTAR.sh "${star_container}" "${samtools_container}" \
    "${outdir}" "${genome_dir}" "${genome_fasta}" "${f}" "${f/_1.fq.gz/_2.fq.gz}"
done
