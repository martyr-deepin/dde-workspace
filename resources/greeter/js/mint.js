var Mint = new Object();
Mint.save = function() 
{
	var now		= new Date();
	var debug	= false; // this is set by php 
	if (window.location.hash == '#Mint:Debug') { debug = true; };
	var path	= 'http://fredhq.com/mint/?record&key=334647314f546631306850474c354d385753444971344164353331';
	path 		= path.replace(/^https?:/, window.location.protocol);
	
	// Loop through the different plug-ins to assemble the query string
	for (var developer in this) 
	{
		for (var plugin in this[developer]) 
		{
			if (this[developer][plugin] && this[developer][plugin].onsave) 
			{
				path += this[developer][plugin].onsave();
			};
		};
	};
	// Slap the current time on there to prevent caching on subsequent page views in a few browsers
	path += '&'+now.getTime();
	
	// Redirect to the debug page
	if (debug) { window.open(path+'&debug&errors', 'MintLiveDebug'+now.getTime()); return; };
	
	var ie = /*@cc_on!@*/0;
	if (!ie && document.getElementsByTagName && (document.createElementNS || document.createElement))
	{
		var tag = (document.createElementNS) ? document.createElementNS('http://www.w3.org/1999/xhtml', 'script') : document.createElement('script');
		tag.type = 'text/javascript';
		tag.src = path + '&serve_js';
		document.getElementsByTagName('head')[0].appendChild(tag);
	}
	else if (document.write)
	{
		document.write('<' + 'script type="text/javascript" src="' + path + '&amp;serve_js"><' + '/script>');
	};
};
if (!Mint.SI) { Mint.SI = new Object(); }
Mint.SI.Referrer = 
{
	onsave	: function() 
	{
		var encoded = 0;
		if (typeof Mint_SI_DocumentTitle == 'undefined') { Mint_SI_DocumentTitle = document.title; }
		else { encoded = 1; };
		var referer		= (window.decodeURI)?window.decodeURI(document.referrer):document.referrer;
		var resource	= (window.decodeURI)?window.decodeURI(document.URL):document.URL;
		return '&referer=' + escape(referer) + '&resource=' + escape(resource) + '&resource_title=' + escape(Mint_SI_DocumentTitle) + '&resource_title_encoded=' + encoded;
	}
};
if (!Mint.SI) { Mint.SI = new Object(); }
Mint.SI.UserAgent007 = 
{
	versionHigh			: 16,
	flashVersion		: 0,
	resolution			: '0x0',
	detectFlashVersion	: function () 
	{
		var ua = navigator.userAgent.toLowerCase();
		if (navigator.plugins && navigator.plugins.length) 
		{
			var p = navigator.plugins['Shockwave Flash'];
			if (typeof p == 'object') 
			{
				for (var i=this.versionHigh; i>=3; i--) 
				{
					if (p.description && p.description.indexOf(' ' + i + '.') != -1) { this.flashVersion = i; break; }
				}
			}
		}
		else if (ua.indexOf("msie") != -1 && ua.indexOf("win")!=-1 && parseInt(navigator.appVersion) >= 4 && ua.indexOf("16bit")==-1) 
		{
			var vb = '<scr' + 'ipt language="VBScript"\> \nOn Error Resume Next \nDim obFlash \nFor i = ' + this.versionHigh + ' To 3 Step -1 \n   Set obFlash = CreateObject("ShockwaveFlash.ShockwaveFlash." & i) \n   If IsObject(obFlash) Then \n      Mint.SI.UserAgent007.flashVersion = i \n      Exit For \n   End If \nNext \n<'+'/scr' + 'ipt\> \n';
			document.write(vb);
		}
		else if (ua.indexOf("webtv/2.5") != -1) this.flashVersion = 3;
		else if (ua.indexOf("webtv") != -1) this.flashVersion = 2;
		return this.flashVersion;
	},
	onsave				: function() 
	{
		if (this.flashVersion == this.versionHigh) { this.flashVersion = 0; };
		this.resolution = screen.width+'x'+screen.height;
		return '&resolution=' + this.resolution + '&flash_version=' + this.flashVersion;
	}
};
Mint.SI.UserAgent007.detectFlashVersion();
if (!Mint.SI) { Mint.SI = new Object(); }
Mint.SI.RealEstate = 
{
	onsave	: function() 
	{
		var width = -1;
		var height = -1;
		
		if (typeof window.innerWidth != "undefined")
		{
			width = window.innerWidth;
			height = window.innerHeight;
		}
		else if (document.documentElement && typeof document.documentElement.offsetWidth != "undefined" && document.documentElement.offsetWidth != 0)
		{
			width = document.documentElement.offsetWidth;
			height = document.documentElement.offsetHeight;
		}
		else if (document.body && typeof document.body.offsetWidth != "undefined")
		{
			width = d.body.offsetWidth;
			height = d.body.offsetHeight;
		};
		
		return '&window_width=' + width + '&window_height=' + height;
	}
};
if (!Mint.TK) {
	Mint.TK = new Object();
}
Mint.TK.Durations = {
	now : new Date(),
	recalc : function() {
		var then = new Date();
		var img = new Image();
		var path = 'http://fredhq.com/mint/pepper/tillkruess/durations/recalc.php?token=251133500&time=';
		path += Math.round((then.getTime() - Mint.TK.Durations.now.getTime()) / 1000);
		img.src = path.replace(/^https?:/, window.location.protocol);
	},
	onsave : function() {
		return '&token=251133500';
	}
};window.setInterval('Mint.TK.Durations.recalc()', 15 * 1000);
if (window.addEventListener) {
	window.addEventListener('unload', Mint.TK.Durations.recalc, false);
} else if (window.attachEvent) {
	window['eunload' + Mint.TK.Durations.recalc] = Mint.TK.Durations.recalc;
	window['unload' + Mint.TK.Durations.recalc] = function() {
		window['eunload' + Mint.TK.Durations.recalc](window.event);
	}
	window.attachEvent('onunload', window['unload' + Mint.TK.Durations.recalc]);
}
Mint.save();