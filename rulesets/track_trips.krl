ruleset track_trips2 {
  meta {
    name "Part 2: Track Trips"
    description <<
      Part 2
    >>
    author "Josh Parsons"
    logging on
    shares __testing
    use module trip_store
  }
  
  global {

    long_trip = 100

    __testing = { "queries": [{ "name": "__testing" } ],
                  "events": [ { "domain": "car", "type": "new_trip",
                                "attrs": [ "mileage" ] } ]
                }

  }
  
  rule process_trip {
    select when car new_trip
    pre {
      mileage = event:attr("mileage")
      timestamp = time:now()
    }
    send_directive("trip") with
      trip_length = mileage
    always {
      raise explicit event "trip_processed" with
        mileage = mileage.klog("sending mileage: ")
        timestamp = timestamp.klog("sending time: ")
    }
  }

  rule find_long_trips {
    select when explicit trip_processed
    pre {
      mileage = event:attr("mileage")
      timestamp = timestamp
    }
    always {
      raise explicit event "found_long_trip" 
        attributes event:attrs() if mileage.as("Number").klog("mileage is: ") > long_trip.klog("long trip is ")
    }

  }

  rule generate_report {
    select when vehicle new_report
    pre {
      trips = trip_store:trips().klog("track trips: ")
      subscription_map = 
      { 
        "eci": event:attr("parent_eci").klog("parent eci"),
        "eid": "generated-report",
        "domain": "fleet",
        "type": "processed_report",
        "attrs": { "vehicle_id": event:attr("vehicle_id"), "trips": trips }
      }
      received = event:attrs().klog("track_trips received")
    }
    event:send(subscription_map.klog("track trips map"))

  }
  
}