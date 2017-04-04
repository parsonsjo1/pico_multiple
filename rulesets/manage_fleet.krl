ruleset manage_fleet {
  meta {
    name "Manage Fleet"
    description <<
      Part 1: Buliding a fleet
    >>
    author "Josh Parsons"
    logging on
    shares showLatestReport, generateReport, vehicles, showVehicles, __testing
    use module io.picolabs.pico alias wrangler
    use module Subscriptions
    use module trip_store
  }
  global {

    responded = 0

    nameFromID = function(vehicle_id) {
      "Vehcile" + vehicle_id + "Pico"
    }

    childFromID = function(vehicle_id) {
      ent:vehicles{vehicle_id}
    }

    vehicles = function() {
      Subscriptions:getSubscriptions().filter(function(k,v) { k["attributes"]["subscriber_role"] == "vehicle" })
    }

    showVehicles = function() {
      wrangler:children()
    }

    showLatestReport = function() {
      ent:fleet_trip_report.slice(0,(ent:fleet_trip_report.length() > 4) => 4 | ent:fleet_trip_report.length() - 1)
    }

    generateReport = function() {
      // cookbook: https://picolabs.atlassian.net/wiki/spaces/docs/pages/1184812/Calling+a+Module+Function+in+Another+Pico
      // working example: http://localhost:8080/sky/cloud/cj10a61fv000fh2icoon3vb4l/trip_store/trips
      cloud_url = "http://localhost:8080/sky/cloud/";
      ruleset_name = "trip_store";
      func = "trips";
      responded = 0;

      result = ent:vehicles.map(
        function(vehicle){ 
          eci = vehicle["eci"];
          response = http:get(cloud_url + eci + "/" + ruleset_name + "/" + func).klog("response:");
          responded = responded + 1;
          { "vehicles": ent:vehicles.length(), "responding": responded, "trips": response["content"].decode()}
        }
      )


//      responses = [];
//      eci = "cj10a61fv000fh2icoon3vb4l";
//      response = http:get(cloud_url + eci + "/" + ruleset_name + "/" + func);
//      responses = responses.append([{"vehicle": 1, "trips": response{"content"}.decode()}]);
//
//      cloud_url = "http://localhost:8080/sky/cloud/";
//      eci = "cj10a63sp000jh2icuz8k1z5j";
//      response = http:get(cloud_url + eci + "/" + ruleset_name + "/" + func);
//      responses = responses.append([{"vehicle": 2, "trips": response{"content"}.decode()}]);
//
//      cloud_url = "http://localhost:8080/sky/cloud/";
//      eci = "cj10a6bwb000rh2icbjhbnqhk";
//      response = http:get(cloud_url + eci + "/" + ruleset_name + "/" + func);
//      responses = responses.append([{"vehicle": 3, "trips": response{"content"}.decode()}]);
//
//      responses
    }

    __testing = { "queries": [ { "name": "vehicles" },
                               { "name": "showVehicles" },
                               { "name": "generateReport" },
                               { "name": "showLatestReport" } ],
                  "events":  [ { "domain": "empty", "type": "collection" },
                               { "domain": "car", "type": "new_vehicle",
                                 "attrs": [ "vehicle_id" ] },
                               { "domain": "car", "type": "unneeded_vehicle",
                                 "attrs": [ "vehicle_id" ] },
                               { "domain": "fleet", "type": "new_report" } ,
                               { "domain": "fleet", "type": "delete_report" }
                             ]
                }

  }  

  // Part 3
  rule generate_reports {
    select when fleet new_report
      foreach ent:vehicles setting(vehicle)
      pre {
        eci = vehicle.eci.klog("eci:")
        subscription_map = 
        { 
          "eci": eci,
          "eid": "generate-report",
          "domain": "vehicle",
          "type": "new_report",
          "attrs": { "parent_eci": meta:eci, "vehicle_id": vehicle.id }
        }
      }
      event:send(subscription_map.klog("map"))
  }  

  rule completed_report {
    select when fleet processed_report
    pre {
      trips = event:attr("trips").klog("manage fleet trips")
      vehicle_id = event:attr("vehicle_id").klog("vehicleid")
    }
    always {
      ent:responded := ent:responded.defaultsTo(0) + 1;
      ent:responded := 1 if ent:responded > ent:vehicles.length();
      ent:fleet_trip_report := ent:fleet_trip_report.defaultsTo([]);
      report = { };
      report = report.put([vehicle_id], { "vehicles": ent:vehicles.length(), "responding": ent:responded.as("String").klog("responded"), "trips": trips });
      ent:fleet_trip_report := ent:fleet_trip_report.append([report])
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
          "attrs": { "rid": "app_vehicle", "vehicle_id": vehicle_id }
        }
      )
      event:send(
        { "eci": the_vehicle.eci, 
          "eid": "install-ruleset",
          "domain": "pico",
          "type": "new_ruleset",
          "attrs": { "rid": "Subscriptions" }
        }
      )
      event:send(
        { "eci": the_vehicle.eci, 
          "eid": "install-ruleset",
          "domain": "pico",
          "type": "new_ruleset",
          "attrs": { "rid": "trip_store" }
        }
      )
      event:send(
        { "eci": the_vehicle.eci, 
          "eid": "install-ruleset",
          "domain": "pico",
          "type": "new_ruleset",
          "attrs": { "rid": "track_trips2" } 
        }
      )
    fired {
      ent:vehicles := ent:vehicles.defaultsTo({}).klog("vehicles: ");
      ent:vehicles{[vehicle_id]} := the_vehicle;
      raise wrangler event "subscription" with
         name = vehicle_id
         name_space = "fleet"
         my_role = "controller"
         subscriber_role = "vehicle"
         channel_type = "subscription"
         subscriber_eci = the_vehicle.eci
    }
  }

  rule delete_vehicle {
    select when car unneeded_vehicle
    pre{
      vehicle_id = event:attr("vehicle_id")
      exists = ent:vehicles >< vehicle_id
      eci = meta:eci
      child_to_delete = childFromID(vehicle_id)
    }
    if exists then
      send_directive("vehicle_deleted") with
        vehicle_id = vehicle_id
    fired {
      raise wrangler event "subscription_cancellation" with
        subscription_name = "fleet:" + vehicle_id.klog("cancel sub: ");
      raise pico event "delete_child_request"
        attributes child_to_delete;
      ent:vehicles{[vehicle_id]} := null
    }
  }

  rule empty_collection {
    select when empty collection
    always {
      ent:vehicles := {}
    }
  }

  rule delete_fleet_report {
    select when fleet delete_report
    always {
      ent:fleet_trip_report := []
    }
  }

}