import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
//import { DynamodbService } from '../app/services/dynamodb.service';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from "../app/components/header/header.component";
import { FooterComponent } from "../app/components/footer/footer.component";


@Component({
  selector: 'app-root',
  imports: [
    RouterOutlet,
    CommonModule,
    HeaderComponent,
    FooterComponent
  ],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  
}
