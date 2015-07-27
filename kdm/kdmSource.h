//
//  kdmSource.h
//  kdm
//
//  Created by Mustafa Gezen on 27.07.2015.
//  Copyright © 2015 Mustafa Gezen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "kdmPackage.h"
#import "AFNetworking/AFNetworking.h"

typedef struct {
	char *label;
	char *description;
} ReleaseStruct;

@interface kdmSource : NSObject {
	AFHTTPSessionManager *_manager;
	dispatch_semaphore_t _semaphore;
	NSString *_source;
	NSMutableArray *_packages;
	ReleaseStruct _rel;
	NSMutableArray *_installedPackages;
}
+ (kdmSource*)initWithSourceURL:(NSString*)url;
+ (kdmSource*)initWithCache:(NSDictionary*)info;
- (kdmPackage*)findPackageByIdentifier:(NSString*)identifier;
- (kdmPackage*)dependencyWithIdentifier:(NSString*)identifier;
- (NSString*)source;
- (NSMutableArray*)packages;
- (NSMutableArray*)installedPackages;
- (ReleaseStruct)rel;
@end
