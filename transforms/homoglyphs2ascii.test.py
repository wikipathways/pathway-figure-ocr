import unittest
import homoglyphs2ascii


class TestHomoglyphs(unittest.TestCase):

    cyrillic = 'МАРК8'
    latin = 'MAPK8'

    def test_latin_and_cyrillic_are_homoglyphs(self):
        self.assertNotEqual(self.cyrillic, self.latin)

    def test_to_ascii_makes_equal(self):
        self.assertEqual(homoglyphs2ascii.homoglyphs2ascii(
            self.cyrillic), homoglyphs2ascii.homoglyphs2ascii(self.latin))

if __name__ == '__main__':
    unittest.main()
