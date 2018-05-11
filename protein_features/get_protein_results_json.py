#!/usr/local/bin/python3
from Bio.SeqUtils.ProtParam import ProteinAnalysis
import Bio.SeqUtils

import json
# example_sequence: "MAEGEITTFTALTEKFNLPPGNYKKPKLLYCSNGGHFLRILPDGTVDGTRDRSDQHIQLQLSAESVGEVYIKSTETGQYLAMDTSGLLYGSQTPSEECLFLERLEENHYNTYTSKKHAEKNWFVGLKKNGSCKRGPRTHYGQKAILFLPLPV"

def get_protein_results_json(aa_sequence):
	prot_analysis= ProteinAnalysis(aa_sequence.strip())	
	results_map = {}
	results_map['molecular_weight'] = prot_analysis.molecular_weight()
	results_map['aromaticity'] = prot_analysis.aromaticity()
	results_map['instability_index'] = prot_analysis.instability_index()
	results_map['isoelectric_point'] = prot_analysis.isoelectric_point()
	epsilon_prot = prot_analysis.molar_extinction_coefficient()
	results_map['extinction_coefficient_reduced_cysteines'] = epsilon_prot[0]
	results_map['extinction_coefficient_disulphide_bridges'] = epsilon_prot[1]
	results_map['amino_acid_percent'] = prot_analysis.get_amino_acids_percent()
	results_map['amino_acid_count'] = prot_analysis.count_amino_acids()
	
	return json.dumps(results_map)

    
