XLSX = require('xlsx')
fs = require('fs')

workbook = XLSX.readFile('./sources/gi.xlsm')

for sheetName in workbook.SheetNames
  fs.writeFileSync("sources/#{sheetName}.csv", XLSX.utils.sheet_to_csv(workbook.Sheets[sheetName]))
