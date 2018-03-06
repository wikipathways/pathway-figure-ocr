# This is to be always run before inserting entries into
# the lexicon table and the words table.

import re
normalize_re = re.compile('[^A-Z0-9]')
swaps = {'ALPHA':'A','BETA':'B', 'GAMMA':'G', 'DELTA':'D', 'EPSILON':'E'}


def normalize(word):
    word_upper = word.upper()
    word_swapped = multipleReplace(word_upper, swaps)
    word_regexed = normalize_re.sub('', word_swapped)
    return word_regexed

def multipleReplace(text, wordDict):
    for key in wordDict:
        text = text.replace(key, wordDict[key])
    return text
