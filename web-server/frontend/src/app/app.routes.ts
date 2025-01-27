import { Routes } from '@angular/router';
import { DynamoCardsComponent } from "./components/dynamo-cards/dynamo-cards.component"

export const routes: Routes = [

    {
        path: 'home',
        component: DynamoCardsComponent,
      },
    { path: '', redirectTo: '/home', pathMatch: 'full' }
];
