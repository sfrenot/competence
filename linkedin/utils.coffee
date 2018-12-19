axios = require 'axios'
# var wordWrap = require('word-wrap');
# var moment = require('moment');
#
_extends = Object.assign || (target) ->
  arguments.forEach (source) ->
    for key in source
      if Object.prototype.hasOwnProperty.call(source, key)
        target[key] = source[key]
  target

fetchCookies = (url, method, config) ->
  reqConfig = _extends({ url: url, method: method }, config)
  axios.request(reqConfig)
  .then (response) ->
    parseToCookieKeyValuePairs(response.headers['set-cookie'])

parseToCookieKeyValuePairs = (cookieHeaders) ->
  cookieHeaders.reduce (keyValuePairs, cookie) ->
    cookieInfo = parseSingleCookie(cookie)
    if not isDeletedCookie(cookieInfo)
      keyValuePairs[cookieInfo.key] = cookieInfo.value
    return keyValuePairs
  ,
    {}

isDeletedCookie = (cookieInfo) ->
  cookieInfo.value.indexOf('delete') isnt -1

parseSingleCookie = (cookieStr) ->
  cookieInfo = {}
  parts = cookieStr.split(/; */)

  pair = parts[0].trim()
  eqIdx = pair.indexOf('=')
  cookieInfo.key = pair.substr(0, eqIdx).trim()
  cookieInfo.value = pair.substr(eqIdx + 1, pair.length).trim()

  parts.forEach (part) ->
    partPair = part.trim().split('=')
    if partPair.length is 2
      cookieInfo[partPair[0].trim()] = partPair[1].trim()

  cookieInfo

stringifyCookies = (cookiePairs) ->
  Object.keys(cookiePairs).map (cookieName) ->
    cookieName + '=' + cookiePairs[cookieName]
  .join('; ')

trim = (str, chr) ->
  regex = new RegExp('(?:^' + escapeRegExp(chr) + '+)|(?:' + escapeRegExp(chr) + '+$)', 'g')
  str.replace(regex, '')

escapeRegExp = (str) ->
  str.replace(/[-[\]/{}()*+?.\\^$|]/g, '\\$&')

#
# var currentPrintStream = process.stderr;
#
# function print(msg) {
#   if (global.verbose) {
#     currentPrintStream.write(msg);
#   }
# }
#
# function resolveNewLines(text) {
#   text = text || '';
#   return text.replace(/[\n\r]+/g, ' ').trim();
# }
#
# function wrapText(text, option) {
#   option = _extends({
#     trim: false
#   }, option);
#
#   return wordWrap(text, option);
# }
#
# function startTimer() {
#   global.startMoment = moment();
# }
#
# function endTimer() {
#   return moment().diff(global.startMoment, 'second', true) + 'sec';
# }
#
module.exports =
  fetchCookies: fetchCookies
#   parseToCookieKeyValuePairs: parseToCookieKeyValuePairs,
  stringifyCookies: stringifyCookies
  trim: trim
#   print: print,
#   resolveNewLines: resolveNewLines,
#   wrapText: wrapText,
#   currentPrintStream: currentPrintStream,
#   startTimer: startTimer,
#   endTimer: endTimer
# }
