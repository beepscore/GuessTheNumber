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

    NSString *opponentID;

    GKSession *gameSession;
    NSString *gamePeerId;
    BOOL isGameHost;
    BOOL playerWins;

    UILabel *instructionRangeLabel;
    UITextField *myNumberField;
    UILabel *opponentNumberLabel;
    UILabel *debugStatusLabel;
    UIBarButtonItem *startQuitButton;
    
    UIAlertView	*connectionAlert;
}

@property(nonatomic, retain)GKSession *gameSession;
@property(nonatomic, copy)NSString *gamePeerId;

@property(nonatomic,assign)BOOL isGameHost;
@property(nonatomic,assign)BOOL playerWins;

@property(nonatomic, retain)IBOutlet UILabel *instructionRangeLabel;
@property(nonatomic, retain)IBOutlet UITextField *myNumberField;
@property(nonatomic, retain)IBOutlet UILabel *opponentNumberLabel;
@property(nonatomic, retain)IBOutlet UILabel *debugStatusLabel;
@property(nonatomic,retain)IBOutlet UIBarButtonItem *startQuitButton;
@property(nonatomic, retain) UIAlertView *connectionAlert;


- (IBAction)handleStartQuitTapped:(id)sender;

- (void)invalidateSession:(GKSession *)session;
-(void) hostGame;
-(void) joinGame;
-(void) endGame;

@end

