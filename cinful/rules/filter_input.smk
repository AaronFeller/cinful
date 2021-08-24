from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
import json
import seqhash

SAMPLES, = glob_wildcards("{sample}.fna")

def hmmsearch(queryFile, hmm):
	
  with pyhmmer.easel.SequenceFile(queryFile) as seq_file:
    sequences = [ seq.digitize(hmm.alphabet) for seq in seq_file ]
  pipeline = pyhmmer.plan7.Pipeline(hmm.alphabet)
  hits = pipeline.search_hmm(hmm, sequences)
  return hits

def build_hmm(alnFile):
  abc = pyhmmer.easel.Alphabet.amino()
  builder = pyhmmer.plan7.Builder(alphabet=abc)

  with pyhmmer.easel.MSAFile(alnFile) as msa_file:
    msa_file.set_digital(abc)
    msa = next(msa_file)
  # MSA must have a name, otherwise building will fail
  if msa.name is None:
    msa.name = b"alignment"
  builder = pyhmmer.plan7.Builder(abc)
  background = pyhmmer.plan7.Background(abc)
  hmm, _, _ = builder.build_msa(msa, background)

  return hmm

rule filter_microcin:
	input:
		"cinfulOut/01_orf_homology/prodigal_out/{sample}.faa"
	output:
		"cinfulOut/01_orf_homology/microcins/all_samples/{sample}.filtered.fa"
	shell:
		"seqkit seq -m 30 -M 150 {input} | seqkit rmdup -s > {output}"



rule nonredundant_microcin:
	input:
		all_samples=expand("cinfulOut/01_orf_homology/microcins/all_samples/{sample}.filtered.fa", sample=SAMPLES),
		signalSeqAln="cinfulOut/00_dbs/verified_SP.aln"

	output:
		fasta="cinfulOut/01_orf_homology/microcins/filtered_nr.fa",
		csv="cinfulOut/01_orf_homology/microcins/filtered_nr.csv"
	run:
		hashDict = {}
		idDict = {}
		for file in input.all_samples:
			sample = file.split("cinfulOut/01_orf_homology/microcins/all_samples/")[1].strip(".filtered.fa")
			with open(file) as handle:
				for seq_record in SeqIO.parse(handle, "fasta"):
					pephash = seqhash.seqhash(seq_record.seq,dna_type='PROTEIN')
					sequence = str(seq_record.seq)
					
					descriptionParts = seq_record.description.split("#") 
					start = descriptionParts[1].strip()
					stop = descriptionParts[2].strip()
					strand = descriptionParts[3].strip()
					contig = '_'.join(seq_record.id.split("_")[:-1])
					hashDict[pephash] = sequence
					seqID = f"{sample}|{contig}|{start}:{stop}:{strand}"
					idDict[seqID] = [pephash,sample,contig,start,stop,strand,sequence]
		

		
		with open(output.fasta,"w") as fasta_file:
			for pephash in hashDict:
				outRecord = SeqRecord(
					Seq(hashDict[pephash]),
					id=pephash,
					description=""
				)
				SeqIO.write(outRecord, fasta_file, "fasta")
		signalSeqHMM = build_hmm(input.signalSeqAln)
		
		signalSeqHits = hmmsearch(output.fasta, signalSeqHMM)
		signalSeqHitStr = [hit.name.decode('utf-8') for hit in signalSeqHits]

		idDF = pd.DataFrame.from_dict(idDict,orient="index")
		
		idDF.columns = ["pephash","sample","contig","start","stop","strand","seq"]
		print("SignalMatch:",len(signalSeqHitStr),signalSeqHitStr)
		idDF["signalMatch"] = idDF["pephash"].isin(signalSeqHitStr)
									
		idDF.to_csv(output.csv)
			



rule filter_immunity_protein:
	input:
		"cinfulOut/01_orf_homology/prodigal_out/{sample}.faa"
	output:
		"cinfulOut/01_orf_homology/immunity_proteins/all_samples/{sample}.filtered.fa"
	shell:
		"seqkit seq -m 30 -M 250  {input} | seqkit rmdup -s > {output}"

rule nonredundant_immunity_protein:
	input:
		expand("cinfulOut/01_orf_homology/immunity_proteins/all_samples/{sample}.filtered.fa", sample=SAMPLES)
	output:
		fasta="cinfulOut/01_orf_homology/immunity_proteins/filtered_nr.fa",
		csv="cinfulOut/01_orf_homology/immunity_proteins/filtered_nr.csv"
	run:
		hashDict = {}
		idDict = {}
		for file in input:
			sample = file.split("cinfulOut/01_orf_homology/immunity_proteins/all_samples/")[1].strip(".filtered.fa")
			with open(file) as handle:
				for seq_record in SeqIO.parse(handle, "fasta"):
					pephash = seqhash.seqhash(seq_record.seq,dna_type='PROTEIN')
					sequence = str(seq_record.seq)
					
					descriptionParts = seq_record.description.split("#") 
					start = descriptionParts[1].strip()
					stop = descriptionParts[2].strip()
					strand = descriptionParts[3].strip()
					contig = '_'.join(seq_record.id.split("_")[:-1])
					hashDict[pephash] = sequence
					seqID = f"{sample}|{contig}|{start}:{stop}:{strand}"
					idDict[seqID] = [pephash,sample,contig,start,stop,strand,sequence]
		idDF = pd.DataFrame.from_dict(idDict,orient="index")
		idDF.columns = ["pephash","sample","contig","start","stop","strand","seq"]
									
		idDF.to_csv(output.csv)


		with open(output.fasta,"w") as fasta_file:
			for pephash in hashDict:
				outRecord = SeqRecord(
					Seq(hashDict[pephash]),
					id=pephash,
					description=""
				)
				SeqIO.write(outRecord, fasta_file, "fasta")


rule filter_CvaB:
	input:
		"cinfulOut/01_orf_homology/prodigal_out/{sample}.faa"
	output:
		"cinfulOut/01_orf_homology/CvaB/all_samples/{sample}.filtered.fa"
	shell:
		"seqkit rmdup -s {input} > {output}"

rule nonredundant_CvaB:
	input:
		expand("cinfulOut/01_orf_homology/CvaB/all_samples/{sample}.filtered.fa", sample=SAMPLES)
	output:
		fasta="cinfulOut/01_orf_homology/CvaB/filtered_nr.fa",
		csv="cinfulOut/01_orf_homology/CvaB/filtered_nr.csv"
	run:
		hashDict = {}
		idDict = {}
		for file in input:
			sample = file.split("cinfulOut/01_orf_homology/CvaB/all_samples/")[1].strip(".filtered.fa")
			with open(file) as handle:
				for seq_record in SeqIO.parse(handle, "fasta"):
					pephash = seqhash.seqhash(seq_record.seq,dna_type='PROTEIN')
					sequence = str(seq_record.seq)

					descriptionParts = seq_record.description.split("#") 
					start = descriptionParts[1].strip()
					stop = descriptionParts[2].strip()
					strand = descriptionParts[3].strip()
					contig = '_'.join(seq_record.id.split("_")[:-1])
					hashDict[pephash] = sequence
					seqID = f"{sample}|{contig}|{start}:{stop}:{strand}"
					idDict[seqID] = [pephash,sample,contig,start,stop,strand,sequence]
		idDF = pd.DataFrame.from_dict(idDict,orient="index")
		idDF.columns = ["pephash","sample","contig","start","stop","strand","seq"]
									
		idDF.to_csv(output.csv)


		with open(output.fasta,"w") as fasta_file:
			for pephash in hashDict:
				outRecord = SeqRecord(
					Seq(hashDict[pephash]),
					id=pephash,
					description=""
				)
				SeqIO.write(outRecord, fasta_file, "fasta")



# TODO: add a merge nonredundant step for each component