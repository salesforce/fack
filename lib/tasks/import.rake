namespace :import do
  desc 'Import queries from a CSV file'
  task queries: :environment do
    require 'csv'

    # Capture the parameters from the environment variables
    library_id = ENV.fetch('library_id', nil)
    user_id = ENV.fetch('user_id', nil)
    csv_file_path = ENV.fetch('csv_file_path', 'queries.csv') # Default to 'queries.csv' if not provided

    if library_id.blank? || user_id.blank?
      puts 'Error: library_id and user_id are required.'
      exit
    end

    unless File.exist?(csv_file_path)
      puts "Error: CSV file #{csv_file_path} does not exist."
      exit
    end

    line_limit = 5000
    line_count = 0

    CSV.foreach(csv_file_path, headers: true) do |row|
      break if line_count >= line_limit

      # Skip this row if name or service_name is blank
      if row['name'].blank? || row['service_name'].blank?
        puts 'Skipping row due to missing name or service_name.'
        next
      end

      # Adjust the column names to match your CSV headers and model attributes
      document = Document.find_or_initialize_by(external_id: row['id'])
      document.document = <<~ENDDOC
        # EXPRESSION
        #{row['expression']}

        # TEXT
        #{row['customtext']}
      ENDDOC

      document.title = row['name']
      document.library_id = library_id # Assign the library_id
      document.user_id = user_id

      if document.save
        puts "Document #{document.title} saved successfully in library #{library_id}."
      else
        puts "Error saving document #{document.title}: #{document.errors.full_messages.join(', ')}"
      end

      line_count += 1
    end
  end
end
