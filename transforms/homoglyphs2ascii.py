from confusable_homoglyphs import confusables


def get_tree_paths(incomplete_tree_paths, homoglyphs):
    updated_tree_paths = list()
    for incomplete_tree_path in incomplete_tree_paths:
        for homoglyph in homoglyphs:
            updated_tree_paths.append(incomplete_tree_path + homoglyph)
    return updated_tree_paths


def homoglyphs2ascii(input_str, acceptable_characters):
    tree_paths = [""]

    for c in input_str:
        # Note that 'confusables.is_confusable()' only includes homoglyphs of
        # the input character but doesn't include the input character itself.
        # 
        homoglyphs = set([c])
        
        if len(tree_paths) > 1000:
            tree_paths = get_tree_paths(tree_paths, homoglyphs)
            continue

        # TODO: if an input character is not acceptable, should we still pass
        # it along? What about if there's no acceptable homoglyph?
        #
        # homoglyphs = set()
        # if c in acceptable_characters:
        #    homoglyphs.add(c)

        results = confusables.is_confusable(
            c, preferred_aliases=[], greedy=True
        )

        if results:
            for result in results:
                for h in result["homoglyphs"]:
                    other_homoglyph = h["c"]
                    if other_homoglyph in acceptable_characters:
                        homoglyphs.add(other_homoglyph)

        tree_paths = get_tree_paths(tree_paths, homoglyphs)
        
    return tree_paths

# The confusables pkg might be too lenient in what it accepts as a homoglyph,
# plus it always accepts the other case of a character, even if they don't look
# alike, e.g., 'A' and 'a'.
#
#from confusables import confusable_characters
#
#
#def homoglyphs2ascii1(input_str, acceptable_characters):
#    tree_paths = [""]
#
#    for c in input_str:
#        homoglyphs = set(confusable_characters(c)).intersection(acceptable_characters)
#
#        if len(homoglyphs) == 0:
#            homoglyphs = set([c])
#
#        tree_paths = get_tree_paths(tree_paths, homoglyphs)
#
#    return tree_paths
