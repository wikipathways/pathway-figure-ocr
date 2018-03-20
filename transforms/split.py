import re
split_re = re.compile('/')

def split(word):
    return split_re.split(word)
