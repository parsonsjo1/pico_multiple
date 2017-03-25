ruleset app_section_collection {
  meta {
    name "App Section Collection"
    description <<
      Pico-Based Systems Lesson
    >>
    author "Josh Parsons"
    logging on
    shares __testing
    use module io.picolabs.pico alias wrangler
  }
  
  global {

    nameFromID = function(section_id) {
      "Section" + section_id + "Pico"
    }

    showChildren = function() {
      wrangler:children()
    }

    __testing = { "queries": [ { "name": "showChildren" } ],
                  "events": [ { "domain": "section", "type": "section_needed",
                                "attrs": [ "section_id" ] } ]
                }

  }  

  rule section_needed {
    select when section section_needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
      eci = meta:eci
    } 
    if exists then
      send_directive("section_ready")
        with section_id = section_id
    fired {

    } else {
      ent:sections := ent:sections.defaultsTo([]).union([section_id]);
      raise pico event "new_child_request"
        attributes { "dname": nameFromID(section_id), "color": "#FF69B4" }
    }
  }
}