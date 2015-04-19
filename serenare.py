#!/usr/bin/env python3

import cgi
import datetime
import getpass
import os
import shlex
import subprocess
import _thread

try:
    import pyotherside
except ImportError:
    pass # Only available when called from Qt Quick

FORMAT = '[%Y/%m/%d %H:%M:%S]'

def parse(line):
    if len(line.strip()) == 0:
        pass
    elif line[0] == '[':
        timestamp = datetime.datetime.strptime(line[:21], FORMAT)
        message = line.split()[2:]
        if message[0] == '(C)':
            user = message[1][:-1]
            text = line.split('> ', 1)[1]
            pyotherside.send('message', timestamp,
                             cgi.escape(user), cgi.escape(text))
        elif message[0] == '(G)':
            if line.endswith('accepted the call') or \
               line.endswith('has joined the conference'):
                if message[2][0] == '(': # Username unavailable
                    return
                user = message[2]
                host = message[3][1:-1]
                pyotherside.send('node-join', timestamp,
                                 cgi.escape(user), host)
            elif ' '.join(message[4:6]) == 'has left':
                user = message[2]
                host = message[3][1:-1]
                pyotherside.send('node-left', timestamp,
                                 cgi.escape(user), host)
            elif message[2] == 'Mute:':
                pyotherside.send('mute', message[2])
            else:
                pyotherside.send('generic', cgi.escape(line))
        else:
            pyotherside.send('generic', cgi.escape(line))
    else:
        pyotherside.send('generic', cgi.escape(line))

def readOutput(stdout):
    for line in stdout:
        parse(line.decode('utf8').rstrip())

def writeInput(message):
    stdin.write((message+'\n').encode('utf8'))
    stdin.flush()

def kill(process):
    if process.poll() == None:
        process.kill()

def startSeren():
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
    _thread.start_new_thread(readOutput, (seren.stdout,))

if __name__ == '__main__':
    directory = os.path.dirname(os.path.abspath(__file__))
    resource = os.path.join(directory, 'serenare.qml')
    qmlscene = subprocess.Popen(['qmlscene', resource])
    qmlscene.wait()
    
