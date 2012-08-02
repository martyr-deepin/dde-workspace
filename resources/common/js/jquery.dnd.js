/*!
 * @fileOverview Native DND support for jQuery
 * @author pozs <david.pozsar@gmail.com>
 * @license http://opensource.org/licenses/gpl-3.0.html GNU General Public License
 */

;( function( $, global, undefined ) {

"use strict";

var MULCHAR = 2,
    icons   = {},
    moveHnd = null,
    moveOff = null,
    isNatv  = "ondragstart" in global,
    cancel  = function ( event ) {
        event.preventDefault();
        return false;
    },
    unparam = function ( str ) {
        var params = {},
            pairs = str.split( "&" ),
            key, value, i, l;
        
        for ( i = 0, l = pairs.length; i < l; ++i ) {
            value = pairs[i].split( "=" );
            key = value.shift();
            value = value.join( "=" );
            params[ decodeURIComponent( key ) ] = value
                  ? decodeURIComponent( value.replace( /\+/g, " " ) ) : "";
        }
        
        return params;
    },
    firstUrl = function ( uriList ) {
        return String( uriList )
            .replace( /^\s*#[^\n\r]*[\n\r]+/, "" )
            .split( /[\n\r]/, 1 )[0];
    },
    fixData = function ( dataTransfer ) {
        var cache = {},
            dropEffect,
            effectAllowed,
            get = function ( type ) {
                try {
                    return dataTransfer.getData( type );
                } catch ( e ) {
                    return null;
                }
            },
            set = function ( type, value ) {
                try {
                    dataTransfer.setData( type, value );
                    return typeof dataTransfer.getData( type ) != "undefined";
                } catch ( e ) {
                    return false;
                }
            },
            clear = function ( type ) {
                try {
                    dataTransfer.clearData( type );
                    var tmp = dataTransfer.getData( type );
                    return ! type || typeof tmp == "undefined" || tmp == null;
                } catch ( e ) {
                    return false;
                }
            },
            types = $.extend( [], {
                "_update": function () {
                    var txt = get( "Text" ),
                        uri = false,
                        ty, i, l, type;
                    
                    this.length = 0;
                    
                    if ( txt ) {
                        if ( MULCHAR == txt.charCodeAt( 0 ) ) {
                            ty = unparam( txt.substr( 1 ) );
                            
                            for ( i in ty ) {
                                this.push( i );
                                
                                if ( "text/uri-list" == i ) {
                                    uri = true;
                                }
                            }
                        } else {
                            this.push( "text/plain" );
                        }
                    }
                    
                    if ( ! uri && ( uri = get( "URL" ) ) ) {
                        this.push( "text/uri-list" );
                    }
                    
                    if ( "types" in dataTransfer && dataTransfer.types ) {
                        for ( i = 0, l = dataTransfer.types.length; i < l; ++i ) {
                            type = dataTransfer.types[i] || dataTransfer.types.item( i );
                            
                            if ( ( "text/uri-list" == type && uri ) ||
                                 ( "text/plain" == type && txt ) ||
                                 ( "text" == type ) || ( "url" == type ) ) {
                                continue;
                            }
                            
                            if ( ! this.contains( type ) ) {
                                this.push( type );
                            }
                        }
                    }
                },
                "item": function ( index ) {
                    return this[index];
                },
                "contains": function ( type ) {
                    var i, l = this.length;
                    type = String( type ).toLowerCase();
                    
                    for ( i = 0; i < l; ++i ) {
                        if ( String( this[i] ).toLowerCase() == type ) {
                            return true;
                        }
                    }
                    
                    return false;
                },
                "indexOf": function ( type ) {
                    var i, l = this.length;
                    type = String( type ).toLowerCase();
                    
                    for ( i = 0; i < l; ++i ) {
                        if ( String( this[i] ).toLowerCase() == type ) {
                            return i;
                        }
                    }
                    
                    return -1;
                }
            } );
        
        types._update();
        
        try {
            dropEffect = dataTransfer.dropEffect;
        } catch ( e ) {}
        
        try {
            effectAllowed = dataTransfer.effectAllowed;
        } catch ( e ) {}
        
        return {
            "types": types,
            "files": dataTransfer.files || [],
            "dropEffect": dropEffect,
            "effectAllowed": effectAllowed,
            "effectAllowedIs": function ( is ) {
                return $.dnd.effectIs( this.effectAllowed, is );
            },
            "effectAllowedAdd": function ( add ) {
                this.effectAllowed = $.dnd.effectAdd( this.effectAllowed, add );
                return this;
            },
            "effectAllowedRemove": function ( remove ) {
                this.effectAllowed = $.dnd.effectRemove( this.effectAllowed, remove );
                return this;
            },
            "addElement": function ( node ) {
                return dataTransfer.addElement( node );
            },
            "getData": function ( type ) {
                type = String( type ).toLowerCase();
                
                if ( type in cache ) {
                    return cache[type];
                }
                
                if ( "html" == type ) {
                    type = "text/html";
                }
                
                if ( "url" == type ) {
                    return get( "URL" );
                }
                
                var result,
                    txt = get( "Text" ),
                    ty = false;
                
                if ( txt && MULCHAR == txt.charCodeAt( 0 ) ) {
                    ty = unparam( txt.substr( 1 ) );
                }
                
                switch ( type ) {
                    case "text":
                    case "text/plain":
                        return ty ? ty["text/plain"] : txt;
                        break;
                    
                    case "text/uri-list":
                        return ty ? ty["text/uri-list"] ||
                            get( "text/uri-list" ) : get( "URL" );
                        break;
                    
                    default:
                        return ty ? ty[type] : get( type );
                        break;
                }
                
                return result;
            },
            "setData": function ( type, value ) {
                type = String( type ).toLowerCase();
                
                if ( "html" == type ) {
                    type = "text/html";
                }
                
                var result,
                    txt = get( "Text" ) || cache._ || cache["text/plain"],
                    ty = {};
                
                if ( txt ) {
                    if ( MULCHAR == txt.charCodeAt( 0 ) ) {
                        ty = unparam( txt.substr( 1 ) );
                    } else {
                        ty["text/plain"] = txt;
                    }
                }
                
                if ( "url" == type ) {
                    set( "URL", value );
                    
                    if ( ! set( "text/uri-list", value ) ) {
                        ty["text/uri-list"] = String( value );
                        set( "Text", cache._ = String.fromCharCode( MULCHAR ) + $.param( ty ) );
                    }
                    
                    if ( ! types.contains( "text/uri-list" ) ) {
                        types.push( "text/uri-list" );
                    }
                    
                    cache["url"] = value;
                    cache["text/uri-list"] = value;
                    return this;
                }
                
                switch ( type ) {
                    case "text":
                    case "text/plain":
                        if ( ! set( "text/plain", value ) ) {
                            ty["text/plain"] = String( value );
                            set( "Text", cache._ = String.fromCharCode( MULCHAR ) + $.param( ty ) );
                        }
                        
                        if ( ! types.contains( "text/plain" ) ) {
                            types.push( "text/plain" );
                        }
                        
                        cache["text/plain"] = value;
                        return this;
                    
                    case "text/uri-list":
                        var url = firstUrl( value );
                        
                        cache["url"] = url;
                        set( "URL", url );
                        
                        if ( ! set( "text/uri-list", value ) ) {
                            ty["text/uri-list"] = String( value );
                            set( "Text", cache._ = String.fromCharCode( MULCHAR ) + $.param( ty ) );
                        }
                        
                        if ( ! types.contains( "text/uri-list" ) ) {
                            types.push( "text/uri-list" );
                        }
                        
                        cache["text/uri-list"] = value;
                        return this;
                    
                    case "text/html":
                        var text = "";
                        
                        if ( "object" == $.type( value ) && "innerHTML" in value ) {
                            value = $( value );
                        }
                        
                        if ( value instanceof $ ) {
                            text = value.text();
                            value = value.html();
                        } else {
                            text = $( "<div />" ).html( value ).text();
                        }
                        
                        if ( ! set( "text/plain", text ) ) {
                            ty["text/plain"] = String( text );
                            set( "Text", cache._ = String.fromCharCode( MULCHAR ) + $.param( ty ) );
                        }
                        
                        if ( ! types.contains( "text/plain" ) ) {
                            types.push( "text/plain" );
                        }
                        
                        cache["text/plain"] = text;
                        
                    default:
                        if ( ! set( type, value ) ) {
                            ty[type] = String( value );
                            set( "Text", cache._ = String.fromCharCode( MULCHAR ) + $.param( ty ) );
                        }
                        
                        if ( ! types.contains( type ) ) {
                            types.push( type );
                        }
                        
                        cache[type] = value;
                        return this;
                }
            },
            "clearData": function ( type ) {
                if ( ! type ) {
                    clear();
                    types.length = 0;
                    return this;
                }
                
                type = String( type ).toLowerCase();
                
                if ( "html" == type ) {
                    type = "text/html";
                }
                
                var result,
                    txt = get( "Text" ) || cache["text/plain"],
                    ty = {},
                    i;
                
                if ( txt ) {
                    if ( MULCHAR == txt.charCodeAt( 0 ) ) {
                        ty = unparam( txt.substr( 1 ) );
                    } else {
                        ty["text/plain"] = txt;
                    }
                }
                
                if ( "url" == type ) {
                    clear( "URL" );
                    
                    if ( ! clear( "text/uri-list" ) ) {
                        delete ty["text/uri-list"];
                        set( "Text", cache._ = String.fromCharCode( MULCHAR ) + $.param( ty ) );
                    }
                    
                    if ( ~ ( i = types.indexOf( "text/uri-list" ) ) ) {
                        delete types[i];
                    }
                    
                    delete cache["url"];
                    delete cache["text/uri-list"];
                    return this;
                }
                
                switch ( type ) {
                    case "text":
                    case "text/plain":
                        if ( ! clear( "text/plain", value ) ) {
                            delete ty["text/plain"];
                            set( "Text", cache._ = String.fromCharCode( MULCHAR ) + $.param( ty ) );
                        }
                        
                        if ( ~ ( i = types.indexOf( "text/plain" ) ) ) {
                            delete types[i];
                        }
                        
                        delete cache["text/plain"];
                        return this;
                    
                    case "text/uri-list":
                        clear( "URL" );
                        
                        if ( ! clear( "text/uri-list", value ) ) {
                            delete ty["text/uri-list"];
                            set( "Text", cache._ = String.fromCharCode( MULCHAR ) + $.param( ty ) );
                        }
                        
                        if ( ~ ( i = types.indexOf( "text/uri-list" ) ) ) {
                            delete types[i];
                        }
                        
                        delete cache["url"];
                        delete cache["text/uri-list"];
                        return this;
                    
                    default:
                        if ( ! clear( type ) ) {
                            delete ty[type];
                            set( "Text", cache._ = String.fromCharCode( MULCHAR ) + $.param( ty ) );
                        }
                        
                        if ( ~ ( i = types.indexOf( type ) ) ) {
                            delete types[i];
                        }
                        
                        delete cache[type];
                        return this;
                }
            },
            "setDragImage": function ( node, x, y ) {
                if ( "string" != typeof node ) {
                    node = $( node );
                    
                    if ( $( node ).is( "img" ) ) {
                        node = node.attr( "src" );
                    }
                }
                
                if ( "string" == typeof node ) {
                    if ( ! ( node in icons ) ) {
                        icons[node] = new Image();
                        icons[node].src = node;
                        
                        $.ajax( {
                            "url": node,
                            "async": false
                        } );
                    }
                    
                    if ( $.isFunction( dataTransfer.setDragImage ) ) {
                        dataTransfer.setDragImage( icons[node], x, y );
                    } else {
                        if ( moveHnd ) {
                            moveOff();
                        }
                        
                        x = Math.min( x, -2 );
                        y = Math.min( y, -2 );
                        
                        $( "body" ).on( "mousemove dragover", moveHnd = function ( evt ) {
                            $( icons[node] ).css( {
                                "display": "inline",
                                "top": ( evt.pageY || evt.originalEvent.pageY || evt.originalEvent.clientY || evt.originalEvent.offsetY ) - y,
                                "left": ( evt.pageX || evt.originalEvent.pageX || evt.originalEvent.clientX || evt.originalEvent.offsetX ) - x
                            } );
                            
                            if ( ! $( icons[node] ).parent().length ) {
                                $( icons[node] )
                                    .css( "position", "absolute" )
                                    .appendTo( "body" );
                            }
                        } );
                        
                        moveOff = function () {
                            $( "body" ).off( "mousemove dragover", moveHnd );
                            $( icons[node] ).css( "display", "none" );
                            moveHnd = null;
                            moveOff = null;
                        };
                    }
                }
                
                return this;
            }
        };
    },
    dndEvent = function ( handler, mode ) {
        switch ( mode ) {
            case "end":
                return function ( evt ) {
                    evt.preventDefault();
                    evt.dataTransfer = fixData( evt.originalEvent.dataTransfer );
                    
                    if ( moveHnd ) {
                        moveOff();
                    }
                    
                    if ( $.isFunction( handler ) ) {
                        handler.call( this, evt );
                    }
                    
                    return false;
                };
            
            case "leave":
                return function ( evt ) {
                    evt.preventDefault();
                    evt.dataTransfer = fixData( evt.originalEvent.dataTransfer );
                    handler.call( this, evt );
                    return false;
                };
            
            case "start":
                return function ( evt ) {
                    // evt.originalEvent.dataTransfer.dropEffect = $.dnd.EFFECT_COPY;
                    evt.originalEvent.dataTransfer.effectAllowed = $.dnd.EFFECT_ALL;
                    
                    if ( ! evt.originalEvent.dataTransfer.getData( "Text" ) &&
                         ! evt.originalEvent.dataTransfer.getData( "URL" ) ) {
                        evt.originalEvent.dataTransfer.setData( "Text", "" );
                    }
                    
                    evt.dataTransfer = fixData( evt.originalEvent.dataTransfer );
                    handler.call( this, evt );
                    
                    try {
                        evt.originalEvent.dataTransfer.effectAllowed =
                            evt.dataTransfer.effectAllowed;
                    } catch ( e ) { }
                };
            
            case "enter":
            case "over":
            case "drop":
            default:
                return function ( evt ) {
                    evt.preventDefault();
                    evt.dataTransfer = fixData( evt.originalEvent.dataTransfer );
                    handler.call( this, evt );
                    
                    if ( moveHnd ) {
                        moveHnd( evt );
                    }
                    
                    try {
                        evt.originalEvent.dataTransfer.dropEffect =
                            evt.dataTransfer.dropEffect;
                    } catch ( e ) { }
                    
                    return false;
                };
        }
    };

$.extend( {
    "dnd": $.extend( function jQuery_dnd () {
        return $.dnd.isNative();
    }, {
        "EFFECT_NONE": "none",
        "EFFECT_COPY": "copy",
        "EFFECT_LINK": "link",
        "EFFECT_MOVE": "move",
        "EFFECT_COPY_LINK": "copyLink",
        "EFFECT_COPY_MOVE": "copyMove",
        "EFFECT_LINK_MOVE": "linkMove",
        "EFFECT_LINK_COPY": "copyLink",
        "EFFECT_MOVE_COPY": "copyMove",
        "EFFECT_MOVE_LINK": "linkMove",
        "EFFECT_COPY_LINK_MOVE": "all",
        "EFFECT_COPY_MOVE_LINK": "all",
        "EFFECT_LINK_COPY_MOVE": "all",
        "EFFECT_LINK_MOVE_COPY": "all",
        "EFFECT_MOVE_LINK_COPY": "all",
        "EFFECT_MOVE_COPY_LINK": "all",
        "EFFECT_ALL": "all",
        
        "effectIs": function ( current, is ) {
            switch ( true ) {
                case current == is:
                case is == $.dnd.EFFECT_NONE:
                case current == $.dnd.EFFECT_ALL:
                    return true;
                
                case current == $.dnd.EFFECT_NONE:
                    return false;
                
                case current == $.dnd.EFFECT_COPY_LINK && is == $.dnd.EFFECT_COPY:
                case current == $.dnd.EFFECT_COPY_LINK && is == $.dnd.EFFECT_LINK:
                case current == $.dnd.EFFECT_LINK_MOVE && is == $.dnd.EFFECT_MOVE:
                case current == $.dnd.EFFECT_LINK_MOVE && is == $.dnd.EFFECT_LINK:
                case current == $.dnd.EFFECT_COPY_MOVE && is == $.dnd.EFFECT_COPY:
                case current == $.dnd.EFFECT_COPY_MOVE && is == $.dnd.EFFECT_MOVE:
                    return true;
            }
            
            return false;
        },
        
        "effectAdd": function ( current, add ) {
            switch ( true ) {
                case current == add:
                case add == $.dnd.EFFECT_NONE:
                case current == $.dnd.EFFECT_ALL:
                    return current;
                
                case current == $.dnd.EFFECT_NONE:
                    return add;
                
                case current == $.dnd.EFFECT_COPY && add == $.dnd.EFFECT_LINK:
                case add == $.dnd.EFFECT_COPY && current == $.dnd.EFFECT_LINK:
                    return $.dnd.EFFECT_COPY_LINK;
                
                case current == $.dnd.EFFECT_COPY && add == $.dnd.EFFECT_MOVE:
                case add == $.dnd.EFFECT_COPY && current == $.dnd.EFFECT_MOVE:
                    return $.dnd.EFFECT_COPY_MOVE;
                
                case current == $.dnd.EFFECT_LINK && add == $.dnd.EFFECT_MOVE:
                case add == $.dnd.EFFECT_LINK && current == $.dnd.EFFECT_MOVE:
                    return $.dnd.EFFECT_LINK_MOVE;
                
                case add == $.dnd.EFFECT_ALL:
                case current == $.dnd.EFFECT_COPY_LINK && add == $.dnd.EFFECT_MOVE:
                case add == $.dnd.EFFECT_COPY_LINK && current == $.dnd.EFFECT_MOVE:
                case current == $.dnd.EFFECT_COPY_MOVE && add == $.dnd.EFFECT_LINK:
                case add == $.dnd.EFFECT_COPY_MOVE && current == $.dnd.EFFECT_LINK:
                case current == $.dnd.EFFECT_LINK_MOVE && add == $.dnd.EFFECT_COPY:
                case add == $.dnd.EFFECT_LINK_MOVE && current == $.dnd.EFFECT_COPY:
                    return $.dnd.EFFECT_ALL;
            }
            
            return add;
        },
        
        "effectRemove": function ( current, remove ) {
            switch ( true ) {
                case remove == $.dnd.EFFECT_NONE:
                    return current;
                
                case current == remove:
                case remove == $.dnd.EFFECT_ALL:
                case current == $.dnd.EFFECT_NONE:
                    return $.dnd.EFFECT_NONE;
                
                case current == $.dnd.EFFECT_ALL && remove == $.dnd.EFFECT_COPY_MOVE:
                case current == $.dnd.EFFECT_COPY_LINK && remove == $.dnd.EFFECT_COPY:
                case current == $.dnd.EFFECT_LINK_MOVE && remove == $.dnd.EFFECT_MOVE:
                    return $.dnd.EFFECT_LINK;
                
                case current == $.dnd.EFFECT_ALL && remove == $.dnd.EFFECT_COPY_LINK:
                case current == $.dnd.EFFECT_COPY_MOVE && remove == $.dnd.EFFECT_COPY:
                case current == $.dnd.EFFECT_LINK_MOVE && remove == $.dnd.EFFECT_LINK:
                    return $.dnd.EFFECT_MOVE;
                
                case current == $.dnd.EFFECT_ALL && remove == $.dnd.EFFECT_LINK_MOVE:
                case current == $.dnd.EFFECT_COPY_MOVE && remove == $.dnd.EFFECT_MOVE:
                case current == $.dnd.EFFECT_COPY_LINK && remove == $.dnd.EFFECT_LINK:
                    return $.dnd.EFFECT_COPY;
                
                case current == $.dnd.EFFECT_ALL && remove == $.dnd.EFFECT_COPY:
                    return $.dnd.EFFECT_LINK_MOVE;
                
                case current == $.dnd.EFFECT_ALL && remove == $.dnd.EFFECT_MOVE:
                    return $.dnd.EFFECT_COPY_LINK;
                
                case current == $.dnd.EFFECT_ALL && remove == $.dnd.EFFECT_LINK:
                    return $.dnd.EFFECT_COPY_MOVE;
            }
            
            return current;
        },
        
        "isNative": function jQuery_dnd_isNative () {
            return isNatv = isNatv || "ondragstart" in global.document.body;
        }
    } )
} );

$.extend( $.fn, {
    "drag": function jQuery_dnd_drag ( start, end ) {
        if ( "object" == typeof start ) {
            end = start.end;
            start = start.start;
        }
        
        if ( $.dnd.isNative() ) {
            this.attr( "draggable", "true" )
                .prop( "draggable", true )
                .css( {
                    "webkitUserDrag": "element",
                    "webkitUserSelect": "none",
                    "khtmlUserDrag": "element",
                    "khtmlUserSelect": "none",
                    "MozUserSelect": "none",
                    "MsUserSelect": "none",
                    "userSelect": "none"
                } );
            
            this.each( function () {
                var thi$ = $( this );
                if ( this.dragDrop && ! thi$.is( "a, img" ) ) {
                    thi$.on( "selectstart", function ( evt ) {
                        this.dragDrop();
                        return false;
                    } );
                }
            } );
            
            this.on( "dragstart", dndEvent( start, "start" ) );
            this.on( "dragend", dndEvent( end, "end" ) );
        }
        
        return this;
    },
    
    "drop": function jQuery_dnd_drop ( drop, over, enter, leave ) {
        if ( "object" == typeof drop ) {
            leave = drop.leave;
            enter = drop.enter;
            over = drop.over;
            drop = drop.drop;
        }
        
        if ( $.dnd.isNative() ) {
            this.on( "dragover", $.isFunction( enter )
                    ? dndEvent( over, "over" ) : cancel )
                .on( "dragenter", $.isFunction( enter )
                    ? dndEvent( enter, "enter" ) : cancel )
                .on( "drop", dndEvent( drop, "drop" ) );
            
            if ( $.isFunction( leave ) ) {
                this.on( "dragleave", dndEvent( leave, "leave" ) );
            }
        }
        
        return this;
    }
} );

} )( jQuery, window );
