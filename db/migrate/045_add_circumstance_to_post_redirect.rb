class AddCircumstanceToPostRedirect < ActiveRecord::Migration
  def self.up
        add_column :post_redirects, :circumstance, :text
        PostRedirect.update_all "circumstance = 'normal'"
        change_column :post_redirects, :circumstance, :text,  :null => false
  end

  def self.down
        remove_column :post_redirects, :circumstance
  end
end
