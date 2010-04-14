/* 
 Copyright (c) 2010, Janrain, Inc.
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer. 
 * Redistributions in binary
 form must reproduce the above copyright notice, this list of conditions and the
 following disclaimer in the documentation and/or other materials provided with
 the distribution. 
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
 */


#import "JRSessionData.h"

@implementation JRProvider

- (JRProvider*)initWithName:(NSString*)nm andStats:(NSDictionary*)stats
{
	[super init];
	
	providerStats = [[NSDictionary dictionaryWithDictionary:stats] retain];
	name = [nm retain];

	welcomeString = nil;
	
	placeholderText = nil;
	shortText = nil;
	userInput = nil;
	friendlyName = nil;
	providerRequiresInput = NO;
	
	return self;
}

- (NSString*)name
{
	return name;
}

- (NSString*)friendlyName 
{
	return [providerStats objectForKey:@"friendly_name"];
}

- (NSString*)placeholderText
{
	return [providerStats objectForKey:@"input_prompt"];
}

- (NSString*)shortText
{
	if (self.providerRequiresInput)
	{
		NSArray *arr = [[self.placeholderText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@" "];
		NSRange subArr = {[arr count] - 2, 2};
		
		NSArray *newArr = [arr subarrayWithRange:subArr];
		return [newArr componentsJoinedByString:@" "];	
	}
	else 
	{
		return @"";
	}
}

- (NSString*)userInput
{
	return userInput;
}

- (void)setUserInput:(NSString*)ui
{
	userInput = [ui retain];
}

- (void)setWelcomeString:(NSString*)ws
{
	welcomeString = [ws retain];
}

- (NSString*)welcomeString
{
	return welcomeString;
}

- (BOOL)providerRequiresInput
{
	if ([[providerStats objectForKey:@"requires_input"] isEqualToString:@"YES"])
		 return YES;
		
	return NO;
}

- (void)dealloc
{
	[providerStats release];
	[name release];
	[welcomeString release];
	[userInput release];
	
	[super dealloc];
}
@end

@interface JRSessionData()
- (void)startGetConfiguredProviders;
- (void)finishGetConfiguredProviders:(NSString*)dataStr;

- (void)startGetAllProviders;
- (void)finishGetAllProviders:(NSString*)dataStr;

- (void)loadAllProviders;
- (void)loadCookieData;
@end



@implementation JRSessionData
@synthesize errorStr;

@synthesize allProviders;
@synthesize configedProviders;

@synthesize currentProvider;
@synthesize returningProvider;

@synthesize forceReauth;

- (id)initWithBaseUrl:(NSString*)URL
{
	if (self = [super init]) 
	{
		baseURL = [[NSString stringWithString:URL] retain];
		
		currentProvider = nil;
		returningProvider = nil;
	
		allProviders = nil;
		configedProviders = nil;
	
		errorStr = nil;
		forceReauth = NO;
		
		[self startGetConfiguredProviders];
		[self loadAllProviders];
		[self loadCookieData];
	}
	return self;
}

- (void)dealloc 
{
	NSLog(@"JRSessionData dealloc");

	[allProviders release];
	[configedProviders release];
	
	[currentProvider release];
	[returningProvider release];
	
	[baseURL release];
	[errorStr release];
	
	[super dealloc];
}

- (NSURL*)startURL
{
	NSDictionary *providerStats = [allProviders objectForKey:currentProvider.name];
	NSMutableString *oid;
	
	if ([providerStats objectForKey:@"openid_identifier"])
	{
		oid = [NSMutableString stringWithString:[providerStats objectForKey:@"openid_identifier"]];
		
		if(currentProvider.userInput)
		{
			[oid replaceOccurrencesOfString:@"%s" withString:[currentProvider.userInput stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] options:NSLiteralSearch range:NSMakeRange(0, [oid length])];
		}
		oid = [[@"openid_identifier=" stringByAppendingString:oid] stringByAppendingString:@"&"];
	}
	else 
	{
		oid = [NSMutableString stringWithString:@""];
	}
	
	NSString* str = [NSString stringWithFormat:@"%@%@?%@%@device=iphone", baseURL, [providerStats objectForKey:@"url"], oid, ((forceReauth)? @"force_reauth=true&" : @"")];
	
	forceReauth = NO;
	
	return [NSURL URLWithString:str];
}


- (void)loadCookieData
{
	NSHTTPCookieStorage* cookieStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [cookieStore cookiesForURL:[NSURL URLWithString:baseURL]];
	
	NSString *welcomeString = nil;
	NSString *provider = nil;
	NSString *userInput = nil;
		
	for (NSHTTPCookie *cookie in cookies) 
	{
		if ([cookie.name isEqualToString:@"welcome_info"])
		{
			welcomeString = [NSString stringWithString:cookie.value];
		}
		else if ([cookie.name isEqualToString:@"login_tab"])
		{
			provider = [NSString stringWithString:cookie.value];
		}
		else if ([cookie.name isEqualToString:@"user_input"])
		{
			userInput = [NSString stringWithString:cookie.value];
		}
	}	
	
	if (provider)
	{
		returningProvider = [[JRProvider alloc] initWithName:provider andStats:[allProviders objectForKey:provider]];
		
		if (welcomeString)
			[returningProvider setWelcomeString:welcomeString];
		if (userInput)
			[returningProvider setUserInput:userInput];
		
	}
}


- (void)loadAllProviders
{
	NSString	 *path = nil;
	NSFileHandle *readHandle = nil;
	NSString	 *provList = nil;
	NSDictionary *jsonDict = nil;
	
	path = [[NSBundle mainBundle] pathForResource:@"provider_list" ofType:@"json"];
	
	if(!path) // Then there was an error
		return; // TODO: manage error and memory
	
	readHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	
	if(!readHandle)  // Then there was an error
		return; // TODO: manage error and memory
	
	provList = [[NSString alloc] initWithData:[readHandle readDataToEndOfFile] 
									 encoding:NSUTF8StringEncoding];
	
	if(!provList) // Then there was an error
		return; // TODO: manage error and memory
	
	jsonDict = [provList JSONValue];
	
	if(!jsonDict) // Then there was an error
		return; // TODO: manage error and memory
	
	allProviders = [NSDictionary dictionaryWithDictionary:[jsonDict objectForKey:@"providers"]];
	[allProviders retain];
	
	printf("finishloadAllProviders\n");
}


- (void)startGetAllProviders
{
	NSString *urlString = @"http://rpxnow.com/iphone/providers";
	
	NSURL *url = [NSURL URLWithString:urlString];
	
	if(!url) // Then there was an error
		return;
	
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL: url];
	
	NSString *tag = [NSString stringWithFormat:@"getAllProviders"];
	[tag retain];
	
	//	if (![self createConnectionFromRequest:request])
	if (![JRConnectionManager createConnectionFromRequest:request forDelegate:self withTag:tag])
		errorStr = [NSString stringWithFormat:@"There was an error initializing JRAuthenticate.\nThere was a problem getting the list of all providers."];
}

- (void)finishGetAllProviders:(NSString*)dataStr
{
	NSDictionary *jsonDict = [dataStr JSONValue];
	
	if(!jsonDict) // Then there was an error
		return;
	
	allProviders = [NSDictionary dictionaryWithDictionary:[jsonDict objectForKey:@"providers"]];
	[allProviders retain];
}


- (void)startGetConfiguredProviders
{
	NSString *urlString = [baseURL stringByAppendingString:@"/openid/ui_config"];
	
	NSURL *url = [NSURL URLWithString:urlString];
	
	if(!url) // Then there was an error
		return;
	
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL: url];
	
	NSString *tag = [NSString stringWithFormat:@"getConfiguredProviders"];
	[tag retain];
	
	if (![JRConnectionManager createConnectionFromRequest:request forDelegate:self withTag:tag])
		errorStr = [NSString stringWithFormat:@"There was an error initializing JRAuthenticate.\nThere was a problem getting the list of configured providers."];
}

- (void)finishGetConfiguredProviders:(NSString*)dataStr
{
	printf("finishGetConfiguredProviders\n");
	NSDictionary *jsonDict = [dataStr JSONValue];
	
	if(!jsonDict)
		return;
	
	configedProviders = [NSArray arrayWithArray:[jsonDict objectForKey:@"enabled_providers"]];
	
	if(configedProviders)
		[configedProviders retain];
	
	
	printf("jsonDict retain count: %d\n", [jsonDict retainCount]);
	printf("configed providers retain count: %d\n", [configedProviders retainCount]);
}


- (void)connectionDidFinishLoadingWithPayload:(NSString*)payload request:(NSURLRequest*)request andTag:(void*)userdata
{
	NSString* tag = (NSString*)userdata;
	
	if ([tag isEqualToString:@"getConfiguredProviders"])
	{
		if ([payload rangeOfString:@"\"provider_info\":{"].length != 0)
		{
			[self finishGetConfiguredProviders:payload];
		}
		else // There was an error...
		{
			errorStr = [NSString stringWithFormat:@"There was an error initializing JRAuthenticate.\nThere was an error in the response to a request."];
		}
	}
	
	[tag release];	
}

- (void)setReturningProviderToProvider:(JRProvider*)provider
{
	[returningProvider release];
	returningProvider = [provider retain];
}

- (void)connectionDidFailWithError:(NSError*)error request:(NSURLRequest*)request andTag:(void*)userdata 
{
	NSString* tag = (NSString*)userdata;
	
	if ([tag isEqualToString:@"getBaseURL"])
	{
		errorStr = [NSString stringWithFormat:@"There was an error initializing JRAuthenticate.\nThere was an error in the response to a request."];
	}
	else if ([tag isEqualToString:@"getConfiguredProviders"])
	{
		errorStr = [NSString stringWithFormat:@"There was an error initializing JRAuthenticate.\nThere was an error in the response to a request."];
	}
	
	[tag release];	
}

- (void)connectionWasStoppedWithTag:(void*)userdata 
{
	[(NSString*)userdata release];
}

- (void)setCurrentProviderToReturningProvider
{
	currentProvider = [returningProvider retain];
}

- (void)setProvider:(NSString *)prov
{
	if (![currentProvider.name isEqualToString:prov])
	{	
		[currentProvider release];
		
		if ([returningProvider.name isEqualToString:prov])
			[self setCurrentProviderToReturningProvider];
		else
			currentProvider = [[[JRProvider alloc] initWithName:prov andStats:[allProviders objectForKey:prov]] retain];
	}

	[currentProvider retain];
}


@end
