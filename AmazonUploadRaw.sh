#!/bin/sh
export time=$1;
export link=$2

if [ -z "${time}" ];
then export time="30";
fi;

if [ -z "${link}" ];
then export link=`pwd -P`;
fi;

if [ -z "${TMPDIR}" ];
then echo "Error: Please run this program thru the queueing system!";
exit 1;
fi;

cd ${link};
file=`pwd -P | cut -f5,6 -d "/" | tr "/" "."`.Raw
zip -0 ${TMPDIR}/${file}.zip */raw_data/* && aws s3 mv ${TMPDIR}/${file}.zip s3://jplab/share/${time}d/;
if [ $? -ne 0 ];
then echo -e "${file} failed to upload to S3, please check error logs for the reason why." | mail -s "${file} Upload Failure" ${USER}@bcm.edu;
else link=`aws s3 presign s3://jplab/share/${time}d/${file}.zip --expires-in $[time * 24 * 60 * 60]`;
echo ${link};
echo -e "${file} successfully uploaded to the Amazon Cloud.  Link below:\n${link}" | mail -s "${file} Upload Complete" ${USER}@bcm.edu;
fi;
exit 0;
