require 'digest'
require 'google/cloud/storage'
require 'json'
require 'sinatra'

storage = Google::Cloud::Storage.new(project_id: 'cs291-f19')
bucket  = storage.bucket('cs291_project2', skip_lookup: true)

def sha2url(sha)
  sha.downcase!
  halt 422 if sha !~ /\A[0-9a-f]{64}\Z/
  "#{sha[0..1]}/#{sha[2..3]}/#{sha[4..63]}"
end

def url2sha(url)
  url.gsub('/', '')
end

get '/' do
  redirect to('/files/')
end

get '/files/' do
  response['Content-Type'] = 'application/json'
  JSON.dump(bucket.files.map {|file| url2sha(file.name)})
end

post '/files/' do
  file = params[:file]
  return 422 if file.nil?
  puts file.inspect

  data = file[:tempfile].read
  return 422 if data.length > 1024 ** 2

  sha = Digest::SHA256.hexdigest(data)
  url = sha2url(sha)

  return 409 unless bucket.file(url).nil?
  bucket.create_file(StringIO.new(data), url, content_type: file[:type])
  halt 201, JSON.dump({uploaded: sha})
end

get '/files/:sha' do |sha|
  file = bucket.file(sha2url(sha))
  return 404 if file.nil?

  response['Content-Type'] = file.content_type
  download = file.download
  download.rewind
  download.read
end

delete '/files/:sha' do |sha|
  file = bucket.file(sha2url(sha))
  file.delete unless file.nil?
end
