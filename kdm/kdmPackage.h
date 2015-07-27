//
//  kdmPackage.h
//  kdm
//
//  Created by Mustafa Gezen on 27.07.2015.
//  Copyright © 2015 Mustafa Gezen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
	char *dependPackageName;
	float *dependPackageVer;
} dependPackage;

@interface kdmPackage : NSObject {
	NSString *_sourceURL;
	NSString *_packageID;
	NSString *_version;
	NSString *_maintainer;
	int _installedSize;
	NSMutableArray *_dependencies;
	NSString *_fileURL;
	int _size;
	NSString *_md5Sum;
	NSString *_sha1Sum;
	NSString *_sha256Sum;
	NSString *_section;
	NSString *_pkgDescription;
	NSString *_author;
	NSString *_icon;
	NSString *_packageName;
}
+ (kdmPackage*)initWithPackageInformation:(NSDictionary*)info sourceURL:(NSString*)url;
- (NSString*)sourceURL;
- (NSString*)packageID;
- (NSString*)version;
- (NSString*)maintainer;
- (int)installedSize;
- (NSMutableArray*)dependencies;
- (NSString*)fileURL;
- (int)size;
- (NSString*)md5Sum;
- (NSString*)sha1Sum;
- (NSString*)sha256Sum;
- (NSString*)section;
- (NSString*)pkgDescription;
- (NSString*)author;
- (NSString*)icon;
- (NSString*)packageName;
@end
