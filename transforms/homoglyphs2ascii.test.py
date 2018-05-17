import unittest
import homoglyphs2ascii


class TestExpand(unittest.TestCase):

    cyrillic = 'МАРК8'
    latin = 'MAPK8'

    def latin_and_cyrillic_are_homoglyphs(self):
        self.assertNotEqual(cyrillic, latin)

    def to_ascii_makes_equal(self):
        self.assertEqual(homoglyphs2ascii.homoglyphs2ascii(
            cyrillic), homoglyphs2ascii.homoglyphs2ascii(latin))
