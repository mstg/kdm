//
//  kdmSource.m
//  kdm
//
//  Created by Mustafa Gezen on 27.07.2015.
//  Copyright © 2015 Mustafa Gezen. All rights reserved.
//

#import "defines.h"
#import "decompress.h"
#import "kdmSource.h"
#import "kdmPackage.h"

@implementation kdmSource
+ (kdmSource*)initWithSourceURL:(NSString*)url {
	kdmSource *this = [[kdmSource alloc] init];
	this->_source = url;
	
	this->_manager = [AFHTTPSessionManager manager];
	this->_semaphore = dispatch_semaphore_create(0);
	this->_manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	this->_manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	
	NSSet *acceptableTypes = [NSSet setWithObjects:@"application/octet-stream", @"text/plain", @"text/html", @"application/x-bzip2", nil];
	[this->_manager.responseSerializer setAcceptableContentTypes:acceptableTypes];
	
	this->_packages = [[NSMutableArray alloc] init];
	
	[this parseRelease];
	[this parsePackages];
	
	DEBUGLOG("Finished scanning packages for %s", [url UTF8String]);
	
	return this;
}

+ (kdmSource*)initWithCache:(NSDictionary*)info {
	kdmSource *this = [[kdmSource alloc] init];
	
	ReleaseStruct rel;
	rel.label = strdup([[info objectForKey:@"ReleaseLabel"] UTF8String]);
	rel.label = strdup([[info objectForKey:@"ReleaseDescription"] UTF8String]);
	
	this->_rel = rel;
	this->_source = [info objectForKey:@"Source"];
	this->_packages = [[NSMutableArray alloc] init];
	
	return this;
}

- (void)parseRelease {
	[self->_manager GET:[self.source stringByAppendingPathComponent:@"Release"] parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
		NSData *responseData = responseObject;
		NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
		
		[self _parseRelease:responseString];
		
		dispatch_semaphore_signal(self->_semaphore);
	} failure:^(NSURLSessionDataTask *task, NSError *error) {
		NLOG(error);
		dispatch_semaphore_signal(self->_semaphore);
	}];
	
	dispatch_semaphore_wait(self->_semaphore, DISPATCH_TIME_FOREVER);
}

- (void)_parseRelease:(NSString*)release {
	NSArray *splitted = [release componentsSeparatedByString:@"\n"];
	ReleaseStruct rel;
	for (NSString *line in splitted) {
		NSArray *releasePart = [line componentsSeparatedByString:@":"];
		
		if ([releasePart count] > 1) {
			NSString *field = [releasePart[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			NSString *value = [releasePart[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			if ([field isEqualToString:@"Label"]) {
				rel.label = strdup([value UTF8String]);
			} else if ([field isEqualToString:@"Description"]) {
				rel.description = strdup([value UTF8String]);
			}
		}
	}
	
	self->_rel = rel;
}

- (void)parsePackages {
	[self->_manager GET:[self.source stringByAppendingPathComponent:@"Packages"] parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
		NSString *responseString;
		if ([responseObject class] == [NSString class]) {
			responseString = responseObject;
		} else {
			NSData *responseData = responseObject;
			responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
		}
		
		[self _parsePackages:responseString];

		dispatch_semaphore_signal(self->_semaphore);
	} failure:^(NSURLSessionDataTask *task, NSError *error) {
		[self parsePackagesBZ2];
		dispatch_semaphore_signal(self->_semaphore);
	}];
	
	dispatch_semaphore_wait(self->_semaphore, DISPATCH_TIME_FOREVER);
}

- (void)parsePackagesBZ2 {
	[self->_manager GET:[self.source stringByAppendingPathComponent:@"Packages.bz2"] parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
		NSString *responseString = decompress(responseObject);
		
		[self _parsePackages:responseString];
		
		dispatch_semaphore_signal(self->_semaphore);
	} failure:^(NSURLSessionDataTask *task, NSError *error) {
		NLOG(error);
		dispatch_semaphore_signal(self->_semaphore);
	}];
	
	dispatch_semaphore_wait(self->_semaphore, DISPATCH_TIME_FOREVER);
}

- (void)_parsePackages:(NSString*)packages {
	NSArray *splitted = [packages componentsSeparatedByString:@"\n"];
	
	NSMutableDictionary *currentVal = [[NSMutableDictionary alloc] init];
	for (NSString *line in splitted) {
		if ([line length] > 2) {
			NSRange range = [line rangeOfString:@":"];
			
			if (range.location != NSNotFound) {
				NSString *field = [[line substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				NSString *value = [[line substringFromIndex:NSMaxRange(range)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				[currentVal setValue:value forKey:field];
			}
		} else {
			kdmPackage *package = [kdmPackage initWithPackageInformation:currentVal sourceURL:self->_source];
			if (![self.packages containsObject:package] && [currentVal count] >= 3) {
				[self.packages addObject:package];
				[currentVal removeAllObjects];
			}
		}
	}
}

- (kdmPackage*)findPackageByIdentifier:(NSString*)identifier {
	for (kdmPackage *package in self.packages) {
		if ([package.packageID isEqualToString:identifier]) {
			return package;
		}
	}
	
	return nil;
}

- (NSString*)source {
	return self->_source;
}

- (NSMutableArray*)packages {
	return self->_packages;
}

- (ReleaseStruct)rel {
	return self->_rel;
}
@end
