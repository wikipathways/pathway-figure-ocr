import unittest
import nfkc


class TestNFKC(unittest.TestCase):

    # this is treated as a single letter, not a ligature:
    ae_letter = u"æ"
    # but this is treated as a ligature of f and i:
    fi_ligature = u'ﬁ'

    def test_ae_letter(self):
        nfkced = nfkc.nfkc(self.ae_letter)
        nfkced_list = list(nfkced[0])
        self.assertEqual(
            set(nfkced_list),
            set({u"æ"}))

        self.assertEqual(len(nfkced), 1)

    def test_fi_ligature(self):
        nfkced = nfkc.nfkc(self.fi_ligature)
        nfkced_list = list(nfkced[0])
        self.assertEqual(
            set(nfkced_list),
            set({'f', 'i'}))

        self.assertEqual(len(nfkced), 1)

if __name__ == '__main__':
    unittest.main()
