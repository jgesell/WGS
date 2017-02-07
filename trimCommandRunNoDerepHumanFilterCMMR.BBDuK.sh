#!/bin/sh

sampleDir=`pwd -P`;
mkdir -p ../Logs;
mkdir -p ../Results;
counter=0;
for i in `find */raw_data/*.bz2 | grep "_1_sequence" | xargs du -D -b | sort -k1 -n -r  | cut -f2`;
do dir=`echo ${i} | cut -f1 -d "/"`;
filesize=`du -D -b ${i} | cut -f1`;
outdir="${dir}/processed";
base=`basename ${i} | sed 's/_[0-9]\+_sequence.*//g'`;
sample=`echo ${i} | cut -f2 -d "/"`;
pair=`echo ${i} | sed 's/_1_sequence/_2_sequence/'`;
fastq1=`basename ${i} | rev | cut -f2- -d "." | rev`;
fastq2=`basename ${pair} | rev | cut -f2- -d "." | rev`;
counter=$[counter + 1];
mkdir -p ${outdir};
mkdir -p ${dir}/Logs;
mkdir -p ${dir}/Results;
echo "bzcat ${i} > \${TMPDIR}/${fastq1} & bzcat ${pair} > \${TMPDIR}/${fastq2} & wait; ~gesell/Programs/bbmap/bbduk.sh in1=\${TMPDIR}/${fastq1} in2=\${TMPDIR}/${fastq2} out1=\${TMPDIR}/${base}.1.Trimmed.fq out2=\${TMPDIR}/${base}.2.Trimmed.fq ref=\${TMPDIR}/Adapters.fasta k=23 hdist=1 minlength=50 trimq=20 minkmerhits=6 ktrim=r stats=${dir}/Logs/${base}.TrimmingStats.txt threads=8; cat \${TMPDIR}/${base}.1.Trimmed.fq | pbzip2 -p3 -c > ${outdir}/${base}.1.Trimmed.fq.bz2 & cat \${TMPDIR}/${base}.2.Trimmed.fq | pbzip2 -p3 -c > ${outdir}/${base}.2.Trimmed.fq.bz2 & bz2prinseq -fastq \${TMPDIR}/${base}.1.Trimmed.fq -fastq2 \${TMPDIR}/${base}.2.Trimmed.fq -out_good \${TMPDIR}/${base}.good -out_bad \${TMPDIR}/${base}.bad -log ${dir}/Logs/${base}.prinseq.log -no_qual_header -lc_method dust -lc_threshold 5 -trim_ns_left 1 -trim_ns_right 1 & wait; bowtie2 -x /gpfs1/db/hg38phix/hg38phix -U \${TMPDIR}/${base}.good_1.fastq.bz2,\${TMPDIR}/${base}.good_2.fastq.bz2 --end-to-end --very-sensitive -p 8 --no-unal --no-hd --no-sq 2> ${dir}/Logs/${base}.hg38phix.align.stats.txt | cut -f1,3 > ${outdir}/${base}.hg38phix.reads.txt; perl /users/mcwong/fastqFilter.pl \${TMPDIR}/${base}.good_1.fastq.bz2 \${TMPDIR}/${base}.good_2.fastq.bz2 ${outdir}/${base}_1.fastq.bz2 ${outdir}/${base}_2.fastq.bz2 ${dir}/Logs/${base}.hg38phix.reads.txt; cp \${TMPDIR}/${base}*_trimming_report.txt ${dir}/Logs/; rm \${TMPDIR}/${base}* \${TMPDIR}/${fastq1}* \${TMPDIR}/${fastq2}*;"; 
done > ../TrimCommand.txt;
if [ "${counter}" -lt 20 ];
then echo "cp /users/gesell/Programs/gitHub/WGS/Adapters.fasta \${TMPDIR}/Adapters.fasta; cat ../TrimCommand.txt | parallel -j5" | qsub -l ncpus=20 -q batch -d `pwd -P` -V -N Trimming.Process -o ../Logs -e ../Logs;
else shuf ../TrimCommand.txt -o ../TrimCommand2;
shuf ../TrimCommand2 -o ../TrimCommand.txt;
rm ../TrimCommand2;
split ../TrimCommand.txt ../TrimCommands -n r/4;
for i in `find ../TrimCommands*`; do echo "cp /users/gesell/Programs/gitHub/WGS/Adapters.fasta \${TMPDIR}/Adapters.fasta; cat ${i} | parallel -j5" | qsub -l ncpus=20 -q batch -d `pwd -P` -V -N Trimming.${i}.Process -o ../Logs -e ../Logs;
done;
fi;
exit 0;