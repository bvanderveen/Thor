#import "Packaging.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface NSURL (Utils)

@end

@implementation NSURL (Utils)

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

@end

@implementation Packaging

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
    if (url.isZipFile)
        return url;
    
    if (url.isWarFile)
        return url;
    
    return nil;
}

@end
