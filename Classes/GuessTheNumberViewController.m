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

@synthesize session;
// instantiated in nib file
@synthesize numberField;
@synthesize opponentNumber;
@synthesize sendBarButton;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    self.sendBarButton.enabled = NO;
    self.numberField.hidden = YES;
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
        self.session = nil;
        self.numberField = nil;
        self.opponentNumber = nil;
        self.sendBarButton = nil;
    }
    [super setView:newView];
}


- (void)dealloc {
    [session release], session = nil;
    [numberField release], numberField = nil;
    [opponentNumber release], opponentNumber = nil;
    [sendBarButton release], sendBarButton = nil;
    [super dealloc];
}


#pragma mark UI interaction
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

#pragma mark IBAction

- (IBAction)startAGame:(id)sender {
    GKPeerPickerController *picker = [[GKPeerPickerController alloc] init];
    picker.delegate = self;
    [picker show];
    [picker release], picker = nil;
}


- (IBAction)sendNumber:(id)sender {
    [self.numberField resignFirstResponder];
    
    NSInteger number = [self.numberField.text integerValue];
    DLog(@"My number = %d", number);
    NSMutableData *message = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:message];
    [archiver encodeInt:number forKey:@"number"];
    [archiver finishEncoding];
    [self.session sendDataToAllPeers:message withDataMode:GKSendDataReliable error:NULL];
    [archiver release], archiver = nil;
    [message release], message = nil;
}

#pragma mark GKPeerPickerControllerDelegate
- (void)peerPickerController:(GKPeerPickerController *)picker 
              didConnectPeer:(NSString *)peerID 
                   toSession:(GKSession *)newSession {
    self.session = newSession;
    [self.session setDataReceiveHandler:self withContext:NULL];
    NSLog(@"Peer: %@", peerID);
    [picker dismiss];
    
    self.numberField.hidden = NO;
    self.sendBarButton.enabled = YES;
}


// TODO: implement session ended, disable sendBarButton

#pragma mark receive data handler

- (void) receiveData:(NSData *)data 
            fromPeer:(NSString *)peer 
           inSession: (GKSession *)session 
             context:(void *)context {
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSInteger theirNumber = [unarchiver decodeIntForKey:@"number"];
    NSString *numberString = [[NSString alloc] initWithFormat:@"%d", theirNumber];
    self.opponentNumber.text = numberString;
    [numberString release], numberString = nil;
    [unarchiver release], unarchiver = nil;
}



@end
