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
	
	this->_db = [FMDatabase databaseWithPath:[kdmCacheFolder stringByAppendingPathComponent:@"cache.db"]];
	
	[this setupCache];
	
	if ([args[1] isEqualToString:@"setup"]) {
		[this setup];
	} else if ([args[1] isEqualToString:@"update"]) {
		[this update];
	} else if ([args[1] isEqualToString:@"check"]) {
		[this check:args[2]];
	} else if ([args[1] isEqualToString:@"install"]) {
		[this install:args[2]];
	}
	
	return this;
}

- (void)setupCache {
	[self->_db open];
	
	FMResultSet *s = [self->_db executeQuery:@"SELECT * FROM sources"];
	while ([s next]) {
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		[dict setObject:[s stringForColumn:@"source"] forKey:@"Source"];
		[dict setObject:[s stringForColumn:@"releaseLabel"] forKey:@"ReleaseLabel"];
		[dict setObject:[s stringForColumn:@"releaseDescription"] forKey:@"ReleaseDescription"];
		
		kdmSource *source = [kdmSource initWithCache:dict];
		
		FMResultSet *s_ = [self->_db executeQuery:[NSString stringWithFormat:@"SELECT * FROM packages WHERE sourceURL='%@'", source.source]];
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
			[source.packages addObject:package];
		}
		
		[self.sources addObject:source];
	}
	
	[self->_db close];
}

- (void)setup {
	NSError *error;
	[[NSFileManager defaultManager] createDirectoryAtPath:kdmCacheFolder withIntermediateDirectories:YES attributes:nil error:&error];
	
	if (error) {
		LOG("Permission error - run kdm with sudo");
	} else  {
		NSString *content = @"http://repo.alexzielenski.com";
		NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
		[[NSFileManager defaultManager] createFileAtPath:kdmSources contents:fileContents attributes:nil];
	}
}
- (void)update {
	[self->_db open];
	[self->_db executeUpdate:@"DROP TABLE IF EXISTS sources;"];
	[self->_db executeUpdate:@"CREATE TABLE `sources` (`source` TEXT, `releaseLabel` TEXT, `releaseDescription` TEXT);"];
	
	[self->_db executeUpdate:@"DROP TABLE IF EXISTS packages;"];
	[self->_db executeUpdate:@"CREATE TABLE `packages` (`sourceURL` TEXT, `packageID` TEXT, `version` TEXT, `maintainer` TEXT, `installedSize` INTEGER, `dependencies` TEXT, `fileURL` TEXT, `size` INTEGER, `md5Sum` TEXT, `sha1Sum` TEXT, `sha256Sum` TEXT, `section` TEXT, `pkgDescription` TEXT, `author` TEXT, `icon` TEXT, `packageName` TEXT);"];
	
	[self.sources removeAllObjects];
	
	NSString *sources = [NSString stringWithContentsOfFile:kdmSources encoding:NSUTF8StringEncoding error:nil];
	NSArray *sourceList = [sources componentsSeparatedByString:@"\n"];
	
	for (NSString *line in sourceList) {
		if ([line length] > 0) {
			LOG("Scanning repository %s", [line UTF8String]);
			kdmSource *source = [kdmSource initWithSourceURL:line];
			[self->_db executeUpdate:[NSString stringWithFormat:@"INSERT INTO `sources` VALUES ('%@', '%s', '%s')", source.source, source.rel.label, source.rel.description]];
			[self.sources addObject:source];
		}
	}
	
	for (kdmSource *source in self.sources) {
		for (kdmPackage *package in source.packages) {
			NSMutableString *dependString = [[NSMutableString alloc] init];
			for (NSString *string in package.dependencies) {
				[dependString appendString:[NSString stringWithFormat:@"%@,", string]];
			}
			
			if ([dependString length] > 0 && [[dependString substringToIndex:[dependString length] - 1] isEqualToString:@"|"]) {
				dependString = [[dependString substringToIndex:[dependString length] - 1] mutableCopy];
			}
			
			[self->_db executeUpdate:[NSString stringWithFormat:@"INSERT INTO `packages` VALUES ('%@', '%@', '%@', '%@', '%d','%@', '%@',  '%d', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@')", package.sourceURL, package.packageID, package.version, package.maintainer, package.installedSize, dependString, [package.fileURL stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/", package.sourceURL] withString:@""], package.size, package.md5Sum, package.sha1Sum, package.sha256Sum, package.section, package.pkgDescription, package.author, package.icon, package.packageName]];
		}
	}
	
	[self->_db close];
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

- (void)install:(NSString*)identifier {
	for (kdmSource *source in self.sources) {
		kdmPackage *pkg = [source findPackageByIdentifier:identifier];
		
		if (pkg) {
			for (NSString *depend in pkg.dependencies) {
				[self install:depend];
			}

			libdpkg_objc *dpkg = [[libdpkg_objc alloc] init];
			
			dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
			[dpkg dpkg_download:pkg.fileURL name:[NSString stringWithFormat:@"%@-%@.deb", pkg.packageID, pkg.version] completion:^(struct dpkg_result result) {
				[dpkg dpkg_install:[dpkg.dpkg_path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.deb", pkg.packageID, pkg.version]] completion:^(struct dpkg_result result) {
					LOG("%s", result.error);
					dispatch_semaphore_signal(semaphore);
				}];
			}];
			dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
		}
	}
}

@end
