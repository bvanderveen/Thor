

@protocol Packaging <NSObject>

- (NSURL *)uploadFileURL;
- (NSURL *)explodeDirectoryURL;

- (void)recursivelyUnlink:(NSURL *)url;

- (NSURL *)resolveURL:(NSURL *)url;

- (BOOL)shouldUnpackURL:(NSURL *)url;

- (void)unarchive:(NSURL *)archive toURL:(NSURL *)url;
- (void)copyFilesInDirectory:(NSURL *)directory toURL:(NSURL *)url;

- (NSArray *)includedFilesInDirectory:(NSURL *)directory; // returns NSArray of NSString paths relative to `directory`

- (void)archiveFiles:(NSArray *)files inDirectory:(NSURL *)directory; // files is NSArray of NSString paths relative to `directory`

@end

@interface Packaging : NSObject <Packaging>

@end
