WindowHeight = window.innerHeight or document.documentElement.clientHeight or document.body.clientHeight
WindowWidth = window.innerWidth or document.documentElement.clientWidth or document.body.clientWidth

StandardWidth = 1366
StandardHeight = 768

scaleWidth = WindowWidth / StandardWidth
scaleHeight = WindowHeight / StandardHeight
scaleFinal = null
if scaleWidth > scaleHeight then scaleFinal = scaleHeight
else scaleFinal = scaleWidth
scaleFinal = scaleFinal * 0.8

WindowSize = {"width":WindowWidth,"height":WindowHeight,"scaleWidth":scaleWidth,"scaleHeight":scaleHeight,"scaleFinal":scaleFinal}
localStorage.setObject("WindowSize",WindowSize)
#echo WindowSize


