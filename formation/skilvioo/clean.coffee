Promise = require 'bluebird'
request = require('request-promise')

headers =
  'Accept': 'application/json'
  'Authorization':'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjFkMWEzMmJ
  lLTM1ZDAtNGRmNy1iYzFhLTY0ZDNjYmU0Mjg5OSIsImZpcnN0bmFtZSI6IkJlbmphbWluIiwi
  bGFzdG5hbWUiOiJSb3VsbGV0IiwiZW1haWwiOiJiZW5qYW1pbi5yb3VsbGV0QHNraWx2aW9vL
  m5ldCIsInBob25lIjoiMDY5NTU1MzcwMSIsInRvQmVDcmVhdGVkIjpudWxsLCJyb2xlIjpudW
  xsLCJyZWFsbSI6InNraWx2aW9vLWZvcm1hdGlvbi1mcm9udGVuZCIsImN1cnJlbnRPcmdhbml
  zYXRpb24iOnsiYWRkcmVzcyI6IjIwIEF2ZW51ZSBBbGJlcnQgRWluc3RlaW4sIDY5MTAwIFZp
  bGxldXJiYW5uZSIsInRyYWluaW5nTnVtYmVyIjoiNSIsIm5hbWUiOiJJTlNBIEx5b24iLCJpZ
  CI6Ijk4NmRjZjNiLTMyMWUtNDVmYi1hZjJlLTQxZWVlMDM5NWQxMyIsInR5cGUiOiJvcmdhbm
  lzYXRpb24udHlwZXMuZW5naW5lZXJpbmdfc2Nob29sIiwicm9sZSI6IkFETUlOX09SR0EifSw
  iaWF0IjoxNTIzNjAzNDIwfQ.ZBY1EJYIt50khcx3Tg5heCEIxmrZEGVTSKvbT6caMKo'

rootPath='https://skilvioo-training.herokuapp.com'

request
  url:"#{rootPath}/trainings"
  method: 'GET'
  headers: headers
.then (dpts) ->
  Promise.each JSON.parse(dpts), (departement) ->
    request
      url:"#{rootPath}/trainings/#{departement.id}/tags"
      method: 'GET'
      headers: headers
    .then (res) ->
      unless res then return
      console.log "-->", JSON.stringify(res)
      tags = JSON.parse(res)
      Promise.each tags, (tag) ->
        console.log "-->", tag.id
        request
          url:"#{rootPath}/tags/#{tag.id}"
          method: 'DELETE'
          headers: headers
    .then () ->
      request
        url:"#{rootPath}/trainings/#{departement.id}/resources"
        method: 'GET'
        headers: headers
      .then (res) ->
        unless res then return
        console.log "-->", JSON.stringify(res)
        tags = JSON.parse(res)
        Promise.each tags, (tag) ->
          console.log "-->", tag.id
          request
            url:"#{rootPath}/resources/#{tag.id}"
            method: 'DELETE'
            headers: headers
    .then () ->
      request
        url:"#{rootPath}/trainings/#{departement.id}/blocks"
        method: 'GET'
        headers: headers
      .then (res) ->
        ues = JSON.parse(res)
        Promise.map ues, (ue) ->
          request
            url:"#{rootPath}/blocks/#{ue.id}/blocks"
            method: 'GET'
            headers: headers
          .then (res) ->
            ecs = JSON.parse(res)
            Promise.each ecs, (ec) ->
              request
                url:"#{rootPath}/blocks/#{ec.id}/blocks"
                method: 'GET'
                headers: headers
              .then (res) ->
                comps = JSON.parse(res)
                Promise.map comps, (comp) ->
                  console.log "Suppression competence", comp
                  request
                    url:"#{rootPath}/blocks/#{comp.id}"
                    method: 'DELETE'
                    headers: headers
              console.log "Suppression ec", ec
              request
                url:"#{rootPath}/blocks/#{ec.id}"
                method: 'DELETE'
                headers: headers
            .then () ->
              console.log "Suppression ue", ue
              request
                url:"#{rootPath}/blocks/#{ue.id}"
                method: 'DELETE'
                headers: headers
        .then () ->
          console.log "Suppression departement non réalisée", departement.id
          # request
          #   url:"#{rootPath}/trainings/#{departement.id}"
          #   method: 'DELETE'
          #   headers: headers
.then (res) ->
  console.log "Fini", res
.catch (err) ->
  console.log "Erreur", err
