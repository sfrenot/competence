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
      if debut.month
        debutDate = "#{debut.year}#{String(debut.month).padStart(2, 0)}"
      else
        debutDate = "#{debut.year}00"

      if dateRange.endDate
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

    jobs.push
      entreprise: getCompanyDetail()
      location: position.locationName
      titre: position.title
      dates: getDates()

  (_.sortBy jobs, (job) -> job.dates[0]).reverse()

module.exports =
  normalize: normalizePositions
