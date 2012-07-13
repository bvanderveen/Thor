//
//  ThorCoreTests.m
//  ThorCoreTests
//
//  Created by Benjamin van der Veen on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ThorCoreTests.h"

@implementation ThorBackendTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (NSArray *)givenConfiguredApps {
    
}

- (NSArray *)whenIGetConfiguredApps {
    
}

- (void)assertActualApps:(NSArray *)actualApps equalExpectedApps:(NSArray *)expectedApps {
    
}

- (void)testGetConfiguredAppsReadsLocalConfiguration {
    NSArray *expectedApps = [self givenConfiguredApps];
    
    NSArray *actualApps = [self whenIGetConfiguredApps];
    
    [self assertActualApps:actualApps equalExpectedApps:expectedApps];
}

- (void)testCreateConfiguredAppAmendsLocalConfiguration {
    
}

- (void)testCreateConfiguredAppThrowsExceptionIfAppLocalPathIsPreviouslyUsed {
}

- (void)testCreateConfiguredAppThrowsExceptionIfAppDefaultMemoryIsOutOfRange {
}

- (void)testCreateConfiguredAppThrowsExceptionIfAppDefaultInstancesIsOutOfRange {
}

- (void)testUpdateConfiguredAppUpdatesLocalConfiguration {
}

- (void)testUpdateConfiguredAppThrowsExceptionIfAppLocalPathIsPreviouslyUsed {
}

- (void)testUpdateConfiguredAppThrowsExceptionIfAppDefaultMemoryIsOutOfRange {
}

- (void)testUpdateConfiguredAppThrowsExceptionIfAppDefaultInstancesIsOutOfRange {
}

- (void)testGetConfiguredTargetsReadsLocalConfiguration {
}

- (void)testCreateConfiguredTargetAmendsLocalConfiguration {
}

- (void)testCreateConfiguredTargetThrowsExceptionIfCredentialsAreInvalid {
}

- (void)testCreateConfiguredTargetThrowsExceptionIfHostnameIsPreviouslyUsed {
}

- (void)testCreateConfiguredTargetThrowsExceptionIfHostnameIsInvalid {
    
}

@end
