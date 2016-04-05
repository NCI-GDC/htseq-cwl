#!/bin/bash
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --workdir=/mnt/SCRATCH/

function cleanup (){
    echo "cleanup tmp data";
    sudo rm -rf $wkdir;
}

bam="XX_GDC_XX"
gdc_id="XX_GDC_ID_XX"
case_id="XX_CASE_ID_XX"
basedir="/mnt/SCRATCH/"
annotation="s3://bioinformatics_scratch/gencode.v22.annotation.gtf"
username="XX_username_XX"
password="XX_password_XX"
repository="git@github.com:NCI-GDC/htseq-cwl.git"
s3dir="s3://bioinformatics_scratch/"
host_base="XX_HOST_BASE_XX"
host="pgreadwrite.osdc.io"
clsafe_endpoint="http://gdc-accessor1.osdc.io"
wkdir=`sudo mktemp -d ht.XXXXXXXXX -p /mnt/SCRATCH` 
sudo chown ubuntu:ubuntu $wkdir

cd $wkdir 
export PATH=$PATH:/home/ubuntu/.virtualenvs/p2/bin/

sudo git clone -b feat/slurm $repository  
sudo chown ubuntu:ubuntu htseq-cwl 
cwl=$wkdir/varscan-cwl/tools/htseq-tool.cwl.yaml

trap cleanup EXIT

/home/ubuntu/.virtualenvs/p2/bin/python $wkdir/htseq-cwl/slurm/run_cwl.py --genome_annotation $annotation --bam $bam --gdc_id $gdc_id --case_id $case_id --username $username --password $password --basedir $wkdir --cwl $cwl --s3dir $s3dir --s3ceph $s3cfg --host $host --cleversafe_endpoint $clsafe_endpoint

