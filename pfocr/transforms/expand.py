import re

# Overall plan:
# Case 1: chunks are digits or single character, e.g., KDM6A/B and WNT9/10
# Case 2: chunks are all assumed to be 2 character, e.g., 5-HT2A/2B
# Case 3: chunks are separate gene symbols, e.g., WNT5/ABP2

# FUTURE CASES TO HANDLE?
# TGF-β1-3 

slash_chunks_re = re.compile("\s*[\/|,&]+\s*")
slash_root_1a_re = re.compile("(.+?)\d[\d\w]*\s*[\/|,&]+\s*\d+")
slash_root_1b_re = re.compile("(.+?)\w\s*[\/|,&]+\s*\w")
slash_root_2a_re = re.compile("(.+?)\d\w*\s*[\/|,&]+\s*\d\w")
slash_root_2b_re = re.compile("(.+?)\w\d*\s*[\/|,&]+\s*\w\d")
dash_chunks_re = re.compile("\-")
dash_from_digit_re = re.compile(".+?\D(\d+)\-\d+") #need non-digit \D check to avoid memory leak cases
dash_root_re = re.compile("(.+?)\d+\-\d+")

def expand(word):
    if not word:
        return []

    word = word.strip('/').strip(',').strip(' ').strip('&').strip('|')
    slash_split = slash_chunks_re.split(word)
    dash_split = dash_chunks_re.split(word)
    result = set()

    # Slash Cases
    if len(slash_split) > 1:
        last_chunk = slash_split[-1]

        # Case 1a: chunks are digits, e.g.,  WNT9/10, WNT11/4/15
        if last_chunk.isdigit():
            m = slash_root_1a_re.match(word)
            result.update(get_expanded_results(m,slash_split))
            return(list(result))

        # Case 1b: chunk is single character, e.g., KDM6A/B, HCKA/B/C
        if len(last_chunk) == 1:
            m = slash_root_1b_re.match(word)
            result.update(get_expanded_results(m,slash_split))
            return(list(result))

        # Case 2: chunks are all assumed to be 2 character, e.g., 5-HT2A/2B
        elif len(last_chunk) == 2:
            if last_chunk[0].isdigit():
                m = slash_root_2a_re.match(word)
                result.update(get_expanded_results(m,slash_split))
                return(list(result))
            else:  # e.g., VSPR1/R2
                m = slash_root_2b_re.match(word)
                result.update(get_expanded_results(m,slash_split))
                return(list(result))

        # Case 3: chunks are separate gene symbols, e.g., WNT5/ABP2
        elif len(last_chunk) > 2:
            for c in slash_split:
                result.update(check_dash_case(c))
            return(list(result))

        else:
            return(word)

    else:
        result.update(check_dash_case(word))
        return(list(result))

def get_expanded_results(match,split):
    expres = set()
    root = split[0] #fallback in case match fails
    if match is not None:
        root = match.group(1)
    expres.add(split[0])
    for c in split[1:]:
        expres.add(root + c)
    return(expres)

def check_dash_case(word):
    dash_set = set()
    dash_split = dash_chunks_re.split(word)
    if len(dash_split) == 2:
        last_chunk = dash_split[-1]
        if last_chunk.rstrip(',').isdigit():
            to_digit = int(last_chunk.rstrip(','))
            if not dash_from_digit_re.match(word) is None:
                from_digit = int(dash_from_digit_re.match(word).group(1))
                # The to_digit - from_digit check is needed to avoid hanging on cases like this:
                # 3VIT19-001490329014
                if from_digit < to_digit and to_digit - from_digit < 30:
                    root = dash_root_re.match(word).group(1)
                    for d in range(from_digit, to_digit + 1):
                        dash_set.add(root + str(d))
                    return(dash_set)

    dash_set.add(word)
    return(dash_set) 

