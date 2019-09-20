import { Component, OnInit, Input } from '@angular/core';
import { Matiere } from '../matiere'

@Component({
  selector: 'app-eval-matiere',
  templateUrl: './eval-matiere.component.html',
  styleUrls: ['./eval-matiere.component.css']
})
export class EvalMatiereComponent implements OnInit {
  @Input() evalMatiere: Matiere;
  capacites = {}
  connaissances = {}

  constructor() { }

  ngOnInit() {
    console.log(this.evalMatiere);

    this.evalMatiere.listeComp.forEach( (comp) => {
      let code = '';
      if (comp.code.startsWith('C')) {
        code = 'TC-' + comp.code;
      }
      let connEtCapa = this.evalMatiere.competenceToCapaciteEtConnaissance.filter((comp) => { return comp.code === code })
      if (connEtCapa.length > 0) {
        this.capacites[comp.code] = connEtCapa[0].capacites
        this.connaissances[comp.code] = connEtCapa[0].connaissances
      }
    })
  }
  getCapacites(code) { return this.capacites[code]; }
  getConnaissances(code) { return this.connaissances[code]; }
}
