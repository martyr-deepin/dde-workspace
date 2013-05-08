#!/usr/bin/env python
# encoding: utf-8
import base64
import StringIO

files = ['/usr/share/icons/Deepin/apps/48/deepin-user-manual.png',
    "/usr/share/icons/Deepin/apps/48/deepin-media-player.png",
    "/usr/share/icons/Deepin/apps/48/deepin-music-player.png",
    "/usr/share/icons/Deepin/apps/48/deepin-screenshot.png"]

for i in xrange(len(files)):
    with open(files[i], 'rb') as h:
        with open(str(i) + ".txt", "wa") as o:
            c = base64.standard_b64encode(h.read())
            s = StringIO.StringIO(c)
            lines = s.readlines()
            for j in iter(xrange(len(lines))):
                lines[j] = "\"" + lines[j] + "\\n\""
                o.write(lines[j])
            base64.encode(h, o)
