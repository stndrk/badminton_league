class CreateCoreSchema < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string  :name,            null: false
      t.string  :email,           null: false, index: { unique: true }
      t.string  :password_digest, null: false
      t.integer :role,            null: false, default: 0
      t.string  :mobile
      t.date    :dob

      t.timestamps
    end

    create_table :leagues do |t|
      t.string     :name,    null: false
      t.references :user,    null: false, foreign_key: true   # owner
      t.timestamps
    end

    create_table :memberships do |t|
      t.references :user,   null: false, foreign_key: true
      t.references :league, null: false, foreign_key: true
      t.integer    :role,   null: false, default: 0
      t.timestamps
      t.index [ :user_id, :league_id ], unique: true
    end

    create_table :matches do |t|
      t.references :league, null: true, foreign_key: true    # optional
      t.references :winner, null: false, foreign_key: { to_table: :users }
      t.references :loser,  null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
