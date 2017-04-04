ruleset app_vehicle {
  meta {
    name "App Vehicle"
    description <<
      Installed in all new vehicles
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
      vehicle_id = event:attr("vehicle_id")
    }
    always {
      ent:vehicle_id := vehicle_id
    }
  }

  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      attributes = event:attrs().klog("subscription :")
    }
    always {
      raise wrangler event "pending_subscription_approval"
          attributes attributes.klog("attributes : ")
    }
  }

}