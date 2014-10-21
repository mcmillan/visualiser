{EventEmitter} = require('events')

class AudioManager
  bufferLength: null
  dataArray: null
  
  constructor: (canvasManager)->
    @canvasManager = canvasManager
    
    # grab a new context
    @context = new (window.AudioContext || window.webkitAudioContext)()

    # create + configure a new analyser
    @analyser = @context.createAnalyser()
    @analyser.fftSize = 512
    
    @loadAudio()
  
  loadAudio: ->
    request = new XMLHttpRequest()
    request.open(
      'GET',
      'https://api.soundcloud.com/tracks/148350322/stream?client_id=f68b551c3dcbb64d4f750a4f7d040308',
      true
    )
    request.responseType = 'arraybuffer'
    request.onload = =>
      @context.decodeAudioData(request.response, @play, console.error)
    request.send()
  
  play: (buffer) =>
    source = @context.createBufferSource()
    source.buffer = buffer
    source.connect(@context.destination)
    source.connect(@analyser)
    source.start(0)
        
    @startAnalysis()

  startAnalysis: ->
    @bufferLength = @analyser.frequencyBinCount
    @dataArray = new Uint8Array(@bufferLength)
    @analyse()

  analyse: ->
    requestAnimationFrame(=> @analyse())
    @analyser.getByteFrequencyData(@dataArray)
    @canvasManager.draw(@dataArray, @bufferLength)

class CanvasManager
  width: 0
  height: 0
  
  constructor: ->
    @canvas  = document.getElementsByTagName('canvas')[0]
    @context = @canvas.getContext('2d')
    
    @width = @canvas.width
    @height = @canvas.height
    
    window.addEventListener('resize', =>
      @resizeCanvas()
    , true)
    
    @resizeCanvas()
  
  resizeCanvas: ->
    @width = window.innerWidth
    @height = window.innerHeight
    @canvas.setAttribute('width', @width)
    @canvas.setAttribute('height', @height)
    @context.clearRect(0, 0, @width, @height)
  
  draw: (dataArray, bufferLength) ->
    @context.fillStyle = 'rgb(255, 0, 0)'
    @context.fillRect(0, 0, @width, @height)
    
    barWidth = Math.floor((@width / bufferLength) * 1.5)
    x = 0
    
    for barHeight in dataArray
      barHeight = (barHeight / 255) * @height / 2
      # console.log barHeight
      
      @context.fillStyle = 'rgb(0, 0, 0)'
      @context.fillRect(x, @height - barHeight / 2, barWidth, barHeight)
      
      x += barWidth + 1
          


cm = new CanvasManager
am = new AudioManager(cm)
