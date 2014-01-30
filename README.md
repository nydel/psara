psara is pretty, small, and really awesome.

it's essentially a method of utilizing commonlisp for web development.

heavily-dependent on system :HUNCHENTOOT and a few others (basically dependent on quicklisp to retrieve files, for now)

this early version of psara assumes a proxypass on an apache server.

in the folder containing your httpd.conf, modify /extras/vhosts.conf (or something?)

add the server such that some folder or subdomain redirects to **port 9903**

in this early version we sometimes assume the folder to be either the subdomain honey.x.x or the folder /hunchentoot/

all this will be automatically handled soon as the project develops
