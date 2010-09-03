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
 
 File:	 JRProvidersController.m
 Author: Lilli Szafranski - lilli@janrain.com, lillialexis@gmail.com
 Date:	 Tuesday, June 1, 2010
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


#import "JRProvidersController.h"

// TODO: Figure out why the -DDEBUG cflag isn't being set when Active Conf is set to debug
// TODO: Take this out of the production app
#define DEBUG
#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define DLog(...)
#endif

#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

UIViewController* TTOpenURL(NSString* URL);

@interface UITableViewCellProviders : UITableViewCell 
{
	UIImageView *icon;
}

@property (nonatomic, retain) UIImageView *icon;

@end

@implementation UITableViewCellProviders

@synthesize icon;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
	{
		[self addSubview:icon];
	}
	
	return self;
}	

- (void) layoutSubviews 
{
	[super layoutSubviews];

	self.imageView.frame = CGRectMake(10, 10, 30, 30);
	self.textLabel.frame = CGRectMake(50, 15, 100, 22);
}
@end

@implementation JRProvidersController

@synthesize myTableView;
@synthesize myLoadingLabel;
@synthesize myActivitySpinner;
@synthesize myImageView;

/*
// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		jrAuth = [JRAuthenticate jrAuthenticate];
		[jrAuth retain];
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	DLog(@"");
	[super viewDidLoad];
	
	jrAuth = [[JRAuthenticate jrAuthenticate] retain];
	sessionData = [[((JRModalNavigationController*)[[self navigationController] parentViewController]) sessionData] retain];	

	titleImageView = nil;
	
	myTableView.backgroundColor = [UIColor clearColor];
	
	/* Check the session data to see if there's information on the last provider the user logged in with. */
	if (sessionData.returningProvider)
	{
		DLog(@"and there was a returning provider");
		[sessionData setCurrentProviderToReturningProvider];
		
		/* If so, go straight to the returning provider screen. */
		[[self navigationController] pushViewController:((JRModalNavigationController*)[self navigationController].parentViewController).myUserLandingController
											   animated:NO]; 
	}
	
	UIView* containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
	containerView.backgroundColor = [UIColor clearColor];
	
	UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, 300, 25)];
	headerLabel.font = [UIFont boldSystemFontOfSize:15];
	headerLabel.textAlignment = UITextAlignmentCenter;
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.text = @"use your existing account!";
	
	[containerView addSubview:headerLabel];
	[headerLabel release];
	myTableView.tableHeaderView = containerView;
	[containerView release];
	
	/* Load the table with the list of providers. */
	[myTableView reloadData];
	
	/* Reposition the background image */
	myImageView.frame = CGRectOffset([UIScreen mainScreen].bounds, 0, -64);
}


- (void)viewWillAppear:(BOOL)animated 
{
	DLog(@"");
	[super viewWillAppear:animated];
	
	self.title = @"Providers";

	if (!titleImageView)
	{
		titleImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sign-in.png"]] autorelease];
		self.navigationItem.titleView = titleImageView;
	}
	
	self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] 
											  initWithTitle:@"back"
											  style:UIBarButtonItemStyleBordered
											  target:nil
											  action:nil] autorelease];
	
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] 
									 initWithTitle:@"cancel"
									  style:UIBarButtonItemStyleBordered
									  target:[self navigationController].parentViewController
									 action:@selector(cancelButtonPressed:)] autorelease];

	self.navigationItem.leftBarButtonItem = cancelButton;
	self.navigationItem.leftBarButtonItem.enabled = YES;
	
	self.navigationItem.leftBarButtonItem.style = UIBarButtonItemStyleBordered;
	
	UIBarButtonItem *placeholderItem = [[[UIBarButtonItem alloc] 
										initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
										target:nil
										action:nil] autorelease];

	placeholderItem.width = 85;
	self.navigationItem.rightBarButtonItem = placeholderItem;
	
	if (!infoBar)
	{
		if (!sessionData || [sessionData hidePoweredBy])
			infoBar = [[JRInfoBar alloc] initWithFrame:CGRectMake(0, 388, 320, 30) andStyle:JRInfoBarStyleHidePoweredBy];
		else
			infoBar = [[JRInfoBar alloc] initWithFrame:CGRectMake(0, 388, 320, 30) andStyle:JRInfoBarStyleShowPoweredBy];
		[self.view addSubview:infoBar];
	}

	DLog(@"prov count = %d", [sessionData.configedProviders count]);
	
	/* If the user calls the library before the session data object is done initializing - 
	   because either the requests for the base URL or provider list haven't returned - 
	   display the "Loading Providers" label and activity spinner. 
	   sessionData = nil when the call to get the base URL hasn't returned
	   [sessionData.configuredProviders count] = 0 when the provider list hasn't returned */
	if (!sessionData || [sessionData.configedProviders count] == 0)
	{
		[myActivitySpinner setHidden:NO];
		[myLoadingLabel setHidden:NO];
		
		[myActivitySpinner startAnimating];
		
		/* Now poll every few milliseconds, for about 16 seconds, until the provider list is loaded or we time out. */
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkSessionDataAndProviders:) userInfo:nil repeats:NO];
	}
	else 
	{
		[myTableView reloadData];
		[infoBar fadeIn];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[(JRModalNavigationController*)[self navigationController].parentViewController dismissModalNavigationController:NO];	
}

/* If the user calls the library before the session data object is done initializing - 
   because either the requests for the base URL or provider list haven't returned - 
   keep polling every few milliseconds, for about 16 seconds, 
   until the provider list is loaded or we time out. */
- (void)checkSessionDataAndProviders:(NSTimer*)theTimer
{
	static NSTimeInterval interval = 0.125;
	interval = interval * 2;
	
	DLog(@"prov count = %d", [sessionData.configedProviders count]);
	DLog(@"interval = %f", interval);
	
	/* If sessionData was nil in viewDidLoad and viewWillAppear, but it isn't nil now, set the sessionData variable. */
	if (!sessionData && [((JRModalNavigationController*)[[self navigationController] parentViewController]) sessionData])
		sessionData = [[((JRModalNavigationController*)[[self navigationController] parentViewController]) sessionData] retain];	

	/* If we have our list of providers, stop the progress indicators and load the table. */
	if ([sessionData.configedProviders count] != 0)
	{
		[myActivitySpinner stopAnimating];
		[myActivitySpinner setHidden:YES];
		[myLoadingLabel setHidden:YES];
		
		[myTableView reloadData];
	
		return;
	}
	
	/* Otherwise, keep polling until we've timed out. */
	if (interval >= 15.0)
	{	
		DLog(@"No Available Providers");

		[myActivitySpinner setHidden:YES];
		[myLoadingLabel setHidden:YES];
		[myActivitySpinner stopAnimating];
		
		UIApplication* app = [UIApplication sharedApplication]; 
		app.networkActivityIndicatorVisible = YES;
			
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No Available Providers"
														 message:@"There seems to be a problem connecting.  Please try again later."
														delegate:self
											   cancelButtonTitle:@"OK" 
											   otherButtonTitles:nil] autorelease];
		[alert show];
		return;
	}
	
	[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(checkSessionDataAndProviders:) userInfo:nil repeats:NO];
}

- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	
	// TODO: Only compile in debug version
	NSArray *vcs = [self navigationController].viewControllers;
	DLog(@"");
	for (NSObject *vc in vcs)
	{
		DLog(@"view controller: %@", [vc description]);
	}
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	// return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

/* Footer makes room for info bar.  If info bar is removed, remove the footer as well. */
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 37)] autorelease];
	return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	if (section == 1)
		return 37;
	return 0;
}

- (CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1) {
		return 60;
	}
	return 50;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section 
{
	if (section == 0) {
		return [sessionData.configedProviders count];
	}
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section == 1) {
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"privacyCell"];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewStyleGrouped reuseIdentifier:@"privacyCell"] autorelease];
			UIWebView* webView = [[[UIWebView alloc] initWithFrame:CGRectMake(3, 3, 300 - 6, 60 - 6)] autorelease];
			webView.delegate = self;
			NSString* css = @"p {top:-2px;font-size:12px;position:relative;color:#666666;font-family:sans-serif;} a {color:#ED139A;}";
			NSString* html = [NSString stringWithFormat:@"<html><head><style>%@</style></head><body><p>by continuing you agree to our <a href='http://www.gotryiton.com/terms.php'>terms and conditions of use</a>, <a href='http://www.gotryiton.com/terms.php'>privacy policy</a>, <a href='http://www.gotryiton.com/terms.php'>legal terms</a>, and <a href='http://www.gotryiton.com/community-standards.php'>community standards</a>.</p></body></html>", css];
			[webView loadHTMLString:html baseURL:nil];
			[cell.contentView addSubview:webView];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	}
	UITableViewCellProviders *cell = 
	(UITableViewCellProviders*)[tableView dequeueReusableCellWithIdentifier:@"cachedCell"];
	
	if (cell == nil)
		cell = [[[UITableViewCellProviders alloc] 
				 initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cachedCell"] autorelease];
	
	// TODO: Add error handling for the case where there may be an error retrieving the provider stats.
	// Shouldn't happen, unless the response from rpxnow becomes malformed in the future, but just in case.
	NSString *provider = [sessionData.configedProviders objectAtIndex:indexPath.row];
	NSDictionary* provider_stats = [sessionData.allProviders objectForKey:provider];
	
	NSString *friendly_name = [provider_stats objectForKey:@"friendly_name"];
	NSString *imagePath = [NSString stringWithFormat:@"jrauth_%@_icon.png", provider];
	
	DLog(@"cell for %@", provider);
	cell.textLabel.font = [UIFont boldSystemFontOfSize:15];

#if __IPHONE_3_0
	cell.textLabel.text = friendly_name;
#else
	cell.text = friendly_name;
#endif

#if __IPHONE_3_0
	// TODO: Add error handling in the case that the icon can't be loaded. (Like moving the textLabel over?)
	// Shouldn't happen, but just in case.
	cell.imageView.image = [UIImage imageNamed:imagePath];
#else
	cell.image = [UIImage imageNamed:imagePath];
#endif

	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1) {
		return;
	}
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	/* Let sessionData know which provider the user selected */
	NSString *provider = [sessionData.configedProviders objectAtIndex:indexPath.row];
	[sessionData setProvider:[NSString stringWithString:provider]];

	DLog(@"cell for %@ was selected", provider);

	/* If the selected provider requires input from the user, go to the user landing view.
	   Or if the user started on the user landing page, went back to the list of providers, then selected 
	   the same provider as their last-used provider, go back to the user landing view. */
	if (sessionData.currentProvider.providerRequiresInput || [provider isEqualToString:sessionData.returningProvider.name]) 
	{	
		[[self navigationController] pushViewController:((JRModalNavigationController*)[self navigationController].parentViewController).myUserLandingController
											   animated:YES]; 
	}
	/* Otherwise, go straight to the web view. */
	else
	{
		[[self navigationController] pushViewController:((JRModalNavigationController*)[self navigationController].parentViewController).myWebViewController
											   animated:YES]; 
	}	
}

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewWillDisappear:(BOOL)animated
{
	[infoBar fadeOut];
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)viewDidUnload	
{
	[super viewDidUnload];
}

- (void)dealloc 
{
	DLog(@"");

	[jrAuth release];
	[sessionData release];

	[myTableView release];
	[myLoadingLabel release];
	[myActivitySpinner release];
	[infoBar release];
    
	[super dealloc];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if ([[request.URL absoluteString] isEqualToString:@"about:blank"]) {
		return YES;
	}
//	[[UIApplication sharedApplication] openURL:request.URL];
//	[[UIApplication sharedApplication].delegate application:[UIApplication sharedApplication] handleOpenURL:request.URL];
	Class navigator = NSClassFromString(@"TTNavigator");
	UIViewController* viewController = [[navigator navigator] viewControllerForURL:[request.URL absoluteString]];
	[viewController openRequest:request];
	[self.navigationController pushViewController:viewController animated:YES];
	return NO;
}

@end
