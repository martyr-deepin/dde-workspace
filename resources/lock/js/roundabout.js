$(document).ready(function() {
	// smooth scroll support
	$('a[href*=#]').live('click', function() {
		$.bbq.pushState('#/' + this.hash.slice(1));
		return false;
	});
	
	$(window).bind('hashchange', function(e) {
		var target = (location.hash) ? location.hash.replace(/#\//i, '') : '#top';
		$.smoothScroll({offset: -20, scrollTarget: '#' + target});
	});
	
	$(window).trigger('hashchange');
	
	// nav docking
	$(window).resize(checkDockNav);
	$(window).scroll(checkDockNav);
	
	// donation button
	$('#donate-now').click(function() {
		$('form.donate-form').submit();
		return false;
	});
	
	// roundabout
	$("#sample-roundabout").roundabout({
		tilt: 0.6,
		minScale: 0.6,
		minOpacity: 1,
		duration: 400,
		easing: 'easeOutQuad',
		enableDrag: true,
		dropEasing: 'easeOutBounce'
	}, function() {
		$(this).fadeTo(500, 1);
	});
	
	// classroom things
	$('.lessons h4 a').click(function() {
		loadLesson($(this).attr('href'));
		return false;
	});
	$('#classroom').delegate('a.lesson', 'click', function() {
		loadLesson($(this).attr('href'));
		return false;
	});
});


function loadLesson(href) {
	var classroom = $('#classroom'),
	    lesson = '/assets/projects/roundabout2/lessons/' + href.replace('#', '') + '.html';
	
	// expand if it needs expanding
	if (classroom.css('display') === "none") {
		classroom
			.css('display', 'block')
			.animate({
				height: 486,
				opacity: 1
			}, 600, 'easeOutQuad', function() {
				fadeInLesson(lesson);
			});
	} else {
		if (classroom.find('ul').length) {
			classroom.find('ul, ol, h2').animate({
				opacity: 0
			}, 400, function () {
				classroom.empty();
				fadeInLesson(lesson);
			})
		} else {
			fadeInLesson(lesson);
		}
	}
}

function fadeInLesson(lesson) {
	$('#classroom').load(lesson + '?ts=' + $.now(), function(response, status, xhr) {
		$(this).find('.lesson-display').roundabout({
			clickToFocus: false,
			duration: 550,
			easing: 'easeOutQuad',
			minOpacity: 0,
			minScale: 1
		}, function() {
			// console.log($(this));
			$(this).animate({ opacity: 1 }, 600);
			$(this)
				.siblings('h2')
					.css({
						width: $('.lesson-title').width() + 20,
						display: 'block'
					})
					.delay(400)
					.animate({ top: '-1.6em' }, 800, 'easeOutBack')
					.end()
				.siblings('ol')
					.css({ 
						width: $('.lesson-nav').width(),
						display: 'block'
					})
					.find('li')
						.css({
							display: 'block',
							float: 'left'
						})
						.each(function(i) {
							$(this).find('a').css({display: 'block', width: 'auto'}).click(function() {
								$(this).parent().parent().find('li').removeClass('on').end().end().addClass('on');
								$('.lesson-display').roundabout('animateToChild', i);
								return false;
							});
						})
						.end()
					.delay(400)
					.animate({ top: '-0.55em' }, 800, 'easeOutBack');
		})
	});
}

function checkDockNav() {
	if ($(window).scrollTop() > 100) {
		$('nav#primary').removeClass('docked');
	} else {
		$('nav#primary').addClass('docked');
	}
}