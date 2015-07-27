//
//  kdmArgs.h
//  kdm
//
//  Created by Mustafa Gezen on 27.07.2015.
//  Copyright © 2015 Mustafa Gezen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface kdmArgs : NSObject {
	FMDatabase *_db;
}
@property (retain) NSMutableArray *sources;
+ (kdmArgs*)initWithArguments:(NSArray*)args;
@end
