ruleset track_trips2 {
  meta {
    name "Part 2: Track Trips"
    description <<
      Part 2
    >>
    author "Josh Parsons"
    logging on
    shares __testing
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
  
}