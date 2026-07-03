#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'optparse'
require 'securerandom'

options = {
  total: 1_000_000,
  batch_size: 10_000,
  deleted_percent: 1.0,
  library_id: nil,
  user_id: nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/rails runner scripts/load_test_documents.rb [options]"

  opts.on("--total N", Integer, "Total docs to create (default: #{options[:total]})") { |v| options[:total] = v }
  opts.on("--batch-size N", Integer, "Batch size per insert (default: #{options[:batch_size]})") { |v| options[:batch_size] = v }
  opts.on("--deleted-percent N", Float, "Percent soft-deleted (default: #{options[:deleted_percent]})") { |v| options[:deleted_percent] = v }
  opts.on("--library-id N", Integer, "Library id to attach documents to") { |v| options[:library_id] = v }
  opts.on("--user-id N", Integer, "User id to set on documents") { |v| options[:user_id] = v }
end.parse!(ARGV)

library = if options[:library_id]
            Library.find(options[:library_id])
          else
            Library.first || raise("No library found. Create one first or pass --library-id.")
          end

user = if options[:user_id]
         User.find(options[:user_id])
       else
         User.first || raise("No user found. Create one first or pass --user-id.")
       end

adjectives = %w[fast resilient scalable reliable practical async semantic lexical vector indexed distributed]
nouns = %w[search engine document policy report note guide index pipeline system endpoint]
verbs = %w[explains summarizes indexes connects optimizes compares audits tracks recommends explores]

total = options[:total]
batch_size = options[:batch_size]
deleted_ratio = options[:deleted_percent] / 100.0
start_time = Time.current
inserted = 0

puts "Starting bulk insert: total=#{total}, batch_size=#{batch_size}, deleted_percent=#{options[:deleted_percent]}, library_id=#{library.id}, user_id=#{user.id}"

while inserted < total
  now = Time.current
  remaining = total - inserted
  batch_count = [batch_size, remaining].min

  rows = Array.new(batch_count) do |offset|
    doc_number = inserted + offset + 1

    adjective = adjectives[doc_number % adjectives.length]
    noun = nouns[(doc_number / 3) % nouns.length]
    verb = verbs[(doc_number / 7) % verbs.length]

    body = [
      "Document #{doc_number} describes #{adjective} #{noun} behavior.",
      "This sample text #{verb} how retrieval and filtering work at scale.",
      "Keywords: library-#{library.id}, test-data, batch-#{inserted / batch_size}, token-#{SecureRandom.hex(4)}."
    ].join(" ")

    is_deleted = deleted_ratio.positive? && rand < deleted_ratio
    deleted_at = is_deleted ? now - rand(30..300).days : nil

    {
      document: body,
      title: "Load Test Document #{doc_number}",
      length: body.length,
      token_count: (body.split.size * 1.3).to_i,
      check_hash: Digest::SHA2.hexdigest(body),
      library_id: library.id,
      user_id: user.id,
      enabled: true,
      disabled: false,
      created_at: now - rand(1..365).days,
      updated_at: now,
      deleted_date: deleted_at
    }
  end

  Document.insert_all(rows)
  inserted += batch_count

  elapsed = (Time.current - start_time).round(1)
  puts "Inserted #{inserted}/#{total} (#{((inserted.to_f / total) * 100).round(2)}%) in #{elapsed}s"
end

total_deleted = Document.unscoped.where(library_id: library.id).where.not(deleted_date: nil).count
total_active = Document.unscoped.where(library_id: library.id, deleted_date: nil).count

puts "Done in #{(Time.current - start_time).round(1)}s"
puts "Library #{library.id} totals: active=#{total_active}, deleted=#{total_deleted}"
