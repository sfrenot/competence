import { Component, OnInit } from '@angular/core';
import { Matiere } from '../matiere';
import { MatiereService } from '../matiere.service';

@Component({
  selector: 'app-matieres',
  templateUrl: './matieres.component.html',
  styleUrls: ['./matieres.component.css']
})

export class MatieresComponent implements OnInit {

  matieres: Matiere[];
  selectedMatiere: Matiere;

  constructor(private matiereService: MatiereService) { }

  ngOnInit() {
    this.getMatieres();
  }

  getMatieres(): void {
    this.matiereService.getMatieres()
      .subscribe(res => this.matieres = res.data.evalsMatieres.matieres);
  }

  onSelect(matiere: Matiere): void {
    this.selectedMatiere = matiere;
  }

}
