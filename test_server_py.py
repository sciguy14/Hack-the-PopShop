import SocketServer
from osax import OSAX
from os import system as cmd
import random

# ------------- THIS ONLY RUNS ON MAC -----------------
# However, it can probably be ported to equivalents for 
# Windows and UNIX

# Code heavily borrowed from http://docs.python.org/library/socketserver.html

# TODO: Fill this in
# PANIC_WAV_FILENAME = /path/to/wav/file

class MyTCPHandler(SocketServer.BaseRequestHandler):

    def handle(self):
        # self.request is the TCP socket connected to the client
        # This assumes only one command is sent per TCP connection - Inefficent!
        sa = OSAX()
        self.data = self.request.recv(1024).strip()
        if self.data != "":
            print "{} wrote:".format(self.client_address[0])
            print self.data
            
            # Loosely, designed as I went "protocol"
            if self.data.isdigit():
                d = int(self.data)
                sa.set_volume((d+0.2)/14.2)
                print "set volume to %f" % d
            elif self.data == "PLAY":
                print "Playing iTunes"
                cmd('osascript -e \'tell application "iTunes" to play\'')
            elif self.data == "PAUSE":
                print "Pausing Itunes"
                cmd('osascript -e \'tell application "iTunes" to pause\'')
            elif self.data == "NEXT":
                print "Going to the next track"
                cmd('osascript -e \'tell application "iTunes" to next track\'')
            elif self.data == "PANIC":
                print "Going to the next track"
                cmd('osascript -e \'tell application "iTunes" to pause\'')
                cmd("afplay %s" % PANIC_WAV_FILENAME)
                cmd('osascript -e \'tell application "iTunes" to play\'')
            else:
                print ("UNDEFINED COMMAND", self.data)

if __name__ == "__main__":
    # Put your IP/PORT here
    HOST, PORT = "192.168.10.13", 10000

    # Create the server, binding to localhost on port 10000
    server = SocketServer.TCPServer((HOST, PORT), MyTCPHandler)

    # Activate the server; this will keep running until you
    # interrupt the program with Ctrl-C
    server.serve_forever()