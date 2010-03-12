//
//  GuessTheNumberAppDelegate.h
//  GuessTheNumber
//
//  Created by Steve Baker on 3/11/10.
//  Copyright Beepscore LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GuessTheNumberViewController;

@interface GuessTheNumberAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    GuessTheNumberViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet GuessTheNumberViewController *viewController;

@end

