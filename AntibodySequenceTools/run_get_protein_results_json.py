#!/usr/local/bin/python3
import sys
from get_protein_results_json import get_protein_results_json
aa_seq = sys.argv[1].strip()
print(get_protein_results_json(aa_seq))
