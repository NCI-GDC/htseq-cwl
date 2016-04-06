import argparse
import pipelineUtil
import uuid
import os
import postgres
import setupLog
import logging
import tempfile
import datetime

def compress_output(workdir, logger):
    """ compress all files in a directory """


    for filename in os.listdir(workdir):
        filepath = os.path.join(workdir, filename)
        cmd = ['gzip', filepath]
        exit = pipelineUtil.run_command(cmd)
        if exit:
            raise Exception("Cannot compress file %s" %filepath)

def update_postgres(exit, cwl_failure, upload_location ):
    """ update the status of job on postgres """

    loc = "UNKNOWN"
    status = "UNKNOWN"


    if sum(exit) == 0:

        loc = upload_location

        if not(cwl_failure):

            status = "SUCCESS"
            logger.info("uploaded all files to object store. The path is: %s" %upload_location)

        else:

            status = "COMPLETE"
            logger.info("CWL failed but outputs were generated. The path is: %s" %upload_location)

    else:

        loc = "Not Applicable"

        if not(cwl_failure):

            status = "UPLOAD FAILURE"
            logger.info("Upload of files failed")
        else:
            status = "FAILED"
            logger.info("CWL and upload both failed")
    return(status, loc)


def get_input_file(fromlocation, tolocation, logger, s3cfg="/home/ubuntu/.s3cfg", endpoint_url='http://gdc-cephb-objstore.osdc.io/', profile='ceph'):
    """ download a file and return its location"""

    exit_code = pipelineUtil.download_from_cleversafe(logger, fromlocation, tolocation, s3cfg, endpoint_url, profile)

    if exit_code:
        raise Exception("Cannot download file: %s" %(fromlocation))

    outlocation = os.path.join(tolocation, os.path.basename(fromlocation))
    return outlocation

def upload_all_output(localdir, remotedir, logger, s3cfg="/home/ubuntu/.s3cfg"):
    """ upload output files to object store """

    all_exit_code = list()

    for filename in os.listdir(localdir):
        localfilepath = os.path.join(localdir, filename)
        remotefilepath = os.path.join(remotedir, filename)
        exit_code = pipelineUtil.upload_to_cleversafe(logger, remotefilepath, localfilepath, s3cfg)
        all_exit_code.append(exit_code)

    return all_exit_code


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Run variant calling CWL")
    required = parser.add_argument_group("Required input parameters")
    required.add_argument("--bam", default=None, help="path to aligned rna-seq bam file", required=True)
    required.add_argument("--genome_annotation", default=None, help="path to genome annotation file", required=True)
    required.add_argument("--gdc_id", default=None, help="UUID for aligned BAM", required=True)
    required.add_argument("--case_id", default=None, help="UUID for case", required=True)
    required.add_argument("--username", default=None, help="Username for postgres", required=True)
    required.add_argument("--password", default=None, help="Password for postgres", required=True)
    required.add_argument("--cwl", default=None, help="Path to CWL code", required=True)
    required.add_argument("--gene_lengths", default="/home/ubuntu/bin/htseq-tool/gencode.v22.gene.length.txt", help="path to gene lengths")

    optional = parser.add_argument_group("Optional input parameters")
    optional.add_argument("--strand", default="no", help="Strandedness for HTseq")
    optional.add_argument("--record_metrics", default="0", help="Option to record metrics")
    optional.add_argument("--ref", default=None, help="path to reference genome")
    optional.add_argument("--refindex", default=None, help="path to reference index")
    optional.add_argument("--s3dir", default="s3://bioinformatics_scratch/", help="path to output files")
    optional.add_argument("--basedir", default="/mnt/SCRATCH/", help="Base directory for computations")
    optional.add_argument("--s3clsafe", default="/home/ubuntu/.s3cfg.cleversafe", help="config file for cleversafe")
    optional.add_argument("--s3ceph", default="/home/ubuntu/.s3cfg.ceph", help="config file for ceph")
    optional.add_argument("--host", default="pgreadwrite.osdc.io", help="hostname for postgres")
    optional.add_argument("--cleversafe_endpoint", default='http://gdc-accessors.osdc.io/', help="round robin endpoint URL for cleversafe")
    optional.add_argument("--ceph_endpoint", default='http://gdc-cephb-objstore.osdc.io/', help="round robin endpoint URL for cephb")

    args = parser.parse_args()

    if not os.path.isdir(args.basedir):
        raise Exception("Could not find path to base directory: %s" %args.basedir)

    #create directory structure
    casedir = tempfile.mkdtemp(prefix="%s_" %args.case_id, dir=args.basedir)
    workdir = tempfile.mkdtemp(prefix="workdir_", dir=casedir)
    inp = tempfile.mkdtemp(prefix="input_", dir=casedir)

    #generate a random uuid
    count_uuid = uuid.uuid4()

    #setup logger
    log_file = os.path.join(workdir, "%s.htseq.cwl.log" %str(count_uuid))
    logger = setupLog.setup_logging(logging.INFO, str(count_uuid), log_file)

    #logging inputs
    logger.info("bam_path: %s" %(args.bam))
    logger.info("bam_id: %s" %(args.gdc_id))
    logger.info("case_id: %s" %(args.case_id))
    logger.info("count_id: %s" %(str(count_uuid)))

    #download reference file
    if not args.ref == None :
        if not os.path.isfile(args.ref):
            logger.info("getting reference: %s" %args.ref)
            reference = get_input_file(args.ref, inp, logger, endpoint_url=args.cleversafe_endpoint, profile='cleversafe')

    #download reference index
    if not args.refindex == None:
        if not os.path.isfile(args.refindex):
            logger.info("Getting reference index: %s" %args.refindex)
            refindex = get_input_file(args.refindex, inp, logger, endpoint_url=args.cleversafe_endpoint, profile='cleversafe')


    #download genome annotation
    if not os.path.isfile(args.genome_annotation):
        logger.info("downloading genome annotation")
        genome_annotation = get_input_file(args.genome_annotation, inp, logger, endpoint_url=args.cleversafe_endpoint, profile='cleversafe')

    #download gene-lengths file
    gene_lengths = args.gene_lengths
    if not os.path.isfile(args.gene_lengths):
        logger.info("downloading gene lengths file")
        gene_lengths = get_input_file(args.gene_lengths, inp, logger, endpoint_url=args.cleversafe_endpoint, profile='cleversafe')

    #download rnaseq bam
    logger.info("getting aligned bam: %s" %args.bam)
    if "ceph" in args.bam:
        bam = get_input_file(args.bam, inp, logger, args.s3ceph, args.ceph_endpoint, profile='ceph')
    else:
        bam = get_input_file(args.bam, inp, logger, args.s3clsafe, args.cleversafe_endpoint, profile='cleversafe')

    os.chdir(workdir)

    #run cwl command
    cmd = ['/home/ubuntu/.virtualenvs/p2/bin/cwl-runner', "--debug", args.cwl,
            "--genome_annotation", genome_annotation,
            "--bam", bam,
            "--gdc_id", args.gdc_id,
            "--case_id", args.case_id,
            "--username", args.username,
            "--password", args.password,
            "--id", str(count_uuid),
            "--host", args.host,
            "--strand", args.strand,
            "--outdir", ".",
            "--gene_lengths", gene_lengths,
            "--record_metrics", args.record_metrics
            ]

    cwl_exit = pipelineUtil.run_command(cmd, logger)

    #establish connection with database

    DATABASE = {
        'drivername': 'postgres',
        'host' : 'pgreadwrite.osdc.io',
        'port' : '5432',
        'username': args.username,
        'password' : args.password,
        'database' : 'prod_bioinfo'
    }

    cwl_failure= False
    engine = postgres.db_connect(DATABASE)

    #record as failure if a non-zero exit status is returned
    if cwl_exit:

        cwl_failure = True

    #upload results to s3

    upload_location = os.path.join(args.s3dir, str(count_uuid))

    compress_output(workdir, logger)
    exit = upload_all_output(workdir, upload_location, logger, args.s3ceph)

    #update postgres
    status, loc = update_postgres(exit, cwl_failure, upload_location)
    timestamp = str(datetime.datetime.now())
    postgres.add_status(engine, args.case_id, str(count_uuid), args.gdc_id, status, loc, timestamp)

    #remove work and input directories
    #pipelineUtil.remove_dir(casedir)
