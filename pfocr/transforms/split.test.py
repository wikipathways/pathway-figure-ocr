import unittest
from split import split

class TestSplit(unittest.TestCase):

    cyrillic_text = 'МАРК8'
    latin_text = 'MAPK8'

    def test_Relative_Pimdash2_mRNA_expression(self):
        results = split('Relative Pim-2 mRNA expression')
        self.assertEqual(
            'Pim-2' in set(results),
            True)
        
    def test_Pimdash2(self):
        results = split('Pim-2')
        self.assertEqual(
            set({'Pim-2'}),
            set(results))
        
    def test_ABLspaceFAMILY_alone(self):
        results = split('ABL FAMILY')
        self.assertEqual(
            set({'ABLFAMILY', 'ABL FAMILY', 'ABL', 'FAMILY'}),
            set(results))

    def test_ABLspaceFAMILY_in_string(self):
        results = split('The ABL FAMILY observed in vitro')
        self.assertEqual(
            'ABL FAMILY' in set(results),
            True)

    def test_ABLunderscoreFAMILY_alone(self):
        results = split('ABL_FAMILY')
        self.assertEqual(
            set({'ABL_FAMILY'}),
            set(results))

    def test_ABLunderscoreFAMILY_in_string(self):
        results = split('The ABL_FAMILY observed in vitro')
        self.assertEqual(
            'ABL_FAMILY' in set(results),
            True)

    def test_ABC1comma2and4_alone(self):
        results = split('ABC1,2 and 4')
        self.assertEqual(
            set({'ABC1,2 and 4'}),
            set(results))

    def test_ABC1comma2and4_in_string(self):
        results = split('The ABC1,2 and 4 observed in vitro')
        self.assertEqual(
            'ABC1,2 and 4' in set(results),
            True)

    def test_ABC1comma2dash4_in_string(self):
        results = split('The ABC1,2-4 observed in vitro')
        self.assertEqual(
            'ABC1,2-4' in set(results),
            True)

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

if __name__ == '__main__':
    unittest.main()
