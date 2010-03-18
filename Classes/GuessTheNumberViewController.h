/*
//  GuessTheNumberViewController.h
//  GuessTheNumber
//
//  Created by Steve Baker on 3/11/10.
//  Copyright Beepscore LLC 2010. All rights reserved.
//
// Ref Apple sample code for Game Kit GKTank
// Ref Dudney iPhone SDK Development Ch 13
// Ref GuessTheNumberViewController.m  created by Kris Markel on 3/8/10. 
//     Kris Markel UW HW9 video
*/

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

//protocolkeys
#define START_GAME_KEY @"startgame"
#define END_GAME_KEY @"endgame"
#define WINNER_ID_KEY @"winnerID"

@interface GuessTheNumberViewController : UIViewController 
<GKPeerPickerControllerDelegate, GKSessionDelegate, UITextFieldDelegate> {

    GKSession *gameSession;
    
    NSString *opponentID;
    BOOL isGameHost;
    UInt32 myNumber;
    UInt32 opponentNumber;

    UILabel *instructionRangeLabel;
    UITextField *myNumberField;
    UILabel *opponentNumberLabel;
    UILabel *debugStatusLabel;
    UIBarButtonItem *startQuitButton;

}

#pragma mark properties
@property(nonatomic, retain)GKSession *gameSession;
@property(nonatomic, copy)NSString *opponentID;

@property(nonatomic,assign)BOOL isGameHost;

@property(nonatomic, retain)IBOutlet UILabel *instructionRangeLabel;
@property(nonatomic, retain)IBOutlet UITextField *myNumberField;
@property(nonatomic, retain)IBOutlet UILabel *opponentNumberLabel;
@property(nonatomic, retain)IBOutlet UILabel *debugStatusLabel;
@property(nonatomic,retain)IBOutlet UIBarButtonItem *startQuitButton;

- (IBAction)handleStartQuitTapped:(id)sender;

@end

