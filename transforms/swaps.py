swaps = {
'ALPHA':'A',
'BETA':'B', 
'GAMMA':'G', 
'DELTA':'D', 
'EPSILON':'E',
'P13K':'PI3K',
'EB13':'EBI3'
}

def multipleReplace(text, wordDict):
    for key in wordDict:
        text = text.replace(key, wordDict[key])
    return text

def swaps(word):
    return [multipleReplace(word, swaps)]
