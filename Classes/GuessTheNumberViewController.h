//
//  GuessTheNumberViewController.h
//  GuessTheNumber
//
//  Created by Steve Baker on 3/11/10.
//  Copyright Beepscore LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface GuessTheNumberViewController : UIViewController 
<GKPeerPickerControllerDelegate, GKSessionDelegate, UITextFieldDelegate> {
    GKSession *gameSession;
    UILabel *instructionRangeLabel;
    UITextField *myNumberField;
    UILabel *opponentNumberLabel;
    UIBarButtonItem *sendBarButton;
}

@property(nonatomic, retain)GKSession *gameSession;
@property(nonatomic, retain)IBOutlet UILabel *instructionRangeLabel;

@property(nonatomic, retain)IBOutlet UITextField *myNumberField;
@property(nonatomic, retain)IBOutlet UILabel *opponentNumberLabel;

@property(nonatomic, retain)IBOutlet UIBarButtonItem *sendBarButton;


- (IBAction)startAGame:(id)sender;
- (IBAction)sendNumber:(id)sender;


@end

