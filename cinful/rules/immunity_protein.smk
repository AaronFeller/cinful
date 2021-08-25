from io import StringIO
from Bio import SeqIO


# rule final:
	# input:
		# expand("cinfulOut/01_orf_homology/immunity_proteins/filtered_nr.fa", sample = SAMPLES)

# rule filter_immunity_protein:
# 	input:
# 		"cinfulOut/01_orf_homology/{sample}.faa"
# 	output:
# 		"cinfulOut/01_orf_homology/immunity_proteins/filtered_nr.fa"
# 	shell:
# 		"seqkit seq -m 30 -M 250  {input} | seqkit rmdup -s > {output}"

rule makeblastdb_immunity_protein:
	input:
		"cinfulOut/00_dbs/immunity_proteins.verified.pep"
	output:
		"cinfulOut/00_dbs/immunity_proteins.verified.pep.phr"
	shell:
		"makeblastdb -dbtype prot -in {input}"

rule blast_immunity_protein:
	input:
		verified_component = "cinfulOut/00_dbs/immunity_proteins.verified.pep",
		blastdb = "cinfulOut/00_dbs/immunity_proteins.verified.pep.phr",
		input_seqs = "cinfulOut/01_orf_homology/immunity_proteins/filtered_nr.fa"
	output:
		"cinfulOut/01_orf_homology/immunity_proteins/blast.txt"
	threads:threads_max
	shell:
		"blastp -db {input.verified_component} -query {input.input_seqs} -outfmt 6 -out {output} -evalue 0.001 -max_target_seqs 1 -num_threads {threads}"

rule msa_immunity_protein:
	input:
		"cinfulOut/00_dbs/immunity_proteins.verified.pep"
	output:
		"cinfulOut/00_dbs/immunity_proteins.verified.aln"
	shell:
		"mafft --auto {input} > {output}"

rule buildhmm_immunity_protein:
	input:
		"cinfulOut/00_dbs/immunity_proteins.verified.aln"
	output:
		"cinfulOut/00_dbs/immunity_proteins.verified.hmm"
	shell:
		"hmmbuild {output} {input}"



rule blast_v_hmmer_immunity_protein:
	input:
		verifiedHMM = "cinfulOut/00_dbs/immunity_proteins.verified.hmm",
		input_seqs = "cinfulOut/01_orf_homology/immunity_proteins/filtered_nr.fa",
		blastOut = "cinfulOut/01_orf_homology/immunity_proteins/blast.txt"
	output:
		"cinfulOut/01_orf_homology/immunity_proteins/blast_v_hmmer.csv"
	run:
		blastDF = load_blast(input.blastOut)
		hmmer_hits, hmm_name = run_hmmsearch(input.input_seqs, input.verifiedHMM)
		hmmer_hitsHeaders = [hit.name.decode() for hit in hmmer_hits]
		blastDF["component"] = hmm_name
		blastDF["hmmerHit"] = blastDF["qseqid"].isin(hmmer_hitsHeaders)#hmmer_hitsHeaders in blastDF["qseqid"]
		blastDF.to_csv(output[0], index = False)



# rule makeblastdb:
# 	input:
# 		"verified_immunity_proteins.pep"
# 	output:
# 		"verified_immunity_proteins.pep.phr"
# 	shell:
# 		"makeblastdb -dbtype prot -in {input}"

# rule blast:
# 	input:
# 		verified_immunity_proteins = "verified_immunity_proteins.pep",
# 		blastdb = "verified_immunity_proteins.pep.phr",
# 		input_seqs = "{sample}_cinfulOut/{sample}.30_150.fa"
# 	output:
# 		"{sample}_cinfulOut/{sample}.verified_immunity_proteins.blast.txt"
# 	shell:
# 		"blastp -db {input.verified_immunity_proteins} -query {input.input_seqs} -outfmt 6 -out {output} -evalue 0.001 -max_target_seqs 1"

# rule verified_immunity_proteinsMSA:
# 	input:
# 		"verified_immunity_proteins.pep"
# 	output:
# 		"verified_immunity_proteins.aln"
# 	shell:
# 		"mafft --auto {input} > {output}"

# rule buildhmm:
# 	input:
# 		"verified_immunity_proteins.aln"
# 	output:
# 		"verified_immunity_proteins.hmm"
# 	shell:
# 		"hmmbuild {output} {input}"

# rule duomolog:
# 	input:
# 		verified_immunity_proteins = "verified_immunity_proteins.pep",
# 		input_seqs = "{sample}_cinfulOut/{sample}.30_150.fa",
# 		blastout="{sample}_cinfulOut/{sample}.verified_immunity_proteins.blast.txt",
# 		hmm="verified_immunity_proteins.hmm"
# 	output:
# 		"{sample}_cinfulOut/duomolog_immunity_protein/summary_out.txt"
# 	shell:
# 		"""duomolog blast_v_hmmer --inFile {input.verified_immunity_proteins} --queryFile {input.input_seqs} \
# 			--blastFile {input.blastout} \
# 			--intersectOnly \
# 			--hmmFile {input.hmm}	\
# 			--summaryOut {output}
# 		"""		





# rule getBestHits:
# 	input:
# 		blast_hits = "verified_immunity_proteins.blast.txt",
# 		hmmer_hits = "verified_immunity_proteins.hmmerOut.txt",
# 		seq = "input_seqs.short.fa"
# 	output:
# 		"verified_immunity_proteins.bestHits.fa"
# 	shell:
# 		"touch {output}"

# rule bestHitsMSA:
# 	input:
# 		"verified_immunity_proteins.bestHits.fa"
# 	output:
# 		"verified_immunity_proteins.bestHits.aln"
# 	shell:
# 		"touch {output}"

# rule evaluateMSA:
# 	input:
# 		"verified_immunity_proteins.bestHits.aln"
# 	output:
# 		"verified_immunity_proteins.evaluateMSA.txt"

# rule subcellular_localization:
# 	input:
# 		"verified_immunity_proteins.bestHits.fa"
# 	output:
# 		"verified_immunity_proteins.bestHits.subcellular_localization.txt"
# 	shell:
# 		"touch {output}"

# rule transmembrane_helix:
# 	input:
# 		"verified_immunity_proteins.bestHits.fa"
# 	output:
# 		"verified_immunity_proteins.bestHits.transmembrane_helix.txt"
# 	shell:
# 		"touch {output}"



# rule putative_immunity_proteins:
# 	input:
# 		seqs = "verified_immunity_proteins.bestHits.fa",
# 		evaluateMSA = "verified_immunity_proteins.evaluateMSA.txt",
# 		subcellular_localization = "verified_immunity_proteins.bestHits.subcellular_localization.txt",
# 		transmembrane_helix = "verified_immunity_proteins.bestHits.transmembrane_helix.txt"

# 	output:
# 		"putative_immunity_proteins.txt"