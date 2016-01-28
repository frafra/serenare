#!/usr/bin/env python3

import sys
if sys.version_info < (3, 4):
    print("I need Python 3.4 or newer")
    exit(1)

import asyncio
import datetime
import getpass
import html
import importlib.util
import os
import re
import shlex
import signal
import subprocess
import threading

# Only available when called from Qt Quick
if importlib.util.find_spec('pyotherside'):
    import pyotherside

URL = re.compile(r'(https?://\S*)')
TOGGLE = ['mute', 'loop', 'autoaccept']

def parse(line):
    """ Parser compatible with seren 0.0.22 """
    message = line.split()
    if message[0] in TOGGLE:
        yield message[0], message[2] == '1'
    elif message[0] == 'err':
        pass # error
    else:
        yield 'generic', html.escape(line)

class SerenClient(asyncio.Protocol):
    def __init__(self, loop):
        self.loop = loop

    def connection_made(self, transport):
        self.transport = transport

    def data_received(self, data):
        for result in parse(data.decode('utf8').rstrip()):
            pyotherside.send(*result)

    def connection_lost(self, exc):
        self.loop.stop()

    def write(self, message):
        self.transport.write((message+'\n').encode('utf8'))

def create_seren_client(loop):
    global serenClient
    serenClient = SerenClient(loop)
    return serenClient

def start_loop(loop):
    """ Reading from Seren output """
    coro = loop.create_connection(lambda: create_seren_client(loop), '127.0.0.1', 8111)
    loop.run_until_complete(coro)
    loop.run_forever()
    loop.close()

def write_input_transport(transport):
    def write_input(message):
        """ Writing to Seren input """
        transport.write((message+'\n').encode('utf8'))
    return write_input

def kill(process):
    """ Kill process """
    if process.poll() == None:
        process.send_signal(signal.SIGINT)

def start_seren():
    """ Run Seren without ncurses and connect pipes """
    username = getpass.getuser()
    seren = subprocess.Popen(
        shlex.split('seren -N'),
    )
    pyotherside.atexit(lambda: kill(seren))
    loop = asyncio.get_event_loop()
    t = threading.Thread(target=start_loop, args=(loop,))
    t.start()
    pyotherside.send('node-join', datetime.datetime.now(),
                     html.escape(username), '127.0.0.1:8110')

if __name__ == '__main__':
    directory = os.path.dirname(os.path.abspath(__file__))
    resource = os.path.join(directory, 'serenare.qml')
    os.execvp('qmlscene', ('qmlscene', resource))
