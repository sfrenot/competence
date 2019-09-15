import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Matiere } from './matiere';

@Component({
  selector: 'app-matieres',
  templateUrl: './matieres.component.html',
  styleUrls: ['./matieres.component.css']
})

export class MatieresComponent implements OnInit {

  matieres: Matiere[] = [
    { name: 'ELP' },
    { name: 'TRI' }
  ]

  constructor(private http: HttpClient) { }

  ngOnInit() {
    this.http.get('http://localhost/graphql?query={listeEtudiants{name}}')
    .toPromise()
    .then( (res) => {console.log(res)} )
  }

}
