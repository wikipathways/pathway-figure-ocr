import unittest
from shake import shake

class TestShake(unittest.TestCase):

    cyrillic_text = 'МАРК8'
    latin_text = 'MAPK8'

    def test_Relative_Pimdash2_mRNA_expression(self):
        results = shake('Relative Pim-2 mRNA expression')
        self.assertIn(
            'Pim-2', results)
        
    def test_Pimdash2(self):
        results = shake('Pim-2')
        self.assertIn(
            'Pim-2', results)
        
    def test_ABLspaceFAMILY_alone(self):
        results = shake('ABL FAMILY')
        self.assertEqual(
            set({'ABLFAMILY', 'ABL FAMILY', 'ABL', 'FAMILY'}),
            set(results))

    def test_ABLspaceFAMILY_in_string(self):
        results = shake('The ABL FAMILY observed in vitro')
        self.assertIn(
            'ABL FAMILY', results)

    def test_ABLunderscoreFAMILY_alone(self):
        results = shake('ABL_FAMILY')
        self.assertEqual(
            set({'ABL_FAMILY'}),
            set(results))

    def test_ABLunderscoreFAMILY_in_string(self):
        results = shake('The ABL_FAMILY observed in vitro')
        self.assertIn(
            'ABL_FAMILY', results)

    def test_ABC1c_2_and_4(self):
        results = shake('ABC1, 2 and 4')
        self.assertEqual(
            set({'ABC1, 2 and 4'}),
            set(results))

    def test_ABC1c2_and_4(self):
        results = shake('ABC1,2 and 4')
        self.assertEqual(
            set({'ABC1,2 and 4'}),
            set(results))

    def test_ABC1comma2and4_in_string(self):
        results = shake('The ABC1,2 and 4 observed in vitro')
        self.assertIn(
            'ABC1,2 and 4', results)

    def test_ABC1comma2dash4_in_string(self):
        results = shake('The ABC1,2-4 observed in vitro')
        self.assertIn(
            'ABC1,2-4', results)

    def test_cyrillic_text_alone(self):
        results = shake(self.cyrillic_text)
        self.assertEqual(
            set({self.cyrillic_text}),
            set(results))

    def test_cyrillic_text_in_string(self):
        results1 = shake(self.cyrillic_text + ' and ABC1,2-4 observed in vitro')
        self.assertIn(
            (self.cyrillic_text + ' and ABC1,2-4'), results1)

        results2 = shake("Initially ABC1,2-4 and %s observed in vitro" % self.cyrillic_text)
        self.assertIn(
            ('ABC1,2-4 and ' + self.cyrillic_text), results2)

    def test_Rap_arrow_Rae(self):
        results = shake("Rap↑Rae")
        self.assertIn('Rap', results)
        self.assertIn('Rae', results)

    def test_Rap_space_arrow_space_Rae(self):
        results = shake("Rap ↑ Rae")
        self.assertIn('Rap', results)
        self.assertIn('Rae', results)

    def test_Rap_space_arrow(self):
        results = shake("Rap ↑")
        self.assertIn('Rap', results)

    def test_space_arrow_Rap(self):
        results = shake(" ↑Rap")
        self.assertIn('Rap', results)

    def test_arrow_space_Rap(self):
        results = shake("↑ Rap")
        self.assertIn('Rap', results)

    def test_arrow_Rap(self):
        results = shake("↑Rap")
        self.assertIn('Rap', results)

    def test_Rap_newline_Rae(self):
        results = shake("Rap\nRae")
        self.assertIn('Rap', results)
        self.assertIn('Rae', results)

    def test_full_text_sample(self):
        long_input = '''
CC LA1 NFKBIE\nTNFAIP6\n\nControl\nCancer1\nNFKBIA\nCXCL3\nNormal 1\nCancer 2\nNormal 2\nCancer 3\nQuery gene\nOther gene\nNormal\nCancerous\nRelationship confidenceTranscription factor\nQuery Gene Gene Description\n1. GRO-a4. C\n2. IL-8\n3. CXCL7\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nNFKB1\n5. IL-16\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 2 (p49/p100)\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nCXCL1\nnuclear factor of kappa light polypeptide27\ngene enhancer in B-cells 2 (p49/p100)\nCXCL1\nNFkB2\n0.9279 .\nD\nNormalization of GRO-a & IL-8 by dry mass of omental tissue\nconcentration of GRO-a\nand IL-8 in OCM\nP= 0.56\n*P = 0.04\n2 0.0\nO Normal Cancerous\nNormal Cancerous\nGRO-a & IL-8 expression in\nES-2 cells with IL-8 treatment\n*P <0.05\nH&E\nGRO-a\nDIL-8\nIL-8 (ng/ml)\nGRO-a& IL-8expression in\nES-2 cells with GRO-a treatment\nOIL-8\n*P <0.01\nGRO-a (ng/mL)\n
'''

        expected_gene_names = {
                'IL8',
                'NFKB1',
                'GROa',
                'CXCL3',
                'ES2',
                'CXCL1',
                'TNFAIP6',
                'CXCL7',
                'NFKBIE',
                'NFKBIA',
                'IL16',
                'p49',
                'NFkB2'
                }

        actual = set(shake(long_input))

        self.assertEqual(actual.intersection(expected_gene_names), expected_gene_names)
        self.assertEqual(len(actual), 6142)


if __name__ == '__main__':
    unittest.main()
