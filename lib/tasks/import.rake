require 'csv'

def csv_import
  # Save the file from http://www.psd.govt.nz/list/index.php after checking Acronym, Website, Email
  @parsed_file=CSV::Reader.parse(File.open(File.join(RAILS_ROOT, "db", "psdlist.csv"), "r").read)
  n=0
  @parsed_file.each  do |row|
    body = PublicBody.new(
      :name => row[0],
      :short_name => row[1],
      :request_email => row[3],
      :home_page => row[2],
      :url_name => row[0].parameterize,
      :last_edit_editor => "automated"
    )

    if PublicBody.find_by_name(body.name).nil?
      if body.save
        n = n + 1
        GC.start if n % 50 == 0
      end
    end
  end
  puts "CSV Import Successful,  #{n} new records added to data base"
end


namespace :db do
  namespace :psd do
    desc "Reads psdlist.csv and adds any public bodies not found to the db"
    task :update => :environment do
      csv_import
    end
  end
end

