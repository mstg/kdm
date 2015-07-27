//
//  kdmPackage.m
//  kdm
//
//  Created by Mustafa Gezen on 27.07.2015.
//  Copyright © 2015 Mustafa Gezen. All rights reserved.
//

#import "defines.h"
#import "kdmPackage.h"

@implementation kdmPackage
+ (kdmPackage*)initWithPackageInformation:(NSDictionary*)info sourceURL:(NSString*)url {
	kdmPackage *this = [[kdmPackage alloc] init];
	
	this->_dependencies = [[NSMutableArray alloc] init];
	this->_sourceURL = url;
	
	NSArray *possibleValues = @[@"Package", @"Version", @"Maintainer", @"Installed-Size", @"Depends", @"Filename", @"Size", @"MD5sum", @"SHA1", @"SHA256", @"Section", @"Description", @"Author", @"Name", @"Icon"];
	
	NSArray *dependenciesSplit;
	for (NSString *key in info) {
		NSUInteger item = [possibleValues indexOfObject:key];
		id value = [info objectForKey:key];
		switch (item) {
			case 0:
				this->_packageID = value;
				break;
			case 1:
				this->_version = value;
				break;
			case 2:
				this->_maintainer = value;
				break;
			case 3:
				this->_installedSize = (int)value;
				break;
			case 4:
				dependenciesSplit = [value componentsSeparatedByString:@","];
				
				for (NSString *_value in dependenciesSplit) {
					if (![_value containsString:@"("]) {
						[this.dependencies addObject:[[_value componentsSeparatedByString:@"("][0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
					}
				}
				break;
			case 5:
				this->_fileURL = [url stringByAppendingString:[NSString stringWithFormat:@"/%@", value]];
				break;
			case 6:
				this->_size = (int)value;
				break;
			case 7:
				this->_md5Sum = value;
				break;
			case 8:
				this->_sha1Sum = value;
				break;
			case 9:
				this->_sha256Sum = value;
				break;
			case 10:
				this->_section = value;
				break;
			case 11:
				this->_pkgDescription = value;
				break;
			case 12:
				this->_author = value;
				break;
			case 13:
				this->_packageName = value;
				break;
			case 14:
				this->_icon = value;
				break;
		}
	}
	
	return this;
}

- (NSString*)sourceURL {
	return self->_sourceURL;
}

- (NSString*)packageID {
	return self->_packageID;
}

- (NSString*)version {
	return self->_version;
}

- (NSString*)maintainer {
	return self->_maintainer;
}

- (int)installedSize {
	return self->_installedSize;
}

- (NSMutableArray*)dependencies {
	return self->_dependencies;
}

- (NSString*)fileURL {
	return self->_fileURL;
}

- (int)size {
	return self->_size;
}

- (NSString*)md5Sum {
	return self->_md5Sum;
}

- (NSString*)sha1Sum {
	return self->_sha1Sum;
}

- (NSString*)sha256Sum {
	return self->_sha256Sum;
}

- (NSString*)section {
	return self->_section;
}

- (NSString*)pkgDescription {
	return self->_pkgDescription;
}

- (NSString*)author {
	return self->_author;
}

- (NSString*)icon {
	return self->_icon;
}

- (NSString*)packageName {
	return self->_packageName;
}

@end
