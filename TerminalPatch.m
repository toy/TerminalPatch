//
//  TerminalPatch.m
//  TerminalPatch
//
//  Created by toy on 20.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TerminalPatch.h"

@implementation NSTask (Simple)

+ (NSString *) stdoutForCommand:(NSArray *)command {
	NSTask *task = [[NSTask alloc] init];
	NSPipe *stdoutPipe = [NSPipe pipe];
	NSFileHandle *stdoutHandle = [stdoutPipe fileHandleForReading];

	[task setLaunchPath:@"/usr/bin/env"];
	[task setArguments:command];
	[task setStandardOutput:stdoutPipe];

	[task launch];
	[task waitUntilExit];
	[task release];

	return [[[NSString alloc] initWithData:[stdoutHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
}

@end

@implementation TerminalPatch

+ (void) load {
	NSMenu *shellMenu = [[[NSApp mainMenu] itemWithTitle:@"Shell"] submenu];

	NSUInteger newWindowIndex = [shellMenu indexOfItemWithTitle:@"New Window"];
	NSMenuItem *newWindowHereItem = [shellMenu insertItemWithTitle:@"New Window Here" action:@selector(newWindowHere:) keyEquivalent:@"n" atIndex:newWindowIndex + 1];
	[newWindowHereItem setTarget:self];
	[newWindowHereItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask];

	NSUInteger newTabIndex = [shellMenu indexOfItemWithTitle:@"New Tab"];
	NSMenuItem *newTabHereItem = [shellMenu insertItemWithTitle:@"New Tab Here" action:@selector(newTabHere:) keyEquivalent:@"t" atIndex:newTabIndex + 1];
	[newTabHereItem setTarget:self];
	[newTabHereItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask];

	NSLog(@"TerminalPatch loaded");
}

+ (TTShell *) frontmostShell {
	return [[[NSApp mainTerminalWindow] selectedTabController] shell];
}

+ (NSString *) frontmostShellWorkingDir {
	NSMutableArray *paths = [NSMutableArray arrayWithObject:[@"~" stringByExpandingTildeInPath]];

	NSString *tty = [[self frontmostShell] ptyPathNSString];

	if (tty && [tty length] > 0) {
		NSCharacterSet *numberSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];

		NSArray *psCommand = [NSArray arrayWithObjects:@"ps", @"-t", tty, @"-o", @"pid", nil];
		NSString *psStdout = [NSTask stdoutForCommand:psCommand];

		NSMutableArray *pids = [NSMutableArray array];
		NSString *pid;
		NSScanner *psScanner = [NSScanner scannerWithString:psStdout];
		while (NO == [psScanner isAtEnd]) {
			[psScanner scanUpToCharactersFromSet:numberSet intoString:NULL];
			if ([psScanner scanCharactersFromSet:numberSet intoString:&pid]) {
				[pids addObject:pid];
			}
		}

		if ([pids count] > 0) {
			NSArray *lsofCommand = [NSArray arrayWithObjects:@"lsof", @"-a", @"-p", [pids componentsJoinedByString:@","], @"-d", @"cwd", @"-F", @"n", nil];
			NSString *lsofStdout = [NSTask stdoutForCommand:lsofCommand];

			[lsofStdout enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
				if ([line hasPrefix:@"n"] && ![line isEqualToString:@"n/"]) {
					[paths addObject:[line substringFromIndex:1]];
				}
			}];
		}
	}

	return [paths lastObject];
}

+ (void) cdSameDir:(void (^)())block {
	NSString *dir = [self frontmostShellWorkingDir];
	NSString *command = [@" printf %b \\\\ec && cd " stringByAppendingString:[dir escapedFilename]];

	block();

	[[self frontmostShell] writeData:[[command stringByAppendingString:@"\r"] dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (void) newWindowHere:(id)sender {
	[self cdSameDir:^() {
		[NSApp sendAction:@selector(newShell:) to:nil from:sender];
	}];
}

+ (void) newTabHere:(id)sender {
	[self cdSameDir:^() {
		[NSApp sendAction:@selector(newTab:) to:nil from:sender];
	}];
}

@end
