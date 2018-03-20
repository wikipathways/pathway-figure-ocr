# see http://www.unicode.org/reports/tr15/#Canon_Compat_Equivalence

import unicodedata

def nfkc(word):
    return [unicodedata.normalize("NFKC", word)]
