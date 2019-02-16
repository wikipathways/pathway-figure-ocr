def truncate(string, length=40):
    truncation_indication = '...'
    return (string[:(length - len(truncation_indication))] + truncation_indication) if len(string) > length else string

