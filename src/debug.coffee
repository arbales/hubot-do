# 0 = Errors
# 1 = Success
# 2 = Events
# 3 = Information
#
ENV = process.env

exports.debug = debug = (message, level=2) ->
  if ENV.HUBOT_DO_DEBUG is 'true' and level <= parseInt(ENV.HUBOT_DO_DEBUG_VERBOSITY||2)
    console.log message

exports.info = (message) -> debug(message, 3)
