/*
 //  GuessTheNumberViewController.m
 //  GuessTheNumber
 //
 //  Created by Steve Baker on 3/11/10.
 //  Copyright Beepscore LLC 2010. All rights reserved.
 //
 //  Reference: GuessTheNumberViewController.m
 //  Created by Kris Markel on 3/8/10.
 */

#import "GuessTheNumberViewController.h"
#import "Debug.h"


/*
 * declare anonymous category for "private" methods, avoid showing in .h file
 * Note in Objective C no method is private, it can be called from elsewhere.
 * Ref http://stackoverflow.com/questions/1052233/iphone-obj-c-anonymous-category-or-private-category
 */
@interface GuessTheNumberViewController()
- (void)invalidateSession:(GKSession *)session;
- (void)hostGame;
- (void)joinGame;
- (void)sendWinnerID;
- (void)endGameWithWinnerID:(NSString*)winnerID;
- (void)showEndGameAlertForWon:(BOOL)iWon;
- (void)sendNumber:(id)sender;

@end


@implementation GuessTheNumberViewController

const NSInteger kMinimumNumber = 1;
const NSInteger kMaximumNumber = 10;
// the host instance generates secretNumber, players try to guess it.
NSInteger secretNumber = 0;

#pragma mark properties
@synthesize gameSession;
@synthesize opponentID;
@synthesize isGameHost;

//@synthesize connectionAlert;

// instantiated in nib file
@synthesize instructionRangeLabel;
@synthesize myNumberField;
@synthesize opponentNumberLabel;
@synthesize debugStatusLabel;
@synthesize startQuitButton;

#pragma mark -


- (void)enableUI:(BOOL)enableUI {    
    if (! enableUI) {
        self.instructionRangeLabel.hidden = YES;
        self.myNumberField.hidden = YES;
    } else {
        self.instructionRangeLabel.hidden = NO;
        self.myNumberField.hidden = NO;
    }
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    self.gameSession = nil;
	self.opponentID = nil;
    [self enableUI:NO];
}


#pragma mark memory management methods
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)setView:(UIView *)newView {
    if (nil == newView) {
        self.gameSession = nil;
        self.opponentID = nil;
        self.instructionRangeLabel = nil;
        self.myNumberField = nil;
        self.opponentNumberLabel = nil;
        self.debugStatusLabel = nil;
        self.startQuitButton = nil;
        
        //        if(self.connectionAlert.visible) {
        //            [self.connectionAlert dismissWithClickedButtonIndex:-1 animated:NO];
        //        }
        //        self.connectionAlert = nil;        
    }
    [super setView:newView];
}


- (void)dealloc {
    [gameSession release], gameSession = nil;
    [opponentID release], opponentID = nil;
    [instructionRangeLabel release], instructionRangeLabel = nil;
    [myNumberField release], myNumberField = nil;
    [opponentNumberLabel release], opponentNumberLabel = nil;
    [debugStatusLabel release], debugStatusLabel = nil;
    [startQuitButton release], startQuitButton = nil;
    
    //    if(self.connectionAlert.visible) {
    //		[self.connectionAlert dismissWithClickedButtonIndex:-1 animated:NO];
    //	}
    //	self.connectionAlert = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark UI event handlers
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


#pragma mark textField delegate methods
// When user presses Return (or Done) key, resignFirstResponder will dismiss the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)aTextField {
    [aTextField resignFirstResponder];
    return YES;
}

// called when textField resigns first responder
- (void)textFieldDidEndEditing:(UITextField *)aTextField {
    [self sendNumber:self];
}


#pragma mark IBActions
// When Start button is tapped, show peerPicker.  Ref Dudney sec 13.5
- (IBAction)handleStartQuitTapped:(id)sender {
    if (DEBUG) {
        NSString *debugString = [[NSString alloc] initWithString:@"handleStartQuitTapped:"];        
        DLog(@"%@", debugString);         
        self.debugStatusLabel.text = debugString;
        [debugString release];
    }
    
    // Note: picker is released in various picker delegate methods when picker use is done.
    // Ignore Clang warning of potential leak.
    GKPeerPickerController *peerPickerController = [[GKPeerPickerController alloc] init];
    
    peerPickerController.delegate = self;
    peerPickerController.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
    [peerPickerController show];
}


#pragma mark -
#pragma mark GKPeerPickerControllerDelegate Methods
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker { 
	// Peer Picker automatically dismisses on user cancel. No need to programmatically dismiss.
    
	// autorelease the picker. 
	picker.delegate = nil;
    [picker autorelease]; 
	
	// invalidate and release game session if one is around.
	if(self.gameSession != nil)	{
		[self invalidateSession:self.gameSession];
		self.gameSession = nil;
	}	
	// go back to start mode
    // self.gameState = kStateStartGame;
} 


/*
 // Don't need to implement this method because this app doesn't support multiple connection types.
 // See reference documentation for this delegate method and 
 // the GKPeerPickerController's connectionTypesMask property.
 -peerPickerController:didSelectConnectionType: {
 } 
 */


// Notifies peerPickerController delegate that the connection type is requesting a GKSession object.
// You should return a valid GKSession object for use by the picker.
// If this method is not implemented or returns 'nil', a default GKSession is created on the delegate's behalf.
- (GKSession*)peerPickerController:(GKPeerPickerController*)controller 
          sessionForConnectionType:(GKPeerPickerConnectionType)type {
    
    if (!self.gameSession) {        
        self.gameSession = [[GKSession alloc]
                            initWithSessionID:nil
                            displayName:nil
                            sessionMode:GKSessionModePeer];
        self.gameSession.delegate = self;
    }    
	return self.gameSession;
}


/* Notifies peerPickerController delegate that the peer was connected to a GKSession.
 * During the game, each device retains its own session object instance in its own memory.
 * Each view controller sets itself as that device's session delegate.
 * The two sessions communicate over the one network connection.
 */
- (void)peerPickerController:(GKPeerPickerController *)picker 
              didConnectPeer:(NSString *)peerID 
                   toSession:(GKSession *)session {
    
    
    // Remember the current peer.
	self.opponentID = peerID;  // copy    
    
	// Make sure we have a reference to the game session and it is set up
	self.gameSession = session; // retain
    
    // Ref Kris Markel Class9.mov 11:30.  
    // Compare each player's peerID, lower alpha becomes game host
    if (DEBUG) {
        NSString *debugString = [[NSString alloc]
                                 initWithFormat:@"I am %@ peerID = %@ \n Opponent is %@ peerID = %@", 
                                 [session displayNameForPeer:self.gameSession.peerID],
                                 self.gameSession.peerID, 
                                 [session displayNameForPeer:self.opponentID],
                                 self.opponentID];        
        DLog(@"%@", debugString);         
        self.debugStatusLabel.text = debugString;
        [debugString release];
    }
    if (NSOrderedAscending == [self.gameSession.peerID compare:self.opponentID]) {
        self.isGameHost = YES;
    } else {
        self.isGameHost = NO;
    }    
	
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
	[picker autorelease];
}


#pragma mark -
#pragma mark Session Related Methods
- (void)invalidateSession:(GKSession *)session {
	if(session != nil) {
		[session disconnectFromAllPeers]; 
		session.available = NO; 
		[session setDataReceiveHandler: nil withContext: NULL]; 
		session.delegate = nil; 
	}
}


#pragma mark Data Send/Receive Methods
/*
 * This is the data receive handler method expected by the GKSession. 
 * We set ourselves as the receive data handler in the -peerPickerController:didConnectPeer:toSession: method.
 * Receive data from a peer. Callbacks here are set by calling
 * [session setDataHandler: self context: whatever];
 * when accepting a connection from another peer (ie, when didChangeState sends GKPeerStateConnected)
 */
- (void)receiveData:(NSData *)data 
           fromPeer:(NSString *)peerID 
          inSession: (GKSession *)session 
            context:(void *)context {
    
    // Ref Dudney sec 13.8
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    opponentNumber = [unarchiver decodeIntForKey:@"number"];
    
    if (DEBUG) {
        NSString *debugString = [[NSString alloc]
                                 initWithFormat:@"opponentNumber = %d", opponentNumber];        
        DLog(@"%@", debugString);         
        self.debugStatusLabel.text = debugString;
        [debugString release];
    }
    
    NSString *opponentNumberString = [[NSString alloc] initWithFormat:@"%d", opponentNumber];
    self.opponentNumberLabel.text = opponentNumberString;
    [opponentNumberString release], opponentNumberString = nil;
    
    // only host will be allowed to test.
    // ????: this line didnt break joiner seeing host number
    //[self sendWinnerID];
    
    //    if ([unarchiver containsValueForKey:END_GAME_KEY]) {
    //        NSString *winnerString = [unarchiver decodeObjectForKey:WINNER_ID_KEY];
    //		[self endGameWithWinnerID:winnerString];
    //	}
    
    if ([unarchiver containsValueForKey:WINNER_ID_KEY]) {
        NSString *winnerString = [unarchiver decodeObjectForKey:WINNER_ID_KEY];
		[self endGameWithWinnerID:winnerString];
	}    
    
    if ([unarchiver containsValueForKey:START_GAME_KEY]) {
		[self joinGame];
	}    
    [unarchiver release], unarchiver = nil;
}


- (void)sendNumber:(id)sender {
    
    [self.myNumberField resignFirstResponder];    
    myNumber = [self.myNumberField.text integerValue];
    if (DEBUG) {
        NSString *debugString = [[NSString alloc]
                                 initWithFormat:@"sendNumber = %d", myNumber];        
        DLog(@"%@", debugString);         
        self.debugStatusLabel.text = debugString;
        [debugString release];
    }
    
    NSMutableData *message = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:message];
    [archiver encodeInt:myNumber forKey:@"number"];
    
    // move from sendWinnerID to try to fix joiner not getting host numbers
    if (self.isGameHost) {
        if (secretNumber == myNumber) {
            [archiver encodeObject:self.gameSession.peerID forKey:WINNER_ID_KEY];
            [archiver encodeBool:YES forKey:END_GAME_KEY];
            [self showEndGameAlertForWon:YES];            
        }
        if (secretNumber == opponentNumber) {
            [archiver encodeObject:self.opponentID forKey:WINNER_ID_KEY];
            [archiver encodeBool:YES forKey:END_GAME_KEY];
            [self showEndGameAlertForWon:NO];            
        }
    }
    // =============
        
    [archiver finishEncoding];
    
    [self.gameSession sendDataToAllPeers:message withDataMode:GKSendDataReliable error:NULL];
    [archiver release], archiver = nil;
    [message release], message = nil; 
    
    // only host will be allowed to test.
    //[self sendWinnerID];
}


#pragma mark GKSessionDelegate methods
// we've gotten a state change in the session for the given peer.
- (void)session:(GKSession *)session
           peer:(NSString *)peerID
 didChangeState:(GKPeerConnectionState)state {
    
    switch (state) 
    { 
        case GKPeerStateConnected: 
            if (DEBUG) {
                NSString *debugString = [[NSString alloc]
                                         initWithFormat:@"GKPeerStateConnected to %@ peerID = %@",
                                         [session displayNameForPeer:peerID], peerID];        
                DLog(@"%@", debugString);         
                self.debugStatusLabel.text = debugString;
                [debugString release];
            }
            [session setDataReceiveHandler:self withContext:nil]; 

            // ????: not necessary???????????????????????????????????????????????????????????????
//            self.opponentID = peerID;
            
            self.isGameHost ? [self hostGame] : [self joinGame];
            break;
            
        case GKPeerStateDisconnected:
            // We've been disconnected from the other peer.
            DLog(@"GKPeerStateDisconnected");
            if (DEBUG) {
                NSString *debugString = [[NSString alloc]
                                         initWithFormat:@"GKPeerStateDisconnected from %@ peerID = %@",
                                         [session displayNameForPeer:peerID], peerID];        
                DLog(@"%@", debugString);         
                self.debugStatusLabel.text = debugString;
                [debugString release];
            } 
            break; 
    } 
}


- (void)session:(GKSession *)session
didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    DLog(@"session:didReceiveConnectionRequestFromPeer: = %@", peerID);
    self.debugStatusLabel.text = [NSString 
                                  stringWithFormat:@"session:didReceiveConnectionRequestFromPeer: = %@",
                                  peerID];
}


- (void)session:(GKSession *)session 
connectionWithPeerFailed:(NSString *)peerID 
      withError:(NSError *)error {
    if (DEBUG) {
        NSString *debugString = [[NSString alloc]
                                 initWithFormat:@"session:connectionWithPeerFailed: to %@ peerID = %@",
                                 [session displayNameForPeer:peerID], peerID];        
        DLog(@"%@", debugString);         
        self.debugStatusLabel.text = debugString;
        [debugString release];
    }
}


- (void)session:(GKSession *)session 
didFailWithError:(NSError *)error {
    if (DEBUG) {
        NSString *debugString = [[NSString alloc]
                                 initWithString:@"session:didFailWithError:"];        
        DLog(@"%@", debugString);         
        self.debugStatusLabel.text = debugString;
        [debugString release];
    }
}


#pragma mark -
#pragma mark Game Logic Methods
// Ref http://stackoverflow.com/questions/1131101/whats-wrong-with-this-randomize-function
// Note this works for arguments in either algebraic order.  i.e. it works if minimum > maximum
- (float)randomFloatBetweenMin:(float)minimum andMax:(float)maximum {
    return (((float) arc4random() / 0xFFFFFFFFu) * (maximum - minimum)) + minimum;
}


- (NSInteger)randomIntegerBetweenMin:(NSInteger)minimum andMax:(NSInteger)maximum {
    return (NSInteger) lround([self randomFloatBetweenMin:(float)minimum andMax:(float)maximum]);
}


-(void)initGame {
    NSString *tempInstruction = [[NSString alloc]
                                 initWithFormat:@"Please enter a number between %d and %d",
                                 kMinimumNumber, kMaximumNumber];    
    self.instructionRangeLabel.text = tempInstruction;
    [tempInstruction release];
    [self enableUI:YES];
}


// Ref Dudney sec 13.6
- (void) hostGame {
    [self initGame];
    
    // only the host sets secretNumber
    secretNumber = [self randomIntegerBetweenMin:kMinimumNumber andMax:kMaximumNumber];
    if (DEBUG) {
        NSString *debugString = [[NSString alloc]
                                 initWithFormat:@"hostGame isGameHost = %d, secretNumber = %d", 
                                 self.isGameHost, secretNumber];        
        DLog(@"%@", debugString);         
        self.debugStatusLabel.text = debugString;
        [debugString release];
    }
    
	NSMutableData *message = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]
                                 initForWritingWithMutableData:message];
	[archiver encodeBool:YES forKey:START_GAME_KEY];
	[archiver finishEncoding];
	NSError *sendErr = nil;
	[self.gameSession sendDataToAllPeers: message
                            withDataMode:GKSendDataReliable error:&sendErr];
	if (sendErr) {
		DLog(@"send greeting failed: %@", sendErr);
    }
	[message release];
	[archiver release];
}


- (void)joinGame {
    if (DEBUG) {
        NSString *debugString = [[NSString alloc] initWithString:@"joinGame"];        
        DLog(@"%@", debugString);         
        self.debugStatusLabel.text = debugString;
        [debugString release];
    }
    [self initGame];
}


- (void)sendWinnerID {
    // If we are the host, we know the secret number and can test for a winner
    // FIXME: Currently this doesn't allow for a tie    
    if (self.isGameHost) {
        NSMutableData *message = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] 
                                           initForWritingWithMutableData:message];
        
        if (secretNumber == myNumber) {
            [archiver encodeObject:self.gameSession.peerID forKey:WINNER_ID_KEY];
            [archiver encodeBool:YES forKey:END_GAME_KEY];
            [self showEndGameAlertForWon:YES];            
        }
        if (secretNumber == opponentNumber) {
            [archiver encodeObject:self.opponentID forKey:WINNER_ID_KEY];
            [archiver encodeBool:YES forKey:END_GAME_KEY];
            [self showEndGameAlertForWon:NO];            
        }
        [archiver finishEncoding];    
        [self.gameSession sendDataToAllPeers:message withDataMode:GKSendDataReliable error:NULL];
        [archiver release], archiver = nil;
        [message release], message = nil;        
    }    
}


-(void)showEndGameAlertForWon:(BOOL)iWon {	
    
    UIAlertView *endGameAlert = [[UIAlertView alloc]
                                 initWithTitle: iWon ? @"Victory!" : @"Defeat!"
                                 message: iWon ? @"You guessed the number!" : @"You lose."
                                 delegate:nil
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
    [endGameAlert show];
    [endGameAlert release];
}


- (void)endGameWithWinnerID:(NSString*)winnerID {
    if (DEBUG) {
        NSString *debugString = [[NSString alloc]
                                 initWithFormat:@"endGameWithWinnerID:%@ %@", 
                                 [self.gameSession displayNameForPeer:winnerID],
                                 winnerID];
        DLog(@"%@", debugString);         
        self.debugStatusLabel.text = debugString;
        [debugString release];
    }
    
    // NOTE: use isEqualToString: for string comparison, not ==
    BOOL iWon = [winnerID isEqualToString:self.gameSession.peerID];
    [self showEndGameAlertForWon:iWon];

	self.opponentID = nil;
	//[self invalidateSession:self.gameSession];
}

@end
