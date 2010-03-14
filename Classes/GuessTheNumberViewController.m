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

@implementation GuessTheNumberViewController

@synthesize gameSession;
// instantiated in nib file
@synthesize instructionRangeLabel;
@synthesize myNumberField;
@synthesize opponentNumberLabel;
@synthesize startQuitButton;
@synthesize isGameHost;
@synthesize playerWins;


// the program generates theAnswer, players try to guess it.
NSInteger theAnswer;

#pragma mark helper methods
// Ref http://stackoverflow.com/questions/1131101/whats-wrong-with-this-randomize-function
// Note this works for arguments in either algebraic order.  i.e. it works if minimum > maximum
- (float)randomFloatBetweenMin:(float)minimum andMax:(float)maximum {
    return (((float) arc4random() / 0xFFFFFFFFu) * (maximum - minimum)) + minimum;
}


- (NSInteger)randomIntegerBetweenMin:(NSInteger)minimum andMax:(NSInteger)maximum {
    return (NSInteger) lround([self randomFloatBetweenMin:(float)minimum andMax:(float)maximum]);
}


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
    [self enableUI:NO];
}
#pragma mark -


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
        self.instructionRangeLabel = nil;
        self.myNumberField = nil;
        self.opponentNumberLabel = nil;
        self.startQuitButton = nil;
    }
    [super setView:newView];
}


- (void)dealloc {
    [gameSession release], gameSession = nil;
    [instructionRangeLabel release], instructionRangeLabel = nil;
    [myNumberField release], myNumberField = nil;
    [opponentNumberLabel release], opponentNumberLabel = nil;
    [startQuitButton release], startQuitButton = nil;
    [super dealloc];
}


#pragma mark game methods
// Ref Dudney sec 13.6
-(void) updateTapCountLabels {
}

-(void) initGame {
    NSString *tempInstruction = [[NSString alloc]
                                 initWithFormat:@"Please enter a number between %d and %d",
                                 kMinimum, kMaximum];    
    self.instructionRangeLabel.text = tempInstruction;
    [tempInstruction release];        
    
    theAnswer = [self randomIntegerBetweenMin:kMinimum andMax:kMaximum];
    DLog(@"theAnswer = %d", theAnswer); 
}


-(void) hostGame {
	[self initGame];
	NSMutableData *message = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]
                                 initForWritingWithMutableData:message];
	[archiver encodeBool:YES forKey:START_GAME_KEY];
	[archiver finishEncoding];
	NSError *sendErr = nil;
	[self.gameSession sendDataToAllPeers: message
                            withDataMode:GKSendDataReliable error:&sendErr];
	if (sendErr)
		NSLog (@"send greeting failed: %@", sendErr);
	// change state of startQuitButton
	self.startQuitButton.title = @"Quit";
	[message release];
	[archiver release];
	[self updateTapCountLabels];
}

-(void) joinGame {
	[self initGame];
	self.startQuitButton.title = @"Quit";
    //	[self updateTapCountLabels];
}


-(void) showEndGameAlert {	
    self.playerWins = YES;
    UIAlertView *endGameAlert = [[UIAlertView alloc]
                                 initWithTitle: self.playerWins ? @"Victory!" : @"Defeat!"
                                 message: self.playerWins ? @"You guessed the number!": @"You lose."
                                 delegate:nil
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
    [endGameAlert show];
    [endGameAlert release];
}

-(void) endGame {
	opponentID = nil;
	self.startQuitButton.title = @"Find";
	[self.gameSession disconnectFromAllPeers];
	[self showEndGameAlert];
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
// when Start button is tapped, show peerPicker.  Ref Dudney sec 13.5
- (IBAction)startAGame:(id)sender {
	if (! opponentID) {
		isGameHost = YES;
        
		GKPeerPickerController *peerPickerController = [[GKPeerPickerController alloc] init];
		peerPickerController.delegate = self;
		peerPickerController.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
		[peerPickerController show];
        [peerPickerController release], peerPickerController = nil;
    }
}


- (void)sendNumber:(id)sender {
    [self.myNumberField resignFirstResponder];
    
    NSInteger number = [self.myNumberField.text integerValue];
    NSMutableData *message = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:message];
    [archiver encodeInt:number forKey:@"number"];
    [archiver finishEncoding];
    [self.gameSession sendDataToAllPeers:message withDataMode:GKSendDataReliable error:NULL];
    [archiver release], archiver = nil;
    [message release], message = nil;
}


#pragma mark GKPeerPickerControllerDelegate methods
- (void)peerPickerController:(GKPeerPickerController *)picker 
              didConnectPeer:(NSString *)peerID 
                   toSession:(GKSession *)newSession {
    self.gameSession = newSession;
    [self.gameSession setDataReceiveHandler:self withContext:NULL];
    NSLog(@"Peer: %@", peerID);
    [picker dismiss];
    
    [self enableUI:YES];
}


#pragma mark GKSessionDelegate methods
- (void)session:(GKSession *)session
           peer:(NSString *)peerID
 didChangeState:(GKPeerConnectionState)state {
    switch (state) 
    { 
        case GKPeerStateConnected: 
			[session setDataReceiveHandler: self withContext: nil]; 
            
            opponentID = peerID;
            
            isGameHost ? [self hostGame] : [self joinGame];
            [self enableUI:YES];
			break;
        case GKPeerStateDisconnected: 
            [self enableUI:NO];
			break;            
    } 
}


- (void)session:(GKSession *)session
didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    self.isGameHost = NO;
}


- (void)session:(GKSession *)session 
connectionWithPeerFailed:(NSString *)peerID 
      withError:(NSError *)error {
	NSLog (@"session:connectionWithPeerFailed:withError:");	
}

- (void)session:(GKSession *)session 
didFailWithError:(NSError *)error {
	NSLog (@"session:didFailWithError:");		
}

// Ref Dudney sec 13.8
// TODO: add endGame and joinGame messages !!!!!!!!!!!!!!!!!
#pragma mark receive data handler
- (void) receiveData:(NSData *)data 
            fromPeer:(NSString *)peerID 
           inSession: (GKSession *)session 
             context:(void *)context {
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSInteger opponentNumber = [unarchiver decodeIntForKey:@"number"];
    NSString *opponentNumberString = [[NSString alloc] initWithFormat:@"%d", opponentNumber];
    self.opponentNumberLabel.text = opponentNumberString;
    [opponentNumberString release], opponentNumberString = nil;
    [unarchiver release], unarchiver = nil;
}

@end
