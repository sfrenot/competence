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

fetch = (sessionCookies, candidate) ->
  makeReqPYMKGET(sessionCookies, candidate.positions[0].linkedinid)
  .then (data) ->
    candidate.positions[0].description = normalizePositions.getCompanyDetails(data, candidate.positions[0].linkedinid)
    candidate

makeReqPYMKGET = (cookies, linkedInId) ->
  csrfToken = utils.trim(cookies.JSESSIONID, '"')

  query =
    q: 'universalName'
    universalName: linkedInId
    decorationId: 'com.linkedin.voyager.deco.organization.web.WebFullCompanyMain-12'

  headers = _extends {}, constants.headers.peopleYouMayKnowGET,
    cookie: utils.stringifyCookies(cookies)
    'csrf-token': csrfToken

  reqConfig =
    headers: headers
    params: query
    responseType: 'json'

  voyagerUrl = "https://www.linkedin.com/voyager/api/organization/companies"
  axios.get(voyagerUrl, reqConfig)
  .then (response) ->
    response.data

module.exports =
  fetch: fetch
