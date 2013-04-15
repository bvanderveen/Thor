#import "PackagingTests.h"
#import "Packaging.h"
#import "Specta.h"
#define EXP_SHORTHAND
#import "Expecta.h"
#import "SBJson/SBJson.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

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

- (NSData *)readFileContents:(NSURL *)fileURL {
    return [[NSFileManager defaultManager] contentsAtPath:fileURL.path];
}

- (BOOL)fileExists:(NSURL *)fileURL {
    return [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path];
}

@end

SpecBegin(Packaging)

describe(@"Packaging", ^{
    FSUtils *fs = [[FSUtils alloc] init];
    Packaging *packaging = [[Packaging alloc] init];
    
    __block NSURL *directoryURL;
    __block NSURL *warURL;
    __block NSURL *zipURL;
    __block NSURL *explodeDirectoryURL;
    
    afterEach(^{
        [fs removeTemporaryFiles];
    });
    
    __block NSArray *filePaths = @[@"some_directory/file0.txt",
                                   @"some_directory/file1.txt",
                                   @"some_directory/file2.txt",
                                   @"some_directory/subdir/subfile0.txt",
                                   @"some_directory/subdir/subfile1.txt",
                                   @"some_directory/.DS_Store",
                                   @"some_directory/.git/.DS_Store",
                                   @"some_directory/.git/config",
                                   @"some_directory/.git/index",
                                   @"some_directory/.git/modules/.DS_Store",
                                   @"some_directory/.git/modules/foo",
                                   @"some_directory/.git/modules/blah"];
    
    NSArray *(^fileURLS)() = ^ {
        return [filePaths.rac_sequence map:^id(id value) {
            return [fs temporaryFileURLFromPath:value];
        }].array;
    };
    
    void (^createDirectory)() = ^ {
        directoryURL = [fs temporaryFileURLFromPath:@"some_directory"];
        [fs createDirectory:directoryURL];
    };
    
    void (^createExplodeDirectory)() = ^ {
        explodeDirectoryURL = [fs temporaryFileURLFromPath:@"some_explode_directory"];
        [fs createDirectory:explodeDirectoryURL];
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
    
    void (^createFilesInDirectory)() = ^ {
        createDirectory();
        [fs createDirectory:[fs temporaryFileURLFromPath:@"some_directory/subdir"]];
        [fs createDirectory:[fs temporaryFileURLFromPath:@"some_directory/.git"]];
        [fs createDirectory:[fs temporaryFileURLFromPath:@"some_directory/.git/modules"]];
        
        // side-effects plz
        NSArray *units = [fileURLS().rac_sequence map:^id(id value) {
            [fs createFile:value withContents:[[NSString stringWithFormat:@"this is %@", [value pathRelativeToURL:directoryURL]] dataUsingEncoding:NSUTF8StringEncoding]];
            return [RACUnit defaultUnit];
        }].array;
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
    
    it(@"unarchive:toURL: should place archive contents in URL", ^ {
        createFilesInDirectory();
        
        NSURL *slugURL = [fs temporaryFileURLFromPath:@"slug.zip"];
        [[NSFileManager defaultManager] removeItemAtPath:slugURL.path error:nil];
        
        NSTask *task = [NSTask new];
        task.launchPath = @"/usr/bin/zip";
        task.currentDirectoryPath = directoryURL.path;
        task.arguments = [@[@"file0.txt", @"file1.txt", @"file2.txt"].rac_sequence startWith:slugURL.path].array;
        
        [task launch];
        [task waitUntilExit];
        
        createExplodeDirectory();
        
        [packaging unarchive:slugURL toURL:explodeDirectoryURL];
        
        
        NSString *file0Contents = [[NSString alloc] initWithData:[fs readFileContents:[fs temporaryFileURLFromPath:@"some_explode_directory/file0.txt"]] encoding:NSUTF8StringEncoding];
        NSString *file1Contents = [[NSString alloc] initWithData:[fs readFileContents:[fs temporaryFileURLFromPath:@"some_explode_directory/file1.txt"]] encoding:NSUTF8StringEncoding];
        NSString *file2Contents = [[NSString alloc] initWithData:[fs readFileContents:[fs temporaryFileURLFromPath:@"some_explode_directory/file2.txt"]] encoding:NSUTF8StringEncoding];
        
        BOOL subfile0Exists = [fs fileExists:[fs temporaryFileURLFromPath:@"some_explode_directory/subdir/subfile0.txt"]];
        BOOL subfile1Exists = [fs fileExists:[fs temporaryFileURLFromPath:@"some_explode_directory/subdir/subfile1.txt"]];
        
        expect(file0Contents).to.equal(@"this is file0.txt");
        expect(file1Contents).to.equal(@"this is file1.txt");
        expect(file2Contents).to.equal(@"this is file2.txt");
        expect(subfile0Exists).to.beFalsy();
        expect(subfile1Exists).to.beFalsy();
    });
    
    it(@"copyFiles:inDirectory:toDirectory: should place files into destination directory URL", ^ {
        createFilesInDirectory();
        
        createExplodeDirectory();
        
        NSArray *files = [@[
                         @"file0.txt",
                         @"file1.txt",
                         @"file2.txt",
                         @"subdir/subfile0.txt",
                         @"subdir/subfile1.txt",
                          ].rac_sequence map:^id(NSString *value) {
            return [NSURL URLWithPath:value relativeToDirectory:directoryURL];
        }].array;
        
        [packaging copyFiles:files inDirectory:directoryURL toDirectory:explodeDirectoryURL];
        
        
        NSString *file0Contents = [[NSString alloc] initWithData:[fs readFileContents:[fs temporaryFileURLFromPath:@"some_explode_directory/file0.txt"]] encoding:NSUTF8StringEncoding];
        NSString *file1Contents = [[NSString alloc] initWithData:[fs readFileContents:[fs temporaryFileURLFromPath:@"some_explode_directory/file1.txt"]] encoding:NSUTF8StringEncoding];
        NSString *file2Contents = [[NSString alloc] initWithData:[fs readFileContents:[fs temporaryFileURLFromPath:@"some_explode_directory/file2.txt"]] encoding:NSUTF8StringEncoding];
        

        NSString *subfile0Contents = [[NSString alloc] initWithData:[fs readFileContents:[fs temporaryFileURLFromPath:@"some_explode_directory/subdir/subfile0.txt"]] encoding:NSUTF8StringEncoding];
        NSString *subfile1Contents = [[NSString alloc] initWithData:[fs readFileContents:[fs temporaryFileURLFromPath:@"some_explode_directory/subdir/subfile1.txt"]] encoding:NSUTF8StringEncoding];
        
        expect(file0Contents).to.equal(@"this is file0.txt");
        expect(file1Contents).to.equal(@"this is file1.txt");
        expect(file2Contents).to.equal(@"this is file2.txt");
        expect(subfile0Contents).to.equal(@"this is subdir/subfile0.txt");
        expect(subfile1Contents).to.equal(@"this is subdir/subfile1.txt");
    });
    
    it(@"includedFilesInDirectory: should recursively list contents, excluding .git and .DS_Store files", ^ {
        createFilesInDirectory();
        
        NSSet *actualFiles = [NSSet setWithArray:[packaging includedFilesInDirectory:directoryURL]];
        NSSet *expectedFiles = [NSSet setWithArray:[@[
                           @"file0.txt",
                           @"file1.txt",
                           @"file2.txt",
                           @"subdir/subfile0.txt",
                           @"subdir/subfile1.txt",
                           ].rac_sequence map:^id(NSString *value) {
                               return [NSURL URLWithPath:value relativeToDirectory:directoryURL];
                           }].array];
        
        expect(actualFiles).to.equal(expectedFiles);
    });
    
    it(@"manifestForFiles:inDirectory: should provide relative path, file size, and sha1", ^ {
        createFilesInDirectory();
        
        NSArray *actualManifest = [packaging manifestForFiles:fileURLS() inDirectory:directoryURL];
        NSArray *expectedManifest =
        @[
          @{ @"sha1": @"f6fe670ce6f37d8d4e8395e877c79f3649f3f461", @"size": @17, @"fn": @"file0.txt" },
          @{ @"sha1": @"7b0ef8788b86ac6bc2b89e363eb318a01080e7ec", @"size": @17, @"fn": @"file1.txt" },
          @{ @"sha1": @"b96a70bc8f01440d591ccff012f33f181ba0da3c", @"size": @17, @"fn": @"file2.txt" },
          @{ @"sha1": @"3e1c22b9faa6911e2dc1608cb461f12ca478a60b", @"size": @27, @"fn": @"subdir/subfile0.txt" },
          @{ @"sha1": @"8461febf1cd052aabce7664144ce75dd256d551f", @"size": @27, @"fn": @"subdir/subfile1.txt" },
          @{ @"sha1": @"fa45c4f4d815c9270cc798b9eba0278284d33186", @"size": @17, @"fn": @".DS_Store" },
          @{ @"sha1": @"74f11ad7c965765149cb08e6f9c441b199fe5a12", @"size": @22, @"fn": @".git/.DS_Store" },
          @{ @"sha1": @"ceb77794ca662f2af25c5b139229b5d0fe456f8f", @"size": @19, @"fn": @".git/config" },
          @{ @"sha1": @"e8aae047be3c50225bcfa6a8cc980666bd7ad79e", @"size": @18, @"fn": @".git/index" },
          @{ @"sha1": @"a1c7a3549937f41008ba8ad917166e60dd02b2b5", @"size": @30, @"fn": @".git/modules/.DS_Store" },
          @{ @"sha1": @"9bdaa9541a0d49781bcf622f432054c8f19f4759", @"size": @24, @"fn": @".git/modules/foo" },
          @{ @"sha1": @"d52b34af939e19c4532d43303804818fd7bd72f4", @"size": @25, @"fn": @".git/modules/blah" }
    ];
        
        expect(actualManifest).to.equal(expectedManifest);
    });
    
    it(@"archiveFiles:inDirectory:archiveURL: should create archive at the given URL containing the given files, with paths relative to the base directory", ^ {
        createFilesInDirectory();
        
        [packaging archiveFiles:fileURLS() inDirectory:directoryURL archiveURL:zipURL];
        
        BOOL archiveExists = [fs fileExists:zipURL];
        
        // lazy.
        expect(archiveExists).to.beTruthy();
    });
    
    it(@"writeMultipartMessage:withManifest:archive:boundary: writes multipart message with a manifest and an archive", ^{
        
        NSURL *archive = [fs temporaryFileURLFromPath:@"the_archive.zip"];
        
        [[NSFileManager defaultManager] createFileAtPath:archive.path contents:[@"this is some data in a file" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        
        NSArray *manifest = @[ @"a", @"b", @"c" ];
        
        NSURL *messageURL = [fs temporaryFileURLFromPath:@"multipart.dat"];
        
        [packaging writeMultipartMessage:messageURL withManifest:manifest archive:archive boundary:@"BVANDERVEEN_WAS_HERE"];
        
        NSString *message = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:messageURL.path] encoding:NSUTF8StringEncoding];
        
        [[NSFileManager defaultManager] removeItemAtPath:messageURL.path error:nil];
        
        NSString *expectedMessage = @"--BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL\r\n" \
        "Content-Disposition: form-data; name=\"_method\"\r\n\r\n" \
        "put\r\n" \
        "--BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL\r\n" \
        "Content-Disposition: form-data; name=\"resources\"\r\n\r\n" \
        "[\"a\",\"b\",\"c\"]\r\n" \
        "--BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL\r\n" \
        "Content-Disposition: form-data; name=\"application\"\r\n" \
        "Content-Type: application/zip\r\n\r\n" \
        "this is some data in a file\r\n"
        "--BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL--\r\n";
    });
    
});

SpecEnd