//
//  main.m
//  kdm
//
//  Created by Mustafa Gezen on 27.07.2015.
//  Copyright © 2015 Mustafa Gezen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defines.h"
#import "kdmArgs.h"

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		NSArray *arguments = [[NSProcessInfo processInfo] arguments];
		
		if ([arguments count] == 1) {
			goto help;
		}
		
		if (([arguments[1]  isEqualToString: @"install"] || [arguments[1]  isEqualToString: @"remove"] || [arguments[1] isEqualToString:@"add-repo"] || [arguments[1] isEqualToString:@"check"] || [arguments[1] isEqualToString:@"remove-repo"]) && [arguments count] < 3) {
			goto help;
		}
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:kdmFolder] && ![arguments[1] isEqualToString:@"setup"]) {
			LOG("Run \"kdm setup\"");
			return 0;
		}
	
		[kdmArgs initWithArguments:arguments];
	}
    return 0;
	
help:
	LOG("kdm");
	LOG("\nUSAGE:");
	LOG("   kdm [update|install (package id)|remove (package id)|autoremove|list|check (package id)|setup|add-repo (repo url)|remove-repo (repo url)|upgrade]");
	
	LOG("\n(C) Copyright 2015 Mustafa Gezen");
	return 0;
}
