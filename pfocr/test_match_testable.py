#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest
from match_testable import match, match_logged, match_verbose, normalize_always
#from fast_match_testable import match


class TestMatch(unittest.TestCase):

    def test_match_verbose1(self):
        actual = match_verbose(
            [{
                'id': 1,
                'symbol': 'WNT9'
            }, {
                'id': 2,
                'symbol': 'WNT10'
            }],
            [{
                'name': 'nfkc',
                'category': 'normalize'
            }, {
                'name': 'asciify',
                'category': 'mutate'
            }, {
                'name': 'shake',
                'category': 'mutate'
            }, {
                'name': 'expand',
                'category': 'mutate'
            }],
            ['WNT9\nWNT10\nWNT9'],
        )

        expected = [{'text': 'WNT9\nWNT10\nWNT9', 'successes': [[{'transform': 'noop', 'indices': [0], 'text': 'WNT9\nWNT10\nWNT9'}, {'transform': 'nfkc', 'indices': [0], 'text': 'WNT9\nWNT10\nWNT9'}, {'transform': 'asciify', 'indices': [0], 'text': 'WNT9\nWNT10\nWNT9'}, {'transform': 'shake', 'indices': [5], 'text': 'WNT10'}, {'transform': 'always', 'indices': [5], 'text': 'WNT10', 'symbol_id': 2}], [{'transform': 'noop', 'indices': [0], 'text': 'WNT9\nWNT10\nWNT9'}, {'transform': 'nfkc', 'indices': [0], 'text': 'WNT9\nWNT10\nWNT9'}, {'transform': 'asciify', 'indices': [0], 'text': 'WNT9\nWNT10\nWNT9'}, {'transform': 'shake', 'indices': [0, 11], 'text': 'WNT9'}, {'transform': 'always', 'indices': [0, 11], 'text': 'WNT9', 'symbol_id': 1}]], 'fails': []}]

        actual_genes = list()
        for r in actual:
            for success in r["successes"]:
                actual_genes.append(success[-1]["text"])
        expected_genes = list()
        for r in expected:
            for success in r["successes"]:
                expected_genes.append(success[-1]["text"])

        self.assertEqual(actual_genes, expected_genes)
        self.assertEqual(actual[0]["successes"][0], expected[0]["successes"][0])
        self.assertEqual(actual[0]["successes"], expected[0]["successes"])

        self.assertEqual(actual, expected)

    def test_match_verbose2(self):
        actual = match_verbose(
            [{
                'id': 1,
                'symbol': 'WNT9'
            }, {
                'id': 2,
                'symbol': 'WNT10'
            }],
            [{
                'name': 'nfkc',
                'category': 'normalize'
            }, {
                'name': 'asciify',
                'category': 'mutate'
            }, {
                'name': 'shake',
                'category': 'mutate'
            }, {
                'name': 'expand',
                'category': 'mutate'
            }],
            ['WNT9/10\nWNT9'],
        )

        expected = [{'text': 'WNT9/10\nWNT9', 'successes': [[{'transform': 'noop', 'indices': [0], 'text': 'WNT9/10\nWNT9'}, {'transform': 'nfkc', 'indices': [0], 'text': 'WNT9/10\nWNT9'}, {'transform': 'asciify', 'indices': [0], 'text': 'WNT9/10\nWNT9'}, {'transform': 'shake', 'indices': [0], 'text': 'WNT9/10'}, {'transform': 'expand', 'indices': [0], 'text': 'WNT10'}, {'transform': 'always', 'indices': [0], 'text': 'WNT10', 'symbol_id': 2}], [{'transform': 'noop', 'indices': [0], 'text': 'WNT9/10\nWNT9'}, {'transform': 'nfkc', 'indices': [0], 'text': 'WNT9/10\nWNT9'}, {'transform': 'asciify', 'indices': [0], 'text': 'WNT9/10\nWNT9'}, {'transform': 'shake', 'indices': [0], 'text': 'WNT9/10'}, {'transform': 'expand', 'indices': [0], 'text': 'WNT9'}, {'transform': 'always', 'indices': [0], 'text': 'WNT9', 'symbol_id': 1}], [{'transform': 'noop', 'indices': [0], 'text': 'WNT9/10\nWNT9'}, {'transform': 'nfkc', 'indices': [0], 'text': 'WNT9/10\nWNT9'}, {'transform': 'asciify', 'indices': [0], 'text': 'WNT9/10\nWNT9'}, {'transform': 'shake', 'indices': [8], 'text': 'WNT9'}, {'transform': 'always', 'indices': [8], 'text': 'WNT9', 'symbol_id': 1}]], 'fails': []}]

        actual_genes = list()
        for r in actual:
            for success in r["successes"]:
                actual_genes.append(success[-1]["text"])
        expected_genes = list()
        for r in expected:
            for success in r["successes"]:
                expected_genes.append(success[-1]["text"])

        self.assertEqual(actual_genes, expected_genes)
        self.assertEqual(actual[0]["successes"], expected[0]["successes"])

        self.assertEqual(actual, expected)

    def test_match_verbose3(self):
        actual = match_verbose(
            [{
                'id': 1,
                'symbol': 'WNT9'
            }, {
                'id': 2,
                'symbol': 'WNT10'
            }],
            [{
                'name': 'nfkc',
                'category': 'normalize'
            }, {
                'name': 'asciify',
                'category': 'mutate'
            }, {
                'name': 'shake',
                'category': 'mutate'
            }, {
                'name': 'expand',
                'category': 'mutate'
            }],
            ['WNT9/10'],
        )
        print(actual)

        expected = [{
            'text': 'WNT9/10',
            'successes': [
                [{'transform': 'noop', 'text': 'WNT9/10'},
                    {'transform': 'nfkc', 'text': 'WNT9/10'},
                    {'transform': 'asciify', 'text': 'WNT9/10'},
                    {'transform': 'shake', 'text': 'WNT9/10'},
                    {'transform': 'expand', 'text': 'WNT10'},
                    {'transform': 'always', 'text': 'WNT10', 'symbol_id': 2}],
                [{'transform': 'noop', 'text': 'WNT9/10'},
                    {'transform': 'nfkc', 'text': 'WNT9/10'},
                    {'transform': 'asciify', 'text': 'WNT9/10'},
                    {'transform': 'shake', 'text': 'WNT9/10'},
                    {'transform': 'expand', 'text': 'WNT9'},
                    {'transform': 'always', 'text': 'WNT9', 'symbol_id': 1}],
                ],
            'fails': []}]

        actual_genes = list()
        for r in actual:
            for success in r["successes"]:
                actual_genes.append(success[-1]["text"])
        expected_genes = list()
        for r in expected:
            for success in r["successes"]:
                expected_genes.append(success[-1]["text"])

        self.assertEqual(actual_genes, expected_genes)
        self.assertEqual(actual[0]["successes"], expected[0]["successes"])

        self.assertEqual(actual, expected)

#    def test_match_verbose_with_fail(self):
#        actual = match_verbose(
#            [{
#                'id': 1,
#                'symbol': 'WNT9'
#            }, {
#                'id': 2,
#                'symbol': 'WNT10'
#            }],
#            [{
#                'name': 'nfkc',
#                'category': 'normalize'
#            }, {
#                'name': 'asciify',
#                'category': 'mutate'
#            }, {
#                'name': 'shake',
#                'category': 'mutate'
#            }, {
#                'name': 'expand',
#                'category': 'mutate'
#            }],
#            ['WNT9/10\nWNT9\nPFOCR_FAILED'],
#        )
#
#        expected = [{
#            'text': 'WNT9/10\nWNT9\nPFOCR_FAILED',
#            'successes': [
#                [
#                    {'transform': 'noop', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'nfkc', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'asciify', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'shake', 'text': 'WNT9/10'},
#                    {'transform': 'expand', 'text': 'WNT10'},
#                    {'transform': 'always', 'text': 'WNT10', 'symbol_id': 2}
#                    ],
#                [
#                    {'transform': 'noop', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'nfkc', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'asciify', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'shake', 'text': 'WNT9/10'},
#                    {'transform': 'expand', 'text': 'WNT9'},
#                    {'transform': 'always', 'text': 'WNT9', 'symbol_id': 1}
#                    ],
#                [
#                    {'transform': 'noop', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'nfkc', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'asciify', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'shake', 'text': 'WNT9'},
#                    {'transform': 'always', 'text': 'WNT9', 'symbol_id': 1}
#                    ]
#                ],
#            'fails': [
#                [
#                    {'transform': 'noop', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'nfkc', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'asciify', 'text': 'WNT9/10\nWNT9\nPFOCR_FAILED'},
#                    {'transform': 'shake', 'text': 'PFOCR_FAILED'},
#                    {'transform': 'always', 'text': 'PFOCR_FAILED'}
#                    ]
#                ]
#                }]
#
#        actual_genes = list()
#        for r in actual:
#            for success in r["successes"]:
#                actual_genes.append(success[-1]["text"])
#        expected_genes = list()
#        for r in expected:
#            for success in r["successes"]:
#                expected_genes.append(success[-1]["text"])
#
#        self.assertEqual(actual_genes, expected_genes)
#        self.assertEqual(actual[0]["successes"], expected[0]["successes"])
#        self.assertEqual(actual[0]["fails"], expected[0]["fails"])
#
#        self.assertEqual(actual, expected)
#
#    def test_match_logged(self):
#        actual = match_logged(
#            [{
#                'id': 1,
#                'symbol': 'WNT9'
#            }, {
#                'id': 2,
#                'symbol': 'WNT10'
#            }],
#            [{
#                'name': 'nfkc',
#                'category': 'normalize'
#            }, {
#                'name': 'asciify',
#                'category': 'mutate'
#            }, {
#                'name': 'shake',
#                'category': 'mutate'
#            }, {
#                'name': 'expand',
#                'category': 'mutate'
#            }],
#            ['WNT9/10\nWNT9'],
#        )
#
#        expected = [
#                [[
#                    ['WNT9/10\nWNT9', 'WNT9/10\nWNT9', 'WNT9/10\nWNT9', 'WNT9/10', 'WNT10', 'WNT10'],
#                    ['WNT9/10\nWNT9', 'WNT9/10\nWNT9', 'WNT9/10\nWNT9', 'WNT9/10', 'WNT9', 'WNT9'],
#                    ['WNT9/10\nWNT9', 'WNT9/10\nWNT9', 'WNT9/10\nWNT9', 'WNT9', 'WNT9']
#                    ]],
#                [[]]
#                ]
#
#        self.assertEqual(actual, expected)
#
#    def test_digit_chunks(self):
#        actual = match(
#            [{
#                'id': 1,
#                'symbol': 'WNT9'
#            }, {
#                'id': 2,
#                'symbol': 'WNT10'
#            }],
#            [{
#                'name': 'nfkc',
#                'category': 'normalize'
#            }, {
#                'name': 'asciify',
#                'category': 'mutate'
#            }, {
#                'name': 'shake',
#                'category': 'mutate'
#            }, {
#                'name': 'expand',
#                'category': 'mutate'
#            }],
#            ['WNT9/10'],
#        )
#        self.assertEqual(actual,
#        {'WNT9', 'WNT10'})
#
#    def test_newline(self):
#        self.assertEqual(set(match(
#            [{
#                'id': 1,
#                'symbol': 'WNT9'
#            }, {
#                'id': 2,
#                'symbol': 'WNT10'
#            }],
#            [{
#                'name': 'nfkc',
#                'category': 'normalize'
#            }, {
#                'name': 'asciify',
#                'category': 'mutate'
#            }, {
#                'name': 'shake',
#                'category': 'mutate'
#            }, {
#                'name': 'expand',
#                'category': 'mutate'
#            }],
#            ['WNT9\nWNT10'],
#        )),
#        {'WNT9', 'WNT10'})
#
#    def test_short_input(self):
#        text = '''
#CC NFKBIE\nTNFAIP6\n
#'''
#
#        symbols_and_ids = [{
#                'id': 3164,
#                'symbol': 'NFKBIE'
#            }, {
#                'id': 4876,
#                'symbol': 'TNFAIP6'
#            }]
#
#        expected = set([normalize_always(s['symbol']) for s in symbols_and_ids])
#        actual_raw = match(
#            symbols_and_ids,
#            [{
#                'name': 'nfkc',
#                'category': 'normalize'
#            }, {
#                'name': 'asciify',
#                'category': 'mutate'
#            }, {
#                'name': 'shake',
#                'category': 'mutate'
#            }, {
#                'name': 'expand',
#                'category': 'mutate'
#            }, {
#                'name': 'alphanumeric',
#                'category': 'normalize'
#            }],
#            [text],
#        )
#        actual = set([normalize_always(a) for a in actual_raw])
#
#        self.assertEqual(actual, expected)
#
#    def test_medium_input(self):
#        text = '''
#CC LA1 NFKBIE\nTNFAIP6\n白\nControl\nCancer1\nNFKBIA\nCXCL3\n
#'''
#
#        symbols_and_ids = [{
#                'id': 3164,
#                'symbol': 'NFKBIE'
#            }, {
#                'id': 4876,
#                'symbol': 'TNFAIP6'
#            }, {
#                'id': 3162,
#                'symbol': 'NFKBIA'
#            }, {
#                'id': 1966,
#                'symbol': 'CXCL3'
#            }]
#
#        expected = set([normalize_always(s['symbol']) for s in symbols_and_ids])
#        actual_raw = match(
#            symbols_and_ids,
#            [{
#                'name': 'nfkc',
#                'category': 'normalize'
#            }, {
#                'name': 'asciify',
#                'category': 'mutate'
#            }, {
#                'name': 'shake',
#                'category': 'mutate'
#            }, {
#                'name': 'expand',
#                'category': 'mutate'
#            }, {
#                'name': 'upper',
#                'category': 'normalize'
#            }, {
#                'name': 'alphanumeric',
#                'category': 'normalize'
#            }],
#            [text],
#        )
#        actual = set([normalize_always(a) for a in actual_raw])
#
#        self.assertEqual(actual, expected)
#
#    def test_long_input(self):
#        text = '''
#CC LA1 NFKBIE\nTNFAIP6\n白\nControl\nCancer1\nNFKBIA\nCXCL3\nNormal 1\nCancer 2\nNormal 2\nCancer 3\n·Query gene\nOther gene\nNormal\nCancerous\nRelationship confidenceTranscription factor\nQuery Gene Gene Description\n1. GRO-a4. C\n2. IL-8\n3. CXCL7\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nNFKB1\n5. IL-16\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 2 (p49/p100)\nnuclear factor of kappa light polypeptide\ngene enhancer in B-cells 1\nCXCL1\nnuclear factor of kappa light polypeptide27\ngene enhancer in B-cells 2 (p49/p100)\nCXCL1\nNFkB2\n0.9279 .\nD\nNormalization of GRO-a & IL-8 by dry mass of omental tissue\nconcentration of GRO-α\nand IL-8 in OCM\nP= 0.56\n*P = 0.04\n2 0.0\nO Normal Cancerous\nNormal Cancerous\nGRO-a & IL-8 expression in\nES-2 cells with IL-8 treatment\n*P <0.05\nH&E\nGRO-a\nDIL-8\nIL-8 (ng/ml)\nGRO-a& IL-8expression in\nES-2 cells with GRO-a treatment\nOIL-8\n*P <0.01\nGRO-a (ng/mL)\n
#'''
#
#        symbols_and_ids = [{
#                'id': 3164,
#                'symbol': 'NFKBIE'
#            }, {
#                'id': 4876,
#                'symbol': 'TNFAIP6'
#            }, {
#                'id': 3162,
#                'symbol': 'NFKBIA'
#            }, {
#                'id': 1966,
#                'symbol': 'CXCL3'
#            }, {
#                'id': 34567,
#                'symbol': 'GROa'
#            }, {
#                'id': 57263,
#                'symbol': 'IL8'
#            }, {
#                'id': 26871,
#                'symbol': 'CXCL7'
#            }, {
#                'id': 2395,
#                'symbol': 'IL16'
#            }, {
#                'id': 3160,
#                'symbol': 'NFKB1'
#            }, {
#                'id': 45187,
#                'symbol': 'p49'
#            }, {
#                'id': 1964,
#                'symbol': 'CXCL1'
#            }, {
#                'id': 3161,
#                'symbol': 'NFKB2'
#            }, {
#                'id': 29581,
#                'symbol': 'ES2'
#            }]
#
#        expected = set([normalize_always(s['symbol']) for s in symbols_and_ids])
#        actual_raw = match(
#            symbols_and_ids,
#            [{
#                'name': 'nfkc',
#                'category': 'normalize'
#            }, {
#                'name': 'asciify',
#                'category': 'mutate'
#            }, {
#                'name': 'shake',
#                'category': 'mutate'
#            }, {
#                'name': 'expand',
#                'category': 'mutate'
#            }, {
#                'name': 'upper',
#                'category': 'normalize'
#            }, {
#                'name': 'alphanumeric',
#                'category': 'normalize'
#            }],
#            [text],
#        )
#        actual = set([normalize_always(a) for a in actual_raw])
#
#        self.assertEqual(actual, expected)
#
#    def test_Relative_mRNA_etc(self):
#        text = '''
#Relative mRNA expression Q\nRelative to p-actin D\n3\nAhR\nGPR35\nGRIN1\nGRIN2A\nGRIN2B\nGRIN3A\nα7nAChR\nRelative mRNA expression\nAMPAR2\nAMPAR3\nAMPAR4\nKainateR1\nKainateR2\nKainateR3\nKainateR4\nKainateR5\nRelative mRNA expression O\nAhR binding\n2\npg/ml\n
#'''
#
#        symbols_and_ids = [{'symbol': 'ACTIN', 'id': 21591}, {'symbol': 'GRIN2B', 'id': 1950}, {'symbol': 'GPR35', 'id': 1910}, {'symbol': 'GRIN2A', 'id': 1949}, {'symbol': 'GRIN1', 'id': 1948}, {'symbol': 'AHR', 'id': 136}, {'symbol': 'GRIN3A', 'id': 14478}]
#
#        expected = set([normalize_always(s['symbol']) for s in symbols_and_ids])
#        actual_raw = match(
#            symbols_and_ids,
#            [{
#                'name': 'stop',
#                'category': 'normalize'
#            }, {
#                'name': 'nfkc',
#                'category': 'normalize'
#            }, {
#                'name': 'deburr',
#                'category': 'normalize'
#            }, {
#                'name': 'shake',
#                'category': 'mutate'
#            }, {
#                'name': 'expand',
#                'category': 'mutate'
#            }, {
#                'name': 'root',
#                'category': 'mutate'
#            }, {
#                'name': 'swaps',
#                'category': 'normalize'
#            }, {
#                'name': 'alphanumeric',
#                'category': 'normalize'
#            }],
#            [text],
#        )
#        actual = set([normalize_always(a) for a in actual_raw])
#
#        self.assertEqual(actual, expected)
#
#    def test_PTEN_CdashFLIP1_etc(self):
#        texts = [
#                'PTEN',
#                '"으',
#                'C-FLIP',
#                'Caspase3 4',
#                'Caspase7',
#                '■P53',
#                'LKB1',
#                'TSC2']
#
#        symbols_and_ids = [{'symbol': 'PTEN', 'id': 3854}, {'symbol': 'P53', 'id': 45201}, {'symbol': 'LKB1', 'id': 39986}, {'symbol': 'C-FLIP', 'id': 24252}, {'symbol': 'TSC2', 'id': 4940}]
#
#        expected = set([normalize_always(s['symbol']) for s in symbols_and_ids])
#        actual_raw = match(
#            symbols_and_ids,
#            [{
#                'name': 'nfkc',
#                'category': 'normalize'
#            }, {
#                'name': 'deburr',
#                'category': 'normalize'
#            }, {
#                'name': 'expand',
#                'category': 'mutate'
#            }, {
#                'name': 'root',
#                'category': 'mutate'
#            }, {
#                'name': 'swaps',
#                'category': 'normalize'
#            }, {
#                'name': 'alphanumeric',
#                'category': 'normalize'
#            }],
#            texts,
#        )
#        actual = set([normalize_always(a) for a in actual_raw])
#
#        self.assertEqual(actual, expected)
#
#    def test_PTEN_CdashFLIP_etc_match_verbose(self):
#        text = '''
#PTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2
#'''
#
#        symbols_and_ids = [{'symbol': 'PTEN', 'id': 3854}, {'symbol': 'P53', 'id': 45201}, {'symbol': 'LKB1', 'id': 39986}, {'symbol': 'C-FLIP', 'id': 24252}, {'symbol': 'TSC2', 'id': 4940}]
#
#        expected = [{
#            'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n',
#            'successes': [
#                # TODO: how should we handle the case where we get both C-FLIP and CFLIP?
#                [{'transform': 'noop', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'nfkc', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'deburr', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'shake', 'text': 'C-FLIP'},
#                    {'transform': 'always', 'text': 'C-FLIP', 'symbol_id': 24252}],
#                [{'transform': 'noop', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'nfkc', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'deburr', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'shake', 'text': 'CFLIP'},
#                    {'transform': 'always', 'text': 'CFLIP', 'symbol_id': 24252}],
#                [{'transform': 'noop', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'nfkc', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'deburr', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'shake', 'text': 'LKB1'},
#                    {'transform': 'always', 'text': 'LKB1', 'symbol_id': 39986}],
#                [{'transform': 'noop', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'nfkc', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'deburr', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'shake', 'text': 'P53'},
#                    {'transform': 'always', 'text': 'P53', 'symbol_id': 45201}],
#                [{'transform': 'noop', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'nfkc', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'deburr', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'shake', 'text': 'PTEN'},
#                    {'transform': 'always', 'text': 'PTEN', 'symbol_id': 3854}],
#                [{'transform': 'noop', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'nfkc', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'deburr', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'shake', 'text': 'TSC2'},
#                    {'transform': 'always', 'text': 'TSC2', 'symbol_id': 4940}]
#                ],
#            'fails': [
#                [{'transform': 'noop', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'nfkc', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'deburr', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'shake', 'text': 'Caspase3 4'},
#                    {'transform': 'expand', 'text': 'Caspase3 4'},
#                    {'transform': 'root', 'text': 'Caspase3 4'},
#                    {'transform': 'swaps', 'text': 'CASPASE3 4'},
#                    {'transform': 'always', 'text': 'CASPASE34'}],
#                [{'transform': 'noop', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'nfkc', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'deburr', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'shake', 'text': 'Caspase7'},
#                    {'transform': 'expand', 'text': 'Caspase7'},
#                    {'transform': 'root', 'text': 'Caspase7'},
#                    {'transform': 'swaps', 'text': 'CASPASE7'},
#                    {'transform': 'always', 'text': 'CASPASE7'}],
#                [{'transform': 'noop', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'nfkc', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'deburr', 'text': '\nPTEN\n"으\nC-FLIP\nCaspase3 4\nCaspase7\n■P53\nLKB1\nTSC2\n'},
#                    {'transform': 'shake', 'text': '으'},
#                    {'transform': 'expand', 'text': '으'},
#                    {'transform': 'root', 'text': '으'},
#                    {'transform': 'swaps', 'text': '으'},
#                    {'transform': 'always', 'text': ''}]
#                ]}]
#
#        actual = match_verbose(
#            symbols_and_ids,
#            [{
#                'name': 'nfkc',
#                'category': 'normalize'
#            }, {
#                'name': 'deburr',
#                'category': 'normalize'
#            }, {
#                'name': 'shake',
#                'category': 'mutate'
#            }, {
#                'name': 'expand',
#                'category': 'mutate'
#            }, {
#                'name': 'root',
#                'category': 'mutate'
#            }, {
#                'name': 'swaps',
#                'category': 'normalize'
#            }, {
#                'name': 'alphanumeric',
#                'category': 'normalize'
#            }],
#            [text],
#        )
#
#        actual_genes = set()
#        for r in actual:
#            for success in r["successes"]:
#                actual_genes.add(success[-1]["text"])
#        expected_genes = set()
#        for r in expected:
#            for success in r["successes"]:
#                expected_genes.add(success[-1]["text"])
#
#        self.assertEqual(actual_genes, expected_genes)
#        self.assertEqual(actual[0]["successes"], expected[0]["successes"])
#
#        self.assertEqual(actual, expected)

        
if __name__ == '__main__':
    unittest.main()
