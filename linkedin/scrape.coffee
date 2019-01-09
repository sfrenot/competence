login = require './login'
peoples = require './peoples'
company = require './company'
credentials = require './creds.json'

loadAndShuffle = require './loadAndShuffle'

candidate = loadAndShuffle.getNextCandidate()
console.error(JSON.stringify candidate, null, 2)

# Testing
# candidate =
#   "id": "jean-baptiste-blondel-5539481"
# process.exit()

login.sessionCookies(credentials.email, credentials.password)
.then (sessionCookies) ->
  fetchNextPeoples(sessionCookies)
.catch (err) ->
  console.log '->', err

fetchNextPeoples = (sessionCookies) ->
  targetFunction = if candidate.positions?[0] then company else peoples
  targetFunction.fetch(sessionCookies, candidate)
  .then (data) ->
    loadAndShuffle.storeCandidate(data)
    loadAndShuffle.print(data)

  # .then (peoples) ->
  #   inviter.invite(sessionCookies, peoples).then(function () {
  #     setTimeout(function () {
  #       fetchNextPeoples(sessionCookies);
  #     }, constants.requestInterval);
  #   })
