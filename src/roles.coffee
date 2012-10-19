_                 = require 'underscore'
Faye              = require 'faye'
ENV               = process.env
PUSH_URL          = ENV.HUBOT_DO_PUSH_URL || "https://push.do.com"
PRESENCE_INTERVAL = 4 * 60 * 1000
{debug, info}     = require './debug'

_.noop = ->

AccountManager =
  fetchAccount: (success=_.noop) ->
    @get('/account')
      .end (error, response) =>
        if response.ok
          @set 'account', response.body

HubotResponder = 
  sendMessage: (message, user) ->
    @post("/workspaces/#{user.room.workspace_id}/rooms/#{user.room.id}/chats")
      .send({text: message})
      .end()

  receiveMessage: (message) ->
    switch message.type
      when 'chats'
        switch message.action
          when 'add'
            @emit "TextMessage", message.payload

PushManager =
  _updatePresence: ->
    debug 'Maintaining presence...'
    @post('/presence').end()

  maintainPresence: ->
    @_presence = setInterval =>
      @_updatePresence()
    , PRESENCE_INTERVAL
    @_updatePresence()

  connectPush: ->
    @get('/ping')
      .end (error, response) =>
        if response.ok
          token = response.body.push_token
          @pushClient = new Faye.Client PUSH_URL,
            timeout: 30
            retry: 15

          @pushClient.disable('websocket') if ENV.HUBOT_DO_DISABLE_WEBSOCKETS is 'true'

          @pushClient.bind 'transport:up', ->
            debug 'transport:up'

          @pushClient.bind 'transport:down', ->
            debug 'transport:down'

          @pushClient.addExtension
            # Detect subscription failures that might happen on reconnects. Notify the
            # connection manager since there might be a stale session.
            incoming: (message, callback) =>
              info message
              if message.channel == '/meta/subscribe' && !message.successful
                @emit 'message:fail'
              callback message

            # Attach token to subscription messages.
            outgoing: (message, callback) =>
              if message.channel == '/meta/subscribe'
                message.ext ||= {}
                message.ext.token = token
              info message
              callback message
          _.defer =>
            @pushClient.subscribe("/users/#{@account.id}", @receiveMessage, this)
            @maintainPresence()
            @emit 'push:connect'

exports.PushManager = PushManager
exports.HubotResponder = HubotResponder
exports.AccountManager = AccountManager
