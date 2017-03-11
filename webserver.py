from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
from configobj import ConfigObj
import os.path
import signal
PORT_NUMBER = 8000

def handler(signum, frame):
    print "Caught signal: " + str(signum) + ", shutting down gracefully"
    destroy_pid()
    exit()
    return

def create_pid(location):
    f = open(location, 'w')
    f.write(str(os.getpid()))
    f.close()
    return os.getpid()

def destroy_pid():
    os.remove(cfg['OCS_PID_WEBSERVER_PATH'])
    return

#This class will handles any incoming request from
#the browser 
class myHandler(BaseHTTPRequestHandler):
    #Handler for the GET requests
    def do_GET(self):
        # Turn on the override and then redirect to homepage
        if self.path == "/on":
            self.send_response(301)
            self.send_header('Location', '/')
            open(override_file_loc, "w")
            print "Creating file"
            self.end_headers()
            return
        # Turn off the override and then redirect to homepage
        elif self.path == "/off":
            self.send_response(301)
            self.send_header('Location', '/')
            os.remove(override_file_loc)
            print "Deleted file"
            self.end_headers()
            return
        else:
            self.send_response(200)
            self.send_header('Content-type','text/html')
            self.end_headers()

        if os.path.isfile(override_file_loc):
            self.wfile.write("<h1>Override is on</h1><a href='off'>Turn off override</a>")
        else:
            self.wfile.write("<h1>Override is off</h1><a href='on'>Turn on override</a>")
        return

# Do setup stuff like creating pid file
cfg = ConfigObj('ocs.cfg')
override_file_loc = cfg['OCS_OVERRIDE_FILE']
create_pid(cfg['OCS_PID_WEBSERVER_PATH']);
signal.signal(signal.SIGABRT, handler)

#Create a web server and define the handler to manage the
#incoming request
server = HTTPServer(('', PORT_NUMBER), myHandler)
print 'Started httpserver on port ' , PORT_NUMBER

#Wait forever for incoming htto requests
server.serve_forever()

