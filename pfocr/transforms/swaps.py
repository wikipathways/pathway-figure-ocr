## Replaces character strings in uppercased words with matched strings in "swaps" dictionary.

# NOTE: entries should be upper and may contain non-alphanumerics
swap_list = {
'ALPHA':'A',
'BETA':'B', 
'GAMMA':'G', 
'DELTA':'D', 
'EPSILON':'E',
'KAPPA':'K',
'α':'A',
'β':'B',
'ß':'B',
'γ':'G',
'δ':'D',
'ε':'E',
'κ':'K',
'Θ':'Q',
'IKKP':'IKKG',
'IKKY':'IKKG',
'IFNY':'IFNG',
'SEMAY':'SEMAG',
'PLCY':'PLCG',
'TGFBRI':'TGFBR1',
'II':'2',
'III':'3',
'VE-CADHERIN':'CDH5',
'E-CADHERIN':'CDH1',
'N-CADHERIN':'CDH2',
'K-CADHERIN':'CDH6',
'R-CADHERIN':'CDH4',
'T-CADHERIN':'CDH13',
'M-CADHERIN':'CDH15',
'KSP-CADHERIN':'CDH16',
'LI-CADHERIN':'CDH17',
'P13K':'PI3K',
'NUCLEOLIN':'NCL',
'VITRONECTIN':'VTN',
'PLASMINOGEN':'PLG',
'PLASMIN':'PLG',
'EB13':'EBI3'
}

def multipleReplace(text, wordDict):
    for key in wordDict:
        text = text.upper().replace(key, wordDict[key])
    return text

def swaps(word):
    return [multipleReplace(word, swap_list)]
