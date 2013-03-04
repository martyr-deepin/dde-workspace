#ifndef _DEEPIN_BACKGROUND_H_
#define _DEEPIN_BACKGROUND_H_

#include <gio/gio.h>
#include "gsd-background-manager.h"
#include "gsd-background-manager-private.h"

#define DEEPIN_EXPORT
//gaussian blur
#define BG_GAUSSIAN_PICT_NAME	".deepin_background_gaussian.png"
//#define BG_GAUSSIAN_PICT_PATH	"/var/cache/background/gaussian.png"
//not used#define BG_GAUSSIAN_PICT_DIR	"/var/cache/background"
//for test#define BG_GAUSSIAN_PICT_PATH	"gaussian.png"

#define BG_GAUSSIAN_SIGMA	10.0  //double
#define BG_GAUSSIAN_NSTEPS	10UL  //long

// all schema related information.
#define	BG_SCHEMA_ID		"com.deepin.dde.background"

#define BG_FPS			30		//in my implementation, the actual fps may not be 30.

#define	BG_CURRENT_PICT		"current-picture"
#define BG_PICTURE_URIS		"picture-uris" //better renamed to picture-URIs
#define DELIMITER		';'		//picture-uri string delimiter 
#define BG_BG_DURATION		"background-duration"
#define BG_XFADE_MANUAL_INTERVAL "cross-fade-manual-interval"     //manually change background
#define BG_XFADE_AUTO_INTERVAL	 "cross-fade-auto-interval"       //automatically change background
#define BG_XFADE_AUTO_MODE	 "cross-fade-auto-mode"		  //how next picture is chosen, random, or 
#define BG_DRAW_MODE		 "draw-mode"			  //

#define BG_DEFAULT_PICTURE	 "/usr/share/backgrounds/default_background.jpg"
//the following enumerations should be synced with com.deepin.dde.background.gschema.xml
typedef enum BgXFadeAutoMode BgXFadeAutoMode;
enum BgXFadeAutoMode
{
    XFADE_AUTO_MODE_SEQUENTIAL = 1,
    XFADE_AUTO_MODE_RANDOM = 2
};
typedef enum BgDrawMode BgDrawMode;
enum BgDrawMode
{
    DRAW_MODE_SCALING = 1,
    DRAW_MODE_TILING = 2
};

//exporting functions for gsd-background-manager.c
extern void bg_util_init (GsdBackgroundManager* manager);

extern void bg_util_connect_screen_signals (GsdBackgroundManager* manager);
extern void bg_util_disconnect_screen_signals (GsdBackgroundManager* manager);

#endif
