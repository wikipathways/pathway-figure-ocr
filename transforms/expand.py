import re

# we want to be able to get rid of a multi-digit number at the end, e.g., WNT11 => WNT
end_numeric_re = re.compile('[0-9]+$')
range_re = re.compile('(.*?)(\w+[a-zA-Z])([0-9]+)\-([0-9]+)(.*?)')
shorthand_re = re.compile("\/|,(?=\d)|\-(?=\d)|\&(?=\d)")
# to see examples of each of these in use, run this type of query:
# grep -P "\&\ .*\=\>" successes.txt
# grep -P "\ and>" successes.txt
# grep -P "\ or\ " successes.txt
# grep -P "[↑→↓←]" successes.txt
separator_re = re.compile("\ |\ \/\ |\ ?\&\ ?|\ and\ |\ or\ |\|(?=\D)|\-(?=\D\D)|,(?=\D)|\/(?=\D[^\/])|↑|→|↓|←|个|\-+\>|\<\-+")
separator_san_space_re = re.compile("\ \/\ |\ ?\&\ ?|\ and\ |\ or\ |\|(?=\D)|\-(?=\D\D)|,(?=\D)|\/(?=\D[^\/])|↑|→|↓|←|个|\-+\>|\<\-+")
#separator_re = re.compile("\ |\ \/\ |\ ?\&\ ?|\ and\ |\ or\ |\-(?=\D\D)|,(?=\D\D)|\/(?=\D[^\/])|↑|→|↓|←|↔|↕|↖|↗|↘|↙|⟵|⟶|⟷")
#separators = ["\ ", "\ \& \ ", "\ and \ ", "\ or \ ", "\/(?=\D[^\/])"]

# Overall plan:
# Case 1: chunks are digits or single character, e.g., KDM6A/B and WNT9/10
# Case 2: chunks are all assumed to be 2 character, e.g., 5-HT2A/2B
# Case 3: chunks are separate gene symbols, e.g., WNT5/ABP2

def is_shorthand(chunk):
    # a chunk here could be SMAD1, 5 or 8 from SMAD1/5/8 

    # allow digits, e.g., SMAD1/5/8 and 2 character cases, e.g., 5-HT2A/2B
    return chunk.isdigit() or len(chunk) <= 2

def expand(word):
    if not word:
        return []

    chunks = set()
    chunks.add(word)

    for c in separator_re.split(word):
        if c:
            chunks.add(c)

    for c in separator_san_space_re.split(word):
        if c:
            chunks.add(c)

    for chunk in list(chunks):
        for c in separator_san_space_re.split(chunk):
            if c:
                chunks.add(c)

    # TODO do we want to broaden this further? Something kind of like what's below?
    #    for separator in separators:
    #        separator_re = re.compile(separator)
    #        # adding word split separate from chunk split to handle this case with a bad space: ME K1/2
    #        # splitting first on space and then only splitting chunks by slash would yield this:
    #        # ["ME", "K1", "K2"]
    #        # but this is better, because it can be handled by alphanumeric:
    #        # ["ME", "K1", "K2", "ME K1", "ME K2"]
    #        for c in separator_re.split(word):
    #            chunks.add(c)
    #        for chunk in list(chunks):
    #            for c in separator_re.split(chunk):
    #                chunks.add(c)

    for chunk in list(chunks):
        # expand Smad1-3 to Smad1, Smad2, Smad3
        m = range_re.match(chunk)
        if m:
            start = m.group(1)
            base = m.group(2)
            range_start = int(m.group(3))
            range_end = int(m.group(4))
            end = m.group(5)
            if range_start < range_end:
                for i in range(range_start, range_end + 1):
                    chunks.add(start + base + str(i) + end)

    result = set()
    for c in list(chunks):
        bases = [""]
        for chunk in shorthand_re.split(c):
            if chunk:
                if is_shorthand(chunk):
                    # example of shorthand chunk: 5 from SMAD1/5/8
                    for base in bases:
                        if len(base) == 0:
                            # This case probably shouldn't happen, where there's a shorthand chunk with an empty base.
                            # But if it does, I guess we can add it as a candidate to test for whether it's a hit
                            result.add(chunk)
                        else:
                            # Concatenate shorthand chunk with base, e.g.: SMAD + 5 from SMAD1/5/8.

                            # Example: KDM6 from KDM6A/B
                            base_ends_in_digit = base[-1].isdigit()

                            # Example: 5 from SMAD1/5/8
                            chunk_starts_as_digit = chunk[0].isdigit()

                            # We avoid mashing together two numbers, e.g.,
                            # 5-HT2A/2B yields 5-HT2A and 5-HT2B but NOT HT22B.
                            if not (base_ends_in_digit and chunk_starts_as_digit):
                                result.add(base + chunk)
                else:
                    # example of a NON-shorthand chunk: SMAD1 from SMAD1/5/8

                    # define base
                    if chunk[-1].isdigit():
                        bases = [end_numeric_re.sub("", chunk)]
                    else:
                        # TODO what about this one? IL-17A/F => IL-17F & IL-17A & ILF
                        # should we only use base2?
                        # note: can't assume same length, e.g,. WNT9/10
                        # for example, KDM6A from KDM6A/B
                        base1 = chunk[0:-1]
                        # for example, 5-HT2A/2B
                        base2 = end_numeric_re.sub("", base1)
                        bases = [base1, base2]

                    # add chunk as a candidate to test for whether it's a hit
                    result.add(chunk)
    return list(result)
