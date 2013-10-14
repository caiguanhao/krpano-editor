#= require vendor/cytoscape.min
if $("#graph").length == 1
  $.getJSON '/tours/' + tour_id, (json) ->
    nodes = []
    edges = []
    $.each json.panos, (a, b) ->
      nodes.push { data: { _id: b.id, id: "panos:" + b.id, name: b.name, image: b.thumb } }
      $.each b.connections, (c, d) ->
        d = JSON.parse(d)
        edges.push { data: { source: "panos:" + b.id, target: d.to } }
    console.log json, nodes, edges
    $("#graph").cytoscape
      style: cytoscape.stylesheet().selector("node").css(
        content: "data(name)"
        "background-image": "data(image)"
        shape: "rectangle"
        width: 250
        height: 125
        "text-valign": "center"
        color: "white"
        "text-outline-width": 2
        "text-outline-color": "#000"
      ).selector("edge").css("target-arrow-shape": "triangle").selector(":selected").css(
        "background-color": "black"
        "line-color": "black"
        "target-arrow-color": "black"
        "source-arrow-color": "black"
      )
      elements:
        nodes: nodes
        edges: edges
      showOverlay: false
      ready: ->
        window.cy = this
        cy.elements().unselectify()
        cy.on "tap", "node", (e) ->
          link = '/tours/' + tour_id + '/panoramas/' + this.data('_id')
          window.location.href = link
