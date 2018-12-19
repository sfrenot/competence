request = require('request')
Linkedin = require('node-Linkedin')('789m0osszt86gq', 'z5BmOdHkMJ5yQi02')
linkedin = Linkedin.init('AIEDANKJAKAOHA')

# authorizeUrl = Linkedin.auth.authorize()
# request.get authorizeUrl, (err, res, body) ->
#   console.log(err)
#   console.log '->', body
#   process.exit()


linkedin.people.me (err, $in) ->
  console.log 'errer', err
  console.log 'in', $in
