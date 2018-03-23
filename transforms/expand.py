import re

end_numeric_re = re.compile('[0-9]+$')
separator_split_re = re.compile('\/')

def is_shorthand(chunk):
    # TODO how to handle SMAD1/S/8 ?
    # S should be 5
    return chunk.isdigit() or len(chunk) == 1

def expand(word):
    chunks = separator_split_re.split(word)
    if not chunks:
        return [word]

    result = set()
    bases = [""]
    for chunk in chunks:
        if chunk:
            if is_shorthand(chunk):
                for base in bases:
                    if len(base) == 0:
                        result.add(chunk)
                    else:
                        base_ends_d = base[-1].isdigit()
                        chunk_ends_d = chunk[-1].isdigit()
                        if base_ends_d != chunk_ends_d or not chunk_ends_d:
                            result.add(base + chunk)
            else:
                if chunk[-1].isdigit():
                    bases = [end_numeric_re.sub("", chunk)]
                else:
                    base1 = chunk[0:-1]
                    base2 = end_numeric_re.sub("", base1)
                    bases = [base1, base2]
                result.add(chunk)
    return list(result)
