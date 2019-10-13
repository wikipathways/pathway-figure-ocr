import unittest
import expand

class TestExpand(unittest.TestCase):

    def test_digit_chunks(self):
        self.assertEqual(set(expand.expand('WNT9/10')), {'WNT9', 'WNT10'})
        self.assertEqual(set(expand.expand('WNT10/11')), {'WNT10', 'WNT11'})
        self.assertEqual(set(expand.expand('WNT9-11')), {'WNT9', 'WNT10', 'WNT11'})
        self.assertEqual(set(expand.expand('WNT10-11')), {'WNT10', 'WNT11'})

    def test_single_char_chunks(self):
        # TODO which of these is the desired result?
        self.assertEqual(set(expand.expand('KDM6A/B')), {'KDM6A', 'KDM6B'})
        self.assertEqual({'CDK25C', 'CDK25B'},set(expand.expand('CDK25B/C')))
        
    def test_two_char_chunks(self):
        # TODO which of these is the desired result?
        self.assertEqual(set(expand.expand('5-HT2A/2B')), {'5-HT2A', '5-HT2B'})
        # grep -P "\d[a-zA-Z]\/\d" ./fails.txt 
        self.assertEqual({'CDKN1A', 'CDKN2A'},set(expand.expand('CDKN1A/2A')))
        # grep -P "\d\/[a-zA-Z]\d" ./successes.txt 
        self.assertEqual({'AdipoR1', 'AdipoR2'}, set(expand.expand('AdipoR1/R2')))

    def test_complex_chunks(self):
        # TODO: the item actually in the data is Wnt-1/3a
        self.assertEqual({'Wnt1', 'Wnt3a'}, set(expand.expand('Wnt1/3a')))

        # TODO can we delete the following one? It's not actually in the data.
        self.assertEqual({'Wnt1a', 'Wnt3'}, set(expand.expand('Wnt1a/3')))

        # TODO here's what we're actually getting:
        self.assertEqual(set(expand.expand('Wnt-1/3a')), {'Wnt-1', 'Wnt-3a'})
        self.assertEqual(set(expand.expand('Wnt-1a/3')), {'Wnt-1a', 'Wnt-3'})

    def test_mixed_chunks(self):
        self.assertEqual(set(expand.expand('WNT1/HCK1-3/ABC')), {'WNT1','HCK1','HCK2','HCK3','ABC'})

    #def test_tricky_chunks(self):
        # TODO: IL-12/IL-23/I1-27 => I1 this is wrong. Currently broken.
        # self.assertEqual({'IL-12', 'IL-23', 'I1-27'}, set(expand.expand('IL-12/IL-23/I1-27')))

    def test_simple_chunks(self):
        self.assertEqual(set(expand.expand('WNT1/HCK3/ABC')), {'WNT1','HCK3','ABC'})

    def test_memory_leak(self):
       self.assertEqual(set(expand.expand('4000-3295')), {'4000-3295'})
       self.assertEqual(set(expand.expand('3VIT19-001490329014')), {'3VIT19-001490329014'})

    def test_comma_case(self):
       self.assertEqual(set(expand.expand('MEKK1-3,')), {'MEKK1','MEKK2','MEKK3'})

    def test_not_increasing_slash(self):
       self.assertEqual(set(expand.expand('TLR2/1')), {'TLR2','TLR1'})
       self.assertEqual(set(expand.expand('TLR2/6')), {'TLR2','TLR6'})

    def test_digit_separators(self):
       self.assertEqual(set(expand.expand('TLR1,2, 5')), {'TLR2','TLR1','TLR5'})
       # TODO: failing on the following
       #self.assertEqual(set(expand.expand('TLR1,2, and 5')), {'TLR2','TLR1','TLR5'})
       #self.assertEqual(set(expand.expand('TLR1,2 and 5')), {'TLR2','TLR1','TLR5'})
       #self.assertEqual(set(expand.expand('TLR1,2 or 5')), {'TLR2','TLR1','TLR5'})
       #self.assertEqual(set(expand.expand('TLR1,2or 5')), {'TLR2','TLR1','TLR5'})

if __name__ == '__main__':
    unittest.main()
