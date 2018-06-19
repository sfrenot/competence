request = require 'request-promise'
Promise = require 'bluebird'
_ = require 'lodash'

headers = {
  'Accept': 'application/json'
  'Authorization':'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjFkMWEzMmJlLTM1ZDAtNGRmNy1iYzFhLTY0ZDNjYmU0Mjg5OSIsImZpcnN0bmFtZSI6IkJlbmphbWluIiwibGFzdG5hbWUiOiJSb3VsbGV0IiwiZW1haWwiOiJiZW5qYW1pbi5yb3VsbGV0QHNraWx2aW9vLm5ldCIsInBob25lIjoiMDY5NTU1MzcwMSIsInRvQmVDcmVhdGVkIjpudWxsLCJyb2xlIjpudWxsLCJyZWFsbSI6InNraWx2aW9vLWZvcm1hdGlvbi1mcm9udGVuZCIsImN1cnJlbnRPcmdhbmlzYXRpb24iOnsiYWRkcmVzcyI6IjIwIEF2ZW51ZSBBbGJlcnQgRWluc3RlaW4sIDY5MTAwIFZpbGxldXJiYW5uZSIsInRyYWluaW5nTnVtYmVyIjoiNSIsIm5hbWUiOiJJTlNBIEx5b24iLCJpZCI6Ijk4NmRjZjNiLTMyMWUtNDVmYi1hZjJlLTQxZWVlMDM5NWQxMyIsInR5cGUiOiJvcmdhbmlzYXRpb24udHlwZXMuZW5naW5lZXJpbmdfc2Nob29sIiwicm9sZSI6IkFETUlOX09SR0EifSwiaWF0IjoxNTIzNjAzNDIwfQ.ZBY1EJYIt50khcx3Tg5heCEIxmrZEGVTSKvbT6caMKo'
}

UEs = {}
departements = {
  'TC': 'c0c6ce75-2214-47c6-aed3-b6b80e53ad2a'
  'GCU': '4d3a7e42-c251-4211-a760-03454977893f'
}

randomColor = () ->
  Math.floor(Math.random()*1000000000).toString(16)[0...6]

insertDepartement = (name) ->
  console.log 'ajout dans departement', name
  # request
  #   url:'https://skilvioo-training.herokuapp.com/trainings'
  #   method: 'POST'
  #   headers: headers
  #   form:
  #     'idOrganisation':'986dcf3b-321e-45fb-af2e-41eee0395d13'
  #     'trainingName': "INSA Lyon #{name}"
  #     'trainingType': 'training.training_types.5'
  #     'userId': '1d1a32be-35d0-4df7-bc1a-64d3cbe42899'
  #     'isContinue': false
  #     'isInitial': true
  #     'trainingVae': true
  Promise.resolve("{\"id\": \"#{departements[name]}\"}")


insertUE = (departement_id, UE_name) ->
  ue_id = UEs[UE_name]
  unless ue_id?
    console.log "Ajout UE #{UE_name}"
    request
      url: "https://skilvioo-training.herokuapp.com/trainings/#{departement_id}/blocks"
      method: 'POST'
      headers: headers
      form:
        "name": UE_name
        "color": '#FF0000'
    .then (res) ->
      ue_id = JSON.parse(res).id
      UEs[UE_name]=ue_id
      Promise.resolve(ue_id)
  else
    console.log "Insert dans #{UE_name}"
    Promise.resolve(ue_id)

insertEC = (UE_id, ec) ->
  request
    url: "https://skilvioo-training.herokuapp.com/blocks/#{UE_id}/blocks"
    method: 'POST'
    headers: headers
    form:
      "name": "#{ec.detail.nom}(#{ec.detail.code})"
      "color": '#FFFF00'

insertCompetencesAsTag = (departementId, ec) ->
  Promise.map ec.detail.listeComp, (comp) ->
    request
      url: "https://skilvioo-training.herokuapp.com/trainings/#{departementId}/tags"
      method: 'POST'
      headers: headers
      form:
        "label": "#{comp.code} - #{comp.val}"
        "color": "##{randomColor()}"
    .then (res) ->
      JSON.parse(res)[0]
    .then (data) ->
      data.code = comp.code
      data
  .then (res) ->
    res.reduce (acc, val) ->
      acc[val.code] = val.id
      acc
    , {}

insertResource = (departementId, ecId, type) ->
  Promise.map type, (comp) ->
    request
      url: "https://skilvioo-training.herokuapp.com/trainings/#{departementId}/resources"
      method: 'POST'
      headers: headers
      form:
        "name": "#{comp}"
    .then (res) ->
      JSON.parse(res)[0]
    .then (ressource) ->
      request
        url: "https://skilvioo-training.herokuapp.com/blocks/#{ecId}/resources/#{ressource.id}"
        method: 'POST'
        headers: headers
      .then () ->
        ressource
  , concurrency: 1
  .then (res) ->
    res.reduce (acc, val) ->
      acc[val.name] = val.id
      acc
    , {}

linkResourceToTags = (links, mapTags, resources) ->
  Promise.all _.map links, (elems, tag) ->
    Promise.map elems, (elem) ->
      console.log "-> #{tag}: #{mapTags[tag]} --> #{elem} : #{resources[elem]}"
      request
        url: "https://skilvioo-training.herokuapp.com/tags/#{mapTags[tag]}/resources/#{resources[elem]}"
        method: 'POST'
        headers: headers

module.exports.insert = (catalogue) ->
  console.log "insertion Skilvioo"
  Promise.map catalogue, (departement) ->
    insertDepartement(departement.departement)
    .then (res) ->
      departement.id = JSON.parse(res).id
      Promise.map departement.semestres, (semestre) ->
        console.log "Ajout semestre", semestre.url
        Promise.each semestre.ecs, (ec) ->
          insertUE(departement.id, ec.UE)
          .then (UE) ->
            insertEC(UE, ec)
            .then (res) ->
              ec.id = JSON.parse(res).id
              insertCompetencesAsTag(departement.id, ec)
              .then (mapTags) ->
                console.log '->', mapTags
                Promise.all [
                  insertResource(departement.id, ec.id, ec.detail.capacite)
                  insertResource(departement.id, ec.id, ec.detail.connaissance)
                ]
                .then (res) ->
                  linkResourceToTags(ec.detail.competenceToCapaciteEtConnaissance, mapTags, _.assignIn(res[0], res[1]))
