import re

end_numeric_re = re.compile('[0-9]+$')
separator_split_re = re.compile('\/')

wordslash = re.compile("^.+\/.+$")

#numslash = re.compile("^([^\/]+?)([0-9]+)\/([0-9]+)$")
numslash = re.compile("^(.+?)([0-9])+\/([0-9])+$")
#multinumslash = re.compile("(^[^\/]+?)(([0-9])+(\/([0-9])+))+$")
multinumslash = re.compile("^(.+?)([0-9])+(\/([0-9])+)+$")

def expand1(word):
    result = []
    wordslash_match = wordslash.match(word)
    if wordslash_match:
        multinumslash_match = multinumslash.match(word)
        if multinumslash_match:
            #duplicate non-numeric portion and append each number
            #example: MKK4/5/7/9 = MKK4, MKK5, MKK7, MKK9
            base = multinumslash_match.group(1)
            remainder = multinumslash_match.group(2) + multinumslash_match.group(3)
            for chunk in separator_split_re.split(remainder):
                if chunk:
                    result.append(base + chunk)
        elif numslash.match(word):
            #duplicate non-numeric portion and append each number
            #example: MEK1/2 = MEK1, MEK2
            numslash_match = numslash.match(word)
            base = numslash_match.group(1)
            chunks = [numslash_match.group(2), numslash_match.group(3)]
            #print('base')
            #print(base)
            for chunk in chunks:
                if chunk:
                    result.append(base + chunk)
        else:
            #split on slash
            #example: TCR/CD3 = TRC, CD3
            for chunk in separator_split_re.split(word):
                if chunk:
                    result.append(chunk)
    else:
        cleaned = separator_split_re.sub("", word)
        if cleaned:
            result.append(cleaned)

    return result;

def is_shorthand(chunk):
    # TODO how to handle SMAD1/S/8 ?
    # S should be 5
    return chunk.isdigit() or len(chunk) == 1

def expand2(word):
    chunks = separator_split_re.split(word)
    if not chunks:
        return [word]

    result = []
    base = ""
    for chunk in chunks:
        if chunk:
            if is_shorthand(chunk):
                result.append(base + chunk)
            else:
                if chunk[-1].isdigit():
                    base = end_numeric_re.sub("", chunk)
                else:
                    base = end_numeric_re.sub("", chunk[0:-1])
                result.append(chunk)
    return result

def expand(word):
    first = expand1(word)
    second = expand2(word)
    if first != second:
        #print("Warning: expand results do not match")
        print(word + " => " + ",".join(first) + " vs " + ",".join(second))
#        #raise Exception()
    return second
