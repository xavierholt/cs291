# frozen_string_literal: true

require 'json'
require 'jwt'
require 'pp'

def header(event, key)
  key = key.downcase
  event['headers'].each do |k, v|
    return v if k.downcase == key
  end

  return ''
end

def token(event)
  if event['httpMethod'] != 'POST'
    return response(status: 405)
  elsif header(event, 'content-type') != 'application/json'
    return response(status: 415)
  end

  time = Time.now.to_i
  data = JSON.parse(event['body'].to_s)
  response(status: 201, body: {
    token: JWT.encode({data: data, nbf: time+2, exp: time+5}, ENV['JWT_SECRET'], 'HS256')
  })
rescue JSON::ParserError
  response(status: 422)
end

def root(event)
  if event['httpMethod'] != 'GET'
    return response(status: 405)
  end

  token = header(event, 'authorization')
  unless token.start_with?('Bearer ')
    return response(status: 403)
  end

  data = JWT.decode(token.sub('Bearer ', ''), ENV['JWT_SECRET'], true)
  response(status: 200, body: data.dig(0, 'data'))
rescue JWT::ExpiredSignature, JWT::ImmatureSignature
  response(status: 401)
rescue JWT::DecodeError
  response(status: 403)
end

def main(event:, context:)
  # You shouldn't need to use context, but its fields are explained here:
  # https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html
  if event['path'] == '/token'
    token(event)
  elsif event['path'] == '/'
    root(event)
  else
    response(status: 404)
  end
end

def response(body: nil, status: 200)
  {
    body: body ? body.to_json + "\n" : '',
    statusCode: status
  }
end

if $PROGRAM_NAME == __FILE__
  # If you run this file directly via `ruby function.rb` the following code
  # will execute. You can use the code below to help you test your functions
  # without needing to deploy first.
  ENV['JWT_SECRET'] = 'NOTASECRET'

  # Call /token
  PP.pp main(context: {}, event: {
    'body'       => '{"name": "bboe"}',
    'headers'    => {'ConTent-Type' => 'application/json'},
    'httpMethod' => 'POST',
    'path'       => '/token'
  })

  # Generate a token
  payload = {
    data: { user_id: 128 },
    exp: Time.now.to_i + 1,
    nbf: Time.now.to_i
  }
  token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
  # Call /
  PP.pp main(context: {}, event: {
    'headers' => {
      'Authorization' => "Bearer #{token}",
      'Content-Type'  => 'application/json'
    },
    'httpMethod' => 'GET',
    'path' => '/'
  })
end
