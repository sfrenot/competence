csv = require 'csvtojson'
students = []

readCsv = ->
  new Promise (resolve, reject) ->
    datas = []

    csv({flatKeys: true, delimiter: ",", noheader: true})
    .fromFile('./etudiants.csv')
    .on 'json', (data) ->
      datas.push data
    .on 'done', (error) ->
      if error
        return reject error
      resolve(datas)

readCsv()
.then (datas) ->
  datas.forEach (data) ->
    students.push
      "nom": data.field3
      "prenom": data.field4
      "id": data.field20


  console.log JSON.stringify students, null, 2
  # console.error 'Terminé'
