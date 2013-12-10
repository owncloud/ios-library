//
//  NSString+Encode.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/10/12.
//
//

#import "NSString+Encode.h"

@implementation NSString (encode)
- (NSString *)encodeString:(NSStringEncoding)encoding
{
    
    /*NSString *output = (__bridge NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self,
                                                                                     NULL, (CFStringRef)@";/?:@&=$+{}<>,",
                                                                                     CFStringConvertNSStringEncodingToEncoding(encoding));*/
    
    CFStringRef stringRef = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self,
                                                                    NULL, (CFStringRef)@";?@&=$+{}<>,",
                                                                    CFStringConvertNSStringEncodingToEncoding(encoding));
    
    NSString *output = (NSString *)CFBridgingRelease(stringRef);
                                                                    
                                                                    
    

    int countCharactersAfterPercent = -1;
    
    for(int i = 0 ; i < [output length] ; i++) {
        NSString * newString = [output substringWithRange:NSMakeRange(i, 1)];
        //NSLog(@"newString: %@", newString);
        
        if(countCharactersAfterPercent>=0) {
            
            //NSLog(@"newString lowercaseString: %@", [newString lowercaseString]);
            output = [output stringByReplacingCharactersInRange:NSMakeRange(i, 1) withString:[newString lowercaseString]];
            countCharactersAfterPercent++;
        }
        
        if([newString isEqualToString:@"%"]) {
            countCharactersAfterPercent = 0;
        }
        
        if(countCharactersAfterPercent==2) {
            countCharactersAfterPercent = -1;
        }
    }
    
    NSLog(@"output: %@", output);
    
    return output;
}

@end
