login = require './login'
peoples = require './peoples'

credentials = require './creds.json'

login.sessionCookies(credentials.email, credentials.password)
.then (sessionCookies) ->
  fetchNextPeoples(sessionCookies)
.catch (err) ->
  console.log '->', err

fetchNextPeoples = (sessionCookies) ->
  peoples.fetch(sessionCookies)
  # .then (peoples) ->
  #   inviter.invite(sessionCookies, peoples).then(function () {
  #     setTimeout(function () {
  #       fetchNextPeoples(sessionCookies);
  #     }, constants.requestInterval);
  #   })
