/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

#import "HBLOListController.h"
#import "HBLOFooterCell.h"
#import "../HBLOGlobal.h"
#include <notify.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

@implementation HBLOListController

@synthesize view = _view;

- (id)initForContentSize:(CGSize)size {
	self = [super init];

	if (self) {
		self.navigationItem.title = @"Opener";

		_view = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
		_view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_view.delegate = self;
		_view.dataSource = self;

		_prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFS_PATH] ?: [[NSMutableDictionary alloc] init];

		NSDictionary *callback = [[CPDistributedMessagingCenter centerNamed:@"ws.hbang.libopener.server"] sendMessageAndReceiveReplyName:@"GetHandlers" userInfo:nil];

		if (callback) {
			_handlers = [[[callback objectForKey:@"Handlers"] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] retain];
		}
	}
	return self;
}

- (void)dealloc {
	[_view release];
	[_prefs release];
	[_handlers release];
	
	[super dealloc];
}

#pragma mark - Preferences.framework stuff

- (CGSize)contentSize {
	return _view.frame.size;
}

- (UITableView *)table {
	return _view;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 1:
			return _handlers.count;
			break;

		case 3:
			return 1;
			break;

		default:
			return 0;
			break;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return _handlers.count == 0 ? nil : @"Handlers";
			break;

		default:
			return nil;
			break;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return _handlers.count == 0 ? @"Opener is a developer library for overriding link destinations - for example, to redirect opening a YouTube link in Safari to a 3rd-party YouTube app.\n\nYou currently don’t have any handler packages installed. This can happen after uninstalling all packages that depend on Opener, such as MapsOpener and YTOpener. To remove this Settings page, search for “Opener” in Cydia, then tap Modify and Remove.\n" : @"Turn off handlers below to prevent them from overriding URLs.";
			break;

		case 2:
			return @"Opener Version 1.1\nBy HASHBANG Productions";
			break;

		default:
			return nil;
			break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case 1:
		{
			static NSString *ReuseIdentifier = @"LibOpenerHandlerCell";

			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];

			if (!cell) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseIdentifier];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;

				cell.accessoryView = [[UISwitch alloc] init];
				cell.accessoryView.tag = indexPath.row;
				[(UISwitch *)cell.accessoryView addTarget:self action:@selector(didToggleSwitch:) forControlEvents:UIControlEventValueChanged];
			}

			cell.textLabel.text = [_handlers objectAtIndex:indexPath.row];
			((UISwitch *)cell.accessoryView).on = [_prefs objectForKey:[_handlers objectAtIndex:indexPath.row]] ? [[_prefs objectForKey:[_handlers objectAtIndex:indexPath.row]] boolValue] : YES;

			return cell;
			break;
		}

		case 3:
		{
			static NSString *ReuseIdentifier = @"LibOpenerFooterCell";

			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];

			if (!cell) {
				cell = [[HBLOFooterCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseIdentifier];
			}

			return cell;
			break;
		}

		default:
		{
			return nil;
			break;
		}
	}
}

#pragma mark - UISwitch Delegate

-(void)didToggleSwitch:(UISwitch *)sender {
	[_prefs setObject:[NSNumber numberWithBool:sender.on] forKey:[_handlers objectAtIndex:sender.tag]];
	[_prefs writeToFile:PREFS_PATH atomically:YES];

	notify_post("ws.hbang.libopener/ReloadPrefs");
}

@end
