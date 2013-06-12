# There are three agentsets and their corresponding 
# agents: Patches/Patch, Agents/Agent, and Links/Link.

# The usual alias for **ABM.util**.
u = ABM.util

# ### Patch and Patches

# Class Patch instances represent a rectangle on a grid with::
#
# * id: installed by Patches agentset
# * x,y: the x,y position within the grid
# * color: the color of the patch as an RGBA array, A optional.
# * label: text for the patch
# * n/n4: adjacent neighbors: n: 8 patches [SW, S , SE, W, E, NW, N, NE], n4: 4 patches [S, W, E, N].
class ABM.Patch
  # Class variable defaults, "promoted" to instance variables if needed
  # when unique per instance rather than shared.
  # This approach yields considerable space effeciency when appropriate.
  
  # Not all patches need their neighbor patches, thus we use a default
  # of none.  n and n4 are promoted by the ABM.Patches agent set 
  # constructor if the constructor variable "neighbors" is true,
  # the default. This is only important in very large patch sets
  # and should be handled with care!
  n: null
  n4: null
  cachedRects: null
  # Default color starts as black, can be set to different default value
  # by setDefault methods in ABM.Patches
  color: [0,0,0]
  # Default patch is visible but can be changed to true if
  # appropriate by setDefault methods
  hidden: false
  # new Patch: set x,y. Neighbors set by Patches constructor if needed.
  constructor: (@x, @y) ->

  # Return a string representation of the patch.
  toString: ->
    "{id:#{@id} xy:#{u.aToFixed [@x,@y]} c:#{@color}}"

  # Set patch color to `c` scaled by `s`. Usage:
  #
  #     p.scaleColor p.color, .8 # reduce patch color by .8
  #     p.scaleColor @foodColor, p.foodPheromone # ants model
  #
  # Promotes color if currently using the default.
  scaleColor: (c, s) -> 
    @color = u.clone @color if not @.hasOwnProperty("color")
    u.scaleColor c, s, @color
  
  # Draw the patch and its text label if there is one.
  draw: (ctx) ->
    ctx.fillStyle = u.colorStr @color
    ctx.fillRect @x-.5, @y-.5, 1, 1
    if @label?
      [x,y] = ctx.labelXY
      ctx.save()
      ctx.translate @x, @y # bug: fonts don't scale for size < 1
      ctx.scale 1/ABM.patches.size, -1/ABM.patches.size
      u.ctxDrawText ctx, @label, [x,y], ctx.labelColor
      ctx.restore()
  
  # Return an array of the agents on this patch.
  # See model.setCacheAgentsHere for optimization.
  agentsHere: ->
    @agents ? (a for a in ABM.agents when a.p is @)
  
  # Returns true if this patch is on the edge of the grid.
  isOnEdge: ->
    @x is ABM.patches.minX or @x is ABM.patches.maxX or \
    @y is ABM.patches.minY or @y is ABM.patches.maxY
  
  # Factory: Create num new agents on this patch.
  # The optional init proc is called on each of the newly created agents.<br>
  # NOTE: init must be applied after object inserted in agent set
  sprout: (num = 1, init = ->) ->
    ABM.agents.create num, (a) => # fat arrow so that @ = this patch
      a.setXY @x, @y; init(a); a
  

# Class Patches is a singleton 2D matrix of Patch instances, each patch 
# representing a 1x1 square in patch coordinates (via 2D coord transforms).
#
# * size: pixel h/w of each patch.
# * minX/maxX: min/max x coord, each patch being a unit square.
# * minY/maxY: min/max y coord.
# * numX/numY: total patches in x/y direction, width/height of grid.
# * isTorus: topology of patches, see **ABM.util**.
class ABM.Patches extends ABM.AgentSet
  # Constructor: set variables, fill patch neighbor variables, n & n4.
  constructor: (
    @size, @minX, @maxX, @minY, @maxY, @isTorus=true, neighbors=true
  ) ->
    super()
    @numX = @maxX-@minX+1
    @numY = @maxY-@minY+1
    for y in [minY..maxY] by 1
      for x in [minX..maxX] by 1
        @add new ABM.Patch x, y
    @setNeighbors() if neighbors
    @setPixels() 
    @drawWithPixels = @size is 1 #false
  
  # Install neighborhoods in patches
  setNeighbors: -> 
    for p in @
      p.n =  @patchRect p, 1, 1 # p.n =  p.patchRect 1, 1
      p.n4 = [ p.n[1], p.n[3], p.n[4], p.n[6] ]

  # Setup pixels used for `drawScaledPixels` and `importColors`
  setPixels: ->
    if @size is 1
      @pixelsCtx = ABM.contexts.patches
    else
      can = document.createElement 'canvas'  # small pixel grid for patch colors
      can.width = @numX; can.height = @numY
      @pixelsCtx = can.getContext "2d"
    @pixelsImageData = @pixelsCtx.getImageData(0, 0, @numX, @numY)
    @pixelsData = @pixelsImageData.data
    if @pixelsData instanceof Uint8Array # Check for typed arrays
      @pixelsData32 = new Uint32Array @pixelsData.buffer
      @pixelsAreLittleEndian = u.isLittleEndian()
  
  # If using scaled pixels, use pixel manipulation below, or use default.
  draw: (ctx) ->
    if @drawWithPixels then @drawScaledPixels ctx else super ctx
  
  # Set the default color for new Patch instances.
  # Note coffeescript :: which refers to the Patch prototype.
  # This is the usual way to modify class variables.
  setDefaultColor: (color) -> ABM.Patch::color = color

# #### Patch grid coord system utilities:

  # Return the patch at matrix position x,y where 
  # x & y are both valid integer patch coordinates.
  patchXY: (x,y) -> @[x-@minX + @numX*(y-@minY)]
  
  # Return x,y float values to be between min/max patch coord values
  clamp: (x,y) -> [u.clamp(x, @minX-.5, @maxX+.5), u.clamp(y, @minY-.5, @maxY+.5)]
  
  # Return x,y float values to be modulo min/max patch coord values.
  wrap: (x,y)  -> [u.wrap(x, @minX-.5, @maxX+.5),  u.wrap(y, @minY-.5, @maxY+.5)]
  
  # Return x,y float values to be between min/max patch values
  # using either clamp/wrap above according to isTorus topology.
  coord: (x,y) -> #returns a valid world coord (real, not int)
    if @isTorus then @wrap x,y else @clamp x,y

  # Return patch at x,y float values according to topology.
  patch: (x,y) -> 
    [x,y]=@coord x,y
    x = u.clamp Math.round(x), @minX, @maxX
    y = u.clamp Math.round(y), @minY, @maxY
    @patchXY x, y
  
  # Return a random valid float x,y point in patch space
  randomPt: -> [u.randomFloat2(@minX-.5,@maxX+.5), u.randomFloat2(@minY-.5,@maxY+.5)]

# #### Patch metrics

  # Return pixel width/height of patch grid
  bitWidth:  -> @numX*@size # methods, not constants in case resize
  bitHeight: -> @numY*@size
  
  # Convert patch measure to pixels
  patches2Bits: (p) -> p*@size
  # Convert bit measure to patches
  bits2Patches: (b) -> b/@size

# #### Patch utilities

  # Return an array of patches in a rectangle centered on the given 
  # patch `p`, dx, dy units to the right/left and up/down. 
  # Exclude `p` unless meToo is true, default false.
  patchRect: (p, dx, dy, meToo=false) ->
    if p.pRect? and p.pRect.radius is dx and p.pRect.radius is dy
      return p.pRect
    rect = []; # REMIND: could optimize w/ a loop for the all inside patches case
    for y in [p.y-dy..p.y+dy] by 1 # by 1: perf: avoid bidir JS for loop
      for x in [p.x-dx..p.x+dx] by 1
        if @isTorus or (@minX<=x<=@maxX and @minY<=y<=@maxY)
          if @isTorus
            x+=@numX if x<@minX; x-=@numX if x>@maxX
            y+=@numY if y<@minY; y-=@numY if y>@maxY
          pnext = @patchXY x, y # much faster than coord()
          if not pnext?
            u.error "patchRect: x,y out of bounds, see console.log"
            console.log "  x #{x} y #{y} p.x #{p.x} p.y #{p.y} dx #{dx} dy #{dy} minX #{@minX} minY #{@minY}"
        else
          pnext = null
        rect.push pnext if (meToo or p isnt pnext)
    @asSet rect

  # Draws, or "imports" an image URL into the drawing layer.
  # The image is scaled to fit the drawing layer.
  #
  # This is an async load, see this
  # [new Image()](http://javascript.mfields.org/2011/creating-an-image-in-javascript/)
  # tutorial.  We draw the image into the drawing layer as
  # soon as the onload callback executes.
  # The "fat arrow" insures the callback executes within the importDrawing context.
  importDrawing: (imageSrc) ->
    u.importImage imageSrc, (img) ->
      ctx = ABM.drawing
      ctx.save() # revert to native 2D transform
      ctx.setTransform 1, 0, 0, 1, 0, 0
      ctx.drawImage img, 0, 0, ctx.canvas.width, ctx.canvas.height
      ctx.restore() # restore patch transform
  
  # Utility function for pixel manipulation.  Given a patch, returns the 
  # native canvas index i into the pixel data.
  pixelIndex: (p) ->
    ( (p.x-@minX) + (@maxY-p.y)*@numX )*4
    
  # Draws, or "imports" an image URL into the patches as their color property.
  # The drawing is scaled to the number of x,y patches, thus one pixel
  # per patch.  The colors are then transferred to the patches.
  importColors: (imageSrc) ->
    u.importImage imageSrc, (img) => # fat arrow, this context
      if img.width isnt @numX or img.height isnt @numY
        @pixelsCtx.drawImage img, 0, 0, @numX, @numY
      else
        @pixelsCtx.drawImage img, 0, 0
      data = @pixelsCtx.getImageData(0, 0, @numX, @numY).data
      for p in @
        i = @pixelIndex p
        p.color = (data[i+j] for j in [0..2])
      null # avoid CS return of array
  
  # Draw the patches via pixel manipulation rather than 2D drawRect.
  # See Mozilla pixel [manipulation article](http://goo.gl/Lxliq)
  drawScaledPixels: (ctx) -> 
    if @pixelsData32?
      @drawScaledPixels32 ctx
    else
      @drawScaledPixels8 ctx
  # The 8-bit version for drawScaledPixels.  Used for systems w/o typed arrays
  drawScaledPixels8: (ctx) ->
    data = @pixelsData
    minX=@minX; numX=@numX; maxY=@maxY
    for p in @
      i = ( (p.x-minX) + (maxY-p.y)*numX )*4
      c = p.color
      data[i+j] = c[j] for j in [0..2] 
      data[i+3] = if c.length is 4 then c[3] else 255
      
    @pixelsCtx.putImageData(@pixelsImageData, 0, 0)
    return if @size is 1
    ctx.drawImage @pixelsCtx.canvas, 0, 0, ctx.canvas.width, ctx.canvas.height
  # The 32-bit version of drawScaledPixels, with both little and big endian hardware.
  drawScaledPixels32: (ctx) ->
    data = @pixelsData32
    minX=@minX; numX=@numX; maxY=@maxY
    for p in @
      i = (p.x-minX) + (maxY-p.y)*numX
      c = p.color
      a = if c.length is 4 then c[3] else 255
      if @pixelsAreLittleEndian
        data[i] = 
          (a    << 24) |  # alpha
          (c[2] << 16) |  # blue
          (c[1] << 8)  |  # green
          c[0];           # red
      else
        data[i] = 
          (c[0] << 24) |  # red
          (c[1] << 16) |  # green
          (c[2] << 8)  |  # blue
          a;              # alpha
    @pixelsCtx.putImageData(@pixelsImageData, 0, 0)
    return if @size is 1
    ctx.drawImage @pixelsCtx.canvas, 0, 0, ctx.canvas.width, ctx.canvas.height
      
  # Diffuse the value of patch variable `p.v` by distributing `rate` percent
  # of each patch's value of `v` to its neighbors. If a color `c` is given,
  # scale the patch's color to be `p.v` of `c`. If the patch has
  # less than 8 neighbors, return the extra to the patch.
  diffuse: (v, rate, c=null) -> # variable name, diffusion rate, max color (optional)
    # zero temp variable if not yet set
    if not @[0]._diffuseNext?
      p._diffuseNext = 0 for p in @
    # pass 1: calculate contribution of all patches to themselves and neighbors
    for p in @
      dv = p[v]*rate; dv8 = dv/8; nn = p.n.length
      p._diffuseNext += p[v] - dv + (8-nn)*dv8
      n._diffuseNext += dv8 for n in p.n
    # pass 2: set new value for all patches, zero temp, modify color if c given
    for p in @
      p[v] = p._diffuseNext
      p._diffuseNext = 0
      p.scaleColor c, p[v] if c
    null # avoid returning copy of @

# ### Agent & Agents

# Class Agent instances represent the dynamic, behavioral element of ABM.
class ABM.Agent
  # Constructor & Class Variables:
  #
  # * x,y: position on the patch grid, in patch coordinates, default: 0,0
  # * color: the color of the agent, default: ABM.util.randomColor
  # * shape: the ABM.shape name of the agent, default: ABM.agents.defaultShape
  # * heading: direction of the agent, in radians, from x-axis
  # * size: size of agent, in patch coords, default: 1
  # * p: patch at current x,y location
  # * penDown: true if agent pen is drawing
  # * penSize: size in patch coords of the pen, default: 1 pixel
  # * breed: string represented the type of agent. Ex: wolf, rabbit.

  # Default class variables, promoted to instances when needed
  color: null  # default color, overrides random color if set
  shape: "default"
  breed: "default"
  hidden: false
  size: 1
  penDown: false
  penSize: 1
  heading: null
  sprite: null
  links: null
  constructor: ->
    @x = @y = 0
    @color = u.randomColor() if not @color? # promote color if default not set
    @heading = u.randomFloat(Math.PI*2) if not @heading? 
    @p = ABM.patches.patch @x, @y
    @p.agents.push @ if @p.agents? # ABM.patches.cacheAgentsHere
    @links = [] if ABM.links.cacheAgentLinks

  #  Set agent color to `c` scaled by `s`. Usage: see patch.scaleColor
  scaleColor: (c, s) -> 
    @color = u.clone @color if not @.hasOwnProperty("color")
    u.scaleColor c, s, @color
  
  # Return a string representation of the agent.
  toString: ->
    "{id:#{@id} xy:#{u.aToFixed [@x,@y]} c:#{@color} h: #{@heading.toFixed 2}}"
  
  # Place the agent at the given x,y (floats) in patch coords
  # using patch topology (isTorus)
  setXY: (x, y) -> # REMIND GC problem, 2 arrays
    [x0, y0] = [@x, @y] if @penDown
    [@x, @y] = ABM.patches.coord x, y
    p = @p
    @p = ABM.patches.patch @x, @y
    if p.agents? and p isnt @p # ABM.patches.cacheAgentsHere 
      u.removeItem p.agents, @
      @p.agents.push @
    if @penDown
      drawing = ABM.drawing
      drawing.strokeStyle = u.colorStr @color
      drawing.lineWidth = ABM.patches.bits2Patches @penSize
      drawing.beginPath()
      drawing.moveTo x0, y0; drawing.lineTo x, y # REMIND: euclidean
      drawing.stroke()
  
  # Place the agent at the given patch/agent location,
  # using patch topology (isTorus)
  moveTo: (a) -> @setXY a.x, a.y
  
  # Move forward (along heading) d units (patch coords),
  # using patch topology (isTorus)
  forward: (d) ->
    @setXY @x + d*Math.cos(@heading), @y + d*Math.sin(@heading)
  
  # Change current heading by rad radians which can be + (left) or - (right)
  rotate: (rad) -> @heading = u.wrap @heading + rad, 0, Math.PI*2 # returns new h
  
  # Draw the agent: Around ctx save/restore pair
  #
  # * Get the agent shape object: procedure & rotate flag
  # * Set agent transform, assuming patch coordinate transform in place
  # * Rotate shape by heading if rotate flag set on shape
  # * Call the shape draw with our ctx, closing the path
  # * Fill with agent color
  draw: (ctx) ->
    shape = ABM.shapes[@shape]
    ctx.save()
    if @sprite?
      ctx.translate @x, @y # see tutorial: http://goo.gl/VUlhY
      ctx.rotate @heading if shape.rotate
      ctx.scale 1/ABM.patches.size, -1/ABM.patches.size # convert back to pixel scale
      ctx.drawImage @sprite.canvas, -@sprite.canvas.width/2, -@sprite.canvas.height/2
    else
      ctx.translate @x, @y
      ctx.scale @size, @size
      ctx.rotate @heading if shape.rotate
      @colorStr = u.colorStr @color if ABM.agents.staticColors and not @colorStr?
      ctx.fillStyle = @colorStr or u.colorStr @color
      ctx.beginPath()
      shape.draw ctx
      ctx.closePath()
      ctx.fill()
    ctx.restore()
  
  # Draw the agent on the drawing layer, leaving perminant image.
  stamp: -> @draw ABM.drawing
  
  # Return distance in patch coords from me to x,y 
  # using patch topology (isTorus)
  distanceXY: (x,y) ->
    if ABM.patches.isTorus
    then u.torusDistance @x, @y, x, y, ABM.patches.numX, ABM.patches.numY
    else u.distance @x, @y, x, y
  
  # Return distance in patch coords from me to given agent/patch
  # using patch topology (isTorus)
  distance: (o) -> # o any object w/ x,y, patch or agent
    @distanceXY o.x, o.y
  
  # Return the closest torus topology point of given x,y relative to myself.
  # See util.torusPt.
  torusPtXY: (x, y) ->
    u.torusPt @x, @y, x, y, ABM.patches.numX, ABM.patches.numY

  # Return the closest torus topology point of given agent/patch 
  # relative to myself. See util.torusPt.
  torusPt: (o) ->
    @torusPtXY o.x, o.y

  # Set my heading towards given agent/patch using patch topology (isTorus)
  face: (o) -> @heading = @towards o

  # Return heading towards x,y using patch topology (isTorus)
  towardsXY: (x, y) ->
    if ABM.patches.isTorus
    then u.torusRadsToward @x, @y, x, y, ABM.patches.numX, ABM.patches.numY
    else u.radsToward @x, @y, x, y

  # Return heading towards given agent/patch using patch topology (isTorus)
  towards: (o) -> @towardsXY o.x, o.y
  
  # Remove myself from the model.  Includes removing myself from the agents
  # agentset and removing any links I may have.
  die: ->
    ABM.agents.remove @
    l.die() for l in @myLinks()
    u.removeItem @p.agents, @ if @p.agents?
    null

  # Factory: create num new agents here
  # The optional init proc is called on each of the newly created agents.<br>
  # NOTE: init must be applied after object inserted in agent set
  hatch: (num = 1, init = ->) ->
    ABM.agents.create num, (a) => # fat arrow so that @ = this agent
      a.setXY @x, @y # for side effects like patches.agentsHere
      a[k] = v for own k, v of @ when k isnt "id"    
      init(a); a

  # Return the members of the given agentset that are within radius distance 
  # from me, and within cone radians of my heading using patch topology (isTorus)
  inCone: (aset, cone, radius, meToo=false) -> 
    aset.inCone @p, @heading, cone, radius, meToo # REMIND: @p vs @?
  
  # Return other end of link from me
  otherEnd: (l) -> if l.end1 is @ then l.end2 else l.end1

  # Return all links linked to me
  myLinks: ->
    @links ? (l for l in ABM.links when (l.end1 is @) or (l.end2 is @))
  
  # Return all agents linked to me.
  linkNeighbors: -> # return all agents linked to me
    @otherEnd l for l in @myLinks()
  
  # Return links where I am the "to" agent in links.create
  myInLinks: ->
    l for l in @myLinks() when l.end2 is @

  # Return other end of myInLinks
  inLinkNeighbors: ->
    l.end1 for l in @myLinks() when l.end2 is @
    
  # Return links where I am the "from" agent in links.create
  myOutLinks: ->
    l for l in @myLinks() when l.end1 is @
  
  # Return other end of myOutinks
  outLinkNeighbors: ->
    l.end2 for l in @myLinks() when l.end1 is @

# Class Agents is a subclass of AgentSet which stores instances of Agent.

class ABM.Agents extends ABM.AgentSet
  # Constructor creates the AgentSet instance and installs
  # variables shared by all the Agents.  This can be used to
  # minimize Agent variables by using a "default".  Here for example
  # we provide a default shape for agents.
  constructor: ->
    super()
    @staticColors = false
    @useSprites = false

  # Methods to change the default Agent class variables.
  setDefaultColor:  (color) -> ABM.Agent::color = color#; @setDefaultSprite()
  setDefaultShape:  (shape) -> ABM.Agent::shape = shape#; @setDefaultSprite()
  setDefaultSize:   (size)  -> ABM.Agent::size = size#; @setDefaultSprite()
  setDefaultHeading:(heading)-> ABM.Agent::heading = heading
  setDefaultHidden: (hidden)-> ABM.Agent::hidden = hidden
  setDefaultSprite: -> 
    if ABM.Agent::color?
      ABM.Agent::sprite = ABM.shapes.shapeToCtx \
        ABM.Agent::shape, ABM.Agent::color, ABM.Agent::size*ABM.patches.size
  setDefaultPen:   (size, down=false) -> 
    ABM.Agent::penSize = size
    ABM.Agent::penDown = down
  
  # Performance: tell draw to reuse existing color string
  setStaticColors: (@staticColors) ->
  # Use sprites rather than drawing
  setUseSprites: (@useSprites) ->      

  # Factory: create num new agents stored in this agentset.
  # The optional init proc is called on each of the newly created agents.<br>
  # NOTE: init must be applied after object inserted in agent set
  create: (num, init = ->) -> # returns list too
    ((o) -> init(o); o) @add new ABM.Agent for i in [1..num] by 1 # too tricky?

  # Remove all agents from set via agent.die()
  # Note call in reverse order to optimize list restructuring.
  clear: -> @last().die() while @any(); null # tricky, each die modifies list

  # Return the subset of this set with the given breed value.
  breed: (breed) -> @getWithProp "breed", breed
  
  # Return an agentset of agents within the patch array
  agentsInPatches: (patches) ->
    array = []
    array.push p.agentsHere()... for p in patches # concat measured slower
    @asSet array
  
  # Return an agentset of agents within the patchRect
  agentRect: (a, dx, dy, meToo=false) ->
    rect = ABM.patches.patchRect a.p, dx, dy, true
    rect = @agentsInPatches rect
    u.removeItem rect, a if not meToo
    rect
  
  # Return the members of this agentset that are within radius distance
  # from me, and within cone radians of my heading using patch topology (isTorus)<br>
  # See agentset.inCone
  inCone: (a, heading, cone, radius, meToo=false) -> # heading? .. so p ok?
    as = @agentRect a, radius, radius, true
    as.inCone a, heading, cone, radius, meToo
  
  # Return the members of this agentset that are with radius distance
  # from me, using patch topology (isTorus)<br>
  # See agentset.inRadius
  inRadius: (a, radius, meToo=false)->
    as = @agentRect a, radius, radius, true
    as.inRadius a, radius, meToo

# ### Link and Links

# Class Link connects two agent endpoints for graph modeling.
class ABM.Link
  # Constructor initializes instance variables:
  #
  # * end1, end2: two agents being connected
  # * color: defaults to light gray
  # * thickness: the thickness of the line connecting the ends<br>
  #   Defaults to 2 pixels in patch coordinates.
  breed: "default"
  color: [130, 130, 130]
  thickness: 2
  hidden: false
  constructor: (@end1, @end2) ->
    if ABM.links.cacheAgentLinks
      @end1.links.push @
      @end2.links.push @
      
  
  # Draw a line between the two endpoints.  Draws "around" the
  # torus if appropriate using two lines. As with Agent.draw,
  # is called with patch coordinate transform installed.
  draw: (ctx) ->
    ctx.save()
    ctx.strokeStyle = u.colorStr @color
    ctx.lineWidth = ABM.patches.bits2Patches @thickness
    ctx.beginPath()
    if !ABM.patches.isTorus
      ctx.moveTo @end1.x, @end1.y
      ctx.lineTo @end2.x, @end2.y
    else
      pt = @end1.torusPt @end2
      ctx.moveTo @end1.x, @end1.y
      ctx.lineTo pt...
      if pt[0] isnt @end2.x or pt[1] isnt @end2.y
        pt = @end2.torusPt @end1
        ctx.moveTo @end2.x, @end2.y
        ctx.lineTo pt...
    ctx.closePath()
    ctx.stroke()
    ctx.restore()
  
  # Remove this link from the agent set
  die: ->
    ABM.links.remove @
    u.removeItem @end1.links, @ if @end1.links?
    u.removeItem @end2.links, @ if @end2.links?
  
  # Return the two endpoints of this link
  bothEnds: -> [@end1, @end2]
  
  # Return the distance between the endpoints with the current topology.
  length: -> @end1.distance @end2
  
  # Return the other end of the link, given an endpoint agent.
  # Assumes the given input *is* one of the link endpoint pairs!
  otherEnd: (a) -> if @end1 is a then @end2 else @end1

# Class Links is a subclass of AgentSet which stores instances of Link.

class ABM.Links extends ABM.AgentSet
  # Constructor simply creates an unmodified AgentSet
  constructor: ->
    super()
    @cacheAgentLinks = false
  
  # Methods to change the default Link class variables.
  setDefaultColor:     (color)      -> ABM.Link::color = color
  setDefaultThickness: (thickness)  -> ABM.Link::thickness = thickness
  setDefaultHidden:    (hidden)     -> ABM.Link::hidden = hidden

  # Factory: Add 1 or more links from the from agent to
  # the to agent(s) which can be a single agent or an array
  # of agents.
  # The optional init proc is called on each of the newly created links.
  create: (from, to, init = ->) -> # returns list too
    to = [to] if not to.length?
    # NOTE: init must be applied after object inserted in agent set
    ((o) -> init(o); o) @add new ABM.Link from, a for a in to # too tricky?
  
  # Remove all links from set via link.die()
  # Note call in reverse order to optimize list restructuring.
  clear: -> @last().die() while @any(); null # tricky, each die modifies list

  # Return the subset of this set with the given breed value.
  breed: (breed) -> @getWithProp "breed", breed

  # Return all the nodes in this agentset, with duplicates
  # included.  If 4 links have the same endpoint, it will
  # appear 4 times.
  allEnds: -> # all link ends, w/ dups
    n = @asSet []
    n.push l.end1, l.end2 for l in @
    n

  # Returns all the nodes in this agentset sorted by ID and with
  # duplicates removed.
  nodes: -> # allEnds without dups
    @allEnds().sortById().uniq()
  
  # Circle Layout: position the agents in the list in an equally
  # spaced circle of the given radius, with the initial agent
  # at the given start angle (default to pi/2 or "up") and in the
  # +1 or -1 direction (counder clockwise or clockwise) 
  # defaulting to -1 (clockwise).
  layoutCircle: (list, radius, startAngle = Math.PI/2, direction = -1) ->
    dTheta = 2*Math.PI/list.length
    for a, i in list
      a.setXY 0, 0
      a.heading = startAngle + direction*dTheta*i
      a.forward radius
    null
      
