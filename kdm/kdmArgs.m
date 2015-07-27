//
//  kdmArgs.m
//  kdm
//
//  Created by Mustafa Gezen on 27.07.2015.
//  Copyright © 2015 Mustafa Gezen. All rights reserved.
//

#import "defines.h"
#import "kdmArgs.h"
#import "kdmSource.h"
#import "kdmPackage.h"
#import "libdpkg_objc.h"

@implementation kdmArgs
+ (kdmArgs*)initWithArguments:(NSArray*)args {
	kdmArgs *this = [[kdmArgs alloc] init];
	this.sources = [[NSMutableArray alloc] init];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[kdmCacheFolder stringByAppendingPathComponent:@"cache.db"]]) {
		this->_queue = [FMDatabaseQueue databaseQueueWithPath:[kdmCacheFolder stringByAppendingPathComponent:@"cache.db"]];
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:kdmFolder]) {
		[this setupCache];
	}
	
	if ([args[1] isEqualToString:@"setup"]) {
		[this setup];
	} else if ([args[1] isEqualToString:@"update"]) {
		[this update];
	} else if ([args[1] isEqualToString:@"autoremove"]) {
		[this autoremove];
	} else if ([args[1] isEqualToString:@"list"]) {
		[this list];
	} else if ([args[1] isEqualToString:@"upgrade"]) {
		[this upgrade];
	}  else if ([args[1] isEqualToString:@"check"]) {
		[this check:args[2]];
	} else if ([args[1] isEqualToString:@"install"]) {
		[this install:args[2] type:@"package"];
	} else if ([args[1] isEqualToString:@"remove"]) {
		[this remove:args[2]];
	} else if ([args[1] isEqualToString:@"remove-repo"]) {
		[this removeRepo:args[2]];
	} else if ([args[1] isEqualToString:@"add-repo"]) {
		[this addRepo:args[2]];
	}
	
	return this;
}

- (void)setupCache {
	[_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
		[db executeUpdate:@"CREATE TABLE IF NOT EXISTS `installed` ( `packageID` TEXT, `type` TEXT, `version` TEXT);"];
		
		FMResultSet *s = [db executeQuery:@"SELECT * FROM sources"];
		while ([s next]) {
			NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
			[dict setObject:[s stringForColumn:@"source"] forKey:@"Source"];
			[dict setObject:[s stringForColumn:@"releaseLabel"] forKey:@"ReleaseLabel"];
			[dict setObject:[s stringForColumn:@"releaseDescription"] forKey:@"ReleaseDescription"];
			
			kdmSource *source = [kdmSource initWithCache:dict];
			
			FMResultSet *s_ = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM packages WHERE sourceURL='%@'", source.source]];
			while ([s_ next]) {
				NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
				[dict setObject:[s_ stringForColumn:@"packageID"] forKey:@"Package"];
				[dict setObject:[s_ stringForColumn:@"version"] forKey:@"Version"];
				[dict setObject:[s_ stringForColumn:@"maintainer"] forKey:@"Maintainer"];
				[dict setObject:[s_ stringForColumn:@"installedSize"] forKey:@"Installed-Size"];
				
				[dict setObject:[s_ stringForColumn:@"dependencies"] forKey:@"Depends"];
				[dict setObject:[s_ stringForColumn:@"fileURL"] forKey:@"Filename"];
				[dict setObject:[s_ stringForColumn:@"size"] forKey:@"Size"];
				[dict setObject:[s_ stringForColumn:@"md5Sum"] forKey:@"MD5sum"];
				[dict setObject:[s_ stringForColumn:@"sha1Sum"] forKey:@"SHA1"];
				[dict setObject:[s_ stringForColumn:@"sha256Sum"] forKey:@"SHA256"];
				[dict setObject:[s_ stringForColumn:@"section"] forKey:@"Section"];
				[dict setObject:[s_ stringForColumn:@"pkgDescription"] forKey:@"Description"];
				[dict setObject:[s_ stringForColumn:@"author"] forKey:@"Author"];
				[dict setObject:[s_ stringForColumn:@"icon"] forKey:@"Icon"];
				[dict setObject:[s_ stringForColumn:@"packageName"] forKey:@"Name"];
				
				kdmPackage *package = [kdmPackage initWithPackageInformation:dict sourceURL:[s_ stringForColumn:@"sourceURL"]];
				
				FMResultSet *_s = [db executeQuery:@"SELECT * FROM installed"];
				while ([_s next]) {
					if ([package.packageID isEqualToString:[_s stringForColumn:@"packageID"]]) {
						[source.installedPackages addObject:package];
					}
				}
				
				[source.packages addObject:package];
			}
			
			[self.sources addObject:source];
		}
	}];
}

- (void)setup {
	NSError *error;
	[[NSFileManager defaultManager] createDirectoryAtPath:kdmCacheFolder withIntermediateDirectories:YES attributes:nil error:&error];
	
	if (error) {
		LOG("Permission error - fix your /usr/local dir permissions");
	} else  {
		NSString *content = @"http://repokdm.mstg.io";
		NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
		[[NSFileManager defaultManager] createFileAtPath:kdmSources contents:fileContents attributes:nil];
		FMDatabase *db = [[FMDatabase alloc] initWithPath:[kdmCacheFolder stringByAppendingPathComponent:@"cache.db"]];
		[db open];
		[db close];
	}
}
- (void)update {
	[_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
		[db executeUpdate:@"CREATE TABLE IF NOT EXISTS `sources` (`source` TEXT, `releaseLabel` TEXT, `releaseDescription` TEXT);"];
		[db executeUpdate:@"DELETE FROM sources;"];
		
		[db executeUpdate:@"CREATE TABLE IF NOT EXISTS `packages` (`sourceURL` TEXT, `packageID` TEXT, `version` TEXT, `maintainer` TEXT, `installedSize` INTEGER, `dependencies` TEXT, `fileURL` TEXT, `size` INTEGER, `md5Sum` TEXT, `sha1Sum` TEXT, `sha256Sum` TEXT, `section` TEXT, `pkgDescription` TEXT, `author` TEXT, `icon` TEXT, `packageName` TEXT);"];
		[db executeUpdate:@"DELETE FROM packages;"];
		
		[db executeUpdate:@"CREATE TABLE IF NOT EXISTS `installed` ( `packageID` TEXT, `type` TEXT, `version` TEXT);"];
	}];
	
	[self.sources removeAllObjects];
	
	NSString *sources = [NSString stringWithContentsOfFile:kdmSources encoding:NSUTF8StringEncoding error:nil];
	
	NSRange range = NSMakeRange(0, sources.length);
	while (range.location != NSNotFound) {
		NSRange nextRange = [sources rangeOfString:@"\n" options:NSLiteralSearch range:NSMakeRange(range.location + 2, sources.length - range.location - 2)];
		
		NSUInteger end = nextRange.location;
		if (end == NSNotFound) {
			end = sources.length;
		}
		
		NSString *segment = [sources substringWithRange:NSMakeRange(range.location, end - range.location)];
		segment = [segment stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		range = nextRange;
		
		LOG("Scanning repository %s", [segment UTF8String]);
		kdmSource *source = [kdmSource initWithSourceURL:segment db:_queue];
		[self.sources addObject:source];
	}
}

- (void)check:(NSString*)identifier {
	for (kdmSource *source in self.sources) {
		if ([source findPackageByIdentifier:identifier]) {
			LOG("%s is found in %s", [identifier UTF8String], [source.source UTF8String]);
			return;
		}
	}
	
	LOG("%s was not found", [identifier UTF8String]);
}

- (void)upgrade {
	[self update];
	NSMutableArray *upgradePkgs = [[NSMutableArray alloc] init];
	
	[_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
		FMResultSet *_s_ = [db executeQuery:@"SELECT * FROM installed"];
		
		while ([_s_ next]) {
			for (kdmSource *source in self.sources) {
				for (kdmPackage *package in source.packages) {
					if ([package.packageID isEqualToString:[_s_ stringForColumn:@"packageID"]] && package.version != [_s_ stringForColumn:@"version"]) {
						[upgradePkgs addObject:package];
					}
				}
			}
		}
	}];
	
	for (kdmPackage *package in upgradePkgs) {
		[self install:package.packageID type:@"package"];
		LOG("Upgraded package %s to v%s", [package.packageID UTF8String], [package.version UTF8String]);
	}
}

- (void)install:(NSString*)identifier type:(NSString*)type {
	[_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
		[db executeUpdate:@"CREATE TABLE IF NOT EXISTS `installed` ( `packageID` TEXT, `type` TEXT, `version` TEXT);"];
	}];
	
	for (kdmSource *source in self.sources) {
		kdmPackage *pkg = [source findPackageByIdentifier:identifier];
		
		if (pkg) {
			for (NSString *depend in pkg.dependencies) {
				[self install:depend type:@"dependency"];
			}

			libdpkg_objc *dpkg = [[libdpkg_objc alloc] init];
			dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
			
			[dpkg dpkg_download:pkg.fileURL name:[NSString stringWithFormat:@"%@-%@.deb", pkg.packageID, pkg.version] completion:^(struct dpkg_result result) {
				[dpkg dpkg_install:[dpkg.dpkg_path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.deb", pkg.packageID, pkg.version]] completion:^(struct dpkg_result result) {
					
					if (result.result == 1) {
						LOG("Successfully installed %s", [pkg.packageName UTF8String]);
						[_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
							[db executeUpdate:[NSString stringWithFormat:@"DELETE FROM `installed` WHERE packageID='%@'", pkg.packageID]];
							[db executeUpdate:[NSString stringWithFormat:@"INSERT INTO `installed` VALUES('%@', '%@', '%@')", pkg.packageID, type, pkg.version]];
						}];
						
					} else {
						LOG("%s install failed", [pkg.packageName UTF8String]);
						LOG("Error: \n%s", result.error);
					}
					
					dispatch_semaphore_signal(semaphore);
				}];
			}];
			dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
			break;
		}
	}
}

- (void)remove:(NSString*)identifier {
	for (kdmSource *source in self.sources) {
		kdmPackage *pkg = [source findPackageByIdentifier:identifier];
		
		if (pkg) {
			libdpkg_objc *dpkg = [[libdpkg_objc alloc] init];
			dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

			[dpkg dpkg_remove:identifier completion:^(struct dpkg_result result) {
				if (result.result == 1) {
					LOG("Successfully removed %s", [pkg.packageName UTF8String]);
					[_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
						[db executeUpdate:[NSString stringWithFormat:@"DELETE FROM `installed` WHERE packageID='%@'", pkg.packageID]];
					}];
				} else {
					LOG("Could not remove %s", [pkg.packageName UTF8String]);
					LOG("Error:\n%s", result.output);
				}
				dispatch_semaphore_signal(semaphore);
			}];
			dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
			break;
		}
	}
}

- (void)addRepo:(NSString*)url {
	NSMutableString *content = [NSMutableString stringWithContentsOfFile:kdmSources encoding:NSUTF8StringEncoding error:nil];
	NSArray *contentLines = [content componentsSeparatedByString:@"\n"];
	
	BOOL sourceExists = false;
	for (NSString *line in contentLines) {
		if ([line containsString:url]) {
			sourceExists = true;
		}
	}
	
	if (!sourceExists) {
		if (![url containsString:@"http://"] && ![url containsString:@"https://"]) {
			url = [NSString stringWithFormat:@"http://%@", url];
		}
		[content appendString:[NSString stringWithFormat:@"\n%@", url]];
		LOG("Added %s", [url UTF8String]);
	} else {
		LOG("Could not add repo, because it already exists");
	}
	
	NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
	[[NSFileManager defaultManager] createFileAtPath:kdmSources contents:fileContents attributes:nil];
}

- (void)removeRepo:(NSString*)url {
	NSString *content = [NSString stringWithContentsOfFile:kdmSources encoding:NSUTF8StringEncoding error:nil];
	NSArray *contentLines = [content componentsSeparatedByString:@"\n"];
	
	BOOL removedSource = false;
	for (NSString *line in contentLines) {
		if ([line containsString:url]) {
			content = [content stringByReplacingOccurrencesOfString:line withString:@""];
			removedSource = true;
		}
	}
	
	if (removedSource) {
		LOG("Removed %s", [url UTF8String]);
	} else {
		LOG("Could not remove repo, because it wasn't added");
	}
	
	NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
	[[NSFileManager defaultManager] createFileAtPath:kdmSources contents:fileContents attributes:nil];
}

- (void)autoremove {
	NSMutableArray *dependencies = [[NSMutableArray alloc] init];
	
	[_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
		FMResultSet *s_ = [db executeQuery:@"SELECT * FROM installed"];
		while ([s_ next]) {
		if ([[s_ stringForColumn:@"type"] isEqualToString:@"dependency"]) {
			[dependencies addObject:[s_ stringForColumn:@"packageID"]];
		}
	}
	}];
	
	NSMutableArray *foundPkgs = [[NSMutableArray alloc] init];
	for (kdmSource *source in self.sources) {
		for (NSString *identifier in dependencies) {
			kdmPackage *pkg = [source dependencyWithIdentifier:identifier];
			if (!pkg && ![foundPkgs containsObject:identifier]) {
				[foundPkgs addObject:identifier];
			} else if (pkg && [foundPkgs containsObject:identifier]) {
				[foundPkgs removeObject:identifier];
			}
		}
	}
	
	if ([foundPkgs count] > 0) {
		for (NSString *identifier in foundPkgs) {
			[self remove:identifier];
		}
	}
}

- (void)list {
	for (kdmSource *source in self.sources) {
		LOG("In source: %s", [source.source UTF8String]);
		for (kdmPackage *package in source.packages) {
			if ([source.installedPackages containsObject:package]) {
				LOG("    Package: %s - v%s (Installed)", [package.packageName UTF8String], [package.version UTF8String]);
			} else {
				LOG("    Package: %s - v%s", [package.packageName UTF8String], [package.version UTF8String]);
			}
			LOG("        %s", [package.pkgDescription UTF8String]);
		}
		LOG("\n");
	}
}

@end
