#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest
from match_testable import match
#from fast_match_testable import match


class TestMatch(unittest.TestCase):

    def test_digit_chunks(self):
        actual = set(match(
            [{
                'name': 'nfkc',
                'category': 'normalize'
            }, {
                'name': 'asciify',
                'category': 'mutate'
            }, {
                'name': 'split',
                'category': 'mutate'
            }, {
                'name': 'expand',
                'category': 'mutate'
            }],
            ['WNT9/10'],
            [{
                'id': 1,
                'symbol': 'WNT9'
            }, {
                'id': 2,
                'symbol': 'WNT10'
            }]
        ))
        self.assertEqual(actual,
        {'WNT9', 'WNT10'})

    def test_newline(self):
        self.assertEqual(set(match(
            [{
                'name': 'nfkc',
                'category': 'normalize'
            }, {
                'name': 'asciify',
                'category': 'mutate'
            }, {
                'name': 'split',
                'category': 'mutate'
            }, {
                'name': 'expand',
                'category': 'mutate'
            }],
            ['WNT9\nWNT10'],
            [{
                'id': 1,
                'symbol': 'WNT9'
            }, {
                'id': 2,
                'symbol': 'WNT10'
            }]
        )),
        {'WNT9', 'WNT10'})

    def test_short_input(self):
        text = '''
CC NFKBIE\nTNFAIP6\n
'''

        symbols_and_ids = [{
                'id': 3164,
                'symbol': 'NFKBIE'
            }, {
                'id': 4876,
                'symbol': 'TNFAIP6'
            }]

        expected = set([s['symbol'].upper() for s in symbols_and_ids])
        actual_raw = match(
            [{
                'name': 'nfkc',
                'category': 'normalize'
            }, {
                'name': 'asciify',
                'category': 'mutate'
            }, {
                'name': 'split',
                'category': 'mutate'
            }, {
                'name': 'expand',
                'category': 'mutate'
            }, {
                'name': 'alphanumeric',
                'category': 'normalize'
            }],
            [text],
            symbols_and_ids
        )
        actual = set([a.upper() for a in actual_raw])

        self.assertEqual(actual, expected)

    def test_medium_input(self):
        text = '''
CC LA1 NFKBIE\nTNFAIP6\n白\nControl\nCancer1\nNFKBIA\nCXCL3\n
'''

        symbols_and_ids = [{
                'id': 3164,
                'symbol': 'NFKBIE'
            }, {
                'id': 4876,
                'symbol': 'TNFAIP6'
            }, {
                'id': 3162,
                'symbol': 'NFKBIA'
            }, {
                'id': 1966,
                'symbol': 'CXCL3'
            }]

        expected = set([s['symbol'].upper() for s in symbols_and_ids])
        actual_raw = match(
            [{
                'name': 'nfkc',
                'category': 'normalize'
            }, {
                'name': 'asciify',
                'category': 'mutate'
            }, {
                'name': 'split',
                'category': 'mutate'
            }, {
                'name': 'expand',
                'category': 'mutate'
            }, {
                'name': 'upper',
                'category': 'normalize'
            }, {
                'name': 'alphanumeric',
                'category': 'normalize'
            }],
            [text],
            symbols_and_ids
        )
        actual = set([a.upper() for a in actual_raw])

        self.assertEqual(actual, expected)

    def test_long_input(self):
        text = '''
CC LA1 NFKBIE\nTNFAIP6\n白\nControl\nCancer1\nNFKBIA\nCXCL3\nNormal 1\nCancer 2\nNormal 2\nCancer 3\n·Query gene\nOther gene\nNormal\nCancerous\nRelationship confidenceTranscription factor\nQuery Gene Gene Description\n1. GRO-a4. C\n2. IL-8\n3. CXCL7\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nNFKB1\n5. IL-16\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 2 (p49/p100)\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nCXCL1\nnuclear factor of kappa light polypeptide27\ngene enhancer in B-cells 2 (p49/p100)\nCXCL1\nNFkB2\n0.9279 .\nD\nNormalization of GRO-a & IL-8 by dry mass of omental tissue\nconcentration of GRO-α\nand IL-8 in OCM\nP= 0.56\n*P = 0.04\n2 0.0\nO Normal Cancerous\nNormal Cancerous\nGRO-a & IL-8 expression in\nES-2 cells with IL-8 treatment\n*P <0.05\nH&E\nGRO-a\nDIL-8\nIL-8 (ng/ml)\nGRO-a& IL-8expression in\nES-2 cells with GRO-a treatment\nOIL-8\n*P <0.01\nGRO-a (ng/mL)\n
'''

        symbols_and_ids = [{
                'id': 3164,
                'symbol': 'NFKBIE'
            }, {
                'id': 4876,
                'symbol': 'TNFAIP6'
            }, {
                'id': 3162,
                'symbol': 'NFKBIA'
            }, {
                'id': 1966,
                'symbol': 'CXCL3'
            }, {
                'id': 34567,
                'symbol': 'GROa'
            }, {
                'id': 57263,
                'symbol': 'IL8'
            }, {
                'id': 26871,
                'symbol': 'CXCL7'
            }, {
                'id': 2395,
                'symbol': 'IL16'
            }, {
                'id': 3160,
                'symbol': 'NFKB1'
            }, {
                'id': 45187,
                'symbol': 'p49'
            }, {
                'id': 1964,
                'symbol': 'CXCL1'
            }, {
                'id': 3161,
                'symbol': 'NFKB2'
            }, {
                'id': 29581,
                'symbol': 'ES2'
            }]

        expected = set([s['symbol'].upper() for s in symbols_and_ids])
        actual_raw = match(
            [{
                'name': 'nfkc',
                'category': 'normalize'
            }, {
                'name': 'asciify',
                'category': 'mutate'
            }, {
                'name': 'split',
                'category': 'mutate'
            }, {
                'name': 'expand',
                'category': 'mutate'
            }, {
                'name': 'upper',
                'category': 'normalize'
            }, {
                'name': 'alphanumeric',
                'category': 'normalize'
            }],
            [text],
            symbols_and_ids
        )
        actual = set([a.upper() for a in actual_raw])

        self.assertEqual(actual, expected)

        
if __name__ == '__main__':
    unittest.main()
