


rule test:
	input: "v3/sasdata/betas_pop_genmod_exch.sas7bdat"
	output: "output.sas7bdat"
	shell: "sas test.sas -sysparm {input}*{output}"

