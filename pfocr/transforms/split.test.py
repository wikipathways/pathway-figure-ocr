import unittest
from split import split

class TestSplit(unittest.TestCase):

    cyrillic_text = 'МАРК8'
    latin_text = 'MAPK8'

    def test_Relative_Pimdash2_mRNA_expression(self):
        results = split('Relative Pim-2 mRNA expression')
        self.assertTrue(
            'Pim-2' in set(results))
        
    def test_Pimdash2(self):
        results = split('Pim-2')
        self.assertTrue(
            'Pim-2' in set(results))
#        self.assertEqual(
#            set({'Pim-2'}),
#            set(results))
        
    def test_ABLspaceFAMILY_alone(self):
        results = split('ABL FAMILY')
        self.assertEqual(
            set({'ABLFAMILY', 'ABL FAMILY', 'ABL', 'FAMILY'}),
            set(results))

    def test_ABLspaceFAMILY_in_string(self):
        results = split('The ABL FAMILY observed in vitro')
        self.assertTrue(
            'ABL FAMILY' in set(results))

    def test_ABLunderscoreFAMILY_alone(self):
        results = split('ABL_FAMILY')
        self.assertEqual(
            set({'ABL_FAMILY'}),
            set(results))

    def test_ABLunderscoreFAMILY_in_string(self):
        results = split('The ABL_FAMILY observed in vitro')
        self.assertTrue(
            'ABL_FAMILY' in set(results))

    def test_ABC1c_2_and_4(self):
        results = split('ABC1, 2 and 4')
        self.assertEqual(
            set({'ABC1, 2 and 4'}),
            set(results))

    def test_ABC1c2_and_4(self):
        results = split('ABC1,2 and 4')
        self.assertEqual(
            set({'ABC1,2 and 4'}),
            set(results))

    def test_ABC1comma2and4_in_string(self):
        results = split('The ABC1,2 and 4 observed in vitro')
        self.assertTrue(
            'ABC1,2 and 4' in set(results))

    def test_ABC1comma2dash4_in_string(self):
        results = split('The ABC1,2-4 observed in vitro')
        self.assertTrue(
            'ABC1,2-4' in set(results))

    def test_cyrillic_text_alone(self):
        results = split(self.cyrillic_text)
        self.assertEqual(
            set({self.cyrillic_text}),
            set(results))

    def test_cyrillic_text_in_string(self):
        results1 = split(self.cyrillic_text + ' and ABC1,2-4 observed in vitro')
        self.assertTrue(
            (self.cyrillic_text + ' and ABC1,2-4') in set(results1))

        results2 = split("Initially ABC1,2-4 and %s observed in vitro" % self.cyrillic_text)
        self.assertTrue(
            ('ABC1,2-4 and ' + self.cyrillic_text) in set(results2))

    def test_Rap_arrow_Rae(self):
        results = split("Rap↑Rae")
        self.assertTrue('Rap' in set(results))
        self.assertTrue('Rae' in set(results))

    def test_Rap_space_arrow_space_Rae(self):
        results = split("Rap ↑ Rae")
        self.assertTrue('Rap' in set(results))
        self.assertTrue('Rae' in set(results))

    def test_Rap_space_arrow(self):
        results = split("Rap ↑")
        self.assertTrue('Rap' in set(results))

    def test_space_arrow_Rap(self):
        results = split(" ↑Rap")
        self.assertTrue('Rap' in set(results))

    def test_arrow_space_Rap(self):
        results = split("↑ Rap")
        self.assertTrue('Rap' in set(results))

    def test_arrow_Rap(self):
        results = split("↑Rap")
        self.assertTrue('Rap' in set(results))

    def test_Rap_newline_Rae(self):
        results = split("Rap\nRae")
        self.assertTrue('Rap' in set(results))
        self.assertTrue('Rae' in set(results))

    def test_full_text_sample(self):
        long_input = '''
CC LA1 NFKBIE\nTNFAIP6\n\nControl\nCancer1\nNFKBIA\nCXCL3\nNormal 1\nCancer 2\nNormal 2\nCancer 3\nQuery gene\nOther gene\nNormal\nCancerous\nRelationship confidenceTranscription factor\nQuery Gene Gene Description\n1. GRO-a4. C\n2. IL-8\n3. CXCL7\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nNFKB1\n5. IL-16\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 2 (p49/p100)\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nCXCL1\nnuclear factor of kappa light polypeptide27\ngene enhancer in B-cells 2 (p49/p100)\nCXCL1\nNFkB2\n0.9279 .\nD\nNormalization of GRO-a & IL-8 by dry mass of omental tissue\nconcentration of GRO-a\nand IL-8 in OCM\nP= 0.56\n*P = 0.04\n2 0.0\nO Normal Cancerous\nNormal Cancerous\nGRO-a & IL-8 expression in\nES-2 cells with IL-8 treatment\n*P <0.05\nH&E\nGRO-a\nDIL-8\nIL-8 (ng/ml)\nGRO-a& IL-8expression in\nES-2 cells with GRO-a treatment\nOIL-8\n*P <0.01\nGRO-a (ng/mL)\n
'''
        results = split(long_input)
        self.assertEqual(set(results), {
                'CCLA1NFKBIE',
                'NFKBIE',
                'CC LA1 NFKBIE',
                'LA1 NFKBIE',
                'CCLA1 NFKBIE',
                'LA1',
                'CC LA1NFKBIE',
                'TNFAIP6',
                'CCLA1',
                'CC LA1',
                'LA1NFKBIE',
                'CC'})


if __name__ == '__main__':
    unittest.main()
