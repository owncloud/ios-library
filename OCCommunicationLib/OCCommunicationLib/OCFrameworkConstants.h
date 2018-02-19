//
//  OCFrameworkConstants.h
//  Owncloud iOs Client
//
// Copyright (C) 2016, ownCloud GmbH. ( http://www.owncloud.org/ )
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

//Timeout for fast requests
#define k_timeout_fast 5 //seconds

//Chunk length
#define k_OC_lenght_chunk 1048576

#define k_domain_error_code @"com.owncloud"

//URL for webdav
//#define k_url_webdav_server @"remote.php/odav/"
#define k_url_webdav_server @"remote.php/webdav/"
#define k_url_webdav_server_without_last_slash @"remote.php/webdav"
#define k_url_webdav_server_with_first_slash @"/remote.php/webdav/"


//URL path for list of files in web interface
#define k_url_path_list_of_files_in_web @"index.php/apps/files"
#define k_url_files_share_link @"apps/files/"
#define k_url_files_private_link @"/remote.php/dav/files/"

//URL to access user data API
#define k_api_user_url_json @"ocs/v1.php/cloud/user?format=json"
#define k_json_ocs @"ocs"
#define k_json_ocs_data @"data"
#define k_json_ocs_data_display_name @"display-name"
#define k_json_ocs_data_user_id @"id"

//Url to access to Shared API to create
#define k_url_acces_shared_api @"ocs/v1.php/apps/files_sharing/api/v1/shares"

//Url to access to Remote Shared API
#define k_url_acces_remote_shared_api @"ocs/v1.php/apps/files_sharing/api/v1/remote_shares"

//Url to access to Sharee API
#define k_url_access_sharee_api @"ocs/v2.php/apps/files_sharing/api/v1/sharees"

//Url to access to Capabilities API
#define k_url_capabilities @"ocs/v1.php/cloud/capabilities"

//Url to access to Remote Thumbnails
//api/v1/thumbnail/{x}/{y}/{file}
#define k_url_thumbnails @"index.php/apps/files/api/v1/thumbnail"

//Version of the server that have share API
#define k_version_support_shared [NSArray arrayWithObjects:  @"5", @"0", @"27", nil]

//Version of the server that have sharee API
#define k_version_support_sharee_api [NSArray arrayWithObjects:  @"8", @"2", @"0", nil]

//Version of the server that supports cookies
#define k_version_support_cookies [NSArray arrayWithObjects:  @"7", @"0", @"0", nil]

//Version of the server that supports forbidden characters
#define k_version_support_forbidden_characters [NSArray arrayWithObjects:  @"8", @"1", @"0", nil]

//Version of the server that supports Capabilities
#define k_version_support_capabilities [NSArray arrayWithObjects:  @"8", @"2", @"0", nil]

//Version of the server that supports enable/disabled share privilege option for federated shares
#define k_version_support_share_option_fed_share [NSArray arrayWithObjects:  @"9", @"1", @"0", nil]

//Version of the server that supports multiple share links and public share links with option to change the name of the link
#define k_version_support_public_share_link_option_name [NSArray arrayWithObjects:  @"10", @"0", @"0", nil]

//Version of the server that supports enable/disabled upload only (file listing, write only) option for public links of folders
#define k_version_support_public_share_link_option_upload_only [NSArray arrayWithObjects:  @"10", @"0", @"1", nil]

//Name of the session using for upload files with NSURLSession
#define k_session_name @"com.owncloud.upload.session"

//Name of the download session using for download files with NSURLSession
#define k_download_session_name @"com.owncloud.download.session"

//Name of the download session using for download files with NSURLSession in ownCloudExtApp
#define k_download_session_name_ext_app @"com.owncloud.download.session.extApp.extension"

//Name of the download session using for download files with NSURLSession
#define k_download_folder_session_name @"com.owncloud.download.folder.session"

//Name of the download session using for download files with NSURLSession
#define k_network_operation_session_name @"com.owncloud.network.operation.session"

//Name of the container to configure NSURLSessions
#define k_shared_container_identifier @"group.com.owncloud.iOSmobileapp";




