import re
normalize_re = re.compile('[^a-zA-Z0-9]')

def alphanumeric(word):
    return [normalize_re.sub('', word)]
