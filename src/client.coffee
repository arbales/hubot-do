_              = require 'underscore'
_.mixin require('underscore.string').exports()
ENV            = process.env
{EventEmitter} = require 'events'
Request        = require 'superagent'
Credentials    = require './credentials'

_.noop = ->

CONVENIENCE_METHODS = ['get', 'post', 'put', 'patch', 'del']

class Client extends EventEmitter
  root: ENV.HUBOT_DO_ROOT || 'https://www.do.com'
  json: yes
  tokenPath: '/oauth2/token'
  authorizationPath: '/oauth2/authorize'

  # Stub method for you to use.
  initialize: (->)


  # Returns a new child client that can be customized in place
  # but that uses the master client's networking and authentication.
  #
  #     client = new Client(...)
  #     client.authorize()
  #
  #     client.on 'authorization:success'
  #       accountClient = _.extend client.child(), Roles.AccountManager
  #       accountClient.all (accountData) ->
  #         console.log accountData
  #
  #       push = _.extend client.child(), Roles.PushManager
  #       push.connect {pushToken: ...}
  #
  #
  child: (child = yes) ->
    c = new Client(@options)

    if child
      c._isChild = yes
      c.request = @request
      for method in CONVENIENCE_METHODS
        c[method] = @[method]
    c

  # Create a Client object and assign the passed options
  # to the instance.
  #
  constructor: (@options) ->  
    _.bindAll @, 'request', 'child', 'authenticate'
    _.bindAll @, CONVENIENCE_METHODS...

    for key in ['root','json','tokenPath','authorizationPath']
      @[key] = @options[key] if @options[key]

    unless @root
      throw new Error('You must set a root property on your client.')
    @initialize(arguments...)

  # Public: Triggers events on updating or creating properties on the client. 
  #
  # Returns the `value`
  set: (key, value) ->
    event = if @[key] then "update" else "create"
    @[key] = value
    @emit "#{key}:#{event}"
    value

  # Private: Make a JSON request to the API and optionally
  # set the `Authorization` header if it's available.
  #
  # method - a String representation of the HTTP method.
  # url    - the URL you'd like to reach
  #
  # Returns a Superagent Request
  request: (method, url, options={}) ->
    throw "Cannot call #request on child clients." if @_isChild
    _.defaults options,
      useCredentials: yes
      prefix: ''

    options.prefix += if _.isNumber(w = options.workspace)
      "/workspaces/#{w}"
    else if _.isObject(w=options.workspace)
      "/workspaces/#{w.id}"
    else
      ""

    # Add a prefix to your URL if it's relative.
    url = [options.prefix, url].join('') if url[0] is '/'

    # If the URL is root-relative, which it usually should be, then
    # join the API Root against it.
    #
    url = if url[0] is '/' then [@root, url].join('') else url

    # Create a request and set the appropriate headers for calling the Do
    # Open API. Conditionally sets the `Authorization` as well.
    #
    r = Request[method](url)
      .on('end', => @_onRequestCompletion(new Request.Response(r.req, r.res), r))

    (r.on 'success', -> options.success(response)) if options.success

    (r.on 'fail', -> options.failure(response)) if options.failure

    # If you're making requests against a JSON API, set the accept header.
    if @type is 'json'
      r.set('Accept', 'application/json').type('json')

    r.set('Authorization', "Bearer #{@credentials.accessToken}") if @credentials?.valid() and options.useCredentials

    # If credentials exist, are expired, and this request requires credentials,
    # then re-authorize the client with a refresh token and wrap the call to `end`
    # so that it waits for a successful reauthorization.
    #
    if options.useCredentials and @credentials?.expired()
      # Reauthorize the client.
      @authenticate(credentials, {useCredentials: no}) ->
        # Reset the acessToken on the request an trigger the appropriate event.
        r.set('Authorization', "Bearer #{credentials.accessToken}") if credentials.valid() and options.useCredentials
        r.emit('authorization:set')

      r.end = ->
        # If `#end` is called on the request after the token fetch completes, 
        # proceed normally.
        if r.get('Authorization')
          r::end(arguments...)

        # Otherwise, have this request wait until reauthorization.
        else
          r.on 'authorization:set', ->
            r::end(arguments...)

    r # the Superagent request

  # Generate convenience methods that utilize our request wrapper. 
  #
  for method in CONVENIENCE_METHODS
    @::[method] = do (method) ->
      (url, rest...) -> @request(method, url, rest...)

  # Private: Dispatches events to inform interested objects about the status of
  # a particular request.
  #
  # Returns nothing
  _onRequestCompletion: (response, request) ->
    @emit 'request:complete', arguments...
    request.emit("success", arguments...) if response.ok
    request.emit("fail", arguments...) if response.error

  # Public: Authenticate the API client, caching credentials on success
  # and emit events to indicate the authorization's success or failure.
  #
  # Returns a Superagent Request
  authenticate: (options, success=_.noop, failure=_.noop) ->
    throw "Cannot call #authenticate on child clients." if @_isChild
    _.defaults options,
      username: ''
      password: ''
      code: ''
      grantType: if @credentials then 'refresh_token' else 'password'

    # Choose the appropriate credentials for a given 
    # grant type.
    #
    credentials = switch options.grantType

      when 'refresh_token'
        refresh_token   : @credentials.refreshToken
        grant_type      : 'refresh_token'
      when 'password'
        username        : options.username
        password        : options.password
        grant_type      : options.grantType
      when 'authorization_code'
        code            : options.code
        grant_type      : options.grantType

      # Throw an error when an unimplemented grant type is used.
      else (throw new Error "Unsupported grant type: #{options.grantType}.")

    # Acquire a Bearer token from the provider.
    # Set `usesCredentials` to `no` so that the Authorizaton header is
    # not send for this request, and no attempt to refresh will be made.
    #
    @post(@tokenPath, usesCredentials: no)
      .send(_.extend
        client_id       : @options.clientID
        client_secret   : @options.clientSecret
        , credentials)
      .end (error, response) =>
        if error
          @emit 'authorization:fail'
        else
          success @credentials
          event = if @credentials then 'refresh' else 'success'
          @credentials = new Credentials response.body, this

          @emit "authorization:#{event}"
          @on 'authorization:expire', @authenticate



module.exports = Client
