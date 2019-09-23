import { Component, OnInit, Input } from '@angular/core';
import { Matiere } from '../matiere'

@Component({
  selector: 'app-eval-matiere',
  templateUrl: './eval-matiere.component.html',
  styleUrls: ['./eval-matiere.component.css']
})
export class EvalMatiereComponent implements OnInit {
  @Input() evalMatiere: Matiere;

  constructor() { }

  ngOnInit() {
    // console.log(this.evalMatiere);
  }
}
