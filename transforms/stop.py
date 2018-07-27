## Excludes uppercased, alphanumeric-only full-words that match against a "stop_list".

from . import alphanumeric

# NOTE: all single letter symbols have already been removed from the lexicon
# NOTE: all double letter symbols have already been removed from prev_symbol, alias_symbol; 
#       some remain from current HGNC symbols and bioentities sources, e.g., GK, GA and HR.
# NOTE: entries should be upper and alphanumeric-only
stop_list = ["2", "CO2", "HR", "GA", "CA2", "TYPE",
        "DAMAGE", "GK", "S21", "TAT", "L10","CYCLIN",
	"CAMP","FOR","DAG","PIP","FATE","ANG",
	"NOT","CAN","MIR","CEL","ECM","HITS","AID","HDS",
	"REG","ROS", "D1", "CALL", "BEND3"]


def stop(word):
    alphanumerics = alphanumeric.alphanumeric(word)
    if len(alphanumerics) > 0 and alphanumerics[0].upper() not in stop_list:
        return [word]
    else:
        return []
