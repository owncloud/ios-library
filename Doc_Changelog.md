What's the new in 1.1.3 version
---------------

From OC 8.1, the server manage the forbbiden characters except the '/'. 

New method to check if the server has forbidden characters support.
- (void) hasServerForbiddenCharactersSupport:(NSString*) path onCommunication:(OCCommunication *)sharedOCCommunication .....

We have prepared the current createFolder and moveFileOrFolder methods for do support that. We have added a new BOOL parameter "isFCSupported" using the previews method you can know what is the value of "isFCSupported"

You can see more specific in OCCommunication class.



Previous changes:
---------------

Download queue
---------------
When we download a file we use a queue in order to download the files one by one. 
By default the queue es FIFO. We will download the files in the order that the developer add them.
But if we want to use the queue as LIFO (download first the last file that we add to download) we need to call "setDownloadQueueToLIFO" method
Code example
~~~~~~~~~~~~
.. code-block:: objective-c
//Set the downloads with LIFO system
[[AppDelegate sharedOCCommunication] setDownloadQueueToLIFO:YES];
