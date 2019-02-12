import unittest
from homoglyphs2symbol_chars import homoglyphs2symbol_chars, get_homoglyphs_for_char


class TestHomoglyphs(unittest.TestCase):

    cyrillic_text = 'МАРК8'
    latin_text = 'MAPK8'

    ae_letter = u"æ"
    cyrillic_small_letter_el = u"л"
    cyrillic_letter_small_capital_el = u"ᴫ"
    fi_ligature = u'ﬁ'

    def test_hangul_khieukh(self):
        hangul_choseong_khieukh = u"\u110F"
        hangul_jongseong_khieukh = u"\u11BF"
        hangul_letter_khieukh = u"\u314B"

        # the input texts are homoglyphs
        self.assertNotEqual(hangul_choseong_khieukh, hangul_jongseong_khieukh)
        self.assertNotEqual(hangul_choseong_khieukh, hangul_letter_khieukh)
        self.assertNotEqual(hangul_jongseong_khieukh, hangul_letter_khieukh)

        # but after homoglyphs2symbol_chars, they are the same and no longer homoglyphs
        self.assertEqual(
            set(get_homoglyphs_for_char(hangul_choseong_khieukh)),
            set(get_homoglyphs_for_char(hangul_jongseong_khieukh)))

        self.assertEqual(
            set(get_homoglyphs_for_char(hangul_choseong_khieukh)),
            set(get_homoglyphs_for_char(hangul_letter_khieukh)))

        self.assertEqual(
            set(get_homoglyphs_for_char(hangul_jongseong_khieukh)),
            set(get_homoglyphs_for_char(hangul_letter_khieukh)))

#    def test_hangul_letter_eu_homoglyphs(self):
#        hangul_letter_eu_homoglyph1 = '_'
#        hangul_letter_eu_homoglyph2 = u"\u3161"
#
#        self.assertNotEqual('_', 'ㅡ')
#        self.assertNotEqual('_', 'abcㅡ')
#        self.assertNotEqual('_', u"\u3161")
#        self.assertNotEqual('_', 'abc' + u"\u3161")
#
#        # the input texts are homoglyphs
#        self.assertNotEqual(hangul_letter_eu_homoglyph1, hangul_letter_eu_homoglyph2)
#
##        # TODO: The following test fails so both it and the entire test is commented out.
##        # See https://github.com/orsinium/homoglyphs/issues/9#issuecomment-458640294
##        self.assertEqual(
##            set(get_homoglyphs_for_char(hangul_letter_eu_homoglyph1)),
##            set(get_homoglyphs_for_char(hangul_letter_eu_homoglyph2)))

    def test_homoglyph_texts(self):
        # the input texts are homoglyphs
        self.assertNotEqual(self.cyrillic_text, self.latin_text)

        # but after homoglyphs2symbol_chars, they are the same and no longer homoglyphs
        self.assertEqual(
            homoglyphs2symbol_chars(self.cyrillic_text),
            homoglyphs2symbol_chars(self.latin_text))

        self.assertEqual(
            set(homoglyphs2symbol_chars('RIG-1')),
            set(homoglyphs2symbol_chars('RIG-I')))

        self.assertEqual(
            set(homoglyphs2symbol_chars('RIG-l')),
            set(homoglyphs2symbol_chars('RIG-I')))

    def test_ae_letter(self):
        self.assertEqual(
            set(homoglyphs2symbol_chars(self.ae_letter)),
            set(['ae']))

    def test_fi_ligature(self):
        self.assertEqual(set(homoglyphs2symbol_chars(self.fi_ligature)), set(['fi']))

    def test_eye_vs_ell_vs_one_vs_pipe(self):
        expected = set(['1', 'I', 'l'])
        # TODO: should we expect pipe when it's in the input but not in
        #       any character in the symbols?
        # Currently, it's not included, but in the past, we have included it.
        self.assertEqual(set(homoglyphs2symbol_chars('|')), set(['1', 'I', 'l']))
        self.assertEqual(set(homoglyphs2symbol_chars('1')), expected)
        self.assertEqual(set(homoglyphs2symbol_chars('I')), expected)
        self.assertEqual(set(homoglyphs2symbol_chars('l')), expected)

    def test_cyrillic_small_letter_el(self):
        self.assertEqual(
            set(get_homoglyphs_for_char(self.cyrillic_small_letter_el)),
            set([
                self.cyrillic_small_letter_el,
                self.cyrillic_letter_small_capital_el]))

        # No US-ASCII homoglyphs available for Cyrillic smaller letter el.
        self.assertEqual(len(homoglyphs2symbol_chars(self.cyrillic_small_letter_el)), 0)

    def test_number_dot_number(self):
        text = 'IM(uM)00.010.11.00.10.10.11.0'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 3)

    def test_number_combos(self):
        text = '001411:0070310.0510102108t01609:0220.11006'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 1)

    def test_letter_number_combos(self):
        text = '|bc001411:0070310.0510102108t01609:0220.11006'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 3)

    def test_number_combos_letter(self):
        text = '001411:0070310.0510102108t01609:0220.11006aIc'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 3)

    def test_letter_number_combos_letter(self):
        text = 'aIc001411:0070310.0510102108t01609:0220.11006abl'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 9)

    def test_ABC1c3(self):
        text = 'ABC1,3'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1slash3(self):
        text = 'ABC1/3'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1dash3(self):
        text = 'ABC1-3'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1dash3c5(self):
        text = 'ABC1-3,5'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1dash3c5_and_DEF8(self):
        text = 'ABC1-3,5 and DEF8'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1_and_3(self):
        text = 'ABC1 and 3'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1c_2_and_3(self):
        hgs = homoglyphs2symbol_chars('ABC1, 2 and 3')
        self.assertEqual(len(hgs), 1)

    def test_ABC1c_2c_and_3(self):
        hgs = homoglyphs2symbol_chars('ABC1, 2, and 3')
        self.assertEqual(len(hgs), 1)

    def test_ABC1_and_DEF2(self):
        hgs = homoglyphs2symbol_chars('ABC1 and DEF2')
        self.assertEqual(set(hgs), set(['ABC1 and DEF2', 'ABCl and DEF2', 'ABCI and DEF2']))

    def test_ABC1_and_DEF20(self):
        hgs = homoglyphs2symbol_chars('ABC1 and DEF20')
        self.assertEqual(set(hgs), set(['ABC1 and DEF20', 'ABCl and DEF20', 'ABCI and DEF20']))

    def test_ABC1ampersand3(self):
        text = 'ABC1 & 3'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1_2ampersand3(self):
        hgs = homoglyphs2symbol_chars('ABC1, 2 & 3')
        self.assertEqual(set(hgs), set(['ABC1, 2 & 3']))
        hgs = homoglyphs2symbol_chars('ABC1, 2, & 3')
        self.assertEqual(set(hgs), set(['ABC1, 2, & 3']))

    def test_ABC1ampersandDEF2(self):
        hgs = homoglyphs2symbol_chars('ABC1 & DEF2')
        self.assertEqual(set(hgs), set(['ABC1 & DEF2', 'ABCl & DEF2', 'ABCI & DEF2']))
                                       

    def test_ABC1ampersandDEF20(self):
        hgs = homoglyphs2symbol_chars('ABC1 & DEF20')
        self.assertEqual(set(hgs), set(['ABC1 & DEF20', 'ABCl & DEF20', 'ABCI & DEF20']))

    def test_ABC1or3(self):
        text = 'ABC1 or 3'
        hgs = homoglyphs2symbol_chars(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1_2or3(self):
        hgs = homoglyphs2symbol_chars('ABC1, 2 or 3')
        self.assertEqual(len(hgs), 1)
        hgs = homoglyphs2symbol_chars('ABC1, 2, or 3')
        self.assertEqual(len(hgs), 1)

    def test_ABC1orDEF2(self):
        hgs = homoglyphs2symbol_chars('ABC1 or DEF2')
        self.assertEqual(set(hgs), set(['ABC1 or DEF2', 'ABCl or DEF2', 'ABCI or DEF2']))

    def test_ABC1orDEF20(self):
        hgs = homoglyphs2symbol_chars('ABC1 or DEF20')
        self.assertEqual(len(hgs), 3)

## TODO: Currently times out.
#    def test_nnn222n2222inmimimmmmimmmimimmmmmmmminunntnnummmmmnmnnminnm(self):
#        hgs = homoglyphs2symbol_chars('nnn222n2222inmimimmmmimmmimimmmmmmmminunntnnummmmmnmnnminnm')
#        self.assertEqual(len(hgs), 1)

    def test_EdashDGSILICLYESYFDPGKSISENIVSdashFIEKSYKSIFVL(self):
        hgs = homoglyphs2symbol_chars('E-DGSILICLYESYFDPGKSISENIVS-FIEKSYKSIFVL')
        self.assertEqual(len(hgs), 729)

## TODO: Currently times out.
#    def test_EmodinOmmol0mmolM5mmol10mmolslash15mmo15mmoM15mmolM(self):
#        hgs = homoglyphs2symbol_chars('EmodinOmmol0mmolM5mmol10mmol/15mmo15mmoM15mmolM')
#        self.assertEqual(len(hgs), 1)

## TODO: Doesn't currently work well, if at all.
#    def test_IIIIIIIII11IIIIIIIIII(self):
#        hgs = homoglyphs2symbol_chars('IIIIIIIII11IIIIIIIIII')
#        self.assertEqual(len(hgs), 1)
#
## TODO: Doesn't currently work well, if at all.
#    def test_IIIIIIIIIIIIIIIIIII(self):
#        hgs = homoglyphs2symbol_chars('IIIIIIIIIIIIIIIIIII')
#        self.assertEqual(len(hgs), 1)

    def test_NSICSIl4ICSII8ICSII(self):
        hgs = homoglyphs2symbol_chars('NSICSIl4ICSII8ICSII')
        self.assertEqual(len(hgs), 19683)

    def test_NSICSII16NSICSIl4ICSII8ICSII16(self):
        hgs = homoglyphs2symbol_chars('NSICSII16NSICSIl4ICSII8ICSII16')
        self.assertEqual(len(hgs), 531441)
        
if __name__ == '__main__':
    unittest.main()
