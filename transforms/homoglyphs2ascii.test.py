import unittest
import homoglyphs2ascii

# TODO: find a better way to run the tests.
# For now, this works:
# cd transforms
# python homoglyphs2ascii.test.py TestHomoglyphs.latin_and_cyrillic_are_homoglyphs
# python homoglyphs2ascii.test.py TestHomoglyphs.to_ascii_makes_equal


class TestHomoglyphs(unittest.TestCase):

    #cyrillic = 'МАРК8'
    #latin = 'MAPK8'

    def latin_and_cyrillic_are_homoglyphs(self):
        self.assertNotEqual('МАРК8', 'MAPK8')

    def to_ascii_makes_equal(self):
        self.assertEqual(homoglyphs2ascii.homoglyphs2ascii(
            'МАРК8'), homoglyphs2ascii.homoglyphs2ascii('MAPK8'))

if __name__ == '__main__':
    unittest.main()
