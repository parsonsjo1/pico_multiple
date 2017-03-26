ruleset manage_fleet {
  meta {
    name "Manage Fleet"
    description <<
      Part 1: Buliding a fleet
    >>
    author "Josh Parsons"
    logging on
    shares __testing
    use module io.picolabs.pico alias wrangler
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }
  }
}
