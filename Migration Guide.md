# Migration Guide for ownCloud Lib version 1.X to 2.X

### Introduction
This document explain how to adapt your application to the new version 2.X of ownCloud Lib. Do not worry, it is too easy!
The ownCloud Lib now use AFNetworking 3.0 in order to be used also on the Apple Watch and on the Apple TV. The main change it is that now we make every network operation using NSURLSession instead NSOperation.

### Network Operations
The network operations #are:
##### - Read file or folder
##### - Create folder
##### - Move file or folder
##### - Remove file or folder
##### - Share file or folder
##### - Read shares
##### - Read shares
##### - Get server features
##### - Get server capabilities

On all those methods you just have to change the __NSHTTPURLResponse__ for __NSURLResponse__ on the response blocks.

### Downloads and Uploads Operations
Here we have 2 methods for downloads and 2 methods for uploads. One of each one it is for downloades in background and the others are for downloads in foreground.

The main differences are:
###### - It is not necessary send the reference of an __NSProgress__ becaue you receive the __NSProgress__ on the progress block.
###### - You get an NSURLSessionDownloadTask or __NSURLSessionUploadTask__ for background and for foreground a __NSURLSessionTask__. Are cancelable.
###### - All the parameters are exactly the same.
