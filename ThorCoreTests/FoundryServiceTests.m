#import "FoundryServiceTests.h"
#import "ThorCore.h"
#import "Sequence.h"
#import "Specta.h"
#define EXP_SHORTHAND
#import "Expecta.h"

@interface MockEndpoint : NSObject

@property (nonatomic, copy) NSArray *calls, *results;

@end

@implementation MockEndpoint

@synthesize calls, results;

- (id)init {
    if (self = [super init]) {
        self.calls = [NSMutableArray array];
        self.results = [NSMutableArray array];
    }
    return self;
}

- (NSString *)stringFromStream:(NSInputStream *)stream {
    NSMutableString *result = [NSMutableString string];
    
    int bytesRead = 0;
    NSUInteger bufferSize = 1024 * 20;
    uint8_t buffer[bufferSize];
    
    [stream open];
    while (true) {
        bytesRead = [stream read:&buffer maxLength:bufferSize];
        
        if (bytesRead <= 0)
            break;
        
        [result appendString:[[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding]];
    }
    [stream close];
    
    return [result copy];
}

- (RACSubscribable *)authenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    NSDictionary *call = @{
    @"method" : method ? method : [NSNull null],
    @"path" : path ? path : [NSNull null],
    @"headers" : headers ? headers : [NSNull null],
    @"body" : body ? ([body isKindOfClass:[NSInputStream class]] ? [self stringFromStream:(NSInputStream *)body] : body) : [NSNull null]
    };
    
    calls = [calls arrayByAddingObject:call];
    
    id resultObject = results.count ? results[0] : nil;
    
    if (results.count) {
        NSMutableArray *newResults = [results mutableCopy];
        [newResults removeObjectAtIndex:0];
        results = newResults;
    }
    
    return [RACSubscribable return:resultObject];
}

@end

SpecBegin(FoundryService)

describe(@"getApps", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryService *service;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        service = [[FoundryService alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[service getApps] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"GET",
        @"path" : @"/apps",
        @"headers" : [NSNull null],
        @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should parse results", ^ {
        endpoint.results = @[ @[
        @{
        @"name" : @"the name",
        @"uris" : @[ @"uri", @"uri2" ],
        @"instances" : @2,
        @"state" : @"STARTED",
        @"resources" : @{
        @"memory" : @2048,
        @"disk" : @4096
        }
        },
        @{
        @"name" : @"the name2",
        @"uris" : @[ @"uri3", @"uri4" ],
        @"instances" : @3,
        @"state" : @"STOPPED",
        @"resources" : @{
        @"memory" : @2049,
        @"disk" : @4097
        }
        }
        ] ];
        
        __block NSArray *result;
        [[service getApps] subscribeNext:^(id x) {
            result = (NSArray *)x;
        }];
        
        expect(result.count).to.equal(2);
        
        FoundryApp *app0 = result[0];
        expect(app0.name).to.equal(@"the name");
        id uris = @[ @"uri", @"uri2" ];
        expect(app0.uris).to.equal(uris);
        expect(app0.instances).to.equal(2);
        expect(app0.state).to.equal(FoundryAppStateStarted);
        expect(app0.memory).to.equal(2048);
        expect(app0.disk).to.equal(4096);
        
        FoundryApp *app1 = result[1];
        
        expect(app1.name).to.equal(@"the name2");
        uris = @[ @"uri3", @"uri4" ];
        expect(app1.uris).to.equal(uris);
        expect(app1.instances).to.equal(3);
        expect(app1.state).to.equal(FoundryAppStateStopped);
        expect(app1.memory).to.equal(2049);
        expect(app1.disk).to.equal(4097);
    });
});

describe(@"getAppWithName", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryService *service;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        service = [[FoundryService alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[service getAppWithName:@"name"] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"GET",
        @"path" : @"/apps/name",
        @"headers" : [NSNull null],
        @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should parse result", ^ {
        endpoint.results = @[
        @{
        @"name" : @"the name",
        @"uris" : @[ @"uri", @"uri2" ],
        @"instances" : @2,
        @"state" : @"STARTED",
        @"resources" : @{
        @"memory" : @2048,
        @"disk" : @4096
        }
        }];
        
        __block FoundryApp *app;
        
        [[service getAppWithName:@"the name"] subscribeNext:^(id x) {
            app = (FoundryApp *)x;
        }];
        
        expect(app.name).to.equal(@"the name");
        id uris = @[ @"uri", @"uri2" ];
        expect(app.uris).to.equal(uris);
        expect(app.instances).to.equal(2);
        expect(app.state).to.equal(FoundryAppStateStarted);
        expect(app.memory).to.equal(2048);
        expect(app.disk).to.equal(4096);
    });
});

describe(@"getStatsForAppWithName", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryService *service;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        service = [[FoundryService alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[service getStatsForAppWithName:@"name"] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"GET",
        @"path" : @"/apps/name/stats",
        @"headers" : [NSNull null],
        @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should parse result", ^ {
        endpoint.results = @[ @{
        @"0" : @{
            @"stats" : @{
                @"host" : @"10.0.0.1",
                @"port" : @3300,
                @"uptime": @2300.1,
                @"usage" : @{
                    @"cpu" : @99.1,
                    @"mem" : @2048.3,
                    @"disk": @4096
                }
            }
        }
        }];
        
        __block NSArray *result;
        
        [[service getStatsForAppWithName:@"the name"] subscribeNext:^(id x) {
            result = (NSArray *)x;
        }];
        
        expect(result.count).to.equal(1);
        
        FoundryAppInstanceStats *stats = result[0];
        
        expect(stats.ID).to.equal(@"0");
        expect(stats.host).to.equal(@"10.0.0.1");
        expect(stats.port).to.equal(3300);
        expect(stats.uptime).to.equal(2300.1);
        expect(stats.cpu).to.equal(99.1);
        expect(stats.memory).to.equal(2048.3);
        expect(stats.disk).to.equal(4096);
    });
});

describe(@"createApp", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryService *service;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        service = [[FoundryService alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        
        FoundryApp *app = [FoundryApp new];

        app.name = @"appname";
        app.stagingFramework = @"rack";
        app.stagingRuntime = @"ruby18";
        app.uris = @[ @"app.foo.bar.com" ];
        //app.services = @[];
        app.instances = 3;
        app.memory = 256;
        //app.disk = 512;
        app.state = FoundryAppStateStarted;
        
        [[service createApp:app] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"POST",
        @"path" : @"/apps",
        @"headers" : [NSNull null],
        @"body" : @{
            @"name" : @"appname",
        @"staging" : @{
            @"framework" : @"rack",
            @"runtime" : @"ruby18",
        },
        @"uris" : @[ @"app.foo.bar.com" ],
        //@"services" : @[],
        @"instances": @3,
        @"resources" : @{
            @"memory" : @256//,
            //@"disk" : @512
        },
        //@"state" : @"STARTED",
        //@"env" : @[],
        //@"meta" : @{
        //@"debug" : @0
        //}
        }
        
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
});

describe(@"deleteApp", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryService *service;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        service = [[FoundryService alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[service deleteAppWithName:@"foobard"] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
            @"method" : @"DELETE",
            @"path" : @"/apps/foobard",
            @"headers" : [NSNull null],
            @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
});

describe(@"postSlug", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryService *service;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        service = [[FoundryService alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        NSString *tempFilePath = [NSString pathWithComponents:@[ NSTemporaryDirectory(), @"TestUploadFile.txt" ]];
        NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
        
        [[NSFileManager defaultManager] createFileAtPath:tempFilePath contents:[@"this is some data in a file" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        
        NSArray *manifest = @[ @"a", @"b", @"c" ];
        
        [[service postSlug:tempFileURL manifest:manifest toAppWithName:@"appname"] subscribeCompleted:^{ }];
        
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:&error];
        
        NSString *boundary = @"BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL";
        
        NSString *expectedBody = @"--BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL\r\n" \
        "Content-Disposition: form-data; name=\"resources\"\r\n\r\n" \
        "[\"a\",\"b\",\"c\"]\r\n" \
        "--BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL\r\n" \
        "Content-Disposition: form-data; name=\"application\"\r\n" \
        "Content-Type: application/zip\r\n\r\n" \
        "this is some data in a file\r\n"
        "--BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL--\r\n";
        
        
        
        id expectedCalls = @[
        @{
            @"method" : @"PUT",
            @"path" : @"/apps/appname/application",
            @"headers" : @{
                @"Content-Type" : @"multipart/form-data; boundary=BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL",
                @"Content-Length" : [[NSNumber numberWithUnsignedInteger:expectedBody.length] stringValue]
            },
            @"body" : expectedBody
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
});

NSArray *root = @[NSTemporaryDirectory(), @"TestZipDir"];
NSString *rootPath = [NSString pathWithComponents:root];
NSURL *rootURL = [NSURL fileURLWithPath:rootPath];

NSSet *(^createFiles)(NSArray *) = ^ (NSArray *files) {
    NSSet *created = [NSSet set];
    for (NSArray *f in files) {
        NSArray *pathComponents = f[0];
        NSString *contents = f[1];
        
        NSString *directory = [NSString pathWithComponents:[[root concat:pathComponents] take:root.count + pathComponents.count - 1]];
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error) {
            NSLog(@"error: %@", [error localizedDescription]);
            assert(NO);
        }
        
        NSString *path = [NSString pathWithComponents:[root arrayByAddingObjectsFromArray:pathComponents]];
        
        created = [created setByAddingObject:@{
            @"name" : [NSString pathWithComponents:pathComponents],
            @"contents": contents
        }];
        
        [[NSFileManager defaultManager] createFileAtPath:path contents:[contents dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    return created;
};

void (^removeCreatedFiles)() = ^ {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:rootPath error:&error];
};

describe(@"CreateSlugManifestFromPath", ^ {
    void (^expectToBeIntendedFiles)(NSSet *) = ^ (NSSet *filenames) {
        expect(filenames.count).to.equal(8);
        expect(filenames).to.contain(@"foo");
        expect(filenames).to.contain(@"bar");
        expect(filenames).to.contain(@"subdir1/foo1");
        expect(filenames).to.contain(@"subdir1/bar1");
        expect(filenames).to.contain(@"subdir2/foo2");
        expect(filenames).to.contain(@"subdir2/bar2");
        expect(filenames).to.contain(@"subdir2/subdir3/foo3");
        expect(filenames).to.contain(@"subdir2/subdir3/bar3");
    };
    
    id (^filesInManifest)() = ^ id () {
        return [CreateSlugManifestFromPath(rootURL) map:^id(id r) {
            return [r objectForKey:@"fn"];
        }];
    };
    
    __block NSArray *intendedFiles;
    
    beforeEach(^{
        intendedFiles = createFiles(@[
                    @[ @[@"foo"], @"this is /foo" ],
                    @[ @[@"bar"], @"this is /bar" ],
                    @[ @[@"subdir1", @"foo1"], @"this is /subdir1/foo1" ],
                    @[ @[@"subdir1", @"bar1"], @"this is /subdir1/bar1" ],
                    @[ @[@"subdir2", @"foo2"], @"this is /subdir2/foo2" ],
                    @[ @[@"subdir2", @"bar2"], @"this is /subdir2/bar2" ],
                    @[ @[@"subdir2", @"subdir3", @"foo3"], @"this is /subdir2/subdir3/foo3" ],
                    @[ @[@"subdir2", @"subdir3", @"bar3"], @"this is /subdir2/subdir3/bar3" ],
                    ]);
    });
    
    afterEach(^{
        removeCreatedFiles();
    });

    it(@"should list files recursively", ^{
        expectToBeIntendedFiles(filesInManifest());
    });
    
    it(@"should exclude .git directories", ^ {
        createFiles(@[
                    @[ @[@".git", @"index-n-stuff"], @"blah blah blah" ],
                    @[ @[@".git", @"objects"], @"tree or whatever" ],
                    @[ @[@".git", @"whateverelse"], @"wish I understood git more" ]
                    ]);
        
        
        expectToBeIntendedFiles(filesInManifest());
    });
    
    it(@"should provide file sizes", ^ {
        NSArray *manifest = CreateSlugManifestFromPath(rootURL);
        
        NSMutableDictionary *nameToSizeDict = [manifest reduce:^id(id acc, id i) {
            ((NSMutableDictionary *)acc)[[i objectForKey:@"fn"]] = [i objectForKey:@"size"];
            return acc;
        } seed:[NSMutableDictionary dictionary]];
        
        expect(nameToSizeDict[@"foo"]).to.equal(@"this is /foo".length);
        expect(nameToSizeDict[@"subdir1/foo1"]).to.equal(@"this is /subdir1/foo1".length);
        expect(nameToSizeDict[@"subdir2/subdir3/bar3"]).to.equal(@"this is /subdir2/subdir3/bar3".length);
    });
    
    it(@"should calculate SHA1 digests", ^ {
        NSArray *manifest = CreateSlugManifestFromPath(rootURL);
        
        NSMutableDictionary *nameToHashDict = [manifest reduce:^id(id acc, id i) {
            ((NSMutableDictionary *)acc)[[i objectForKey:@"fn"]] = [i objectForKey:@"sha1"];
            return acc;
        } seed:[NSMutableDictionary dictionary]];
        
        expect(nameToHashDict[@"foo"]).to.equal(@"02d93cc62a7f63b4e4bead55fff95176251d7cc7");
        expect(nameToHashDict[@"subdir1/foo1"]).to.equal(@"1411e4e16e797bd23075cf9b4fc0611ea64402f2");
        expect(nameToHashDict[@"subdir2/subdir3/bar3"]).to.equal(@"84fb57be8728b638cfa2b100fc6b8f82dc807e62");
    });
});

void (^extractSlug)(NSURL *, NSURL *) = ^(NSURL *slug, NSURL *path) {
    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/bin/unzip";
    task.arguments = @[slug.path, @"-d", path.path];
    [task launch];
    [task waitUntilExit];
    
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:slug.path error:&error];
};

NSSet *(^filesUnderRoot)(NSURL *) = ^ NSSet * (NSURL *root) {
    NSSet *result = [NSSet set];
    root = [root URLByResolvingSymlinksInPath];
    id i = nil;
    for (id u in [[NSFileManager defaultManager] enumeratorAtURL:root includingPropertiesForKeys:nil options:0 errorHandler:nil]) {
        NSURL *url = [u URLByResolvingSymlinksInPath];
        
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];
        
        if (error)
            NSLog(@"Error: %@", [error localizedDescription]);
        
        if ([attributes[NSFileType] isEqual:NSFileTypeDirectory])
            continue;
        
        result = [result setByAddingObject:@{
            @"name": [url.path stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/", root.path] withString:@""],
            @"contents" : [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil]
         }];
    }
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:root.path error:&error];
    return result;
};

describe(@"CreateSlugFromManifest", ^{
    __block NSSet *createdFiles;
    
    beforeEach(^{
        createdFiles = createFiles(@[
                    @[ @[@"foo"], @"this is /foo" ],
                    @[ @[@"bar"], @"this is /bar" ],
                    @[ @[@"subdir1", @"foo1"], @"this is /subdir1/foo1" ],
                    @[ @[@"subdir1", @"bar1"], @"this is /subdir1/bar1" ],
                    @[ @[@"subdir2", @"foo2"], @"this is /subdir2/foo2" ],
                    @[ @[@"subdir2", @"bar2"], @"this is /subdir2/bar2" ],
                    @[ @[@"subdir2", @"subdir3", @"foo3"], @"this is /subdir2/subdir3/foo3" ],
                    @[ @[@"subdir2", @"subdir3", @"bar3"], @"this is /subdir2/subdir3/bar3" ],
                    ]);
    });
    
    afterEach(^{
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:rootPath error:&error];
    });
    
    it(@"should contain all of the files", ^{
        NSArray *extractionRoot = @[NSTemporaryDirectory(), @"TestZipDirExtracted"];
        NSURL *extractionRootPath = [NSURL fileURLWithPath:[NSString pathWithComponents:extractionRoot]];
        
        NSArray *manifest = CreateSlugManifestFromPath(rootURL);
        NSURL *slug = CreateSlugFromManifest(manifest, rootURL);
        
        extractSlug(slug, extractionRootPath);
        NSSet *files = filesUnderRoot(extractionRootPath);
        
        expect(files).to.equal(createdFiles);
    });
});

describe(@"TestDeployment", ^{
    it(@"should deploy a thing", ^{
        
        NSArray *repoPathComponents = @[ NSTemporaryDirectory(), @"paasIt" ];
        NSString *repoPath = [NSString pathWithComponents:repoPathComponents];
        
        [[NSFileManager defaultManager] removeItemAtPath:repoPath error:nil];
        NSURL *repoURL = [NSURL fileURLWithPath:repoPath];
        
        NSTask *task = [NSTask new];
        task.launchPath = @"/usr/bin/git";
        task.arguments = @[ @"clone", @"git://github.com/Adron/goldmind.git", repoPath ];
        [task launch];
        [task waitUntilExit];
        
        NSURL *nodeTestAppURL = [NSURL fileURLWithPath:[NSString pathWithComponents:repoPathComponents]];
        
        NSArray *manifest = CreateSlugManifestFromPath(nodeTestAppURL);
        NSURL *slug = CreateSlugFromManifest(manifest, nodeTestAppURL);
        
        FoundryEndpoint *endpoint = [FoundryEndpoint new];
        endpoint.email = @"b@bvanderveen.com";
        endpoint.password = @"secret";
        endpoint.hostname = @"api.bvanderveen.cloudfoundry.me";
        
        FoundryService *service = [[FoundryService alloc] initWithEndpoint:endpoint];
        
        FoundryApp *app = [FoundryApp new];
        app.name = @"goldmind";
        app.uris = @[ @"goldmind.bvanderveen.cloudfoundry.me" ];
        app.instances = 1;
        //app.state = FoundryAppStateStarted;
        app.memory = 64;
        //app.disk = 2048;
        app.stagingFramework = @"node";
        //app.stagingRuntime = [NSNull null];//@"node";
        //app.services = @[];
        
        __block BOOL done = NO, err = NO;
        int attempts = 0;
        
        [[service createApp:app] subscribeError:^ (NSError *error) {
            NSLog(@"error: %@", [error localizedDescription]);
            err = YES;
        } completed:^{
            [[service postSlug:slug manifest:manifest toAppWithName:@"goldmind"] subscribeError: ^ (NSError *error) {
                NSLog(@"error: %@", [error localizedDescription]);
                err = YES;
            } completed:^{
                done = YES;
                NSError *error = nil;
            }];
        }];
        
        while (!done && !err && attempts++ < 1) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
        }
        
        expect(err).to.beFalsy();
        expect(done).to.beTruthy();
        
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:repoPath error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:slug.path error:&error];
    });
});

SpecEnd