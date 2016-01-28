#!/usr/bin/env python3

import datetime
import serenare
import unittest

class TestParser(unittest.TestCase):
    """ Test parser """
    def test_boolean(self):
        """ Generic toggle """
        for key in serenare.TOGGLE:
            for value in (0, 1):
                line = '{0} ok {1:d}'.format(key, value)
                expected = [(key, value)]
                self.assertEqual(list(serenare.parse(line)), expected)

if __name__ == '__main__':
    unittest.main()

