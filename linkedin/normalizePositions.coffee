_ = require 'lodash'

normalizePositions = (description) ->

  positions = _.filter description.included,
    $type: 'com.linkedin.voyager.identity.profile.Position'

  jobs = []
  positions.forEach (position) ->

    getCompanyDetail = () ->
      if position.companyUrn
        compName = _.find description.included,
          "$type": "com.linkedin.voyager.entities.shared.MiniCompany"
          "entityUrn": position.companyUrn

        compSize = _.find description.included,
            "$type": "com.linkedin.voyager.identity.profile.EmployeeCountRange"
            "$id": "#{key},company,employeeCountRange"

        "#{compName.name} (#{compSize.start} - #{compSize.end})"
      else
        "#{position.companyName}"

    getDates = () ->
      dateRange = _.find description.included,
        "$type": "com.linkedin.voyager.common.DateRange"
        "$id": "#{key},timePeriod"

      debut = _.find description.included,
        "$type": "com.linkedin.common.Date"
        "$id": "#{key},timePeriod,startDate"
      if debut
        if debut.month
          debutDate = "#{debut.year}#{String(debut.month).padStart(2, 0)}"
        else
          debutDate = "#{debut.year}00"

      if dateRange?.endDate
        end = _.find description.included,
          "$type": "com.linkedin.common.Date"
          "$id": "#{key},timePeriod,endDate"
        if end
          if end.month
            findDate = "#{end.year}#{String(end.month).padStart(2, 0)}"
          else
            findDate = "#{end.year}00"

      return [debutDate, findDate]

    key = position.entityUrn #urn:li:fs_position:(ACoAAAVhWNkBRxxrfHTQx5Czo-n-qB22I1D5O0I,219254659)

    details =
      entreprise: getCompanyDetail()
      location: position.locationName
      titre: position.title
      dates: getDates()

    if position.companyUrn
      details.linkedinid = position.companyUrn.split(':').pop()

    jobs.push(details)


  (_.sortBy jobs, (job) -> job.dates[0]).reverse()

getCompanyDetails = (description, id) ->
  company = _.find description.included,
    url: "https://www.linkedin.com/company/#{id}"
  creation = _.find description.included,
    $id: "urn:li:fs_normalized_company:#{id},foundedOn"

  res = {}
  res.specialities = company.specialities
  if creation
    res.creeele = creation.year

  return res

module.exports =
  normalize: normalizePositions
  getCompanyDetails: getCompanyDetails

unless module.parent
  # val = require('./test-julienlacroix')
  # console.log(JSON.stringify normalizePositions(val), null, 2)
  val = require('./valoris.raw.json')
  console.log(JSON.stringify getCompanyDetails(val, 25403), null, 2)
