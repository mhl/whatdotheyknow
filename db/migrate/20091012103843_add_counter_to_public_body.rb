class AddCounterToPublicBody < ActiveRecord::Migration
  def self.up
    add_column :public_bodies, :info_requests_count, :integer, :default => 0

    PublicBody.reset_column_information
    PublicBody.find(:all).each do |p|
      PublicBody.update_counters p.id, :info_requests_count => p.info_requests.length
    end
  end

  def self.down
    remove_column :public_bodies, :info_requests_count
  end
end
