### AgentScript

AgentScript is a minimalist Agent Based Modeling (ABM) framework based on [NetLogo](http://ccl.northwestern.edu/netlogo/) (NL) agent semantics.  Its goal is to promote the Agent Oriented Programming model in a highly deployable [CoffeeScript](http://coffeescript.org/)/JavaScript (CS/JS) implementation.
Please drop by our 
[Google Group](https://groups.google.com/forum/?hl=en#!forum/agentscript)

#### Build

Cake is used to build agentscript.coffee from individual source files, and to compile into agentscript.js, agentscript.min.js, and agentscript.map.  The map file allows debugging in Chrome via CS source.

See the template.html and models/*.html files for example models.  The individual
.coffee files are documented via Jeremy Ashkenas's
[docco](http://jashkenas.github.com/docco/) in the docs/ dir. See the Cakefile for details.

#### Documentation

Currently the documentation is hosted directly on github via the [rawgithub](https://rawgithub.com/) project using the docco generated html found in the doc/ directory.  One exception is the template.html file in the top level directory.

[**util.coffee**](https://rawgithub.com/backspaces/agentscript/master/docs/1-util.html): is the base module for all of the miscellaneous functions used by the rest of the project.

[**shapes.coffee**](https://rawgithub.com/backspaces/agentscript/master/docs/2-shapes.html): is a simple agent shapes module containing the default shapes and a few functions for getting the named shapes and adding your own shapes.

[**agentset.coffee**](https://rawgithub.com/backspaces/agentscript/master/docs/3-agentset.html) is the core array subclass used by patches, agents, and links.

[**agentsets.coffee**](https://rawgithub.com/backspaces/agentscript/master/docs/4-agentsets.html) contains the three subclasses of AgentSet: Patches, Agents, and Links along with the three classes they manage: Patch, Agent, and Link.

[**model.coffee**](https://rawgithub.com/backspaces/agentscript/master/docs/5-model.html) is the top level integration for all the agentsets and is subclassed by all user models. 

[**template.html**](https://rawgithub.com/backspaces/agentscript/master/docs/6-template.html) is a trivial subclass of Model showing the basic structure how you build your own models.  In addition, the models/ directory contains 10 simple models used in teaching NetLogo. You can [run the model here.](https://rawgithub.com/backspaces/agentscript/master/models/template.html) 

#### Add-ons

The extras/ directory contains libraries that are too specialized to be in the core AgentScript but are essential for certain applications.  They are compiled to JS in the lib/ directory.

[**data.coffee**](https://rawgithub.com/backspaces/agentscript/master/docs/data.html) A 2D DataSet library for data best expressed as an array of numbers.  It includes the ability to treat Images as data, to parse GIS elevation .asc files, to create datasets from patch variables etc.  It includes analytic abilities like nearest neighbor and bilinear sampling, convolution with 3x3 kernels, and resampling datasets to different resolutions.

[**fbui.coffee**](https://rawgithub.com/backspaces/agentscript/master/docs/fbui.html) A simple start at a User Interface abstraction, with JSON representing buttons, sliders, switches and menus.  Each item in the JSON tree modifies the state of the model, either directly by setting Model variables or indirectly by calling a method in class Model.

[**mouse.coffee**](https://rawgithub.com/backspaces/agentscript/master/docs/mouse.html) A trivial event based interface to the mouse, mainly for direct interaction with the model's graphic layers.  It converts the mouse raw coordinates into patch coordinates.

#### Sample Models

The models/ directory contains tiny models used to test the system and offer examples to get started with.  I also use the rawgithub project to view directly on github.  These usually print to the console.log, so opening the developer's javascript console will show model information.

[**ants.html**](https://rawgithub.com/backspaces/agentscript/master/models/ants.html) Ant foraging with nest and food pheromone diffusion. 

[**buttons.html**](https://rawgithub.com/backspaces/agentscript/master/models/buttons.html) Stuart Kauffman's example of randomly connecting pairs of buttons in a pile resulting in a tipping point.

[**diffusion.html**](https://rawgithub.com/backspaces/agentscript/master/models/diffusion.html) Agents randomly flying on a patch grid dropping a color which is diffused over the grid.

[**fire.html**](https://rawgithub.com/backspaces/agentscript/master/models/fire.html) A CA based spread of fire showing burn behavior.

[**flock.html**](https://rawgithub.com/backspaces/agentscript/master/models/flock.html) The classic "boids" model where agents use three simple rules resulting in realistic flocking.

[**gridpath.html**](https://rawgithub.com/backspaces/agentscript/master/models/gridpath.html) One of Knuth's great puzzles on the probability of all Manhattan  traversals diagonally traversing a grid.

[**linktravel.html**](https://rawgithub.com/backspaces/agentscript/master/models/linktravel.html) Agents traversing a graph of nodes and links.

[**nbody.html**](https://rawgithub.com/backspaces/agentscript/master/models/nbody.html) Nonlinear gravitation of n bodies.

[**prefattach.html**](https://rawgithub.com/backspaces/agentscript/master/models/prefattach.html) Example of a dynamic graph with new links preferentially attaching to nodes with most links.  This results in a power-law distribution.

[**tspga.html**](https://rawgithub.com/backspaces/agentscript/master/models/tspga.html) A Traveling Sales Person solution via a Genetic Algorithm showing the rapid conversion of stochastic methods.

#### Sample Models Format

Our example models use CoffeeScript directly within the browser via `text/coffeescript` [script tags](http://coffeescript.org/#scripts):

    <html>
      <head>
        <title>AgentScript Model</title>
        <script src="agentscript.js"></script>
        <script src="coffee-script.js"></script>
        <script type="text/coffeescript">
        class MyModel extends ABM.Model
              ...
        model = new MyModel "layers", 13, -16, 16, -16, 16
              ...
        </script>
      </head>
      <body>
        <div id="layers" style="padding:20"></div>
      </body>
    </html>

You may see this by running a sample model, then use the browser's View Page Source.  (Google "view page source")

Similarly, the models will print to the "javascript console" while they run. (Google "view javascript console")

#### Files
    
    Cakefile            cake file for build, docs etc.
    LICENSE             GPLv3 License
    README.md           This file
    docs/               Docco documentation
    extras/             AgentScript extensions
    lib/                All .js/min.js and .map files
    models/             Sample models
    src/                Component .coffee files for agentscript.coffee
    tools/              coffee-script.js and others
    
#### License

Copyright Owen Densmore, RedfishGroup LLC, 2012, 2013<br>
http://agentscript.org/<br>
AgentScript may be freely distributed under the GPLv3 license:

AgentScript is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program, see LICENSE within the distribution.
If not, see <http://www.gnu.org/licenses/>.

#### Additonal Contributors

- Stephen Bannasch <stephen.bannasch@gmail.com>, as part of the [Concord Consortium](http://concord.org/)

  All contributions from [Concord Consortium](http://concord.org/) to AgentScript
  are licensed under all of the following licenses:
  [Simplified BSD](http://www.opensource.org/licenses/BSD-2-Clause),
  [MIT](http://www.opensource.org/licenses/MIT), or
  [Apache 2.0](http://www.opensource.org/licenses/Apache-2.0).
