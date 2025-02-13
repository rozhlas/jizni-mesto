

years = <[ 1980 1990 2001 2011 ]>
class ig.JizakMap extends ig.GenericMap
  (@parentElement, @display) ->
    if @display == "jizak"
      @mapBounds = L.latLngBounds [50.0061,14.4520] [50.0610,14.5595]
      @mapCenter = [50.0318,14.5071]
      @mapZoom = 14
    else
      @mapBounds = L.latLngBounds [49.9366,14.0625] [50.2143,14.9229]
      @mapCenter = [50.0602,14.4906]
      @mapZoom = 11
    super ...

  drawDemography01: ->
    geojson =
      type: "FeatureCollection"
      features: ig.data.allGeojson.features.filter -> ! isNaN it.properties.demoRatio01
    colorScale = d3.scale.threshold!
      ..domain [0.8 0.92 0.98 1.02 1.08 1.3]
      ..range ['rgb(215,48,39)','rgb(252,141,89)','rgb(254,224,139)','rgb(255,255,191)','rgb(217,239,139)','rgb(145,207,96)','rgb(26,152,80)']
    layer = L.geoJson do
      * geojson
      * style: (feature) ->
          color: colorScale feature.properties.demoRatio01
          fillOpacity: 0.5
          weight: 1
        onEachFeature: (feature, layer) ~>
          layer.on \mouseover ~> @displayDemoPopup feature, layer
          layer.on \click ~> @displayDemoPopup feature, layer
    @lastHighlightedLayer = null
    layer.addTo @map


  drawByty: ->
    geojson =
      type: "FeatureCollection"
      features: ig.data.allGeojson.features.filter -> it.properties.neobydlene_byty_pct isnt null
    colorScale = d3.scale.threshold!
      ..domain [3.16 4.28 5.59 9.46 13.34 22.4]
      ..range ['rgb(255,245,240)','rgb(254,224,210)','rgb(252,187,161)','rgb(252,146,114)','rgb(251,106,74)','rgb(239,59,44)','rgb(203,24,29)','rgb(153,0,13)']
    layer = L.geoJson do
      * geojson
      * style: (feature) ->
          color: colorScale feature.properties.neobydlene_byty_pct
          fillOpacity: 0.5
          weight: 1
        onEachFeature: (feature, layer) ~>
          layer.on \mouseover ~> @displayBytyPopup feature, layer
          layer.on \click ~> @displayBytyPopup feature, layer
    @lastHighlightedLayer = null
    layer.addTo @map

  drawDuchodci: ->
    geojson =
      type: "FeatureCollection"
      features: ig.data.allGeojson.features.filter -> it.properties.duchod_11_pct isnt null
    colorScale = d3.scale.threshold!
      ..domain [5 10 15 20 25 30]
      ..range ['rgb(254,230,206)','rgb(253,208,162)','rgb(253,174,107)','rgb(253,141,60)','rgb(241,105,19)','rgb(217,72,1)','rgb(166,54,3)','rgb(127,39,4)']
    layer = L.geoJson do
      * geojson
      * style: (feature) ->
          color: colorScale feature.properties.duchod_11_pct
          fillOpacity: 0.5
          weight: 1
        onEachFeature: (feature, layer) ~>
          layer.on \mouseover ~> @displayDuchodciPopup feature, layer
          layer.on \click ~> @displayDuchodciPopup feature, layer
    @lastHighlightedLayer = null
    layer.addTo @map


  drawDemography: ->
    geojson =
      type: "FeatureCollection"
      features: ig.data.allGeojson.features.filter -> it.properties.obyv_90 isnt null
    colorScale = d3.scale.threshold!
      ..domain [0.8 0.95 1.05 2]
      ..range ['rgb(215,25,28)','rgb(253,174,97)','rgb(255,255,191)','rgb(166,217,106)','rgb(26,150,65)']
    layer = L.geoJson do
      * geojson
      * style: (feature) ->
          color: colorScale feature.properties.demoRatio
          fillOpacity: 0.5
          weight: 2
        onEachFeature: (feature, layer) ~>
          layer.on \mouseover ~> @displayDemoPopup feature, layer
          layer.on \click ~> @displayDemoPopup feature, layer
    @lastHighlightedLayer = null
    layer.addTo @map

  displayDemoPopup: (feature, layer)->
    ele = d3.select document.createElement "div"
    ele.append \b .html feature.properties.NAZ_ZSJ
    pop = for year in <[obyv_80 obyv_90 obyv_01 obyv_11]>
      feature.properties[year]
    maxPop = d3.max pop
    ele.append \ul
      ..style \height "#{60 + maxPop / 100}px"
      ..selectAll \li .data pop .enter!append \li
        ..style \height "#{60 + maxPop / 100}px"
        ..classed \nan -> it is null
        ..append \span
          ..attr \class \year
          ..html (d, i) -> years[i]
        ..append \span
          ..attr \class \count
          ..html -> ig.utils.formatNumber it
          ..style \bottom -> "#{35 + Math.round it / 100}px"
        ..append \svg
          ..attr \height -> Math.round it / 100
          ..attr \width 40
          ..append \line
            ..attr x1: "50%", x2: "50%", y2: "100%"
    @displayPopup feature, layer, ele.node!

  drawCesticky: ->
    geojson = topojson.feature do
      ig.data.cesticky
      ig.data.cesticky.objects."data"
    layer = L.geoJson do
      * geojson
      * style: (feature) ->
          color: \#ab0000
          weight: 3
          opacity: 1
          clickable: no
    layer.addTo @map


  displayBytyPopup: (feature, layer)->
    content = "<strong>#{feature.properties.NAZ_ZSJ}</strong><br>
    #{ig.utils.formatNumber feature.properties.neobydlene_byty_pct, 1} % bytů je zde neobydlených"
    @displayPopup feature, layer, content

  displayDuchodciPopup: (feature, layer) ->
    content = "<strong>#{feature.properties.NAZ_ZSJ}</strong><br>
    Zde žije #{ig.utils.formatNumber feature.properties.duchod_11_pct, 1} % důchodců"
    @displayPopup feature, layer, content


  displayPopup: (feature, layer, content) ->
    @lastHighlightedLayer.setStyle weight: 2, fillOpacity: 0.5 if @lastHighlightedLayer
    @lastHighlightedLayer = layer
    layer.setStyle weight: 5, fillOpacity: 0.8
    popup = L.popup autoPan: no, className: "demo-popup"
      ..setContent content
      ..setLatLng feature.centroid
      ..openOn @map

