## Excludes uppercased, alphanumeric-only full-words that match against a "stop_list".

from . import alphanumeric

# NOTE: entries should be upper and alphanumeric-only
stop_list = ["2", "CO2", "HR", "PH", "CA2", "PR", "OF", "CO", "TYPE", "IN", "T3", "FA", "GR", "NP", "RD", "ON", "GA",
        "DAMAGE", "GK", "CR", "DS", "ET", "JN", "S21", "S9", "PI", "PP", "TAT", "GO", "L10","CYCLIN","II","LE",
	"TC","TX","UP","CAMP","FOR","DAG","PIP","IP","FATE","DM","FI","CF","HE","PL","PA","P8","S6","PM","ANG","D1",
	"AS","IS","OF","IN","AN","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V",
	"W","X","Y","Z","NOT","NA","CAN","LI","AM","MIR","SS","ER","AR","T1","CEL","ECM","HITS","SR","AID","HDS","HK",
	"REG"]


def stop(word):
    alphanumerics = alphanumeric.alphanumeric(word)
    if len(alphanumerics) > 0 and alphanumerics[0].upper() not in stop_list:
        return [word]
    else:
        return []
