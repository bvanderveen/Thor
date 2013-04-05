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
    
    __block NSURL *directoryURL;
    __block NSURL *warURL;
    __block NSURL *zipURL;
    
    afterEach(^{
        [fs removeTemporaryFiles];
    });
    
    void (^createDirectory)() = ^ {
        directoryURL = [fs temporaryFileURLFromPath:@"some_directory"];
        [fs createDirectory:directoryURL];
    };
    
    void (^createWar)() = ^ {
        createDirectory();
        warURL = [fs temporaryFileURLFromPath:@"some_directory/some_war.war"];
        [fs createFile:warURL withContents:[@"<WAR contents>" dataUsingEncoding:NSUTF8StringEncoding]];
    };
    
    void (^createZip)() = ^ {
        createDirectory();
        zipURL = [fs temporaryFileURLFromPath:@"some_directory/some_zip.zip"];
        [fs createFile:zipURL withContents:[@"<ZIP contents>" dataUsingEncoding:NSUTF8StringEncoding]];
    };
    
    it(@"resolveURL: should resolve to the given URL if given URL is a directory", ^ {
        createDirectory();
        
        NSURL *result = [packaging resolveURL:directoryURL];
        
        expect(result).to.equal(directoryURL);
    });
    
    it(@"resolveURL: should resolve to the given URL if given URL is a WAR file", ^ {
        createWar();
        
        NSURL *result = [packaging resolveURL:warURL];
        
        expect(result).to.equal(warURL);
    });
    
    it(@"resolveURL: should resolve to the given URL if given URL is a ZIP file", ^ {
        createZip();
        
        NSURL *result = [packaging resolveURL:zipURL];
        
        expect(result).to.equal(zipURL);
        
    });
    
    it(@"resolveURL: should resolve to the URL of a ZIP file if given URL is a directory containing a ZIP file", ^ {
        createZip();
        
        NSURL *result = [packaging resolveURL:directoryURL];
        
        expect(result).to.equal(zipURL);
    });
    
    it(@"resolveURL: should resolve to the URL of a WAR file if given URL is a directory containing a WAR file", ^ {
        createWar();
        
        NSURL *result = [packaging resolveURL:directoryURL];
        
        expect(result).to.equal(warURL);
    });
    
    it(@"shouldUnpackURL: should return YES if URL is war file", ^ {
        createWar();
        
        BOOL result = [packaging shouldUnpackURL:warURL];
        
        expect(result).to.beTruthy();
    });
    
    it(@"shouldUnpackURL: should return YES if URL is zip file", ^ {
        createZip();
        
        BOOL result = [packaging shouldUnpackURL:zipURL];
        
        expect(result).to.beTruthy();
        
    });
    
    it(@"shouldUnpackURL: should return NO if URL is a directory", ^ {
        createDirectory();
        
        BOOL result = [packaging shouldUnpackURL:directoryURL];
        
        expect(result).to.beFalsy();
    });
    
    it(@"shouldUnpackURL: should return NO if URL is not a war or zip file", ^ {
        createDirectory();
        NSURL *otherFileURL = [fs temporaryFileURLFromPath:@"some_directory/some_other_file.txt"];
        [fs createFile:zipURL withContents:[@"<ZIP contents>" dataUsingEncoding:NSUTF8StringEncoding]];
        
        BOOL result = [packaging shouldUnpackURL:otherFileURL];
        
        expect(result).to.beFalsy();
    });
});

SpecEnd