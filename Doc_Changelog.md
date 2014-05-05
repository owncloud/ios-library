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