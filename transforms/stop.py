from . import alphanumeric

stop_list = ["2", "CO2", "HR", "PH", "CA2", "PR", "OF", "CO", "TYPE", "IN", "T3", "FA", "GR", "NP", "RD", "ON", "GA",
        "DAMAGE", "GK", "CR", "DS", "ET", "JN", "S21", "S9", "PI", "PP", "TAT", "P", "GO", "L10","CYCLIN","II","LE",
	"TC","TX","UP","CAMP","FOR","DAG","PIP","IP","T","FATE","DM","FI","CF","HE","PL","PA","P8","S6","PM","ANG"]

def stop(word):
    alphanumerics = alphanumeric.alphanumeric(word)
    if len(alphanumerics) > 0 and alphanumerics[0].upper() not in stop_list:
        return [word]
    else:
        return []
