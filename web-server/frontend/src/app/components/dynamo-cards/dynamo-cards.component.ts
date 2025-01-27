import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DynamodbService } from '../../services/dynamodb.service';

@Component({
  selector: 'app-dynamo-cards',
  imports: [
    CommonModule
  ],
  templateUrl: './dynamo-cards.component.html',
  styleUrl: './dynamo-cards.component.css'
})
export class DynamoCardsComponent implements OnInit{
  title = 'frontend';
  
  //holds the dynamo json of all table items
  items: any;

  // holds the info on which card has been expanded upon
  expandedItem = new Set<number>();;
  objectKeys = Object.keys;

  constructor(private DynamodbService: DynamodbService) {}

  ngOnInit(){
    this.loadAllItems()
  }

  // retrieves the json of all the items in the dynamo table on page load
  loadAllItems(){

    this.DynamodbService.getAllItems().subscribe({
      next: (data) => {
        this.items = data;
      },
      error: (err) => console.error('Error fetching item', err),
    });
  }

  // used to provide more detail on each card, hiding and unhiding based on clicks
  loadItem(index:any){
    if (this.expandedItem.has(index)) {
      this.expandedItem.delete(index);
    } else {
      this.expandedItem.add(index);
    }
  }
}
