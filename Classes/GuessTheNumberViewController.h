//
//  GuessTheNumberViewController.h
//  GuessTheNumber
//
//  Created by Steve Baker on 3/11/10.
//  Copyright Beepscore LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

#define TIME_KEY @"time"
//protocolkeys
#define START_GAME_KEY @"startgame"
#define END_GAME_KEY @"endgame"

@interface GuessTheNumberViewController : UIViewController 
<GKPeerPickerControllerDelegate, GKSessionDelegate, UITextFieldDelegate> {
    
    GKSession *gameSession;
    NSString *opponentID;

    UILabel *instructionRangeLabel;
    UITextField *myNumberField;
    UILabel *opponentNumberLabel;
    UIBarButtonItem *startQuitButton;
    BOOL isGameHost;
    BOOL playerWins;

}

@property(nonatomic, retain)GKSession *gameSession;
@property(nonatomic, retain)IBOutlet UILabel *instructionRangeLabel;
@property(nonatomic, retain)IBOutlet UITextField *myNumberField;
@property(nonatomic, retain)IBOutlet UILabel *opponentNumberLabel;
@property(nonatomic,retain)IBOutlet UIBarButtonItem *startQuitButton;
@property(nonatomic,assign)BOOL isGameHost;
@property(nonatomic,assign)BOOL playerWins;


- (IBAction)startAGame:(id)sender;
- (void)sendNumber:(id)sender;


@end

