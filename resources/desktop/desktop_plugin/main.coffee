window.desktop_plugin = []
plugins = window.desktop_plugin
weather = new Weather
plugins.push(weather)

loader = new Loader
loader.addcss('desktop_plugin/weather/weather.css').load()
