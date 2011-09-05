    //
//  GameList.m
//  MapAttack
//
//  Created by Aaron Parecki on 2011-08-31.
//  Copyright 2011 Geoloqi.com. All rights reserved.
//

#import "GameListViewController.h"
#import "LQClient.h"
#import "LQConfig.h"
#import "MapAttackAppDelegate.h"

@implementation GameListViewController

@synthesize reloadBtn, tableView, gameCell, games, selectedIndex;

- (void)dealloc {
	[games release];
	[gameCell release];
	[selectedIndex release];
	[tableView release];
	[reloadBtn release];
    [super dealloc];
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	games = [[NSMutableArray alloc] init];
	[self getNearbyLayers];
}

- (IBAction)reloadBtnPressed {
	[self getNearbyLayers];
}

- (IBAction)logoutBtnPressed {
	[[LQClient single] logout];
}

- (void)getNearbyLayers {
	[[LQClient single] getNearbyLayers:^(NSError *error, NSDictionary *response){
		self.games = [response objectForKey:@"nearby"];
		[self.tableView reloadData];
	}];
}

- (NSString *)urlForGameAtIndex:(NSInteger)index {
	return [[self.games objectAtIndex:index] objectForKey:@"url"];
}

- (NSString *)layerIDForGameAtIndex:(NSInteger)index {
	return [[self.games objectAtIndex:index] objectForKey:@"layer_id"];
}

- (NSString *)groupTokenForGameAtIndex:(NSInteger)index {
	return [[self.games objectAtIndex:index] objectForKey:@"group_token"];
}

#pragma mark -
#pragma mark Table View

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 65;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		default:
			return [self.games count];
	}
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *myIdentifier = @"GameCell";
	
	GameCell *cell = (GameCell *)[t dequeueReusableCellWithIdentifier:myIdentifier];
	
	if(cell == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"GameCell" owner:self options:nil];
		cell = gameCell;
	}

	id game = [self.games objectAtIndex:indexPath.row];
	[cell setNameText:[game objectForKey:@"name"]];
	[cell setDescriptionText:[game objectForKey:@"description"]];
	 
	return cell;
}

- (void)authenticationDidSucceed:(NSNotificationCenter *)notification {
	[[LQClient single] joinGame:[self layerIDForGameAtIndex:selectedIndex.row] withToken:[self groupTokenForGameAtIndex:selectedIndex.row]];

	// If they're not logged in, then loadGameWithURL will first pop up a login screen
	[lqAppDelegate loadGameWithURL:[NSString stringWithFormat:MapAttackGameURLFormat, [self layerIDForGameAtIndex:selectedIndex.row]]];

    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:LQAuthenticationSucceededNotification 
                                                  object:nil];
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	DLog(@"Selected game %d", indexPath.row);
	[t deselectRowAtIndexPath:indexPath animated:NO];
	self.selectedIndex = indexPath;

	// If they're not logged in, wait until after the authentication succeed broadcast received, then join the game
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(authenticationDidSucceed:)
												 name:LQAuthenticationSucceededNotification
											   object:nil];		
	
	if([[LQClient single] isLoggedIn]) {
		// If they're logged in, immediately make a call to the game server to join the game
		[self authenticationDidSucceed:nil];
	} else {
		[lqAppDelegate.tabBarController presentModalViewController:[[AuthView alloc] init] animated:YES];
	}
}

#pragma mark -

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


@end
