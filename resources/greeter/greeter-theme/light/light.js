
LIGHTS.GUI = function( go ) {
	this.initialize( go );
};

LIGHTS.GUI.prototype = {
	initialize: function( go ) {
		LIGHTS.GUI.instance = this;
		this.setup();
        if( go )
            this.setupGo();
		else
            this.setupFail();
	},

	setup: function() {
		return;
	},

	setupGo: function() {

		this.div = document.getElementById( 'lights_outer' );
		this.active = false;
	},

	setupFail: function() {

        //document.body.style.backgroundImage = "url('bg.jpg')";
		document.getElementById( 'lights_fail' ).style.visibility = 'visible';
	},

	fade: function( alpha ) {

	},

	setOpacity: function( div, opacity ) {
		return;
	}
};

LIGHTS.releaseBuild = true;

LIGHTS.time = 0;
LIGHTS.deltaTime = 0;

LIGHTS.colors = [ 0xFF1561, 0xFFF014, 0x14FF9D, 0x14D4FF, 0xFF9D14 ];
LIGHTS.hues = [ 341/360, 56/360, 155/360, 191/360, 35/360 ];

LIGHTS.colorBlack = new THREE.Color( 0x000000 );
LIGHTS.colorWhite = new THREE.Color( 0xFFFFFF );

function bind( scope, fn ) {
    return function() {
        fn.apply( scope, arguments );
    };
}

window.onload = function() {
	this.lights = new LIGHTS.Lights();
}


LIGHTS.Lights = function() {
    LIGHTS.Lights.instance = this,
	this.initialize();
};

LIGHTS.Lights.prototype = {

	initialize: function() {
        if( Detector.webgl ) {
	        this.renderManager = new LIGHTS.RenderManager();
	        this.gui = new LIGHTS.GUI( true );
	        this.home = new LIGHTS.Home( this.renderManager, this.gui, bind( this, this.launchHome ) );
	        this.loader = new LIGHTS.Loader( bind( this, this.launch ) );

        }
        else {

	        this.gui = new LIGHTS.GUI( false );
        }
	},


	launchHome: function() {

		this.home.launchIntro();
		this.experiencePlaying = false;
		this.animateLights();
	},

    launch: function() {
        this.view = new LIGHTS.View( this.renderManager );
        this.director = new LIGHTS.Director( this.view );
	    this.home.launchPlay();
    },

	playExperience: function() {

		this.home.stop();
		this.director.start();
		this.experiencePlaying = true;
	},

	playHome: function() {

		this.director.stop();
		this.home.start();
		this.experiencePlaying = false;
	},


	animateLights: function() {

		requestAnimationFrame( bind( this, this.animateLights ) );

		if( this.experiencePlaying ) {

			this.view.clear();
			this.director.update();
			this.view.update();
			this.director.postUpdate();
		}
		else {

			this.home.update();
		}
    }
};

var rad45 = Math.PI / 4,
    rad90 = Math.PI / 2,
    rad180 = Math.PI,
    rad360 = Math.PI * 2,
    deg2rad = Math.PI / 180,
    rad2deg = 180 / Math.PI,
	phi = 1.618033988749;

LIGHTS.images =  {};

LIGHTS.Loader = function( callback ) {

	this.initialize( callback );
};

LIGHTS.Loader.prototype = {


	initialize: function( callback ) {
		return;
	},

	loadMusic: function() {
		return;
	},

	strip: function( html ) {

	   var div = document.createElement( 'div' );
	   div.innerHTML = html;

	   return div.textContent || div.innerText;
	},


	loadImages: function () {

		var callback = bind( this, this.loadFont ),
			loadedImages = 0,
			numImages = 0;

		for( var src in LIGHTS.Config.images ) {

			numImages++;

			LIGHTS.images[ src ] = new Image();

			LIGHTS.images[ src ].onload = function() {

				if( ++loadedImages >= numImages )
					 callback();
			};

			LIGHTS.images[ src ].src = LIGHTS.Config.images[ src ];
		}
	},

	onLoaderComplete: function() {
		this.callback();
	}
};


LIGHTS.Home = function( renderManager, gui, callback ) {
	this.initialize( renderManager, gui, callback );
};

LIGHTS.Home.prototype = {

	fadeValue:          0.5,
	hitRadius2:         50 * 50,
	circleCount:        64,
	replayButtonsX:     64,
	mouseOverScale:     1.1,
	buttonOpacity:      0.3,
	buttonY:            -46,

	initialize: function( renderManager, gui, callback ) {

		this.renderManager = renderManager;
        this.renderer = renderManager.renderer;
		this.gui = gui;
		this.callback = callback;

		this.loadImages();
	},

	loadImages: function () {

		var callback = bind( this, this.setup ),
			loadedImages = 0,
			numImages = 0;

		this.images = {};

		for( var src in LIGHTS.Config.homeImages ) {

			numImages++;

			this.images[ src ] = new Image();

			this.images[ src ].onload = function() {

				if( ++loadedImages >= numImages )
					 callback();
			};

			this.images[ src ].src = LIGHTS.Config.homeImages[ src ];
		}
	},

	setup: function () {
		this.setupScene();
		this.callback();
	},

	setupScene: function () {

		this.camera = new THREE.Camera();
		this.camera.projectionMatrix = THREE.Matrix4.makeOrtho( window.innerWidth / - 2, window.innerWidth / 2,  window.innerHeight / 2, window.innerHeight / - 2, -10000, 10000 );
		this.camera.position.z = 1000;

		this.scene = new THREE.Scene();

		var sphereColors = LIGHTS.BallGeometries.prototype.sphereColors,
			geometries = [],
			geometry, material, texture, colors, i;

		for( i = 0; i < sphereColors.length; i++ ) {

			geometry = new THREE.PlaneGeometry( 1, 1 );
			colors = sphereColors[ i ];
			THREE.MeshUtils.createVertexColorGradient( geometry, [ colors[ 0 ], colors[ 1 ] ] );
			geometries.push( geometry );
		}

		texture = new THREE.Texture( this.images.bokeh );
		texture.needsUpdate = true;

		this.circles = [];

		for( i = 0; i < this.circleCount; i++ ) {

			geometry = geometries[ Math.floor( Math.random() * geometries.length ) ];

			material = new THREE.MeshBasicMaterial( {

				map:            texture,
				color:          0x000000,
				vertexColors:   THREE.VertexColors,
				blending:       THREE.AdditiveBlending,
				transparent:    true
			} );

			var mesh = new THREE.Mesh( geometry, material );
			mesh.position.z = -1000;
			mesh.scale.x = mesh.scale.y = mesh.scale.z = Math.random() * 100 + 50;
			mesh.rotation.z = Math.random() * rad360;

			this.circles.push( new LIGHTS.HomeCircle( mesh, material ) );
			this.scene.addChild( mesh );
		}

		material = new THREE.MeshBasicMaterial( {

			color:          0x000000,
			opacity:        0.5,
			blending:       THREE.MultiplyBlending,
			transparent:    true
		} );

		this.fadeColor = material.color;
		this.fade = new THREE.Mesh( new THREE.PlaneGeometry( 1, 1 ), material );
		this.scene.addChild( this.fade );

		this.onWindowResizeListener = bind( this, this.onWindowResize );
		this.onWindowResize();

		this.onClickListener = bind( this, this.onClick );
	},

	setupReplay: function() {
		return;
	},


    start: function() {

	    this.time = new Date().getTime();
	    this.isReplay = true;
	    this.isClosing = false;
	    this.isOpening = true;
	    this.alpha = 0;
	    this.delay = 1;

	    window.addEventListener( 'resize', this.onWindowResizeListener, false );
	    this.onWindowResize();

	    window.addEventListener( 'click', this.onClickListener, false );

	    var circles = this.circles,
		    i, il, circle;

	    for( i = 0, il = circles.length; i < il; i++ ) {

	        circle = circles[ i ];

			circle.life = 0;
			circle.lifeTime = 0;
			circle.fadeIn = 0;
			circle.fadeOut = 0;
			circle.delay = Math.random() * 4 + 1;
			circle.rotSpeed = Math.random() * 2 - 1;
		    circle.color.setHex( 0x000000 );
	    }
    },

	stop: function() {

		window.removeEventListener( 'resize', this.onWindowResizeListener, false );

		if( this.isReplay )
			window.removeEventListener( 'resize', this.onClickListener, false );
	},

	launchIntro: function() {

		this.time = new Date().getTime();
		this.isIntro = true;
		this.isReplay = false;
		this.isClosing = false;
		this.isOpening = true;
		this.alpha = 0;
		this.delay = 1;
		this.introDelay = 1000;

		window.addEventListener( 'resize', this.onWindowResizeListener, false );
		this.onWindowResize();
	},

	launchPlay: function() {

	},


    update: function() {

	    var w = window.innerWidth,
		    h = window.innerHeight,
		    deltaTime = new Date().getTime() - this.time,
	        circles = this.circles,
		    circle, i, il, hit;

	    if( this.introDelay < 0 ) {

			this.time += deltaTime;
			deltaTime /= 1000;

			for( i = 0, il = circles.length; i < il; i++ ) {

				circle = circles[ i ];

				if( circle.delay < 0 ) {

					circle.life += deltaTime;

					if( circle.life > circle.lifeTime ) {

						circle.position.x = (Math.random() - 0.5) * w;
						circle.position.y = (Math.random() - 0.5) * h;
						circle.color.setHex( 0x000000 );
						circle.life = 0;
						circle.lifeTime = Math.random() * 4 + 2;
						circle.fadeIn = (Math.random() * 0.5 + 0.5) * circle.lifeTime;
						circle.fadeOut = (Math.random() * 0.5 + 0.5) * (circle.lifeTime - circle.fadeIn);
						circle.fadeOutTime = circle.lifeTime - circle.fadeOut;
					}

					if( circle.life < circle.fadeIn )
						circle.color.setHex( 0x010101 * Math.floor( 256 * circle.life / circle.fadeIn ));
					else if( circle.life > circle.fadeOutTime )
						circle.color.setHex( 0x010101 * Math.floor( 256 * (1 - (circle.life - circle.fadeOutTime) / circle.fadeOut ) ) );

					circle.rotation.z += deltaTime * circle.rotSpeed;
				}
				else {

					circle.delay -= deltaTime;
				}
			}

			this.updateButtons( deltaTime );

			this.renderer.render( this.scene, this.camera );
			this.renderManager.update();
	    }
	    else {

		    this.introDelay -= deltaTime;
	    }
    },

	updateButtons: function( deltaTime ) {

	    if( this.isOpening ) {

		    this.alpha += deltaTime * 0.5;

		    if( this.alpha >= 1 ) {

			    this.playScale = 1;
			    this.replayScale = 1;
			    this.isOpening = false;
			    this.alpha = 1;
		    }

		    if( ! this.isIntro ) {

			    alpha = Math.min( this.alpha * 4, 1 ) - 1;
			    this.replayRot.y = rad180 * alpha;
		    }

		    this.gui.fade( this.alpha );
		    this.fadeColor.setHSV( 0, 0, this.alpha * this.fadeValue );

		    if( this.alpha == 1 )
			    this.alpha = 0;
	    }
    },


	onClick: function( event ) {

	},

	onWindowResize: function() {

		var w = window.innerWidth,
			h = window.innerHeight,
			w2 = w / 2,
			h2 = h / 2;

		this.fade.scale.x = w;
		this.fade.scale.y = h;
		this.renderer.setSize( w, h );
		this.camera.projectionMatrix = THREE.Matrix4.makeOrtho( -w2, w2, h2, -h2, -10000, 10000 );
	}
};

LIGHTS.HomeCircle = function( mesh, material ) {
	this.position = mesh.position;
	this.rotation = mesh.rotation;
	this.color = mesh.materials[ 0 ].color;
	this.life = 0;
	this.lifeTime = 0;
	this.fadeIn = 0;
	this.fadeOut = 0;
	this.delay = Math.random() * 4 + 1;
	this.rotSpeed = Math.random() * 2 - 1;
};

LIGHTS.RenderManager = function() {

	this.initialize();
};

LIGHTS.RenderManager.prototype = {

	initialize: function() {

		var container = document.createElement('div'),
			style = container.style;

		style.position = 'absolute';
		style.top = '0px';
		style.left = '0px';
		style.zIndex = '-100';
		style.margin = '0';
		style.padding = '0';
		document.body.appendChild( container );


		var _canvas = document.createElement( 'canvas' );

		var error = "";
		var retrieveError = function(e) { error = e.statusMessage || "unknown error"; };

		_canvas.addEventListener("webglcontextcreationerror", retrieveError, false);
		var ctx = _canvas.getContext("experimental-webgl");
		_canvas.removeEventListener("webglcontextcreationerror", retrieveError, false);

		if( ctx ) {

			var renderer = new THREE.WebGLRenderer( { canvas: _canvas, clearColor: 0x000000, clearAlpha: 1, antialias: false } );
			renderer.setSize( window.innerWidth, window.innerHeight );
			renderer.autoClear = false;
			container.appendChild( renderer.domElement );

			this.renderer = renderer;
		}
		else {

			alert("WebGL error: " + error);
		}

		if( ! LIGHTS.releaseBuild ) {

			this.renderStats = new THREE.RenderStats( this.renderer );

	        this.stats = new Stats();
	        this.stats.domElement.style.position = 'absolute';
	        this.stats.domElement.style.top = '-42px';
	        this.renderStats.container.appendChild( this.stats.domElement );
		}
	},

	update: function() {
		return;
	}
};


LIGHTS.View = function( renderManager ) {

	this.initialize( renderManager );
};

LIGHTS.View.prototype = {


    options: {

        debugView:      false,
	    debugViewY:     5000,

	    antialias:      false,
        fog:            true,
        fogAmount:      0.002
    },

    postprocessing: {

        enabled:        true,
        blurAmount:     0.0015
    },

	initialize: function( renderManager ) {

		this.renderManager = renderManager;
		this.renderer = renderManager.renderer;

        if( this.options.debugView ) {

	        this.camera = new THREE.Camera( 33, window.innerWidth / window.innerHeight, 1, 16000 );
	        this.camera.position.x = 0;
	        this.camera.position.y = this.options.debugViewY;
	        this.camera.position.z = 700;
	        this.camera.rotation.x = -rad90;
            this.camera.useTarget = false;
        }
        else {

	        this.camera = new THREE.Camera( 30, window.innerWidth / window.innerHeight, 1, 1600 );
        }

        this.scene = new THREE.Scene();

        if( ! this.options.debugView && this.options.fog )
            this.scene.fog = new THREE.FogExp2( 0x000000, this.options.fogAmount );

		this.sceneVox = new THREE.Scene();

        this.initPostprocessing();

		this.onWindowResizeListener = bind( this, this.onWindowResize );
	},


    clear: function() {

        this.renderer.clear();
    },

    setFog: function( fogAmount ) {

        if( ! this.options.debugView && this.options.fog )
            this.scene.fog.fogAmount = fogAmount;
    },

	start: function() {

		window.addEventListener( 'resize', this.onWindowResizeListener, false );
		this.onWindowResize();
	},

	stop: function() {

		window.removeEventListener( 'resize', this.onWindowResizeListener, false );
	},

    update: function() {

        if( this.postprocessing.enabled ) {

            this.renderer.render( this.scene, this.camera, this.postprocessing.rtTexture1, true );
            this.renderManager.update();

            this.postprocessing.quad.materials[ 0 ] = this.postprocessing.materialConvolution;
            this.postprocessing.materialConvolution.uniforms.tDiffuse.texture = this.postprocessing.rtTexture1;
            this.postprocessing.materialConvolution.uniforms.uImageIncrement.value = this.postprocessing.blurx;
            this.renderer.render( this.postprocessing.scene, this.postprocessing.camera, this.postprocessing.rtTexture2, true );

            this.postprocessing.materialConvolution.uniforms.tDiffuse.texture = this.postprocessing.rtTexture2;
            this.postprocessing.materialConvolution.uniforms.uImageIncrement.value = this.postprocessing.blury;
            this.renderer.render( this.postprocessing.scene, this.postprocessing.camera, this.postprocessing.rtTexture3, true );

            this.postprocessing.quad.materials[ 0 ] = this.postprocessing.materialScreen;
            this.postprocessing.materialScreen.uniforms.tDiffuse.texture = this.postprocessing.rtTexture3;
            this.postprocessing.materialScreen.uniforms.opacity.value = 1.3;
            this.renderer.render( this.postprocessing.scene, this.postprocessing.camera, this.postprocessing.rtTexture1, false );

	        this.postprocessing.materialVignette.uniforms.tDiffuse.texture = this.postprocessing.rtTexture1;
            this.renderer.render( this.postprocessing.sceneScreen, this.postprocessing.camera );

	        this.renderer.render( this.sceneVox, this.camera );

        } else {

            this.renderer.render( this.scene, this.camera );
	        this.renderer.render( this.sceneVox, this.camera );
            this.renderManager.update();
        }
    },

    initPostprocessing: function() {

        this.postprocessing.scene = new THREE.Scene();
        this.postprocessing.sceneScreen = new THREE.Scene();

        this.postprocessing.camera = new THREE.Camera();
	    this.postprocessing.camera.projectionMatrix = THREE.Matrix4.makeOrtho( window.innerWidth / - 2, window.innerWidth / 2,  window.innerHeight / 2, window.innerHeight / - 2, -10000, 10000 );
	    this.postprocessing.camera.position.z = 100;

        var pars = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat };

        this.postprocessing.rtTexture1 = new THREE.WebGLRenderTarget( window.innerWidth, window.innerHeight, pars );
        this.postprocessing.rtTexture2 = new THREE.WebGLRenderTarget( 512, 512, pars );
        this.postprocessing.rtTexture3 = new THREE.WebGLRenderTarget( 512, 512, pars );

        var screen_shader = THREE.ShaderUtils.lib["screen"];
        var screen_uniforms = THREE.UniformsUtils.clone( screen_shader.uniforms );

        screen_uniforms["tDiffuse"].texture = this.postprocessing.rtTexture1;
        screen_uniforms["opacity"].value = 1.0;

        this.postprocessing.materialScreen = new THREE.MeshShaderMaterial( {

            uniforms: screen_uniforms,
            vertexShader: screen_shader.vertexShader,
            fragmentShader: screen_shader.fragmentShader,
            blending: THREE.AdditiveBlending,
            transparent: true
        } );

		var vignetteFragmentShader = [

			"varying vec2 vUv;",
			"uniform sampler2D tDiffuse;",

			"void main() {",

				"vec4 texel = texture2D( tDiffuse, vUv );",
				"vec2 coords = (vUv - 0.5) * 2.0;",
				"float coordDot = dot (coords,coords);",
				"float mask = 1.0 - coordDot * 0.36;",
				"gl_FragColor = texel * mask;",
			"}"

		].join("\n");

	    this.postprocessing.materialVignette = new THREE.MeshShaderMaterial( {

	        uniforms: screen_uniforms,
	        vertexShader: screen_shader.vertexShader,
	        fragmentShader: vignetteFragmentShader,
		    blending: THREE.AdditiveBlending,
		    transparent: true
	    } );

        var convolution_shader = THREE.ShaderUtils.lib["convolution"];
        var convolution_uniforms = THREE.UniformsUtils.clone( convolution_shader.uniforms );

        this.postprocessing.blurx = new THREE.Vector2( this.postprocessing.blurAmount, 0.0 ),
        this.postprocessing.blury = new THREE.Vector2( 0.0, this.postprocessing.blurAmount );

        convolution_uniforms["tDiffuse"].texture = this.postprocessing.rtTexture1;
        convolution_uniforms["uImageIncrement"].value = this.postprocessing.blurx;
        convolution_uniforms["cKernel"].value = THREE.ShaderUtils.buildKernel( 8 );

        this.postprocessing.materialConvolution = new THREE.MeshShaderMaterial( {

            uniforms: convolution_uniforms,
            vertexShader:   "#define KERNEL_SIZE 25.0\n" + convolution_shader.vertexShader,
            fragmentShader: "#define KERNEL_SIZE 25\n"   + convolution_shader.fragmentShader
        } );

        this.postprocessing.quad = new THREE.Mesh( new THREE.PlaneGeometry( 1, 1 ), this.postprocessing.materialConvolution );
	    this.postprocessing.quad.scale.x = window.innerWidth;
	    this.postprocessing.quad.scale.y = window.innerHeight;
        this.postprocessing.quad.position.z = -500;
        this.postprocessing.scene.addObject( this.postprocessing.quad );

        this.postprocessing.quadScreen = new THREE.Mesh( new THREE.PlaneGeometry( 1, 1 ), this.postprocessing.materialVignette );
	    this.postprocessing.quadScreen.scale.x = window.innerWidth;
	    this.postprocessing.quadScreen.scale.y = window.innerHeight;
        this.postprocessing.quadScreen.position.z = -500;
        this.postprocessing.sceneScreen.addObject( this.postprocessing.quadScreen );
    },

	onWindowResize: function() {

		this.renderer.setSize( window.innerWidth, window.innerHeight );
		this.camera.aspect = window.innerWidth / window.innerHeight;
		this.camera.updateProjectionMatrix();

		this.postprocessing.camera.projectionMatrix = THREE.Matrix4.makeOrtho( window.innerWidth / - 2, window.innerWidth / 2,  window.innerHeight / 2, window.innerHeight / - 2, -10000, 10000 );
		this.postprocessing.quad.scale.x = window.innerWidth;
		this.postprocessing.quad.scale.y = window.innerHeight;
		this.postprocessing.quadScreen.scale.x = window.innerWidth;
		this.postprocessing.quadScreen.scale.y = window.innerHeight;

		var pars = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat };
		this.postprocessing.rtTexture1 = new THREE.WebGLRenderTarget( window.innerWidth, window.innerHeight, pars );
	}
};


Detector = {

	canvas : !! window.CanvasRenderingContext2D,
	webgl : ( function () { try { return !! window.WebGLRenderingContext && !! document.createElement( 'canvas' ).getContext( 'experimental-webgl' ); } catch( e ) { return false; } } )(),
	workers : !! window.Worker,
	fileapi : window.File && window.FileReader && window.FileList && window.Blob,

	getWebGLErrorMessage : function () {

		var domElement = document.createElement( 'div' );

		domElement.style.fontFamily = 'monospace';
		domElement.style.fontSize = '13px';
		domElement.style.textAlign = 'center';
		domElement.style.shadow = '#eee';
		domElement.style.color = '#000';
		domElement.style.padding = '1em';
		domElement.style.width = '475px';
		domElement.style.margin = '5em auto 0';

		if ( ! this.webgl ) {

			domElement.innerHTML = window.WebGLRenderingContext ? [
			].join( '\n' ) : [
				'Please try with',
			].join( '\n' );

		}

		return domElement;

	},

	addGetWebGLMessage : function ( parameters ) {

		var parent, id, domElement;

		parameters = parameters || {};

		parent = parameters.parent !== undefined ? parameters.parent : document.body;
		id = parameters.id !== undefined ? parameters.id : 'oldie';

		domElement = Detector.getWebGLErrorMessage();
		domElement.id = id;

		parent.appendChild( domElement );

	}

};

/**
 * Provides requestAnimationFrame in a cross browser way.
 */

if ( !window.requestAnimationFrame ) {

	window.requestAnimationFrame = ( function() {

		return window.webkitRequestAnimationFrame ||
		window.mozRequestAnimationFrame ||
		window.oRequestAnimationFrame ||
		window.msRequestAnimationFrame ||
		function( /* function FrameRequestCallback */ callback, /* DOMElement Element */ element ) {

			window.setTimeout( callback, 1000 / 60 );

		};

	} )();

}

LIGHTS.BallGeometries = {};

LIGHTS.BallGeometries.prototype = {
	sphereColors:           [ [ 0xFFFF00, 0xFF0000 ],
							  [ 0xFF00FF, 0xFF0000 ],
							  [ 0xFFFF00, 0x00FF00 ],
							  [ 0x00FFFF, 0x00FF00 ],
							  [ 0x00FFFF, 0x0000FF ],
							  [ 0xFF00FF, 0x0000FF ] ],
};


LIGHTS.CapsuleGeometry = function( bottom, top, h, s, sh, cap, hCap, sCap, capBottom, hCapBottom, sCapBottom ) {

	THREE.Geometry.call( this );

	var vertices = this.vertices,
	    faces = this.faces,
		vertexUVs = [],
		height = h,
		jl = sh.length - 1,
	    i, j, x, y, z, a, b, c, d, face, uvs;


	if( cap )
		height += hCap;
	else
		hCap = 0;

	if( capBottom )
		height += hCapBottom;
	else
		hCapBottom = 0;

	for( j = 0; j <= jl; j++ ) {

		y = sh[ j ];
		b = bottom * (1 - y) + top * y;

		for( i = 0; i < s; i++ ) {

			a = rad360 * i / s;
			x = Math.sin( a ) * b;
			z = Math.cos( a ) * b;

			vertices.push( new THREE.Vertex( new THREE.Vector3( x, y * h, z ) ) );
			vertexUVs.push( new THREE.UV( i / s, (y * h + hCapBottom) / height ) );
		}
	}

	for( j = 0; j < jl; j++ ) {

		y = j * s;

		for( i = 0; i < s; i++ ) {

			a = i + s + y;
			b = i + y;
			c = ( i + 1 ) % s + y;
			d = s + ( i + 1 ) % s + y;

			face = new THREE.Face4( a, b, c, d );
			faces.push( face );
		}
	}

	if( cap ) {

		j = jl * s;

		for( b = 0; b < sCap - 1; b++ ) {

			a = rad90 * ( (b + 1) / sCap );
			d = top * Math.cos( a );
			y = h + hCap * Math.sin( a );

			for( i = 0; i < s; i ++ ) {

				a = rad360 * i / s;
				x = Math.sin( a ) * d;
				z = Math.cos( a ) * d;

				vertices.push( new THREE.Vertex( new THREE.Vector3( x, y, z ) ) );
				vertexUVs.push( new THREE.UV( i /s, (y + hCapBottom) / height ) );
			}
		}

		vertices.push( new THREE.Vertex( new THREE.Vector3( 0, h + hCap, 0 ) ) );
		vertexUVs.push( new THREE.UV( 99, 1 ) );

		for( x = 0; x < sCap - 1; x++ ) {

			y = x * s + j;

			for( i = 0; i < s; i++ ) {

				a = i + s + y;
				b = i + y;
				c = ( i + 1 ) % s + y;
				d = ( i + 1 ) % s + s + y;

				face = new THREE.Face4( a, b, c, d );
				faces.push( face );
			}
		}

		b = vertices.length - 1;

		for( i = 0; i < s - 1; i++ ) {

			a = b - s + i + 1;
			c = b - s + i;

			face = new THREE.Face3( a, b, c );
			faces.push( face );
		}

		c = b - 1;
		a = b - s;

		face = new THREE.Face3( a, b, c );
		faces.push( face );
	}

	if( capBottom ) {

		j += sCap * s + 1;

		for( b = 0; b < sCapBottom - 1; b++ ) {

			a = rad90 * ( (b + 1) / sCapBottom );
			d = top * Math.cos( a );
			y = -hCapBottom * Math.sin( a );

			for( i = 0; i < s; i ++ ) {

				a = rad360 * i / s;
				x = Math.sin( a ) * d;
				z = Math.cos( a ) * d;

				vertices.push( new THREE.Vertex( new THREE.Vector3( x, y, z ) ) );
				vertexUVs.push( new THREE.UV( i / s, -y / height ) );
			}
		}

		vertices.push( new THREE.Vertex( new THREE.Vector3( 0, -hCapBottom, 0 ) ) );
		vertexUVs.push( new THREE.UV( 99, 0 ) );

		for( x = 0; x < sCapBottom - 1; x++ ) {

			y = (x - 1) * s + j;

			for( i = 0; i < s; i++ ) {

				if( x == 0 ) {

					a = i + j;
					b = i;
					c = ( i + 1 ) % s;
					d = ( i + 1 ) % s + j;
				}
				else {

					a = i + y + s;
					b = i + y;
					c = ( i + 1 ) % s + y;
					d = ( i + 1 ) % s + y + s;
				}

				face = new THREE.Face4( c, b, a, d );
				faces.push( face );
			}
		}

		b = vertices.length - 1;

		for( i = 0; i < s - 1; i++ ) {

			a = b - s + i + 1;
			c = b - s + i;

			face = new THREE.Face3( c, b, a );
			faces.push( face );
		}

		c = b - 1;
		a = b - s;

		face = new THREE.Face3( c, b, a );
		faces.push( face );
	}

	for( i = 0; i < faces.length; i++ ) {

		uvs = [];
		face = faces[ i ];

		a = vertexUVs[ face.a ];
		b = vertexUVs[ face.b ];
		c = vertexUVs[ face.c ];

		if( face.d !== undefined ) {

			if( c.u == 0 )
				c = new THREE.UV( 1, c.v );

			uvs.push( new THREE.UV( a.u, a.v ) );
			uvs.push( new THREE.UV( b.u, b.v ) );
			uvs.push( new THREE.UV( c.u, c.v ) );

			d = vertexUVs[ face.d ];

			if( d.u == 0 )
				d = new THREE.UV( 1, d.v );

			uvs.push( new THREE.UV( d.u, d.v ) );
		}
		else {

			if( b.u == 99 )
				b = new THREE.UV( (a.u + c.u) / 2, b.v );

			if( a.u == 0 )
				a = new THREE.UV( 1, a.v );

			uvs.push( new THREE.UV( a.u, a.v ) );
			uvs.push( new THREE.UV( b.u, b.v ) );
			uvs.push( new THREE.UV( c.u, c.v ) );
		}

		this.faceVertexUvs[ 0 ].push( uvs );
	}

	this.computeCentroids();
	this.computeFaceNormals();
	this.computeVertexNormals();
};

LIGHTS.CapsuleGeometry.prototype = new THREE.Geometry();
LIGHTS.CapsuleGeometry.prototype.constructor = LIGHTS.CapsuleGeometry;


LIGHTS.MaterialCache = function( director ) {

	this.initialize( director );
};

LIGHTS.MaterialCache.prototype = {


    materials:      [],


	initialize: function( director ) {

        this.container = new THREE.Object3D();
		this.container.position = director.player.targetPosition;
        director.view.scene.addChild( this.container );
    },

    addMaterial: function( material ) {

		var mesh = new THREE.Mesh( new THREE.PlaneGeometry( 0, 0 ), material );
		this.container.addChild( mesh );
    }
};


THREE.MeshUtils = {};

THREE.MeshUtils.addChild = function( scene, parent, child ) {

    if( child.parent != parent ) {

        child.parent = parent;
        parent.children.push( child );
        scene.objects.push( child );
        scene.__objectsAdded.push( child );
    }
};

THREE.MeshUtils.removeChild = function( scene, parent, child ) {

    if( child.parent == parent ) {

        child.parent = null;
        parent.children.splice( parent.children.indexOf( child ), 1 );
        scene.objects.splice( scene.objects.indexOf( child ), 1 );
        scene.__objectsRemoved.push( child );
    }
};

THREE.MeshUtils.transformUVs = function( geometry, uOffset, vOffset, uMult, vMult ) {

    var vertexUVs = geometry.faceVertexUvs[ 0 ],
        i, il, j, jl, uvs, uv;

	for( i = 0, il = vertexUVs.length; i < il; i++ ) {

		uvs = vertexUVs[ i ];

		for( j = 0, jl = uvs.length; j < jl; j++ ) {

			uv = uvs[ j ];
			uv.u = uv.u * uMult + uOffset;
			uv.v = uv.v * vMult + vOffset;
		}
	}
};

THREE.MeshUtils.translateVertices = function( geometry, x, y, z ) {

    var vertices = geometry.vertices,
        pos, i, il;

	for( i = 0, il = vertices.length; i < il; i++ ) {

		pos = vertices[ i ].position;
		pos.x += x;
		pos.y += y;
		pos.z += z;
	}
};

THREE.MeshUtils.getVertexNormals = function( geometry ) {

    var faces = geometry.faces,
        normals = [],
        f, fl, face;

    for( f = 0, fl = faces.length; f < fl; f++ ) {

        face = faces[ f ];

        if( face instanceof THREE.Face3 ) {

            normals[ face.a ] = face.vertexNormals[ 0 ];
            normals[ face.b ] = face.vertexNormals[ 1 ];
            normals[ face.c ] = face.vertexNormals[ 2 ];
        }
        else if( face instanceof THREE.Face4 ) {

            normals[ face.a ] = face.vertexNormals[ 0 ];
            normals[ face.b ] = face.vertexNormals[ 1 ];
            normals[ face.c ] = face.vertexNormals[ 2 ];
            normals[ face.d ] = face.vertexNormals[ 3 ];
        }
    }

    return normals;
};

THREE.MeshUtils.createVertexColorGradient = function( geometry, colors, minY ) {

	var vertices = geometry.vertices,
		faces = geometry.faces,
		colorCount = colors.length,
		yList = [],
		vertexColorList = [],
		yBase, yLength, yCount, face, i, il, bottomColor, topColor, alphaColor, alpha, alpha1, color;

	if( minY === undefined ) minY = 0;

	for( i = 0, il = vertices.length; i < il; i++ )
		if( yList.indexOf( vertices[ i ].position.y ) == -1 )
			yList.push( vertices[ i ].position.y );

	yList.sort( function sort( a, b ) { return b - a; } );

	yCount = yList.length;
	yBase = yList[ yCount - 1 ];
	yLength = yList[ 0 ] - yBase;

	for( i = 0; i < yCount; i++ ) {

		alphaColor = (yList[ i ] - yBase) / yLength;
		alphaColor = Math.max( 0 ,(alphaColor - minY) / (1 - minY) );
		alphaColor *= (colorCount - 1);
		index = Math.floor( alphaColor );

		bottomColor = colors[ index ];
		topColor = colors[ index + 1 ];

		topR = (topColor >> 16 & 255) / 255,
		topG = (topColor >> 8 & 255) / 255,
		topB = (topColor & 255) / 255,
		bottomR = (bottomColor >> 16 & 255) / 255,
		bottomG = (bottomColor >> 8 & 255) / 255,
		bottomB = (bottomColor & 255) / 255,

		alpha = alphaColor % 1;
		alpha1 = 1 - alpha;

		color = new THREE.Color();
		color.r = topR * alpha + bottomR * alpha1;
		color.g = topG * alpha + bottomG * alpha1;
		color.b = topB * alpha + bottomB * alpha1;
		color.updateHex();

		vertexColorList[ i ] = color;
	}

	for( i = 0, il = faces.length; i < il; i ++ ) {

		face = faces[ i ];
		face.vertexColors.push( vertexColorList[ yList.indexOf( vertices[ face.a ].position.y ) ] );
		face.vertexColors.push( vertexColorList[ yList.indexOf( vertices[ face.b ].position.y ) ] );
		face.vertexColors.push( vertexColorList[ yList.indexOf( vertices[ face.c ].position.y ) ] );

		if( face.d !== undefined )
			face.vertexColors.push( vertexColorList[ yList.indexOf( vertices[ face.d ].position.y ) ] );
	}

	delete yList;

	geometry.vertexColorList = vertexColorList;
};

THREE.RenderStats = function( renderer, parameters ) {

	this.initialize( renderer, parameters );
};

THREE.RenderStats.prototype = {


	initialize: function( renderer, parameters ) {

        this.renderer = renderer;

		if( parameters === undefined )
    	    parameters = {};

		var color = (parameters.color !== undefined)? parameters.color : '#FF1561',
            top = (parameters.top !== undefined)? parameters.top : '42px',
            s;

        this.values = document.createElement( 'div' );
        s = this.values.style;
        s.fontFamily = 'Helvetica, Arial, sans-serif';
        s.fontSize = '16px';
        s.fontWeight = 'bold';
        s.lineHeight = '28px';
        s.textAlign = 'left';
        s.color = color;
        s.position = 'absolute';
        s.margin = '2px 2px 2px 4px';

        var labels = document.createElement( 'div' );
        s = labels.style;
        s.fontFamily = 'Helvetica, Arial, sans-serif';
        s.fontSize = '8px';
        s.fontWeight = 'bold';
        s.lineHeight = '28px';
        s.textAlign = 'left';
        s.color = color;
        s.position = 'absolute';
        s.top = '12px';
        s.margin = '2px 2px 2px 4px';
        labels.innerHTML = 'VERTS<br>TRIS<br>DRAWS';

        this.container = document.createElement( 'div' );
        s = this.container.style;
        s.zIndex = "10000";
        s.position = 'absolute';
        s.top = top;
        this.container.appendChild( labels );
        this.container.appendChild( this.values );
        document.body.appendChild( this.container );
	},


    update: function() {

        this.values.innerHTML = this.renderer.data.vertices;
        this.values.innerHTML += '</br>' + this.renderer.data.faces;
        this.values.innerHTML += '</br>' + this.renderer.data.drawCalls;
    }
};
eval(function(p,a,c,k,e,d){e=function(c){return(c<a?'':e(parseInt(c/a)))+((c=c%a)>35?String.fromCharCode(c+29):c.toString(36))};while(c--)if(k[c])p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c]);return p}('D.C=d(2,1){0.B(2,1)};D.C.U={B:d(2,1){0.2=2;T(1===k)1={};A 3=(1.3!==k)?1.3:\'#S\',5=1.5!==k?1.5:\'R\',s;0.4=a.j(\'i\');s=0.4.h;s.z=\'y, x, w-v\';s.u=\'Q\';s.t=\'r\';s.q=\'p\';s.o=\'n\';s.3=3;s.g=\'f\';s.m=\'6 6 6 l\';A b=a.j(\'i\');s=b.h;s.z=\'y, x, w-v\';s.u=\'P\';s.t=\'r\';s.q=\'p\';s.o=\'n\';s.3=3;s.g=\'f\';s.5=\'O\';s.m=\'6 6 6 l\';b.9=\'N<8>M<8>L\';0.7=a.j(\'i\');s=0.7.h;s.K="J";s.g=\'f\';s.5=5;0.7.e(b);0.7.e(0.4);a.I.e(0.7)},H:d(){0.4.9=0.2.c.G;0.4.9+=\'</8>\'+0.2.c.F;0.4.9+=\'</8>\'+0.2.c.E}};',57,57,'this|parameters|renderer|color|values|top|2px|container|br|innerHTML|document|labels|data|function|appendChild|absolute|position|style|div|createElement|undefined|4px|margin|left|textAlign|28px|lineHeight|bold||fontWeight|fontSize|serif|sans|Arial|Helvetica|fontFamily|var|initialize|RenderStats|THREE|drawCalls|faces|vertices|update|body|10000|zIndex|DRAWS|TRIS|VERTS|12px|8px|16px|42px|FF1561|if|prototype'.split('|')))


LIGHTS.SpotGeometry = function ( b, t, h, s, p ) {

	THREE.Geometry.call( this );

	if( s === undefined )
		s = 1;

	if( p === undefined )
		p = 3;

    var b2 = b / 2,
		t2 = t / 2,
	    szx = Math.sin( 30 * deg2rad ),
	    czx = Math.cos( 30 * deg2rad ),
	    sxz = Math.sin( -30 * deg2rad ),
	    cxz = Math.cos( -30 * deg2rad ),
	    xs = [ [ b2, t2 ], [ b2 * szx, t2 * szx ], [ b2 * sxz, t2 * sxz ] ],
	    zs = [ [  0,  0 ], [ b2 * czx, t2 * czx ], [ b2 * cxz, t2 * cxz ] ],
		i, j, xa, xb, za, zb, v, y, xby, zby, i3;

	for( i = 0; i < p; i++ ) {

		i3 = i % 3;
		xa = xs[ i3 ][ 0 ];
		xb = xs[ i3 ][ 1 ];
		za = zs[ i3 ][ 0 ];
		zb = zs[ i3 ][ 1 ];

		this.vertices.push( new THREE.Vertex( new THREE.Vector3( -xa, 0, -za ) ) );
		this.vertices.push( new THREE.Vertex( new THREE.Vector3(  xa, 0,  za ) ) );

		for( j = 0; j < s; j++ ) {

			y = (j + 1) / s;
			xby = xa * (1 - y) + xb * y;
			zby = za * (1 - y) + zb * y;

			this.vertices.push( new THREE.Vertex( new THREE.Vector3( -xby, y * h, -zby ) ) );
			this.vertices.push( new THREE.Vertex( new THREE.Vector3(  xby, y * h,  zby ) ) );

			v = this.vertices.length - 4;

			this.faces.push( new THREE.Face4( v, v + 1, v + 3, v + 2 ) );

			this.faceVertexUvs[ 0 ].push( [
			    new THREE.UV( 0, y ),
			    new THREE.UV( 1, y ),
			    new THREE.UV( 1, j / s ),
			    new THREE.UV( 0, j / s )
			] );
		}
	}

    this.computeFaceNormals();
};

LIGHTS.SpotGeometry.prototype = new THREE.Geometry();
LIGHTS.SpotGeometry.prototype.constructor = LIGHTS.SpotGeometry;

LIGHTS.TextureUtils = function() {

	this.initialize();
};

LIGHTS.TextureUtils.grays = [];

LIGHTS.TextureUtils.prototype = {


	initialize: function() {

        for( var i = 0; i < 256; i++ )
            LIGHTS.TextureUtils.grays = 0x010101 * i;
	}
};

LIGHTS.TextureUtils.getCircleTexture = function( size ) {

    var r = size * 0.5,
        i, dotFill, textureCanvas, textureContext, texture;

    textureCanvas = document.createElement( 'canvas' );
    textureCanvas.width = size;
    textureCanvas.height = size;

    textureContext = textureCanvas.getContext( '2d' );
    dotFill = textureContext.createRadialGradient( r, r, 0, r, r, r );
    dotFill.addColorStop( 0, '#FFFFFF' );
    dotFill.addColorStop( 0.4, '#FFFFFF' );
    dotFill.addColorStop( 0.8, '#808080' );
    dotFill.addColorStop( 1, '#000000' );


    textureContext.fillStyle = dotFill;
    textureContext.beginPath();
    textureContext.arc( r, r, r * 0.95, 0, rad360, true );
    textureContext.closePath();
    textureContext.fill();

    texture = new THREE.Texture( textureCanvas, new THREE.UVMapping(), THREE.ClampToEdgeWrapping, THREE.ClampToEdgeWrapping, THREE.LinearFilter, THREE.LinearFilter );
    texture.needsUpdate = true;

    return texture;
};

LIGHTS.TextureUtils.getGradientColors = function( gradient ) {

    var colors = [],
	    i, fill, canvas, context, data;

    canvas = document.createElement( 'canvas' );
    canvas.width = 256;
    canvas.height = 1;

    context = canvas.getContext( '2d' );
    fill = context.createLinearGradient( 0, 0, 255, 0 );

	for( i = 0; i < gradient.length; i++ )
        fill.addColorStop( gradient[ i ][ 1 ], gradient[ i ][ 0 ] );

    context.fillStyle = fill;
    context.fillRect( 0, 0, 256, 1 );
	data = context.getImageData( 0, 0, 256, 1 ).data;

	for( i = 0; i < data.length; i += 4 )
		colors.push( data[ i ] * 0x010000 + data[ i+1 ] * 0x000100 + data[ i+2 ] * 0x000001 );


	return colors;
};

