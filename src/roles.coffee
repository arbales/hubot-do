_         = require 'underscore'
Faye      = require 'faye'
ENV       = process.env
PUSH_URL  = ENV.HUBOT_DO_PUSH_URL || "https://push.do.com"

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
                @emit 'message:fail'
              callback message

            # Attach token to subscription messages.
            outgoing: (message, callback) =>
              if message.channel == '/meta/subscribe'
                message.ext ||= {}
                message.ext.token = token
              callback message
          _.defer =>
            @pushClient.subscribe("/users/#{@account.id}", @receiveMessage, this)
            @emit 'push:connect'

exports.PushManager = PushManager
exports.HubotResponder = HubotResponder
exports.AccountManager = AccountManager
