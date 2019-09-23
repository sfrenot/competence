import { Component, OnInit } from '@angular/core';
import { Matiere } from '../matiere';
import { MatiereService } from '../matiere.service';

@Component({
  selector: 'app-matieres',
  templateUrl: './matieres.component.html',
  styleUrls: ['./matieres.component.css']
})

export class MatieresComponent implements OnInit {
  login: String;
  matieres: Matiere[];
  selectedMatiere: Matiere;

  constructor(private matiereService: MatiereService) { }

  ngOnInit() {
    this.getMatieres();
  }

  getMatieres(): void {
    this.matiereService.getMatieres()
      .subscribe(res => {
        this.matieres = res.data.evalsMatieres.matieres
        this.login = res.data.evalsMatieres.login
      });
  }

  onSelect(matiere: Matiere): void {
    this.selectedMatiere = matiere;
  }

  validerMatiere(matiere: Matiere): void {
    console.log(matiere);
    this.matiereService.setMatiere(matiere)
      .subscribe( res => console.log(res))
  }

}
