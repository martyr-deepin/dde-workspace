#include "config.h"
#include "Document.h"
#include "FrameView.h"
#include "Frame.h"
#include "GraphicsContext.h"
#include "HTMLElement.h"
#include <webkit/WebKitDOMElement.h>
#include "webkit/WebKitDOMElementPrivate.h"
#include <cairo/cairo.h>

using namespace WebCore;
extern "C"  {
	int d_dom_element_render(cairo_t* cr, WebKitDOMElement* el);
	void d_dom_element_get_allocation(WebKitDOMElement* el, int *x, int *y, int *width, int *height);
}


void d_dom_element_get_allocation(WebKitDOMElement* el, int *x, int *y, int *width, int *height)
{
	Element* e = WebKit::core(el);
	*x = e->offsetLeft();
	*y = e->offsetTop();
	*width = e->offsetWidth();
	*height = e->offsetHeight();
}

int d_dom_element_render(cairo_t* cr, WebKitDOMElement* el)
{
    Element* e = WebKit::core(el);
    Document* doc = e ? e->document() : 0;
    if (!doc)
        return 0;

    Frame* frame = doc->frame();
    if (!frame || !frame->view() || !frame->contentRenderer())
        return 0;

    FrameView* view = frame->view();
//    view->updateLayoutAndStyleIfNeededRecursive();

    IntRect rect = e->getRect();

    if (rect.size().isEmpty())
        return 0;

    GraphicsContext context(cr);

    context.save();
    context.translate(-rect.x(), -rect.y());

    view->setNodeToDraw(e);
    view->paintContents(&context, rect);
    view->setNodeToDraw(0);
    context.restore();
    return 1;
}
