unless process.argv[2]?
  console.log "Lancement : coffee ./extractVol <fichierVol.json>"
  process.exit(0)

courses = require process.argv[2]

split = (vol) ->
  return vol.split('.0 h')[0]

pods = []

courses.forEach (departement) ->
  departement.semestres.forEach (semestre) ->
    semestre.ecs.forEach (ec) ->
      if not ec.detail.code.startsWith("HU")
        ec.code =  "#{ec.detail.code}"
        ec.annee = semestre.url.charAt(semestre.url.length-3)
        ec.semestre = semestre.url.slice(-1)
        ec.nom = ec.detail.nom
        ec.podcasts = []
        
        delete ec.detail
        delete ec.url
        delete ec.UE

        pods.push ec
      #console.log "#{ec.detail.code},#{split(ec.detail.cours)},\
        #{split(ec.detail.td)},#{split(ec.detail.tp)},\
        #{split(ec.detail.projet)}"
        #

console.log pods
