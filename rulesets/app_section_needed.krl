ruleset app_section_collection {
  meta {
    name "App Section Collection"
    description <<
      Pico-Based Systems Lesson
    >>
    author "Josh Parsons"
    logging on
    shares sections, showChildren, __testing
    use module io.picolabs.pico alias wrangler
  }
  
  global {

    nameFromID = function(section_id) {
      "Section" + section_id + "Pico"
    }

    sections = function() {
      ent:sections
    }

    showChildren = function() {
      wrangler:children()
    }

    __testing = { "queries": [ { "name": "showChildren" },
                               { "name": "sections" } ],
                  "events": [ { "domain": "section", "type": "needed",
                                "attrs": [ "section_id" ] } ]
                }

  }  

  rule section_already_exists {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
    } 
    if exists then
      send_directive("section_ready")
        with section_id = section_id
  }

  rule section_needed {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
    }
    if not exists then
      noop()
    fired {
      raise pico event "new_child_request"
        attributes {
          "dname": nameFromID(section_id),
          "color": "#FF69B4",
          "section_id": section_id
        }
    }
  }

  rule pico_child_initialized {
    select when pico child_initialized
    pre {
      the_section = event:attr("new_child")
      section_id = event:attr("rs_attrs"){"section_id"}
    }
    if section_id.klog("found section_id") then
      noop()
    fired {
      ent:sections := ent:sections.defaultsTo({});
      ent:sections{[section_id]} := the_section
    }
  }

  rule collection_empty {
    select when collection_empty
    always {
      ent:sections := {}
    }
  }
}