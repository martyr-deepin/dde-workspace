WindowHeight = window.innerHeight or document.documentElement.clientHeight or document.body.clientHeight
WindowWidth = window.innerWidth or document.documentElement.clientWidth or document.body.clientWidth

WindowSize = {"width":WindowWidth,"height":WindowHeight}
localStorage.setObject("WindowSize",WindowSize)
echo WindowSize
