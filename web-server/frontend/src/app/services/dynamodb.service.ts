import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http'
import { map, Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class DynamodbService {

  // url should be editied if you set up a proper domain, otherwise the number section of the api will need to be edited to your dynamic load balancer
  private apiUrl = 'http://Terraform-Load-Balancer-Womack-'+'624677713'+'.us-east-1.elb.amazonaws.com/dynamodb';
  private http = inject(HttpClient);

  // GET /dynamodb/all
  getAllItems(){
    return this.http.get(`${this.apiUrl}/all`);
  }

  // GET /dynamodb/:id
  getItemById(id: string) {
    return this.http.get(`${this.apiUrl}/${id}`);
  }

  
}
