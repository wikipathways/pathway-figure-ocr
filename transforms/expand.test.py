import unittest
import expand

class TestExpand(unittest.TestCase):

    def test_digit_chunks(self):
        self.assertEqual(set(expand.expand('WNT9/10')), {'WNT9', 'WNT10'})
        self.assertEqual(set(expand.expand('WNT10/11')), {'WNT10', 'WNT11'})
        self.assertEqual(set(expand.expand('WNT9-11')), {'WNT9', 'WNT10', 'WNT11'})

    def test_single_char_chunks(self):
        # TODO which of these is the desired result?
        self.assertEqual(set(expand.expand('KDM6A/B')), {'KDM6A', 'KDM6B', 'KDMB'})
        self.assertTrue({'KDM6A', 'KDM6B'}.issubset(set(expand.expand('KDM6A/B'))))
        
    def test_two_char_chunks(self):
        # TODO which of these is the desired result?
        self.assertEqual(set(expand.expand('5-HT2A/2B')), {'5', '5-HT2A', '5-HT2B', 'HT2A', 'HT2B'})
        self.assertTrue({'5-HT2A', '5-HT2B', 'HT2A'}.issubset(set(expand.expand('5-HT2A/2B'))))

    def test_shorthand_chunks(self):
        # TODO: the item actually in the data is Wnt-1/3a
        self.assertTrue({'Wnt1', 'Wnt3a'}.issubset(set(expand.expand('Wnt1/3a'))))

        # TODO can we delete the following one? It's not actually in the data.
        #self.assertTrue({'Wnt1a', 'Wnt3'}.issubset(set(expand.expand('Wnt1a/3'))))

        # TODO here's what we're actually getting:
        self.assertEqual(set(expand.expand('Wnt-1/3a')), {'Wn1', 'Wnt', 'Wn3a'})
        self.assertEqual(set(expand.expand('Wnt-1a/3')), {'Wn1a', 'Wnt', 'Wn3'})
        # TODO here's what we probably want:
        #self.assertTrue({'Wnt1', 'Wnt3a'}.issubset(set(expand.expand('Wnt-1/3a'))))
        #self.assertTrue({'Wnt1a', 'Wnt3'}.issubset(set(expand.expand('Wnt-1a/3'))))

        self.assertTrue({'CDK25C', 'CDK25B'}.issubset(set(expand.expand('CDK25B/C'))))

        # grep -P "\d[a-zA-Z]\/\d" ./fails.txt 
        self.assertTrue({'CDKN1A', 'CDKN2A'}.issubset(set(expand.expand('CDKN1A/2A'))))

        # grep -P "\d\/[a-zA-Z]\d" ./successes.txt 
        self.assertTrue({'AdipoR1', 'AdipoR2'}.issubset(set(expand.expand('AdipoR1/R2'))))

        # TODO: IL-12/IL-23/I1-27 => I1 this is wrong. Currently broken.
        self.assertTrue({'IL-12', 'IL-23', 'I1-27'}.issubset(set(expand.expand('IL-12/IL-23/I1-27'))))

if __name__ == '__main__':
    unittest.main()
