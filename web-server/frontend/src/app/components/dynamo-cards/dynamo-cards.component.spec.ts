import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DynamoCardsComponent } from './dynamo-cards.component';

describe('DynamoCardsComponent', () => {
  let component: DynamoCardsComponent;
  let fixture: ComponentFixture<DynamoCardsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DynamoCardsComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DynamoCardsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
