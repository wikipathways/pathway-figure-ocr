import homoglyphs as hg
homoglyphs = hg.Homoglyphs(languages={
                           'en', 'el', 'ru'},
                           strategy=hg.STRATEGY_LOAD,
                           ascii_strategy=hg.STRATEGY_REMOVE)


def homoglyphs2ascii(input_str):
    return hg.to_ascii(input_str)
