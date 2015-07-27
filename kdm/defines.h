//
//  defines.h
//  kdm
//
//  Created by Mustafa Gezen on 27.07.2015.
//  Copyright © 2015 Mustafa Gezen. All rights reserved.
//

#define LOG(fmt, args...) printf(fmt "\n", ##args)
#define NLOG(nsstring) NSLog(@"%@", nsstring)
#define kdmFolder @"/usr/local/kdm"
#define kdmCacheFolder [kdmFolder stringByAppendingPathComponent:@"cache"]
#define kdmSources [kdmFolder stringByAppendingPathComponent:@"sources"]

#ifdef DEBUG
#define DEBUGLOG(fmt, args...) printf(fmt "\n", ##args)
#else
#define DEBUGLOG(fmt, args...)
#endif