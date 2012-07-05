#!/usr/bin/python2
import xcb
from xcb.xproto import *
import xcb.render

def find_format(screen):
    for d in screen.depths:
        if d.depth == depth:
            for v in d.visuals:
                if v.visual == visual:
                    return v.format

    raise Exception("Failed to find an appropriate Render pictformat!")


def startup():
    white = setup.roots[0].white_pixel

    conn.core.CreateWindow(depth, window, root,
                           0, 0, 640, 480, 0,
                           WindowClass.InputOutput,
                           visual,
                           CW.BackPixel | CW.EventMask,
                           [ white, EventMask.ButtonPress | EventMask.EnterWindow | EventMask.LeaveWindow | EventMask.Exposure ])

    cookie = conn.render.QueryPictFormats()
    reply = cookie.reply()
    format = find_format(reply.screens[0])

    name = 'X Python Binding Demo'
    conn.core.ChangeProperty(PropMode.Replace, window,
            Atom.WM_NAME, Atom.STRING,
            8, len(name), name)
    conn.render.CreatePicture(pid, window, format, 0, [])
    conn.core.MapWindow(window)
    conn.flush()


def paint():
    conn.core.ClearArea(False, window, 0, 0, 0, 0)

    for x in xrange(0, 7):
        for y in xrange(0, 5):
            rectangle = ((x + 1) * 24 + x * 64, (y + 1) * 24 + y * 64, 64, 64)
            color = (x * 65535 / 7, y * 65535 / 5, (x * y) * 65535 / 35, 65535)
            conn.render.FillRectangles(xcb.render.PictOp.Src, pid, color, 1, rectangle)

    conn.flush()


def run():
    startup()
    print 'Click in window to exit.'

    while True:
        try:
            event = conn.wait_for_event()
        except xcb.ProtocolException, error:
            print "Protocol error %s received!" % error.__class__.__name__
            break
        except:
            print "Unexpected error received: %s" % error.message
            break

        if isinstance(event, ExposeEvent):
            paint()
        elif isinstance(event, EnterNotifyEvent):
            print 'Enter (%d, %d)' % (event.event_x, event.event_y)
        elif isinstance(event, LeaveNotifyEvent):
            print 'Leave (%d, %d)' % (event.event_x, event.event_y)
        elif isinstance(event, ButtonPressEvent):
            print 'Button %d down' % event.detail
            break

    conn.disconnect()



conn = xcb.connect()
conn.render = conn(xcb.render.key)

setup = conn.get_setup()
root = setup.roots[0].root
depth = setup.roots[0].root_depth
visual = setup.roots[0].root_visual

window = conn.generate_id()
pid = conn.generate_id()

run()
