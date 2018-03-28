swaps = {
'ALPHA':'A',
'BETA':'B', 
'GAMMA':'G', 
'DELTA':'D', 
'EPSILON':'E',
'KAPPA':'K',
'α':'A',
'β':'B',
'γ':'G',
'δ':'D',
'ε':'E',
'κ':'K',
'VE-CADHERIN':'CDH5',
'E-CADHERIN':'CDH1',
'K-CADHERIN':'CDH6',
'R-CADHERIN':'CDH4',
'T-CADHERIN':'CDH13',
'M-CADHERIN':'CDH15',
'KSP-CADHERIN':'CDH16',
'LI-CADHERIN':'CDH17',
'D1':'CYCLIN_D1',
'P13K':'PI3K',
'EB13':'EBI3'
}

def multipleReplace(text, wordDict):
    for key in wordDict:
        text = text.replace(key, wordDict[key])
    return text

def swaps(word):
    return [multipleReplace(word, swaps)]
