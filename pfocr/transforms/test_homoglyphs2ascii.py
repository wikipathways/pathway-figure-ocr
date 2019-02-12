import unittest
from homoglyphs2ascii import homoglyphs2ascii, get_homoglyphs_for_char


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

        # but after homoglyphs2ascii, they are the same and no longer homoglyphs
        self.assertEqual(
            set(get_homoglyphs_for_char(hangul_choseong_khieukh)),
            set(get_homoglyphs_for_char(hangul_jongseong_khieukh)))

        self.assertEqual(
            set(get_homoglyphs_for_char(hangul_choseong_khieukh)),
            set(get_homoglyphs_for_char(hangul_letter_khieukh)))

        self.assertEqual(
            set(get_homoglyphs_for_char(hangul_jongseong_khieukh)),
            set(get_homoglyphs_for_char(hangul_letter_khieukh)))

    def test_hangul_letter_eu_homoglyphs(self):
        hangul_letter_eu_homoglyph1 = '_'
        hangul_letter_eu_homoglyph2 = u"\u3161"

        self.assertNotEqual('_', 'ㅡ')
        self.assertNotEqual('_', 'abcㅡ')
        self.assertNotEqual('_', u"\u3161")
        self.assertNotEqual('_', 'abc' + u"\u3161")

        # the input texts are homoglyphs
        self.assertNotEqual(hangul_letter_eu_homoglyph1, hangul_letter_eu_homoglyph2)

        # The following test fails so is commented out.
        # See https://github.com/orsinium/homoglyphs/issues/9#issuecomment-458640294
#        self.assertEqual(
#            set(get_homoglyphs_for_char(hangul_letter_eu_homoglyph1)),
#            set(get_homoglyphs_for_char(hangul_letter_eu_homoglyph2)))

    def test_homoglyph_texts(self):
        # the input texts are homoglyphs
        self.assertNotEqual(self.cyrillic_text, self.latin_text)

        # but after homoglyphs2ascii, they are the same and no longer homoglyphs
        self.assertEqual(
            homoglyphs2ascii(self.cyrillic_text),
            homoglyphs2ascii(self.latin_text))

        self.assertEqual(
            set(homoglyphs2ascii('RIG-1')),
            set(homoglyphs2ascii('RIG-I')))

        self.assertEqual(
            set(homoglyphs2ascii('RIG-l')),
            set(homoglyphs2ascii('RIG-I')))

    def test_ae_letter(self):
        self.assertEqual(
            set(homoglyphs2ascii(self.ae_letter)),
            set(['ae']))

    def test_fi_ligature(self):
        self.assertEqual(set(homoglyphs2ascii(self.fi_ligature)), set(['fi']))

    def test_eye_vs_ell_vs_one_vs_pipe(self):
        expected = set(['|', '1', 'I', 'l'])
        self.assertEqual(set(homoglyphs2ascii('|')), expected)
        self.assertEqual(set(homoglyphs2ascii('1')), expected)
        self.assertEqual(set(homoglyphs2ascii('I')), expected)
        self.assertEqual(set(homoglyphs2ascii('l')), expected)

    def test_cyrillic_small_letter_el(self):
        self.assertEqual(
            set(get_homoglyphs_for_char(self.cyrillic_small_letter_el)),
            set([
                self.cyrillic_small_letter_el,
                self.cyrillic_letter_small_capital_el]))

        # No US-ASCII homoglyphs available for Cyrillic smaller letter el.
        self.assertEqual(len(homoglyphs2ascii(self.cyrillic_small_letter_el)), 0)

## TODO: Doesn't currently work well if at all. Too long.
#    def test_number_dot_number(self):
#        text = 'IM(uM)00.010.11.00.10.10.11.0'
#        hgs = homoglyphs2ascii(text)
#        self.assertEqual(len(hgs), 4)
#
## TODO: Doesn't currently work well if at all. Too long.
#    def test_number_combos(self):
#        text = '001411:0070310.0510102108t01609:0220.11006'
#        hgs = homoglyphs2ascii(text)
#        self.assertEqual(len(hgs), 1)
#
## TODO: Doesn't currently work well if at all. Too long.
#    def test_letter_number_combos(self):
#        text = '|bc001411:0070310.0510102108t01609:0220.11006'
#        hgs = homoglyphs2ascii(text)
#        self.assertEqual(len(hgs), 1)
#
## TODO: Doesn't currently work well if at all. Too long.
#    def test_number_combos_letter(self):
#        text = '001411:0070310.0510102108t01609:0220.11006aIc'
#        hgs = homoglyphs2ascii(text)
#        self.assertEqual(len(hgs), 1)
#
## TODO: Doesn't currently work well if at all. Too long.
#    def test_letter_number_combos_letter(self):
#        text = 'aIc001411:0070310.0510102108t01609:0220.11006abl'
#        hgs = homoglyphs2ascii(text)
#        self.assertEqual(len(hgs), 1)

    def test_ABC1comma3(self):
        text = 'ABC1,3'
        hgs = homoglyphs2ascii(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1slash3(self):
        text = 'ABC1/3'
        hgs = homoglyphs2ascii(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1dash3(self):
        text = 'ABC1-3'
        hgs = homoglyphs2ascii(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1dash3comma5(self):
        text = 'ABC1-3,5'
        hgs = homoglyphs2ascii(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1dash3comma5(self):
        text = 'ABC1-3,5 and DEF8'
        hgs = homoglyphs2ascii(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1and3(self):
        text = 'ABC1 and 3'
        hgs = homoglyphs2ascii(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1_2and3(self):
        hgs = homoglyphs2ascii('ABC1, 2 and 3')
        self.assertEqual(len(hgs), 1)
        hgs = homoglyphs2ascii('ABC1, 2, and 3')
        self.assertEqual(len(hgs), 1)

    def test_ABC1andDEF2(self):
        hgs = homoglyphs2ascii('ABC1 and DEF2')
        self.assertEqual(len(hgs), 4)

    def test_ABC1andDEF20(self):
        hgs = homoglyphs2ascii('ABC1 and DEF20')
        self.assertEqual(len(hgs), 4)

    def test_ABC1ampersand3(self):
        text = 'ABC1 & 3'
        hgs = homoglyphs2ascii(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1_2ampersand3(self):
        hgs = homoglyphs2ascii('ABC1, 2 & 3')
        self.assertEqual(len(hgs), 1)
        hgs = homoglyphs2ascii('ABC1, 2, & 3')
        self.assertEqual(len(hgs), 1)

    def test_ABC1ampersandDEF2(self):
        hgs = homoglyphs2ascii('ABC1 & DEF2')
        self.assertEqual(len(hgs), 4)

    def test_ABC1ampersandDEF20(self):
        hgs = homoglyphs2ascii('ABC1 & DEF20')
        self.assertEqual(len(hgs), 4)

    def test_ABC1or3(self):
        text = 'ABC1 or 3'
        hgs = homoglyphs2ascii(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1_2or3(self):
        hgs = homoglyphs2ascii('ABC1, 2 or 3')
        self.assertEqual(len(hgs), 1)
        hgs = homoglyphs2ascii('ABC1, 2, or 3')
        self.assertEqual(len(hgs), 1)

    def test_ABC1orDEF2(self):
        hgs = homoglyphs2ascii('ABC1 or DEF2')
        self.assertEqual(len(hgs), 4)

    def test_ABC1orDEF20(self):
        hgs = homoglyphs2ascii('ABC1 or DEF20')
        self.assertEqual(len(hgs), 4)

## TODO: Doesn't currently work well if at all. Too long.
#    def test_nnn222n2222inmimimmmmimmmimimmmmmmmminunntnnummmmmnmnnminnm(self):
#        hgs = homoglyphs2ascii('nnn222n2222inmimimmmmimmmimimmmmmmmminunntnnummmmmnmnnminnm')
#        self.assertEqual(len(hgs), 1)
#
## TODO: Doesn't currently work well if at all. Too long.
#    def test_EdashDGSILICLYESYFDPGKSISENIVSdashFIEKSYKSIFVL(self):
#        hgs = homoglyphs2ascii('E-DGSILICLYESYFDPGKSISENIVS-FIEKSYKSIFVL')
#        self.assertEqual(len(hgs), 4096)
#
## TODO: Doesn't currently work well if at all. Too long.
#    def test_EmodinOmmol0mmolM5mmol10mmolslash15mmo15mmoM15mmolM(self):
#        hgs = homoglyphs2ascii('EmodinOmmol0mmolM5mmol10mmol/15mmo15mmoM15mmolM')
#        self.assertEqual(len(hgs), 1)
#
## TODO: Doesn't currently work well if at all. Too long.
#    def test_IIIIIIIII11IIIIIIIIII(self):
#        hgs = homoglyphs2ascii('IIIIIIIII11IIIIIIIIII')
#        self.assertEqual(len(hgs), 1)

## TODO: Doesn't currently work well if at all. Too long.
#    def test_IIIIIIIIIIIIIIIIIII(self):
#        hgs = homoglyphs2ascii('IIIIIIIIIIIIIIIIIII')
#        self.assertEqual(len(hgs), 1)

    def test_NSICSIl4ICSII8ICSII(self):
        hgs = homoglyphs2ascii('NSICSIl4ICSII8ICSII')
        self.assertEqual(len(hgs), 262144)

## TODO: Gives a warning about being too long.
#    def test_NSICSII16NSICSIl4ICSII8ICSII16(self):
#        hgs = homoglyphs2ascii('NSICSII16NSICSIl4ICSII8ICSII16')
#        self.assertEqual(len(hgs), 1)
        
if __name__ == '__main__':
    unittest.main()
