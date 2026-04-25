class CreateSignupGuardSignals < ActiveRecord::Migration[7.1]
  def change
    create_table :signup_guard_signals do |t|
      t.references :user, foreign_key: {to_table: SignupGuard.configuration.user_class.tableize}, null: true
      t.string :email
      t.string :email_domain
      t.string :ip_address
      t.string :asn
      t.string :country_code
      t.text :user_agent
      t.string :fingerprint
      t.text :referrer
      t.integer :time_to_submit_ms
      t.boolean :honeypot_triggered, default: false, null: false
      t.float :turnstile_score
      t.float :ip_risk_score
      t.boolean :disposable_email, default: false, null: false
      t.boolean :mx_valid
      t.integer :risk_score, default: 0, null: false
      t.string :risk_level, default: "low", null: false
      t.jsonb :raw_signals, default: {}, null: false

      t.timestamps
    end

    add_index :signup_guard_signals, [:email_domain, :created_at]
    add_index :signup_guard_signals, [:ip_address, :created_at]
    add_index :signup_guard_signals, [:fingerprint, :created_at]
    add_index :signup_guard_signals, :risk_level
  end
end
