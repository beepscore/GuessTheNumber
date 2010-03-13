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

@implementation GuessTheNumberViewController

@synthesize gameSession;
// instantiated in nib file
@synthesize instructionRangeLabel;
@synthesize myNumberField;
@synthesize opponentNumberLabel;
@synthesize sendBarButton;

const NSInteger kMinimum = 1;
const NSInteger kMaximum = 10;

// the program generates theAnswer, players try to guess it.
NSInteger theAnswer;


// Ref http://stackoverflow.com/questions/1131101/whats-wrong-with-this-randomize-function
// Note this works for arguments in either algebraic order.  i.e. it works if minimum > maximum
//- (float)randomValueBetweenMin:(float)minimum andMax:(float)maximum {
//    return (((float) arc4random() / 0xFFFFFFFFu) * (maximum - minimum)) + minimum;
//}
- (NSInteger)randomIntegerBetweenMin:(NSInteger)minimum andMax:(NSInteger)maximum {
    return (NSInteger) ((((float)arc4random() / 0xFFFFFFFFu)  * (maximum - minimum)) 
                        + minimum);
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)enableUI:(BOOL)enableUI {
    
    if (! enableUI) {
        self.instructionRangeLabel.hidden = YES;
        self.myNumberField.hidden = YES;
        self.sendBarButton.enabled = NO;        
    } else {
        NSString *tempInstruction = [[NSString alloc]
                                     initWithFormat:@"Please enter a number between %d and %d",
                                     kMinimum, kMaximum];    
        self.instructionRangeLabel.text = tempInstruction;
        [tempInstruction release];
        
        theAnswer = [self randomIntegerBetweenMin:kMinimum andMax:kMaximum];
        
        self.instructionRangeLabel.hidden = NO;
        self.myNumberField.hidden = NO;
        self.sendBarButton.enabled = YES; 
        
        DLog(@"instruction range label %@", self.instructionRangeLabel.text);
        DLog(@"theAnswer = %d", theAnswer); 
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self enableUI:NO];
}
#pragma mark -


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
        self.instructionRangeLabel = nil;
        self.myNumberField = nil;
        self.opponentNumberLabel = nil;
        self.sendBarButton = nil;
    }
    [super setView:newView];
}


- (void)dealloc {
    [gameSession release], gameSession = nil;
    [instructionRangeLabel release], instructionRangeLabel = nil;
    [myNumberField release], myNumberField = nil;
    [opponentNumberLabel release], opponentNumberLabel = nil;
    [sendBarButton release], sendBarButton = nil;
    [super dealloc];
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
    // do nothing.  Make user press send button
}


#pragma mark IBActions
- (IBAction)startAGame:(id)sender {
    GKPeerPickerController *picker = [[GKPeerPickerController alloc] init];
    picker.delegate = self;
    [picker show];
    [picker release], picker = nil;
}


- (IBAction)sendNumber:(id)sender {
    [self.myNumberField resignFirstResponder];
    
    NSInteger number = [self.myNumberField.text integerValue];
    DLog(@"My number = %d", number);
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
            //			opponentID = peerID;
            //			actingAsHost ? [self hostGame] : [self joinGame];
            [self enableUI:YES];
			break;
        case GKPeerStateDisconnected: 
            [self enableUI:NO];
			break;            
    } 
}


- (void)session:(GKSession *)session
didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    //	actingAsHost = NO;
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
#pragma mark -



#pragma mark receive data handler
- (void) receiveData:(NSData *)data 
            fromPeer:(NSString *)peer 
           inSession: (GKSession *)session 
             context:(void *)context {
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSInteger theirNumber = [unarchiver decodeIntForKey:@"number"];
    NSString *numberString = [[NSString alloc] initWithFormat:@"%d", theirNumber];
    self.opponentNumberLabel.text = numberString;
    [numberString release], numberString = nil;
    [unarchiver release], unarchiver = nil;
}

@end
