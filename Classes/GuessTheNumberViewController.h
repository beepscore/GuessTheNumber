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
<GKPeerPickerControllerDelegate, UITextFieldDelegate> {
    GKSession *session;
    UITextField *numberField;
    UILabel *opponentNumber;
    UIBarButtonItem *sendBarButton;

}

@property(nonatomic, retain)GKSession *session;
@property(nonatomic, retain)IBOutlet UITextField *numberField;
@property(nonatomic, retain)IBOutlet UILabel *opponentNumber;

@property(nonatomic, retain)IBOutlet UIBarButtonItem *sendBarButton;


- (IBAction)startAGame:(id)sender;
- (IBAction)sendNumber:(id)sender;

@end

