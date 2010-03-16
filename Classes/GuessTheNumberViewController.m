//
//  GuessTheNumberViewController.m
//  GuessTheNumber
//
//  Created by Steve Baker on 3/11/10.
//  Copyright Beepscore LLC 2010. All rights reserved.
//
//  Reference: GuessTheNumberViewController.m
//  Created by Kris Markel on 3/8/10.


#import "GuessTheNumberViewController.h"
#import "Debug.h"

const NSInteger kMinimum = 1;
const NSInteger kMaximum = 10;


// declare anonymous category for "private" methods, avoid listing in .h file
// Note in Objective C no method is actually private.
// Ref http://stackoverflow.com/questions/1052233/iphone-obj-c-anonymous-category-or-private-category
@interface GuessTheNumberViewController()
-(void)invalidateSession:(GKSession *)session;
-(void) hostGame;
-(void) joinGame;
-(void) endGame;
@end


@implementation GuessTheNumberViewController

@synthesize gameSession;
@synthesize gamePeerId;
@synthesize isGameHost;
@synthesize playerWins;

// instantiated in nib file
@synthesize instructionRangeLabel;
@synthesize myNumberField;
@synthesize opponentNumberLabel;
@synthesize debugStatusLabel;
@synthesize startQuitButton;
@synthesize connectionAlert;

// the host instance generates secretNumber, players try to guess it.
NSInteger secretNumber = 0;


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
	self.gamePeerId = nil;
    self.isGameHost = NO;
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
        self.gamePeerId = nil;
        self.instructionRangeLabel = nil;
        self.myNumberField = nil;
        self.opponentNumberLabel = nil;
        self.debugStatusLabel = nil;
        self.startQuitButton = nil;
        
        if(self.connectionAlert.visible) {
            [self.connectionAlert dismissWithClickedButtonIndex:-1 animated:NO];
        }
        self.connectionAlert = nil;        
    }
    [super setView:newView];
}


- (void)dealloc {
    [gameSession release], gameSession = nil;
    [gamePeerId release], gamePeerId = nil;
    [instructionRangeLabel release], instructionRangeLabel = nil;
    [myNumberField release], myNumberField = nil;
    [opponentNumberLabel release], opponentNumberLabel = nil;
    [debugStatusLabel release], debugStatusLabel = nil;
    [startQuitButton release], startQuitButton = nil;
    
    if(self.connectionAlert.visible) {
		[self.connectionAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
	self.connectionAlert = nil;
    
    [super dealloc];
}


#pragma mark -

- (void)sendNumber:(id)sender {
    [self.myNumberField resignFirstResponder];
    
    NSInteger number = [self.myNumberField.text integerValue];
    NSMutableData *message = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:message];
    [archiver encodeInt:number forKey:@"number"];
    
    // did we just win?
	self.playerWins = (number == secretNumber);
    if (self.playerWins) {
        [archiver encodeBool:YES forKey:END_GAME_KEY];
    }
    
    [archiver finishEncoding];
    [self.gameSession sendDataToAllPeers:message withDataMode:GKSendDataReliable error:NULL];
    [archiver release], archiver = nil;
    [message release], message = nil;    
    
	// also end game locally
	if (playerWins) {
        [self endGame];   
    }
}


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
// when Start button is tapped, show peerPicker.  Ref Dudney sec 13.5
- (IBAction)handleStartQuitTapped:(id)sender {
	if (! opponentID) {
        DLog();
        self.isGameHost = YES;
        self.debugStatusLabel.text = [NSString 
                                      stringWithFormat:@"handleStartQuitTapped: isGameHost = %d", 
                                      isGameHost];
        
        // Note: picker is released in various picker delegate methods when picker use is done.
        // Ignore Clang warning of potential leak.
        GKPeerPickerController *peerPickerController = [[GKPeerPickerController alloc] init];
        
		peerPickerController.delegate = self;
		peerPickerController.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
		[peerPickerController show];
    }
}

// Ref Apple sample code for Game Kit GKTank
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


// Don't need to implement this method because this app doesn't support multiple connection types.
// See reference documentation for this delegate method and 
// the GKPeerPickerController's connectionTypesMask property.
// -peerPickerController:didSelectConnectionType: {
// } 


// Notifies peerPickerController delegate that the connection type is requesting a GKSession object.
// You should return a valid GKSession object for use by the picker.
// If this method is not implemented or returns 'nil', a default GKSession is created on the delegate's behalf.
- (GKSession*)peerPickerController:(GKPeerPickerController*)controller 
          sessionForConnectionType:(GKPeerPickerConnectionType)type {
    
    GKSession *session = [[GKSession alloc]
                          initWithSessionID:nil
                          displayName:nil
                          sessionMode:GKSessionModePeer];
    
    // peer picker retains a reference, so autorelease ours so we don't leak.
	return [session autorelease];
}


// Notifies peerPickerController delegate that the peer was connected to a GKSession.
// During the game, each device retains its own session object instance in its own memory.
// Each view controller sets itself as that device's session delegate.
// The two sessions communicate over the one network connection.
- (void)peerPickerController:(GKPeerPickerController *)picker 
              didConnectPeer:(NSString *)peerID 
                   toSession:(GKSession *)session {
    
	// Remember the current peer.
	self.gamePeerId = peerID;  // copy    
    DLog(@"didConnectPeer: %@", self.gamePeerId);    
    self.debugStatusLabel.text = [NSString 
                                  stringWithFormat:@"didConnectPeer: %@", self.gamePeerId];    
	
	// Make sure we have a reference to the game session and it is set up
	self.gameSession = session; // retain
	self.gameSession.delegate = self; 
	[self.gameSession setDataReceiveHandler:self withContext:NULL];
	
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
	[picker autorelease];
	
	// Start Multiplayer game by entering a cointoss state to determine who is server/client.
	// self.gameState = kStateMultiplayerCointoss;
    // Kris Markel assigns host role to lowest alphabetical PeerID.
    //    if (self.id < self.gamePeerId) {        
    //    self.isGameHost = YES;
    //    }
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
 */
// receive data from a peer. callbacks here are set by calling
// [session setDataHandler: self context: whatever];
// when accepting a connection from another peer (ie, when didChangeState sends GKPeerStateConnected)
- (void)receiveData:(NSData *)data 
           fromPeer:(NSString *)peerID 
          inSession: (GKSession *)session 
            context:(void *)context {
    
    // Ref Dudney sec 13.8
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSInteger opponentNumber = [unarchiver decodeIntForKey:@"number"];
    NSString *opponentNumberString = [[NSString alloc] initWithFormat:@"%d", opponentNumber];
    self.opponentNumberLabel.text = opponentNumberString;
    [opponentNumberString release], opponentNumberString = nil;
    
    
    if ([unarchiver containsValueForKey:END_GAME_KEY]) {
		[self endGame];
	}
	if ([unarchiver containsValueForKey:START_GAME_KEY]) {
		[self joinGame];
	}    
    [unarchiver release], unarchiver = nil;
}


#pragma mark GKSessionDelegate methods
// we've gotten a state change in the session for the given peer.
- (void)session:(GKSession *)session
           peer:(NSString *)peerID
 didChangeState:(GKPeerConnectionState)state {
    
    switch (state) 
    { 
        case GKPeerStateConnected: 
            DLog(@"GKPeerStateConnected");
            self.debugStatusLabel.text = [NSString 
                                          stringWithFormat:@"GKPeerStateConnected peerID = %@",
                                          peerID];
            [session setDataReceiveHandler:self withContext:nil]; 
            
            opponentID = peerID;
            
            isGameHost ? [self hostGame] : [self joinGame];
            break;
            
        case GKPeerStateDisconnected:
            // We've been disconnected from the other peer.
            DLog(@"GKPeerStateDisconnected");
            self.debugStatusLabel.text = [NSString 
                                          stringWithFormat:@"GKPeerStateConnected peerID = %@",
                                          peerID];
            
            // Update user alert or throw alert if it isn't already up
            NSString *message = [NSString stringWithFormat:@"Could not reconnect with %@.", 
                                 [session displayNameForPeer:peerID]];
            if (self.connectionAlert && self.connectionAlert.visible) {
                self.connectionAlert.message = message;
            } else {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Lost Connection" 
                                      message:message 
                                      delegate:self 
                                      cancelButtonTitle:@"End Game" 
                                      otherButtonTitles:nil];
                self.connectionAlert = alert;
                [alert show];
                [alert release];
            }
            
            // go back to start mode
            //self.gameState = kStateStartGame;
            break; 
    } 
}


- (void)session:(GKSession *)session
didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    DLog();
    self.debugStatusLabel.text = [NSString 
                                  stringWithFormat:@"session:didReceiveConnectionRequestFromPeer: = %@",
                                  peerID];
}


- (void)session:(GKSession *)session 
connectionWithPeerFailed:(NSString *)peerID 
      withError:(NSError *)error {
	DLog();	
    self.debugStatusLabel.text = [NSString 
                                  stringWithFormat:@"session:connectionWithPeerFailed: = %@",
                                  peerID];
}

- (void)session:(GKSession *)session 
didFailWithError:(NSError *)error {
	DLog();	
    self.debugStatusLabel.text = @"session:didFailWithError:";
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
                                 kMinimum, kMaximum];    
    self.instructionRangeLabel.text = tempInstruction;
    [tempInstruction release];
    [self enableUI:YES];
}


// Ref Dudney sec 13.6
- (void) hostGame {
    [self initGame];
    
    // only the host sets secretNumber
    secretNumber = [self randomIntegerBetweenMin:kMinimum andMax:kMaximum];
    DLog(@"secretNumber = %d", secretNumber); 
    self.debugStatusLabel.text = [NSString 
                                  stringWithFormat:@"hostGame isGameHost = %d, secretNumber = %d", 
                                  isGameHost, secretNumber];
    
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
	// change state of startQuitButton
	self.startQuitButton.title = @"Quit host";
	[message release];
	[archiver release];
}

- (void)joinGame {
	[self initGame];
    self.debugStatusLabel.text = @"joinGame";
	self.startQuitButton.title = @"Quit";
}


-(void) showEndGameAlert {	
    self.playerWins = YES;
    UIAlertView *endGameAlert = [[UIAlertView alloc]
                                 initWithTitle: self.playerWins ? @"Victory!" : @"Defeat!"
                                 message: self.playerWins ? @"You guessed the number!" : @"You lose."
                                 delegate:nil
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
    [endGameAlert show];
    [endGameAlert release];
}

- (void)endGame {
	opponentID = nil;
    self.debugStatusLabel.text = @"endGame";    
	self.startQuitButton.title = @"Find";
	[self.gameSession disconnectFromAllPeers];
	[self showEndGameAlert];
}


@end
