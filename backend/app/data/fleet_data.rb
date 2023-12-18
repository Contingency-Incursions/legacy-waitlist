# frozen_string_literal: true

class FleetData
  def self.load_default_squads
    wings = []

    on_grid_squads = [
      {name: "Logistics", map_to: "logi"},
      {name: "Bastion", map_to: "bastion"},
      {name: "CQC", map_to: "cqc"},
      {name: "Sniper", map_to: "sniper"},
      {name: "Starter", map_to: "starter"},
      {name: "Alts", map_to: "alt"},
      {name: "Box 1"},
      {name: "Box 2"},
      {name: "Box 3"},
      {name: "Box 4"},
    ]

    wings.push({name: "On Grid", squads: on_grid_squads})

    off_grid_squads = [
      {name: "Scout 1"},
      {name: "Scout 2"},
      {name: "Other"}
    ]

    wings.push({name: "Off Grid", squads: off_grid_squads})

    wings
  end
end
