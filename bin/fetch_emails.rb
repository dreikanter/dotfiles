#!/usr/bin/env ruby
# Fetches the 20 most recent emails from Fastmail via JMAP.
# Usage: FASTMAIL_API_TOKEN=your_token ruby fetch_emails.rb

require "net/http"
require "uri"
require "json"

TOKEN = ENV.fetch("FASTMAIL_API_TOKEN") { abort "FASTMAIL_API_TOKEN not set" }
SESSION_URL = "https://api.fastmail.com/jmap/session".freeze

def auth_headers
  { "Authorization" => "Bearer #{TOKEN}", "Content-Type" => "application/json" }
end

def http_get(url)
  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    res = http.request(Net::HTTP::Get.new(uri, auth_headers))
    JSON.parse(res.body)
  rescue JSON::ParserError
    abort "HTTP #{res.code}: #{res.body}"
  end
end

def http_post(url, body)
  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    req = Net::HTTP::Post.new(uri, auth_headers)
    req.body = body.to_json
    res = http.request(req)
    JSON.parse(res.body)
  rescue JSON::ParserError
    abort "HTTP #{res.code}: #{res.body}"
  end
end

session    = http_get(SESSION_URL)
api_url    = session["apiUrl"]
account_id = session["primaryAccounts"]["urn:ietf:params:jmap:mail"]

payload = {
  using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
  methodCalls: [
    [
      "Email/query",
      {
        accountId: account_id,
        sort: [{ property: "receivedAt", isAscending: false }],
        limit: 20
      },
      "q"
    ],
    [
      "Email/get",
      {
        accountId: account_id,
        properties: %w[id subject from receivedAt],
        "#ids": { resultOf: "q", name: "Email/query", path: "/ids/*" }
      },
      "g"
    ]
  ]
}

response = http_post(api_url, payload)
emails   = response["methodResponses"]
           .find { |name, _, _| name == "Email/get" }
           &.dig(1, "list") || []

puts format("%<date>-30s  %<sender>-35s  %<subject>s", date: "DATE", sender: "FROM", subject: "SUBJECT")
puts "-" * 100

emails.each do |email|
  date    = email["receivedAt"]&.then { |t| t[0, 16].sub("T", " ") } || "—"
  from    = Array(email["from"]).first
  sender  = if from.nil?
              "—"
            elsif from["name"].to_s.empty?
              from["email"]
            else
              from["name"]
            end
  subject = email["subject"] || "(no subject)"

  puts format("%<date>-30s  %<sender>-35s  %<subject>s", date: date, sender: sender[0, 35], subject: subject)
end
