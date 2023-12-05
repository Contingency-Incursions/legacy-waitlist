class CreateInvMetaTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :inv_meta_types, id: false do |t|
      t.integer :typeID
      t.integer :parentTypeID
      t.integer :metaGroupID

      t.timestamps
    end
    add_index :inv_meta_types, :typeID, unique: true
  end
end
