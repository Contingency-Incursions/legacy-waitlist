class CreateMapSolarSystems < ActiveRecord::Migration[7.1]
  def change
    create_table :map_solar_systems, id: false do |t|
      t.integer :regionID
      t.integer :constellationID
      t.integer :solarSystemID
      t.string :solarSystemName
      t.float :x
      t.float :y
      t.float :z
      t.float :xMin
      t.float :xMax
      t.float :yMin
      t.float :yMax
      t.float :zMin
      t.float :zMax
      t.float :luminosity
      t.boolean :border
      t.boolean :fringe
      t.boolean :corridor
      t.boolean :hub
      t.boolean :international
      t.boolean :regional
      t.boolean :constellation
      t.float :security
      t.integer :factionID
      t.float :radius
      t.integer :sunTypeID
      t.string :securityClass

      t.timestamps
    end
    add_index :map_solar_systems, :solarSystemID, unique: true
  end
end
