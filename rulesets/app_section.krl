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

  rule autoAccept {
    select when wrangler inbound_pending_subscription_added
    pre{
      attributes = event:attrs().klog("subcription :");
      }
      {
      noop();
      }
    always{
      raise wrangler event 'pending_subscription_approval'
          attributes attributes;       
          log("auto accepted subcription.");
    }
  }

}