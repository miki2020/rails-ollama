class CreateAffirmations < ActiveRecord::Migration[8.0]
  def change
    create_table :affirmations do |t|
      t.text :content, null: false
      t.date :date, null: false
      t.string :category, default: 'general'
      t.boolean :favorite, default: false
      t.text :generated_prompt
      t.string :model_used, default: 'llama2'
      t.timestamps
    end

    add_index :affirmations, :date
    add_index :affirmations, [:date, :category]
  end
end
