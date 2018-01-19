# This is to be always run before inserting entries into
# the lexicon table and the words table.

import re
normalize_re = re.compile('[^A-Z0-9]')

def normalize(word):
    word_upper = word.upper()
    word_regexed = normalize_re.sub('', word_upper)
    return word_regexed
