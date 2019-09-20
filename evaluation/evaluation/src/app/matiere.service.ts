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
      evalsMatieres {
        login
        matieres {
          code
          competenceToCapaciteEtConnaissance {
            code
            connaissances {
              nom
              eval
            }
            capacites {
              nom
              eval
            }
          }
          listeComp {
            code
            val
            niveau
          }
        }
      }
    }`;
    return this.http.get<any>(`http://${SERVER_URL}:8080/graphql?query=${query}` , {withCredentials: true})
  }
}
