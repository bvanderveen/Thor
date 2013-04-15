#import "Packaging.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "SHA1.h"
#import "NSOutputStream+Writing.h"
#import "NSObject+JSONDataRepresentation.h"

@implementation NSURL (Utils)

+ (NSURL *)URLWithPath:(NSString *)path relativeToDirectory:(NSURL *)directory {
    return [NSURL fileURLWithPathComponents:[directory.pathComponents arrayByAddingObjectsFromArray:path.pathComponents]];
}

- (BOOL)isDirectory {
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:&error];
    
    if (error)
        NSLog(@"Error: %@", [error localizedDescription]);
    
    return [attributes[NSFileType] isEqual:NSFileTypeDirectory];
}

- (BOOL)isFileWithExtension:(NSString *)extension {
    return [self.pathExtension isEqual:extension];
}

- (BOOL)isWarFile {
    return [self isFileWithExtension:@"war"];
}

- (BOOL)isZipFile {
    return [self isFileWithExtension:@"zip"];
}

- (BOOL)isInGitDirectory {
    return [self.pathComponents.rac_sequence filter:^BOOL(NSString *component) {
        return [component isEqual:@".git"];
    }].array.count > 0;
}

- (BOOL)isDSStore {
    return [self.pathComponents.lastObject isEqual:@".DS_Store"];
}

- (NSArray *)itemsInDirectory {
    assert([self isDirectory]);
    
    NSMutableArray *result = [NSMutableArray array];
    NSURL *resolved = [self URLByResolvingSymlinksInPath];
    for (id u in [[NSFileManager defaultManager] enumeratorAtURL:resolved includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil]) {
        NSURL *url = [u URLByResolvingSymlinksInPath];
        [result addObject:url];
    }
    
    return result;
}

- (void)ensureDirectory {
    [[NSFileManager defaultManager] createDirectoryAtURL:self withIntermediateDirectories:YES attributes:nil error:NULL];
}

- (void)removeItem {
    [[NSFileManager defaultManager] removeItemAtURL:self error:nil];
}

- (NSString *)pathRelativeToURL:(NSURL *)baseURL {
    if ([baseURL isEqual:self])
        return [self.pathComponents lastObject];
    
    NSString *stripped = [self.path stringByReplacingOccurrencesOfString:baseURL.path withString:@""];
    if ([[stripped substringToIndex:1] isEqual:@"/"])
        stripped = [stripped substringFromIndex:1];
    
    return stripped;
}

- (NSNumber *)fileSize {
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:&error];
    
    if (error)
        NSLog(@"Error: %@", [error localizedDescription]);
    
    return attributes[NSFileSize];
}

@end

@implementation Packaging

- (NSURL *)temporaryFileURLFromPath:(NSString *)path {
    return [NSURL fileURLWithPath:[NSString pathWithComponents:[@[NSTemporaryDirectory(), @"ThorTemp"] arrayByAddingObjectsFromArray:path.pathComponents]]];
}

- (NSURL *)archiveFileURL {
    return [self temporaryFileURLFromPath:@"ThorStaging/Archive.zip"];
}

- (NSURL *)explodeDirectoryURL {
    NSURL *result = [self temporaryFileURLFromPath:@"ThorStaging/Explode"];
    [result ensureDirectory];
    return result;
}

- (NSURL *)messageFileURL {
    return [self temporaryFileURLFromPath:@"ThorStaging/MultipartMessage"];
}

- (NSURL *)resolveURL:(NSURL *)url {
    if (url.isDirectory) {
        NSArray *zipFiles = [url.itemsInDirectory.rac_sequence filter:^ (NSURL *i) {  return i.isZipFile; }].array;
        
        if (zipFiles.count)
            return zipFiles[0];
        
        NSArray *warFiles = [url.itemsInDirectory.rac_sequence filter:^ (NSURL *i) {  return i.isWarFile; }].array;
        
        if (warFiles.count)
            return warFiles[0];
        
        return url;
    }
    
    if (url.isZipFile || url.isWarFile)
        return url;
    
    return nil;
}

- (BOOL)shouldUnpackURL:(NSURL *)url {
    if (url.isWarFile || url.isZipFile)
        return YES;
    
    return NO;
}

- (void)shell:(NSString *)path withArgs:(NSArray *)args {
    [self shell:path withArgs:args cwd:nil];
}

- (void)shell:(NSString *)path withArgs:(NSArray *)args cwd:(NSString *)cwd {
    NSTask *task = [NSTask new];
    task.launchPath = path;
    task.arguments = args;
    if (cwd)
        task.currentDirectoryPath = cwd;
    [task launch];
    [task waitUntilExit];
}

- (void)unarchive:(NSURL *)archive toURL:(NSURL *)url {
    [[NSFileManager defaultManager] removeItemAtPath:url.path error:nil];
    [self shell:@"/usr/bin/unzip" withArgs:@[ archive.path, @"-d", url.path ]];
}

- (void)copyFiles:(NSArray *)files inDirectory:(NSURL *)sourceDirectory toDirectory:(NSURL *)destinationDirectory {
    for (NSURL *sourceURL in files) {
        NSString *sourcePath = [sourceURL pathRelativeToURL:sourceDirectory];
        NSURL *destinationURL = [NSURL URLWithPath:sourcePath relativeToDirectory:destinationDirectory];
        
        NSArray *destinationPathComponents = destinationURL.pathComponents;
        NSURL *containingDirectoryOfDestinationURL = [NSURL fileURLWithPathComponents:[destinationPathComponents.rac_sequence take:destinationPathComponents.count - 1].array];
        
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtURL:containingDirectoryOfDestinationURL withIntermediateDirectories:YES attributes:nil error:&error];
        NSAssert(error == nil, @"Error ensuring directory %@", containingDirectoryOfDestinationURL);
        
        NSLog(@"Copying %@ to %@", sourceURL, destinationURL);
        [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:destinationURL error:&error];
        NSAssert(error == nil, @"Error copying from '%@' to '%@'", sourceURL, destinationURL);
    }
}

- (NSArray *)includedFilesInDirectory:(NSURL *)directory {
    NSArray *items = [directory itemsInDirectory];
    NSLog(@"Items are %@", items);
    NSArray *result = [items.rac_sequence filter:^BOOL(NSURL *value) {
        BOOL result = !value.isInGitDirectory && !value.isDSStore && !value.isDirectory;
        if (!result)
            NSLog(@"Filtered out item %@ (git=%d dsstore=%d dir=%d)", value, [value isInGitDirectory], [value isDSStore], value.isDirectory);
        return result;
    }].array;
    
    NSLog(@"Results are %@", result);
    
    return result;
}

- (NSArray *)manifestForFiles:(NSArray *)items inDirectory:(NSURL *)directory {
    return [items.rac_sequence map:^id(NSURL *url) {
        return @{
            @"fn" : [url pathRelativeToURL:directory],
            @"size": url.fileSize,
            @"sha1": CalculateSHA1OfFileAtPath(url)
        };
    }].array;
}

- (void)archiveFiles:(NSArray *)files inDirectory:(NSURL *)directory archiveURL:(NSURL *)archiveURL {
    [self shell:@"/usr/bin/zip" withArgs:[[files.rac_sequence map:^id(NSURL *url) {
        return [url pathRelativeToURL:directory];
    }] startWith:archiveURL.path].array cwd:directory.path];
}

- (void)writeMultipartMessage:(NSURL *)outputURL withManifest:(NSArray *)manifest archive:(NSURL *)archive boundary:(NSString *)boundary {
    NSOutputStream *tempFile = [NSOutputStream outputStreamToFileAtPath:outputURL.path append:NO];
    
    [tempFile open];
    
    [tempFile writeString:[NSString stringWithFormat:@"--%@\r\n", boundary]];
    [tempFile writeString:@"Content-Disposition: form-data; name=\"_method\"\r\n\r\n"];
    [tempFile writeString:@"put"];
    [tempFile writeString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
    [tempFile writeString:@"Content-Disposition: form-data; name=\"resources\"\r\n\r\n"];
    [tempFile writeData:[manifest JSONDataRepresentation]];
    [tempFile writeString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
    [tempFile writeString:@"Content-Disposition: form-data; name=\"application\"\r\n"];
    [tempFile writeString:@"Content-Type: application/zip\r\n\r\n"];
    
    NSInputStream *archiveFile = [NSInputStream inputStreamWithURL:archive];
    [archiveFile open];
    
    [tempFile writeStream:archiveFile];
    [archiveFile close];
    
    [tempFile writeString:[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary]];
    
    [tempFile close];
}

@end
