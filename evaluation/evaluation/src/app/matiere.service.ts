import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs'
import { Matiere } from './matiere'

@Injectable({
  providedIn: 'root'
})

export class MatiereService {

  constructor(private http: HttpClient) { }

  getMatieres(): Observable<any> {
    return this.http.get<any>('http://localhost/graphql?query={listeMatieres{code}}')
  }
}
