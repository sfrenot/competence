_extends = Object.assign || (target) ->
  arguments.forEach (source) ->
    for key in source
      if Object.prototype.hasOwnProperty.call(source, key)
        target[key] = source[key]
  target

querystring = require('querystring')
constants = require './constants'
utils = require './utils'

sessionCookies = (email, password) ->
  makeReqLoginGET()
  .then (cookies) ->
    makeReqLoginPOST(email, password, cookies)

makeReqLoginGET = () ->
  reqConfig =
    headers: _extends({}, constants.headers.loginGET)
    responseType: 'text'

  utils.fetchCookies(constants.urls.login, 'get', reqConfig)

makeReqLoginPOST = (email, password, cookies) ->
  csrfParam = utils.trim(cookies.bcookie, '"').split('&')[1]

  auth = querystring.stringify
    'session_key': email
    'session_password': password
    'isJsEnabled': 'false'
    'loginCsrfParam': csrfParam

  headers = _extends {}, constants.headers.loginSubmitPOST,
    cookie: utils.stringifyCookies(cookies)

  reqConfig =
    headers: headers
    maxRedirects: 0
    validateStatus: validateStatusForURLRedirection
    data: auth
    responseType: 'text'

  utils.fetchCookies(constants.urls.loginSubmit, 'post', reqConfig)
    .then (cookieUpdates) ->
      _extends {}, cookies, cookieUpdates

validateStatusForURLRedirection = (status) ->
  status >= 200 && (status < 300 || status is 302)

module.exports =
  sessionCookies: sessionCookies
