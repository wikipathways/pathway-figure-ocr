import homoglyphs as hg

hg_instance = hg.Homoglyphs(categories=hg.Categories.get_all(),
                           strategy=hg.STRATEGY_LOAD,
                           ascii_strategy=hg.STRATEGY_REMOVE)

#homoglyphs = hg.Homoglyphs(languages={
#                           'en', 'el', 'ru'},
#                           strategy=hg.STRATEGY_LOAD,
#                           ascii_strategy=hg.STRATEGY_REMOVE)


## I think this code may have been for the package confusable_homoglyphs
#def homoglyphs2ascii(input_str):
#    return hg.to_ascii(input_str)

def homoglyphs2ascii(input_str):
    return hg_instance.to_ascii(input_str)
