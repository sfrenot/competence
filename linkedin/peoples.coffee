_extends = Object.assign || (target) ->
  arguments.forEach (source) ->
    for key in source
      if Object.prototype.hasOwnProperty.call(source, key)
        target[key] = source[key]
  target

axios = require 'axios'
utils = require './utils'
constants = require './constants'
normalizePositions = require './normalizePositions'

fetch = (sessionCookies) ->
  makeReqPYMKGET(sessionCookies)
  .then (data) ->
    console.log(normalizePositions.normalize(data))

makeReqPYMKGET = (cookies) ->
  csrfToken = utils.trim(cookies.JSESSIONID, '"')

  query =
    includeInsights: false
    start: 0
    usageContext: 'd_flagship3_people'

  headers = _extends {}, constants.headers.peopleYouMayKnowGET,
    cookie: utils.stringifyCookies(cookies)
    'csrf-token': csrfToken

  reqConfig =
    headers: headers
    params: query
    responseType: 'json'

  axios.get(constants.urls.getPeople, reqConfig)
  .then (response) ->
    response.data

module.exports =
  fetch: fetch
