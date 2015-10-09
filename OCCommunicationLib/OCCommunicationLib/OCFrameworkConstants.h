//
//  OCFrameworkConstants.h
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

//Timeout to weddav requests
#define k_timeout_webdav 30 //seconds

//Timeout to upload
#define k_timeout_upload 40 //seconds

//Chunk length
#define k_OC_lenght_chunk 1048576

#define k_domain_error_code @"com.owncloud"

//Url to access to Shared API to create
#define k_url_acces_shared_api @"ocs/v1.php/apps/files_sharing/api/v1/shares"

//Version of the server that have share API
#define k_version_support_shared [NSArray arrayWithObjects:  @"5", @"0", @"27", nil]

//Version of the server that support cookies
#define k_version_support_cookies [NSArray arrayWithObjects:  @"7", @"0", @"0", nil]

//Version of the server that support forbidden characters
#define k_version_support_forbidden_characters [NSArray arrayWithObjects:  @"8", @"1", @"0", nil]

//Name of the session using for upload files with NSURLSession
#define k_session_name @"com.owncloud.upload.session"

//Name of the download session using for download files with NSURLSession
#define k_download_session_name @"com.owncloud.download.session"

//Name of the download session using for download files with NSURLSession
#define k_download_folder_session_name @"com.owncloud.download.folder.session"



