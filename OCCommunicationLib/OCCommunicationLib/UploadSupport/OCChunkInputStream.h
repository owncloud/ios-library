//
//  OCChunkInputStream.h
//  Owncloud iOs Client
//
// Copyright (C) 2014 ownCloud Inc. (http://www.owncloud.org/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
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
@property NSInteger bytesReadInThisIteration;
@property long long totalBytesRead;
@property long long bytesToRead;


@end
