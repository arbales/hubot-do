_       =  require 'underscore'
ENV     =  process.env

# Hubot
{Adapter, TextMessage,EnterMessage,LeaveMessage} = require 'hubot'

# Load the Do API Client
Client                                           = require './client'
{PushManager, AccountManager, HubotResponder}    = require './roles'

class DoAdapter extends Adapter

  # Public: Raw method for sending data back to the chat source. Extend this.
  #
  # user    - A User instance.
  # strings - One or more Strings for each message to send.
  #
  # Returns nothing.
  send: (user, strings...) ->
    for string in string
      @client.send string, user

  # Public: Raw method for building a reply and sending it back to the chat
  # source. Extend this.
  #
  # user    - A User instance.
  # strings - One or more Strings for each reply to send.
  #
  # Returns nothing.
  reply: @send

  # Public: Raw method for setting a topic on the chat source. Extend this.
  #
  # user    - A User instance.
  # strings - One more more Strings to set as the topic.
  #
  # Returns nothing.
  topic: @send

  # Public: Raw method for invoking the bot to run. Extend this.
  #
  # Returns nothing.
  run: ->
    client = new Client
      clientID      :  ENV.HUBOT_DO_CLIENT_ID
      clientSecret  :  ENV.HUBOT_DO_CLIENT_SECRET

    client.on 'authorization:succeess', ->
      console.log "Authentication succeeded."
      client.fetchAccount()

    client.on 'request:complete', ->
      console.log "Request Completed."

    client.on 'account:create', ->
      console.log "Account fetched."
      client.connectPush()

    client.on 'push:connect', ->
      console.log "Push Connected"
      @emit 'connected'

    client.on 'TextMessage', (message) =>
      console.log message
      unless @robot.name == message.creator.name
        @receive new TextMessage(@userForMessage(message), message.text)

    client.authenticate
      username      :  ENV.HUBOT_DO_USERNAME
      password      :  ENV.HUBOT_DO_PASSWORD


    @

  userForMessage: (message) ->
    author = @userForName message.creator.name
    room = message.room
    unless author?
      author = @userForId message.creator.id
      author.name = message.creator.name
      author.email = message.creator.email
    author.room = {id: room.id, name: room.name, workspace_id: room.workspace_id}
    author

exports.use = (robot) ->
  new DoAdapter robot
