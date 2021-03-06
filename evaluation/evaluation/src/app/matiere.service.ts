import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs'
import { Matiere } from './matiere'
import { SERVER_URL } from "../../../back/config.json";

@Injectable({
  providedIn: 'root'
})

export class MatiereService {

  constructor(private http: HttpClient) { }

  getMatieres(): Observable<any> {
    var query = `{
      evalsMatieres{
        login
        matieres{
          code
          listeComp{
            code
            val
            niveau
            connaissances{
              nom
              eval
            }
            capacites{
              nom
              eval
            }
          }
        }
      }
    }`;
    return this.http.get<any>(`http://${SERVER_URL}/graphql?query=${query}` , {withCredentials: true})
  }

  setMatiere(matiere: Matiere): any {
    // console.log("--> SET MATIERE", matiere)
    var query = `
      mutation($matiere: MatiereEvalueeInput!) {
        updateMatiere(matiere: $matiere)
      }
    `
    return this.http.post(`http://${SERVER_URL}/graphql`, {query: query, variables: {matiere: matiere}} , {withCredentials: true})

  }
}
