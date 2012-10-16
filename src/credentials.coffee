class Credentials
  constructor: (r, @client) ->
    expiresInMs = (r['expires_in'] - 10) * 1000
    [@accessToken, @refreshToken, @expiresAt] = [r['access_token'], r['refresh_token'], Date.now() + expiresInMs]
    @timeout = setTimeout =>
      @client.emit 'authorization:expired'
    , expiresInMs

  expired: -> !@valid()
  valid: ->
    Date.now() < @expiresAt

module.exports = Credentials

