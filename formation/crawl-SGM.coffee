# Lancement du parser tika
# java -jar tika-app-1.17.jar --text -s -p 1234
# TODO : fonction de liste de section
# Extraire la section parmis cette liste

Promise = require 'bluebird'
cheerio = require 'cheerio'
request = require('request-promise').defaults
  url: 'https://www.insa-lyon.fr/fr/formation/diplomes/ING'
_ = require 'lodash'
skilvioo = require './skilvioo/skilvioo'
refCompetences = require './refCompetences'
{spawn}  = require 'child_process'

DPTINSA = 'SGM'

extractRe = (re, src) ->
  return re.exec(src)[0].split(' : ')[1]

buildCaptureMiddle = (from, to) ->
  regle = new RegExp("#{from}([\\s\\S]*)#{to}", 'g')
  return regle

getCompetenceBruteSection = (pdf) ->
  mainSections = ["OBJECTIFS", "PROGRAMME", "BIBLIOGRAPHIE", "PRÉ-REQUIS", "\n\nmailto"]
  for section in mainSections
    rech = buildCaptureMiddle("OBJECTIFS RECHERCHÉS PAR CET ENSEIGNEMENT\n", section).exec(pdf)
    if rech?
      solution = rech[1].trim()
      solution = solution.replace(/mailto:[^\n]*\n/g, '')
      solution = solution.replace(/http:\/\/www\.insa-lyon\.fr[\s\S]*?Dernière modification le : [^\n]*\n/g, '')
      return solution.replace(/\n/g,' ')
  return null

getCompetenceSection = (matiere, start) ->
  compSections = [
    "Cet \.\*\? relève de \.\*\? et contribue aux : "
    "\[E\|3\]n \{0,2\}mobilisant les compétences\? suivantes\? :\{0,1\}"
    "\[E\|e\]n permettant à l'étudiant de travailler et d\['\|¿\]être évalué sur les connaissances \.\*\? :"
    "\[E\|e\]n permettant à l'étudiant de travailler et d'être évalué sur les capacités\{0,1\} suivantes :"
    ""
  ]
  startfound = false
  for section in compSections
    unless startfound
      if section is start && matiere.competencesBrutes.match(section)
        startfound = true
    else
      rech = buildCaptureMiddle(start, section).exec(matiere.competencesBrutes)
      if rech?
        return rech
  unless /^HU-|^EPS-|^HUMA-/.test(matiere.code)
    console.error "#{matiere.code} section \"#{start}\" introuvable."

extractPdfStructure = (pdf) ->
  # console.log '->', pdf
  # Suppression de l'addresse et du numéro de page sous toutes les pages
  pdf = pdf.replace(/mailto:[\s\S]*Dernière modification le : [^\n]+/g,'')
  matiere = {}
  # console.warn "-->", pdf
  # console.warn "Recherche mat"
  matiere.code = extractRe(/CODE : .*/, pdf)
  matiere.ects = extractRe(/ECTS : .*/, pdf)
  matiere.cours = extractRe(/Cours : .*/, pdf)
  matiere.td = extractRe(/TD : .*/, pdf)
  matiere.tp = extractRe(/TP : .*/, pdf)
  matiere.projet = extractRe(/Projet : .*/, pdf)
  matiere.perso = extractRe(/Travail personnel : .*/, pdf)
  try
    [..., avant, dernier, blanc, blanc] = buildCaptureMiddle("CONTACT\n","OBJECTIFS RECHERCHÉS PAR CET ENSEIGNEMENT").exec(pdf)[1].split('\n')
    matiere.nom = "#{avant} : #{dernier}"
    matiere.competencesBrutes = getCompetenceBruteSection(pdf)
    # console.log matiere.competencesBrutes
    # process.exit()

  catch error
    console.error("Warning matiere mal saisie #{matiere.code}")
    # console.error(error)
    return matiere

  # Compétences
  lcompetences = getCompetenceSection(matiere, "Cet \.\*\? relève de \.\*\? et contribue aux : ")
  # console.log(lcompetences[1])
  # process.exit()
  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].trim().split(/ (?=[ABC]\d+ )/).map (x) ->
        if /[ABC]\d+ /.test(x)
          # console.log "**#{x}**"
          try
            [, compet, tmp, niveau] = /([ABC]\d)( -? .*)\(Niveau ?(.*)\)/i.exec(x)
            # if niveau.endsWith(')') then niveau = niveau.substring(0, niveau.length()-1 )
            if compet.startsWith('C')
              compet = "#{DPTINSA}-#{compet}"

            comp = _.clone(refCompetences[compet])
            unless comp?
              throw Error("*#{x}* est inconnue, recherche sur #{compet}")
            comp.niveau = niveau
            comp
          catch error
            console.error("ERREUR : Impossible d'extraire Compétence ou niveau pour ----> #{x}")
            console.error("#{JSON.stringify matiere, null, 2}")
    catch error
      console.error(lcompetences)
      console.error(error)
      throw error
  if matiere.listeComp
    matiere.listeComp = matiere.listeComp.filter((x) -> x)

  # Competences mobilisées
  lcompetences = getCompetenceSection(matiere, "[E\|3\]n \{0,2\}mobilisant les compétences\? suivantes\? :\{0,1\}")
  if lcompetences?
    try
      matiere.listeCompMobilise = lcompetences[1].trim().match(/[ABC]\d+/g).map (x) ->
        # console.log "-#{x}-"
        if x.startsWith('C')
          x = "#{DPTINSA}-#{x}"
        comp = refCompetences[x.trim()]
        unless comp?
          throw Error("-#{x}- est inconnue")
        comp
    catch error
      console.error(lcompetences)
      console.error(error)
      throw error
  if matiere.listeCompMobilise
    matiere.listeCompMobilise = matiere.listeCompMobilise.filter((x) -> x)


  matiere.capacite = []
  matiere.connaissance = []
  matiere.competenceToCapaciteEtConnaissance = {}

  injectCapacitesConnaissances = (name, matiere, sectionStartName) ->
    lcapacites = getCompetenceSection(matiere, sectionStartName)

    if lcapacites?
      splitCapacites = lcapacites[1].trim().split(/ *- /)
      splitCapacites.map (capa) ->
        if capa isnt '' and capa.trim().length > 3 # Taille de la chaine à vérifier
          # capaDescription = ''
          # listComp = ''
          # try
          #   # [,capaDescription,listComp] = capa.match(/(.*) \((.*)\)/)
          # catch error
          #   capaDescription = capa

          capaDescription = capa # Hach for SGM
          if name is 'Capacité'
            capaDescription = "Capacité : #{capaDescription.trim()}"
            matiere.capacite.push(capaDescription)
          else
            capaDescription = "Connaissance : #{capaDescription.trim()}"
            matiere.connaissance.push(capaDescription)

          # lcomps = listComp.split(', ')
          # lcomps.map (comp) ->
          #   if _.isNumber(comp)
          #     unless matiere.competenceToCapaciteEtConnaissance[comp]? then matiere.competenceToCapaciteEtConnaissance[comp] = []
          #     matiere.competenceToCapaciteEtConnaissance[comp].push(capaDescription)

  injectCapacitesConnaissances("Connaissance", matiere, "\[E\|e\]n permettant à l'étudiant de travailler et d\['\|¿\]être évalué sur les connaissances \.\*\? :")
  injectCapacitesConnaissances("Capacité", matiere, "\[E\|e\]n permettant à l'étudiant de travailler et d'être évalué sur les capacités\{0,1\} suivantes :")

  # console.warn "-->", matiere
  matiere

# tika=spawn('java', ['-jar', 'tika-app-1.17.jar', '--text', '-s', '-p', '1234'])

catalogue = []
request()
.then (body) ->
  $ = cheerio.load(body)
  $('.diplome').each () ->
    departement = $(@).attr('id')
    if departement is DPTINSA
      semestres = []
      $('.contenu table tr td a', @).each () ->
        # if $(@).attr('href') is '/fr/formation/parcours/728/5/1'
          semestres.push
            url: $(@).attr('href')
            ecs: []
      catalogue.push
        'departement': departement
        'semestres': semestres

  # console.warn "#{JSON.stringify catalogue, null, 2}"
  Promise.each catalogue, (departement) ->
    Promise.each departement.semestres, (semestre) ->
      request
        url:'https://www.insa-lyon.fr'+semestre.url
        method: 'GET'
      .then (body) ->
        urls = []
        $ = cheerio.load(body)
        currentUE = null
        $('.contenu-onglet .detail-parcours-table tr').each () ->
          if $('.thlike', @).get().length is 1
            currentUE = /Unité d'enseignement : (.*)/.exec($('.thlike', @).get(0).children[0].data)[1]
          else if $('a', @).get().length is 1
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36222&_lang=fr'
              urls.push
                UE: currentUE
                url: $('a', @).attr('href')

        Promise.each urls, (url) ->
          console.warn '-->', url.url # A laisser pour la progession du code
          new Promise (resolve) ->
            res=''
            curl = spawn('curl', [url.url])
            tika = spawn('nc', ['localhost', 1234])
            curl.stdout.on 'data', (chunk) ->
              tika.stdin.write(chunk)
            curl.on 'close', (code) ->
              tika.stdin.end()
            tika.stdout.on 'data', (data) ->
              res += data
            tika.on 'close', (code) ->
              resolve(res)
          .then (pdf) ->
            semestre.ecs.push
              UE: url.UE
              url: url.url
              detail: extractPdfStructure(pdf)
.then () ->
  console.log "#{JSON.stringify catalogue, null, 2}"
  # skilvioo.insert(catalogue)

.then () ->
  # console.warn "#{JSON.stringify catalogue, null, 2}"
  console.warn "fin"
.catch (err) ->
  console.warn 'ERR', err
.finally () ->
  # spawn("sh", ["-c", "killall java"])
  console.warn "Fin"
