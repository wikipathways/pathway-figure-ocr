import re

prefix_re = re.compile('^(c\-|p\-)')
suffix_re = re.compile('(\-P|s)$')

def root(word):
    result = set()
    result.add(prefix_re.sub("", word))
    result.add(suffix_re.sub("", word))
    return list(result)
