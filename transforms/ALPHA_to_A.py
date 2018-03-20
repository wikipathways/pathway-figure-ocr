swaps = {'ALPHA':'A','BETA':'B', 'GAMMA':'G', 'DELTA':'D', 'EPSILON':'E'}

def multipleReplace(text, wordDict):
    for key in wordDict:
        text = text.replace(key, wordDict[key])
    return text

def ALPHA_to_A(word):
    return [multipleReplace(word, swaps)]
