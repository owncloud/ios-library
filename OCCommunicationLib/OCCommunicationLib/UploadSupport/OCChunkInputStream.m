//
//  OCChunkInputStream.m
//  Owncloud iOs Client
//
//  Created by javi on 11/21/13.
//
//

#import "OCChunkInputStream.h"
#import "OCFrameworkConstants.h"

@implementation OCChunkInputStream

/**
 * Method to create a InputStream overwritted to read all the chunks with the same InputStream
 *
 * @param NSInputStream -> stream. This is the InputStream that we will control to read chunk by chunk
 * @param long long -> bytesToRead. This is all the bytes that we expect to read (the size of the file)
 *
 * @return id -> we return himself
 *
 */
- (id)initWithInputStream:(NSInputStream *) stream andBytesToRead:(long long) bytesToRead {
    self = [super init];
    if (self) {
        // Initialization code here.
        _parentStream = stream;
        [_parentStream setDelegate:self];
        _bytesReadInThisIteration = 0;
        _totalBytesRead = 0;
        _bytesToRead = bytesToRead;
        
        self.delegate = self;
    }
    
    return self;
}

#pragma mark NSStream subclass methods

- (void)open {
    [_parentStream open];
}

- (void)close {
    if (_totalBytesRead == _bytesToRead) {
        [_parentStream close];
    }
}

- (id <NSStreamDelegate> )delegate {
    return self.delegate;
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    [_parentStream scheduleInRunLoop:aRunLoop forMode:mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    [_parentStream removeFromRunLoop:aRunLoop forMode:mode];
}

- (id)propertyForKey:(NSString *)key {
    return [_parentStream propertyForKey:key];
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    return [_parentStream setProperty:property forKey:key];
}

- (NSStreamStatus)streamStatus {
    return [_parentStream streamStatus];
}

- (NSError *)streamError {
    return [_parentStream streamError];
}

#pragma mark Undocumented CFReadStream bridged methods

- (void)_scheduleInCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)aMode {
    
    CFReadStreamScheduleWithRunLoop((CFReadStreamRef)_parentStream, aRunLoop, aMode);
}

- (BOOL)_setCFClientFlags:(CFOptionFlags)inFlags
                 callback:(CFReadStreamClientCallBack)inCallback
                  context:(CFStreamClientContext *)inContext {
    return NO;
}

- (void)_unscheduleFromCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)aMode {
    
    CFReadStreamUnscheduleFromRunLoop((CFReadStreamRef)_parentStream, aRunLoop, aMode);
}

#pragma mark NSInputStream subclass methods
- (NSInteger) read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    
    NSInteger bytesRead;
    
    if (_isChunkComplete) {
        //In the previous loop we read the last byte of the chunk so we reset the vars an return a 0 to indicate that the buffer was end
        _isChunkComplete = NO;
        _bytesReadInThisIteration = 0;
        bytesRead = 0;
    } else {
        bytesRead = [_parentStream read:buffer maxLength:len];
        
        //We save the bytes to control when we finish the chunk
        _bytesReadInThisIteration = bytesRead + _bytesReadInThisIteration;
        //We save the bytes to control when we finish completly the file
        _totalBytesRead = bytesRead + _totalBytesRead;
        
        if (_bytesReadInThisIteration == k_lenght_chunk) {
            //Each we read the last byte of a full chunk we have to stop the process
            _isChunkComplete = YES;
        }
    }
    
    return bytesRead;
}

- (BOOL) getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
    return NO;
}

- (BOOL) hasBytesAvailable {
    return [_parentStream hasBytesAvailable];
}

@end
