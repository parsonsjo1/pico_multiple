ruleset app_section {
  meta {
    name "App Section"
    description <<
      Pico-Based Systems Lesson
    >>
    author "Josh Parsons"
    logging on
    shares __testing
  }
  
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }
  }

  rule ruleset_added {
    select when pico ruleset_added
    pre {
      section_id = event:attr("section_id")
    }
    always {
      ent:section_id := section_id
    }
  }

}