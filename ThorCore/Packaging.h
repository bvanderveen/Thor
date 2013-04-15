

@interface NSURL (Utils)

+ (NSURL *)URLWithPath:(NSString *)path relativeToDirectory:(NSURL *)directory;
- (BOOL)isDirectory;
- (void)removeItem;
- (NSString *)pathRelativeToURL:(NSURL *)url;
- (NSNumber *)fileSize;

@end

@protocol Packaging <NSObject>

- (NSURL *)archiveFileURL;
- (NSURL *)explodeDirectoryURL;
- (NSURL *)messageFileURL;

- (NSURL *)resolveURL:(NSURL *)url;

- (BOOL)shouldUnpackURL:(NSURL *)url;

- (void)unarchive:(NSURL *)archive toURL:(NSURL *)url;

- (NSArray *)includedFilesInDirectory:(NSURL *)directory; // returns NSArray of NSURL

// files is NSArray of NSURL. all should be in contained in srcDir
- (void)copyFiles:(NSArray *)files inDirectory:(NSURL *)srcDir toDirectory:(NSURL *)destDir;

// files is NSArray of NSURL. all should be in contained in srcDir
// result is a 'manifest' Cloud-Foundry understands
- (NSArray *)manifestForFiles:(NSArray *)files inDirectory:(NSURL *)directory;

- (void)archiveFiles:(NSArray *)files inDirectory:(NSURL *)directory archiveURL:(NSURL *)archiveURL; // files is NSArray of NSString paths relative to `directory`

- (void)writeMultipartMessage:(NSURL *)outputURL withManifest:(NSArray *)manifest archive:(NSURL *)archive boundary:(NSString *)boundary;


@end

@interface Packaging : NSObject <Packaging>

@end
