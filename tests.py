#!/usr/bin/env python3

import datetime
import serenare
import unittest

class TestParser(unittest.TestCase):
    def test_message(self):
        line = '[2016/01/28 12:46:57] (C) frafra> wow! https://github.com/frafra/serenare'   
        expected = [('message', datetime.datetime(2016, 1, 28, 12, 46, 57), 'frafra', 'wow! <a href="https://github.com/frafra/serenare">https://github.com/frafra/serenare</a>')]
        self.assertEqual(list(serenare.parse(line)), expected)
    def test_accepted(self):
        line = '[2015/11/08 14:22:15] (G) [main] frafra (127.0.0.1:8110) accepted the call'
        expected = [('node-join', datetime.datetime(2015, 11, 8, 14, 22, 15), 'frafra', '127.0.0.1:8110')]
        self.assertEqual(list(serenare.parse(line)), expected)
    def test_joined(self):
        line = '[2015/11/08 14:22:15] (G) [main] frafra (127.0.0.1:8111) has joined the conference'
        expected = [('node-join', datetime.datetime(2015, 11, 8, 14, 22, 15), 'frafra', '127.0.0.1:8111')]
    def test_parted(self):
        line = '[2015/11/08 14:22:20] (G) [main] frafra (127.0.0.1:8110) has left (reason: call ended)'
        expected = [('node-left', datetime.datetime(2015, 11, 8, 14, 22, 20), 'frafra', '127.0.0.1:8110')]
        self.assertEqual(list(serenare.parse(line)), expected)
    def test_boolean(self):
        for text, key in (
            ('Autoaccept calls', 'autoaccept'),
            ('Loopback', 'loopback'),
            ('Mute', 'mute'),
        ):
            for value in ('on', 'off'):
                line = '[2015/11/08 14:13:12] (G) [main] {}: {}'.format(text, value)
                expected = [(key, value)]
                self.assertEqual(list(serenare.parse(line)), expected)
    def test_recording(self):
        line = '[2015/11/08 14:13:15] (G) [main] Recording: on, file: rec_20151108_141315.opus'
        expected = [('recording', 'on'), ('generic', '[2015/11/08 14:13:15] (G) [main] Recording: on, file: rec_20151108_141315.opus')]
        self.assertEqual(list(serenare.parse(line)), expected)
        line = '[2015/11/08 14:13:15] (G) [main] Recording: off'
        expected = [('recording', 'off'), ('generic', '[2015/11/08 14:13:15] (G) [main] Recording: off')]
        self.assertEqual(list(serenare.parse(line)), expected)

if __name__ == '__main__':
    unittest.main()

