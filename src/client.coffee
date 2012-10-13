_              = require 'underscore'
{EventEmitter} = require 'events'
request        = require 'superagent'
Faye           = require 'faye'

# Use the non-apex domain for highest QOS.
API_URL            = "https://deathstar-staging.herokuapp.com"
AUTHORIZE_ENDPOINT = "/oauth2/authorize"
TOKEN_ENDPOINT     = "/oauth2/token"
GRANT_TYPE         = "password"
REFRESH_GRANT_TYPE = "refresh_token"
PUSH_URL           = "https://push-staging.do.com"

_.noop = ->

class Credentials
  constructor: (r, @client) ->
    expiresInMs = (r['expires_in'] - 10) * 1000
    [@accessToken, @refreshToken, @expiresAt] = [r['access_token'], r['refresh_token'], Date.now() + expiresInMs]
    setTimeout =>
      @client.emit 'authorization:expired'
    , expiresInMs

  valid: ->
    Date.now() < @expiresAt

ClientActions =
  set: (key, value) ->
    event = if @[key] then "updated" else "created"
    @[key] = value
    @emit "#{key}:#{event}"

  fetchAccount: (success=_.noop) ->
    @get('/account')
      .end (error, response) =>
        if response.ok
          @set 'account', response.body

class Client extends EventEmitter
  # Generate convenience methods that utilize our request wrapper.
  for method in ['get', 'post', 'put', 'patch', 'del']
    @::[method] = do (method) ->
      (url, rest...) -> @request(method, url, rest...)
  
  # Create a Client object and assign the passed options
  # to the instance.
  #
  constructor: (@options) ->
    # @on 'account:succeeded', @connectPush
    @on 'authorization:expired', @authorize


  sendMessage: (message, user) =>
    @post("/workspaces/#{user.room.workspace_id}/rooms/#{user.room.id}/chats")
      .send({text: string})
      .end()

  receiveMessage: (message) =>
    switch message.type
      when 'chats'
        switch message.action
          when 'add'
            @emit "TextMessage", message.payload
            
  connectPush: ->
    @get('/ping')
      .end (error, response) =>
        if response.ok
          token = response.body.push_token
          @pushClient = new Faye.Client PUSH_URL,
            timeout: 30
            retry: 15

          @pushClient.addExtension
            # Detect subscription failures that might happen on reconnects. Notify the
            # connection manager since there might be a stale session.
            incoming: (message, callback) =>
              if message.channel == '/meta/subscribe' && !message.successful
                # Do.connection.check()
                @emit 'message:failure'
              callback message

            # Attach token to subscription messages.
            outgoing: (message, callback) =>
              if message.channel == '/meta/subscribe'
                message.ext ||= {}
                message.ext.token = token
              callback message
          _.defer =>
            @pushClient.subscribe("/users/#{@account.id}", @receiveMessage)
            @emit 'push:connected'

  # Private: Make a JSON request to the API and optionally
  # set the `Authorization` header if it's available.
  #
  # method - a String representation of the HTTP method.
  # url    - the URL you'd like to reach
  #
  # Returns a Superagent Request
  request: (method, url) ->
    url = if url[0] is '/' then [API_URL,url].join('') else url
    r = request[method](url)
      .set('Accept', 'application/json')
      .type('json')
      .on('end', => @_onRequestCompletion(new request.Response(r.req, r.res)))
    r.set('Authorization', "Bearer #{@credentials.accessToken}") if @credentials?.valid()
    r

  _onRequestCompletion: (response) ->
    console.log "request:successful" if response.ok

  # Public: Authorize the API client, caching credentials on success
  # and emit events to indicate the authorization's success or failure.
  #
  # Returns a Superagent Request
  authorize: (success, failure) ->

    # If credentials already exist, then we're trying to
    # use a refresh token.
    currentGrantContext = if @credentials then {
        refresh_token   : @credentials.refresh_token
        grant_type      : REFRESH_GRANT_TYPE
    # If they don't we're using the password grant flow.
      } else {
        username        : @options.username
        password        : @options.password
        grant_type      : GRANT_TYPE
      }

    # Acquire a Bearer token from the API.
    @post(TOKEN_ENDPOINT)
      .send(_.extend({
        client_id       : @options.clientID
        client_secret   : @options.clientSecret
      }, currentGrantContext))
      .end((error, response) =>
        if error
          @emit 'authorization:failed'
        else
          event = if @credentials then 'refreshed' else 'succeeded'
          @credentials = new Credentials(response.body, this)
          @emit "authorization:#{event}"
      )

_.extend Client::, ClientActions

module.exports = Client
