/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
 Copyright (c) 2010, Janrain, Inc.
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
 * Redistributions in binary form must reproduce the above copyright notice, 
   this list of conditions and the following disclaimer in the documentation and/or
   other materials provided with the distribution. 
 * Neither the name of the Janrain, Inc. nor the names of its
   contributors may be used to endorse or promote products derived from this
   software without specific prior written permission.
 
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 
 File:	 JRPublishActivityController.h
 Author: Lilli Szafranski - lilli@janrain.com, lillialexis@gmail.com
 Date:	 Tuesday, August 24, 2010
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <UIKit/UIKit.h>
#import "JREngage.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

typedef enum
{
    NEITHER = 0,
    EMAIL_ONLY,
    SMS_ONLY,
    EMAIL_AND_SMS
} EmailOrSms;
#define EMAIL 1
#define SMS 2

@interface JRPublishActivityController : UIViewController 
                        <UINavigationBarDelegate, UITextViewDelegate, UITabBarDelegate, 
                         JRSessionDelegate, JRConnectionManagerDelegate, JRUserInterfaceDelegate,
                         UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>
{
	JRSessionData	*sessionData;
    
    BOOL iPad;
    BOOL hidesCancelButton;

    JRProvider          *selectedProvider;
    JRAuthenticatedUser *loggedInUser;
    
    JRActivityObject *activity;
    
    EmailOrSms emailOrSms;
    int selectedTab;

    BOOL weAreReady;
    BOOL weHaveJustAuthenticated;
    BOOL weAreCurrentlyPostingSomething;
    BOOL hasEditedUserContentForActivityAlready;
    BOOL userIsAttemptingToSignOut;
    
    NSDictionary *customInterface;
    NSDictionary *colorsDictionary;
    UIView		 *titleView;

    IBOutlet UIView     *myBackgroundView;
	IBOutlet UITabBar   *myTabBar;
    	    
    /* Activity Spinner and Label displayed while the list of configured providers is empty */
    NSTimer *timer;
    IBOutlet UILabel					*myLoadingLabel;
    IBOutlet UIActivityIndicatorView    *myLoadingActivitySpinner; 
    IBOutlet UIView                     *myLoadingGrayView;
    
    IBOutlet UIView *myPadGrayEditingViewTop;
    IBOutlet UIView *myPadGrayEditingViewBottom;
    
    IBOutlet UIView      *myContentView;
    
    IBOutlet UITextView  *myUserContentTextView;
    IBOutlet UIButton    *myUserContentBoundingBox;
    
    IBOutlet UIImageView *myProviderIcon;
    IBOutlet UIButton    *myInfoButton;
    IBOutlet UILabel     *myPoweredByLabel;
    
    IBOutlet UIView                  *myMediaContentView;
    IBOutlet UIView                  *myMediaViewBackgroundMiddle;
    IBOutlet UIImageView             *myMediaViewBackgroundTop;
    IBOutlet UIImageView             *myMediaViewBackgroundBottom;
    IBOutlet UIButton                *myMediaThumbnailView;
    IBOutlet UIActivityIndicatorView *myMediaThumbnailActivityIndicator;
    IBOutlet UILabel                 *myTitleLabel;
    IBOutlet UILabel                 *myDescriptionLabel;
    
    IBOutlet UIView                  *myShareToView;
    IBOutlet UIImageView             *myTriangleIcon;
    IBOutlet UIButton                *myProfilePic;
    IBOutlet UIActivityIndicatorView *myProfilePicActivityIndicator;
    IBOutlet UILabel                 *myUserName;
    IBOutlet UIButton                *myConnectAndShareButton;
    IBOutlet UIButton                *myJustShareButton;
    IBOutlet UIImageView             *mySharedCheckMark;
    IBOutlet UILabel                 *mySharedLabel;
    IBOutlet UIButton                *mySignOutButton;
    
    NSMutableDictionary *cachedProfilePics;
    NSMutableSet        *alreadyShared;
}
@property (assign) BOOL hidesCancelButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil andCustomInterface:(NSDictionary*)_customInterface;
- (IBAction)signOutButtonPressed:(id)sender;
- (IBAction)shareButtonPressed:(id)sender; 
- (IBAction)doneButtonPressed:(id)sender; 
- (IBAction)editButtonPressed:(id)sender; 
- (IBAction)infoButtonPressed:(id)sender;
@end
