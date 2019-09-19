import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { EvalMatiereComponent } from './eval-matiere.component';

describe('EvalMatiereComponent', () => {
  let component: EvalMatiereComponent;
  let fixture: ComponentFixture<EvalMatiereComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ EvalMatiereComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(EvalMatiereComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
