import re

ell_re = re.compile("[lL]")
eye_re = re.compile("[iI]")
one_re = re.compile("1")

def Ivs1vsl(word):
    Ito1 = eye_re.sub('1', word)
    result = [Ito1]

    OnetoI = one_re.sub('I', word)
    if OnetoI not in result:
        result.append(OnetoI)

    OnetoL = one_re.sub('L', word)
    if OnetoL not in result:
        result.append(OnetoL)

    Lto1 = ell_re.sub('1', word)
    if Lto1 not in result:
        result.append(Lto1)

    ItoL = eye_re.sub('L', word)
    if ItoL not in result:
        result.append(ItoL)

    LtoI = ell_re.sub('I', word)
    if LtoI not in result:
        result.append(LtoI)

    return result
