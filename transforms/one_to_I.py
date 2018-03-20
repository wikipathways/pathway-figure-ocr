import re

one_re = re.compile("1")

def one_to_I(word):
    return [one_re.sub('I', word)]
