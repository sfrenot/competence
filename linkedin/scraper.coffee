login = require './login'
peoples = require './peoples'
credentials = require './creds.json'

loadAndShuffle = require './loadAndShuffle'

candidate = loadAndShuffle.getNextCandidate()

login.sessionCookies(credentials.email, credentials.password)
.then (sessionCookies) ->
  fetchNextPeoples(sessionCookies)
.catch (err) ->
  console.log '->', err

fetchNextPeoples = (sessionCookies) ->
  peoples.fetch(sessionCookies, candidate)
  .then (data) ->
    loadAndShuffle.storeCandidate(data)
    loadAndShuffle.print(data)

  # .then (peoples) ->
  #   inviter.invite(sessionCookies, peoples).then(function () {
  #     setTimeout(function () {
  #       fetchNextPeoples(sessionCookies);
  #     }, constants.requestInterval);
  #   })
