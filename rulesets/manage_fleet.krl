ruleset manage_fleet {
  meta {
    name "Manage Fleet"
    description <<
      Part 1: Buliding a fleet
    >>
    author "Josh Parsons"
    logging on
    shares vehicles, showVehicles, __testing
    use module io.picolabs.pico alias wrangler
  }
  global {

    nameFromID = function(vehicle_id) {
      "Vehcile" + vehicle_id + "Pico"
    }

    childFromID = function(vehicle_id) {
      ent:vehicles{vehicle_id}
    }

    vehicles = function() {
      ent:vehicles
    }

    showVehicles = function() {
      wrangler:children()
    }

    __testing = { "queries": [ { "name": "vehicles" },
                               { "name": "showVehicles" } ],
                  "events":  [ { "domain": "empty", "type": "collection" },
                               { "domain": "car", "type": "new_vehicle",
                                 "attrs": [ "vehicle_id" ] }
                             ]
                }

  }  

  rule vehicle_already_exists {
    select when car new_vehicle
    pre {
      vehicle_id = event:attr("vehicle_id")
      exists = ent:vehicles >< vehicle_id
    } 
    if exists then
      send_directive("vehicle_ready")
        with vehicle_id = vehicle_id
  }

  rule create_vehicle {
    select when car new_vehicle
    pre {
      vehicle_id = event:attr("vehicle_id")
      exists = ent:vehicles >< vehicle_id
    }
    if not exists then
      noop()
    fired {
      raise pico event "new_child_request"
        attributes {
          "dname": nameFromID(vehicle_id),
          "color": "#FF69B4",
          "vehicle_id": vehicle_id
        }
    }
  }

  rule pico_child_initialized {
    select when pico child_initialized
    pre {
      the_vehicle = event:attr("new_child")
      vehicle_id = event:attr("rs_attrs"){"vehicle_id"}
    }
    if vehicle_id.klog("found vehicle_id") then
      event:send(
        { "eci": the_vehicle.eci, 
          "eid": "install-ruleset",
          "domain": "pico",
          "type": "new_ruleset",
          "attrs": { "rid": "app_section", "vehicle_id": vehicle_id }
        }
      )
    fired {
      ent:vehicles := ent:vehicles.defaultsTo({});
      ent:vehicles{[vehicle_id]} := the_vehicle
    }
  }

//  rule section_offline {
//    select when section offline
//    pre{
//      section_id = event:attr("section_id")
//      exists = ent:sections >< section_id
//      eci = meta:eci
//      child_to_delete = childFromID(section_id)
//    }
//    if exists then
//      send_directive("section_deleted") with
//        sectio_id = section_id
//    fired {
//      raise pico event "delete_child_request"
//        attributes child_to_delete;
//      ent:sections{[section_id]} := null
//    }
//  }

  rule empty_collection {
    select when empty collection
    always {
      ent:vehicles := {}
    }
  }
}
