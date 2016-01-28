#!/usr/bin/env python3

import sys
if sys.version_info < (3, 4):
    print("I need Python 3.4 or newer")
    exit(1)

import cgi
import datetime
import getpass
import importlib.util
import os
import re
import shlex
import subprocess
import _thread

# Only available when called from Qt Quick
if importlib.util.find_spec('pyotherside'):
    import pyotherside

FORMAT = '[%Y/%m/%d %H:%M:%S]'
URL = re.compile(r'(https?://\S*)')

def parse(line):
    """ Parser compatible with seren 0.0.21 """
    if not line.strip():
        pass
    elif line[0] == '[':
        timestamp = datetime.datetime.strptime(line[:21], FORMAT)
        message = line.split()[2:]
        if message[0] == '(C)':
            user = message[1][:-1]
            text = line.split('> ', 1)[1]
            for word in text.split():
                if URL.match(word) == None:
                    text = text.replace(word, cgi.escape(word))
                else:
                    link = URL.sub(r'<a href="\1">\1</a>', word)
                    text = text.replace(word, link)
            yield 'message', timestamp, cgi.escape(user), text
        elif message[0] == '(G)':
            if line.endswith('accepted the call') or \
               line.endswith('has joined the conference'):
                if message[2][0] == '(': # Username unavailable
                    return
                user = message[2]
                host = message[3][1:-1]
                yield 'node-join', timestamp, cgi.escape(user), host
            #elif line.endswith('is calling: /y to accept, /n to refuse'):
            #    pass
            elif ' '.join(message[4:6]) == 'has left':
                user = message[2]
                host = message[3][1:-1]
                yield 'node-left', timestamp, cgi.escape(user), host
            elif message[2] == 'Autoaccept':
                yield 'autoaccept', message[4]
            elif message[2] == 'Mute:':
                yield 'mute', message[3]
            elif message[2] == 'Recording:':
                yield 'recording', message[3].rstrip(',')
                # Showing file name, if provided, with 'generic'
                yield 'generic', cgi.escape(line)
            elif message[2] == 'Loopback:':
                yield 'loopback', message[3]
            else:
               yield 'generic', cgi.escape(line)
        else:
            yield 'generic', cgi.escape(line)
    else:
        yield 'generic', cgi.escape(line)

def read_output(stdout):
    """ Reading from Seren output """
    for line in stdout:
        for result in parse(line.decode('utf8').rstrip()):
            pyotherside.send(*result)

def write_input(message):
    """ Writing to Seren input """
    stdin.write((message+'\n').encode('utf8'))
    stdin.flush()
    if message.startswith('/q'):
        pyotherside.send('exit')

def kill(process):
    """ Kill process """
    if process.poll() == None:
        process.kill()

def start_seren():
    """ Run Seren without ncurses and connect pipes """
    username = getpass.getuser()
    seren = subprocess.Popen(
        shlex.split('seren -N'),
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    global stdin
    stdin = seren.stdin
    pyotherside.atexit(lambda: kill(seren))
    _thread.start_new_thread(read_output, (seren.stdout,))
    pyotherside.send('node-join', datetime.datetime.now(),
                     cgi.escape(username), '127.0.0.1:8110')

if __name__ == '__main__':
    directory = os.path.dirname(os.path.abspath(__file__))
    resource = os.path.join(directory, 'serenare.qml')
    os.execvp('qmlscene', ('qmlscene', resource))
