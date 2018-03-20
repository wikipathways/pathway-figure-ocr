from . import alphanumeric

stop_list = ["2", "CO2", "HR", "PH", "CA2", "PR", "OF", "CO", "TYPE", "IN", "T3", "FA", "GR", "NP", "RD", "ON", "GA",
        "DAMAGE", "GK", "CR", "DS", "ET", "JN", "S21", "S9", "PI", "PP", "TAT", "P"]

def stop(word):
    alphanumerics = alphanumeric.alphanumeric(word)
    if len(alphanumerics) > 0 and alphanumerics[0].upper() not in stop_list:
        return [word]
    else:
        return []
