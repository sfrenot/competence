import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs'
import { Matiere } from './matiere'

@Injectable({
  providedIn: 'root'
})

export class MatiereService {

  constructor(private http: HttpClient) { }

  getMatieres(): Observable<Matiere []> {
    // this.http.get('http://localhost/graphql?query={listeMatieres{code}}')
    // .toPromise()
    // .then( (res) => {
    //     return res.data.listeMatieres
    //   }
    // )
    return of([{code: 'ELPii'}, {code: 'MGL'}]);

  }
}
