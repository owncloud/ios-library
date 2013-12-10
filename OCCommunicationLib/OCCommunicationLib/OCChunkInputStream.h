//
//  OCChunkInputStream.h
//  Owncloud iOs Client
//
//  Created by javi on 11/21/13.
//
//

#import <Foundation/Foundation.h>

@interface OCChunkInputStream : NSInputStream <NSStreamDelegate>

///-----------------------------------
/// @name initWithInputStream
///-----------------------------------

/**
 * Method to create a InputStream overwritted to read all the chunks with the same InputStream
 *
 * @param NSInputStream -> stream. This is the InputStream that we will control to read chunk by chunk
 * @param long long -> bytesToRead. This is all the bytes that we expect to read (the size of the file)
 *
 * @return id -> we return himself
 *
 */
- (id)initWithInputStream:(NSInputStream *) stream andBytesToRead:(long long) bytesToRead;

@property (nonatomic, retain) NSInputStream *parentStream;
@property (nonatomic,weak) __weak id <NSStreamDelegate> delegate;
@property BOOL isChunkComplete;
@property int bytesReadInThisIteration;
@property long long totalBytesRead;
@property long long bytesToRead;


@end
