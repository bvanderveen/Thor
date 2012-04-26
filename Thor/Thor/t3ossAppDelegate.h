//
//  t3ossAppDelegate.h
//  Thor
//
//  Created by Adron Hall on 4/25/12.
//  Copyright (c) 2012 Three Step Solutions. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface t3ossAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
