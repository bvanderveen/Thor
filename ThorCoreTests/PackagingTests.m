#import "PackagingTests.h"
#import "Packaging.h"
#import "Specta.h"
#define EXP_SHORTHAND
#import "Expecta.h"
#import "SBJson/SBJson.h"

@interface FSUtils : NSObject

@end

@implementation FSUtils

- (NSURL *)temporaryFileURLFromPath:(NSString *)path {
    return [NSURL fileURLWithPath:[NSString pathWithComponents:[@[NSTemporaryDirectory(), @"ThorTestsFSUtilsTemp"] arrayByAddingObjectsFromArray:path.pathComponents]]];
}

- (void)removeTemporaryFiles {
    [self deleteFile:[NSURL fileURLWithPath:[NSString pathWithComponents:@[NSTemporaryDirectory(), @"ThorTestsFSUtilsTemp"]]]];
}

- (void)createDirectory:(NSURL *)directoryURL {
    [[NSFileManager defaultManager] createDirectoryAtPath:directoryURL.path withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)createFile:(NSURL *)fileURL withContents:(NSData *)contents {
    [[NSFileManager defaultManager] createFileAtPath:fileURL.path contents:contents attributes:nil];
}

- (void)deleteFile:(NSURL *)fileURL {
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
}

@end

SpecBegin(Packaging)

describe(@"Packaging", ^{
    FSUtils *fs = [[FSUtils alloc] init];
    Packaging *packaging = [[Packaging alloc] init];
    
    afterEach(^{
        [fs removeTemporaryFiles];
    });
    
    it(@"should resolve to the given URL if given URL is a directory", ^ {
        NSURL *directoryURL = [fs temporaryFileURLFromPath:@"some_directory"];
        [fs createDirectory:directoryURL];
        
        NSURL *result = [packaging resolveURL:directoryURL];
        
        expect(result).to.equal(directoryURL);
    });
    
    it(@"should resolve to the given URL if given URL is a WAR file", ^ {
        [fs createDirectory:[fs temporaryFileURLFromPath:@"some_directory"]];
        NSURL *warURL = [fs temporaryFileURLFromPath:@"some_directory/some_war.war"];
        [fs createFile:warURL withContents:[@"<WAR contents>" dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURL *result = [packaging resolveURL:warURL];
        
        expect(result).to.equal(warURL);
    });
    
    it(@"should resolve to the given URL if given URL is a ZIP file", ^ {
        [fs createDirectory:[fs temporaryFileURLFromPath:@"some_directory"]];
        NSURL *zipURL = [fs temporaryFileURLFromPath:@"some_directory/some_zip.zip"];
        [fs createFile:zipURL withContents:[@"<ZIP contents>" dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURL *result = [packaging resolveURL:zipURL];
        
        expect(result).to.equal(zipURL);
        
    });
    
    it(@"should resolve to the URL of a ZIP file if given URL is a directory containing a ZIP file", ^ {
        NSURL *directoryURL = [fs temporaryFileURLFromPath:@"some_directory"];
        [fs createDirectory:directoryURL];
        NSURL *zipURL = [fs temporaryFileURLFromPath:@"some_directory/some_zip.zip"];
        
        [fs createFile:zipURL withContents:[@"<ZIP contents>" dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURL *result = [packaging resolveURL:directoryURL];
        
        expect(result).to.equal(zipURL);
    });
    
    it(@"should resolve to the URL of a WAR file if given URL is a directory containing a WAR file", ^ {
        NSURL *directoryURL = [fs temporaryFileURLFromPath:@"some_directory"];
        [fs createDirectory:directoryURL];
        NSURL *warURL = [fs temporaryFileURLFromPath:@"some_directory/some_war.war"];
        
        [fs createFile:warURL withContents:[@"<WAR contents>" dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURL *result = [packaging resolveURL:directoryURL];
        
        expect(result).to.equal(warURL);
    });
});

SpecEnd