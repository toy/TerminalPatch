//
//  TerminalPatch.h
//  TerminalPatch
//
//  Created by toy on 20.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (Terminal)

- (id) escapedFilename;

@end

@interface TTShell : NSObject

- (id)ptyPathNSString;
- (void)writeData:(NSData *)arg1;

@end

@interface TTTabController : NSObject

- (TTShell *) shell;

@end

@interface TTWindow : NSWindow

- (TTTabController *) selectedTabController;

@end

@interface TTApplication : NSApplication

- (TTWindow *) mainTerminalWindow;

@end

@interface NSTask (Simple)

+ (NSString *) stdoutForCommand:(NSArray *)command;

@end

@interface TerminalPatch : NSObject

+ (TTShell *) frontmostShell;
+ (NSString *) frontmostShellWorkingDir;
+ (void) cdSameDir:(void (^)())block;
+ (void) newWindowHere:(id)sender;
+ (void) newTabHere:(id)sender;

@end




































