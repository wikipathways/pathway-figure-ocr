import re
match_re = re.compile('(\w+)/(.+)')
split_re = re.compile('/')

def dup(word):
    match = match_re.match(word)
    if not match:
        return [word]

    result = []
    base = match.group(1)
    remainder = match.group(2)
    split_remainder = split_re.split(remainder)
    if split_remainder[0].isdigit():
        for sr in split_remainder:
            result.append(base + sr)
    else:
        result.append(word)
    return result
