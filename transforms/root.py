import re

prefix_re = re.compile('^(c\-|p\-|P\-)')
suffix_re = re.compile('(\-p|\-P)$')
plural_re = re.compile('s$')

def root(word):
    result = set()
    result.add(prefix_re.sub("", word))
    result.add(suffix_re.sub("", word))
    singular = plural_re.sub("", word)
    # Only add words of 3 or more characters in length *after* removal of plural 's' to avoid many false positives
    if len(singular) > 2:
        result.add(singular)
    return list(result)
