import unittest
from asciify import asciify


class TestAsciify(unittest.TestCase):

    cyrillic_text = 'МАРК8'
    latin_text = 'MAPK8'

    ae_letter = u"æ"
    cyrillic_small_letter_el = u"л"
    cyrillic_letter_small_capital_el = u"ᴫ"
    fi_ligature = u'ﬁ'


    def test_homoglyph_texts(self):
        # the input texts are homoglyphs
        self.assertNotEqual(self.cyrillic_text, self.latin_text)

        # but after asciify, they are the same and no longer homoglyphs
        self.assertEqual(
            asciify(self.cyrillic_text),
            asciify(self.latin_text))

        # 1, I and l are all ASCII, so we don't change them
        self.assertNotEqual(
            set(asciify('RIG-1')),
            set(asciify('RIG-I')))
        self.assertNotEqual(
            set(asciify('RIG-l')),
            set(asciify('RIG-I')))

    def test_ae_letter(self):
        self.assertEqual(
            set(asciify(self.ae_letter)),
            set(['ae']))

    def test_fi_ligature(self):
        self.assertEqual(set(asciify(self.fi_ligature)), set(['fi']))

    def test_not_eye_vs_ell_vs_one_vs_pipe(self):
        self.assertEqual(set(asciify('|')), set(['|']))
        self.assertEqual(set(asciify('1')), set(['1']))
        self.assertEqual(set(asciify('I')), set(['I']))
        self.assertEqual(set(asciify('l')), set(['l']))

    def test_cyrillic_small_letter_el(self):
        # No US-ASCII homoglyphs available for Cyrillic smaller letter el.
        self.assertEqual(len(asciify(self.cyrillic_small_letter_el)), 0)

    def test_number_dot_number(self):
        text = 'IM(uM)00.010.11.00.10.10.11.0'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_number_combos(self):
        text = '001411:0070310.0510102108t01609:0220.11006'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_letter_number_combos(self):
        text = '|bc001411:0070310.0510102108t01609:0220.11006'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_number_combos_letter(self):
        text = '001411:0070310.0510102108t01609:0220.11006aIc'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_letter_number_combos_letter(self):
        text = 'aIc001411:0070310.0510102108t01609:0220.11006abl'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1comma3(self):
        text = 'ABC1,3'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1slash3(self):
        text = 'ABC1/3'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1dash3(self):
        text = 'ABC1-3'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1dash3comma5(self):
        text = 'ABC1-3,5'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1dash3comma5(self):
        text = 'ABC1-3,5 and DEF8'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1and3(self):
        text = 'ABC1 and 3'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1_2and3(self):
        hgs = asciify('ABC1, 2 and 3')
        self.assertEqual(len(hgs), 1)
        hgs = asciify('ABC1, 2, and 3')
        self.assertEqual(len(hgs), 1)

    def test_ABC1andDEF2(self):
        hgs = asciify('ABC1 and DEF2')
        self.assertEqual(len(hgs), 1)

    def test_ABC1andDEF20(self):
        hgs = asciify('ABC1 and DEF20')
        self.assertEqual(len(hgs), 1)

    def test_ABC1ampersand3(self):
        text = 'ABC1 & 3'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1_2ampersand3(self):
        hgs = asciify('ABC1, 2 & 3')
        self.assertEqual(len(hgs), 1)
        hgs = asciify('ABC1, 2, & 3')
        self.assertEqual(len(hgs), 1)

    def test_ABC1ampersandDEF2(self):
        hgs = asciify('ABC1 & DEF2')
        self.assertEqual(len(hgs), 1)

    def test_ABC1ampersandDEF20(self):
        hgs = asciify('ABC1 & DEF20')
        self.assertEqual(len(hgs), 1)

    def test_ABC1or3(self):
        text = 'ABC1 or 3'
        hgs = asciify(text)
        self.assertEqual(len(hgs), 1)

    def test_ABC1_2or3(self):
        hgs = asciify('ABC1, 2 or 3')
        self.assertEqual(len(hgs), 1)
        hgs = asciify('ABC1, 2, or 3')
        self.assertEqual(len(hgs), 1)

    def test_ABC1orDEF2(self):
        hgs = asciify('ABC1 or DEF2')
        self.assertEqual(len(hgs), 1)

    def test_ABC1orDEF20(self):
        hgs = asciify('ABC1 or DEF20')
        self.assertEqual(len(hgs), 1)

    def test_nnn222n2222inmimimmmmimmmimimmmmmmmminunntnnummmmmnmnnminnm(self):
        hgs = asciify('nnn222n2222inmimimmmmimmmimimmmmmmmminunntnnummmmmnmnnminnm')
        self.assertEqual(len(hgs), 1)

    def test_EdashDGSILICLYESYFDPGKSISENIVSdashFIEKSYKSIFVL(self):
        hgs = asciify('E-DGSILICLYESYFDPGKSISENIVS-FIEKSYKSIFVL')
        self.assertEqual(len(hgs), 1)

    def test_EmodinOmmol0mmolM5mmol10mmolslash15mmo15mmoM15mmolM(self):
        hgs = asciify('EmodinOmmol0mmolM5mmol10mmol/15mmo15mmoM15mmolM')
        self.assertEqual(len(hgs), 1)

    def test_IIIIIIIII11IIIIIIIIII(self):
        hgs = asciify('IIIIIIIII11IIIIIIIIII')
        self.assertEqual(len(hgs), 1)

    def test_IIIIIIIIIIIIIIIIIII(self):
        hgs = asciify('IIIIIIIIIIIIIIIIIII')
        self.assertEqual(len(hgs), 1)

    def test_NSICSIl4ICSII8ICSII(self):
        hgs = asciify('NSICSIl4ICSII8ICSII')
        self.assertEqual(len(hgs), 1)

    def test_NSICSII16NSICSIl4ICSII8ICSII16(self):
        hgs = asciify('NSICSII16NSICSIl4ICSII8ICSII16')
        self.assertEqual(len(hgs), 1)

    def test_tab(self):
        hgs = asciify('ABC\tDEF')
        self.assertEqual(hgs, ['ABC\tDEF'])

    def test_cr(self):
        hgs = asciify('ABC\rDEF')
        self.assertEqual(hgs, ['ABC\rDEF'])

    def test_cr_newline(self):
        hgs = asciify('ABC\r\nDEF')
        self.assertEqual(hgs, ['ABC\r\nDEF'])

    def test_newline(self):
        hgs = asciify('ABC\nDEF')
        self.assertEqual(hgs, ['ABC\nDEF'])

    def test_clean_string(self):
        hgs = asciify('CC LA1 NFKBIE\nTNFAIP6\n')
        self.assertEqual(set(hgs), {'CC LA1 NFKBIE\nTNFAIP6\n'})

    def test_messy_string(self):
        hgs = asciify('CC LA1 NFKBIE\nTNFAIP6\n白\n')
        self.assertEqual(set(hgs), {'CC LA1 NFKBIE\nTNFAIP6\n\n'})

    def test_full_text_sample(self):
        long_input = '''
CC LA1 NFKBIE\nTNFAIP6\n白\nControl\nCancer1\nNFKBIA\nCXCL3\nNormal 1\nCancer 2\nNormal 2\nCancer 3\n·Query gene\nOther gene\nNormal\nCancerous\nRelationship confidenceTranscription factor\nQuery Gene Gene Description\n1. GRO-a4. C\n2. IL-8\n3. CXCL7\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nNFKB1\n5. IL-16\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 2 (p49/p100)\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nCXCL1\nnuclear factor of kappa light polypeptide27\ngene enhancer in B-cells 2 (p49/p100)\nCXCL1\nNFkB2\n0.9279 .\nD\nNormalization of GRO-a & IL-8 by dry mass of omental tissue\nconcentration of GRO-α\nand IL-8 in OCM\nP= 0.56\n*P = 0.04\n2 0.0\nO Normal Cancerous\nNormal Cancerous\nGRO-a & IL-8 expression in\nES-2 cells with IL-8 treatment\n*P <0.05\nH&E\nGRO-a\nDIL-8\nIL-8 (ng/ml)\nGRO-a& IL-8expression in\nES-2 cells with GRO-a treatment\nOIL-8\n*P <0.01\nGRO-a (ng/mL)\n
'''
        expected = '''
CC LA1 NFKBIE\nTNFAIP6\n\nControl\nCancer1\nNFKBIA\nCXCL3\nNormal 1\nCancer 2\nNormal 2\nCancer 3\nQuery gene\nOther gene\nNormal\nCancerous\nRelationship confidenceTranscription factor\nQuery Gene Gene Description\n1. GRO-a4. C\n2. IL-8\n3. CXCL7\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nNFKB1\n5. IL-16\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 2 (p49/p100)\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nCXCL1\nnuclear factor of kappa light polypeptide27\ngene enhancer in B-cells 2 (p49/p100)\nCXCL1\nNFkB2\n0.9279 .\nD\nNormalization of GRO-a & IL-8 by dry mass of omental tissue\nconcentration of GRO-a\nand IL-8 in OCM\nP= 0.56\n*P = 0.04\n2 0.0\nO Normal Cancerous\nNormal Cancerous\nGRO-a & IL-8 expression in\nES-2 cells with IL-8 treatment\n*P <0.05\nH&E\nGRO-a\nDIL-8\nIL-8 (ng/ml)\nGRO-a& IL-8expression in\nES-2 cells with GRO-a treatment\nOIL-8\n*P <0.01\nGRO-a (ng/mL)\n
'''
        hgs = asciify(long_input)
        self.assertEqual(set(hgs), {expected})

        
if __name__ == '__main__':
    unittest.main()
