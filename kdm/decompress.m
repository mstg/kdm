//
//  decompress.c
//  kdm
//
//  Created by Alexander Zielenski on 3/18/15.
//  Copyright (c) 2015 Alexander Zielenski. All rights reserved.
//

#import "decompress.h"
#import <archive.h>
#import <archive_entry.h>

NSString *decompress(NSData *data) {
	int r;
	ssize_t size;
	
	struct archive *a = archive_read_new();
	struct archive_entry *ae;
	archive_read_support_filter_all(a);
	archive_read_support_format_raw(a);
	r = archive_read_open_memory(a, (void *)data.bytes, data.length);
	
	NSMutableData *buffer = [[NSMutableData alloc] initWithLength:4096];
	
	if (r != ARCHIVE_OK) {
		/* ERROR */
		return @"";
	}
	r = archive_read_next_header(a, &ae);
	if (r != ARCHIVE_OK) {
		/* ERROR */
		return @"";
	}
	
	ssize_t bytesWritten = 0;
	NSMutableData *output = [[NSMutableData alloc] init];
	for (;;) {
		// read the next few mb of data
		size = archive_read_data(a, (void *)buffer.mutableBytes, 4096);
		if (size < 0) {
			/* ERROR */
		}
		if (size == 0)
			break;
		
		bytesWritten += size;
		[output appendData:buffer];
		[buffer resetBytesInRange:NSMakeRange(0, buffer.length)];
	}
	
	archive_read_free(a);
	
	return [[NSString alloc] initWithData:output encoding:NSASCIIStringEncoding];
}