# ownCloud WebDav Library for iOS v1.0

### Introduction
Using ownCloud WebDav library for iOS you have the easy way to communicate with ownCloud servers. You can add the library in your project and integrate your application with ownCloud easily.

### Install Library
#### 2.1. Information how to get the library
You can get this code and compile with Xcode 5. In the repository there are the library project “OCCommunicationLib” and the example project “OCLibraryExample”. Open the “OCLibraryExample” you can see how use the library. 
#### 2.2. Add library to your project
To add the library of your project there are two ways:

Method 1. Reference the headers and the library binary file (.a) directly.
Method 2. Include the library project as a Subproject.

Choosing one or the other method really depends on your own preferences and whether you have the source code and the project file of the static library at your disposal.

#####Method 1: Header and library binary files
__Step 1__.  Compile the OCCommunicationLib and run the project, the libOCConmmunicationLib.a will be generated. 

You need this files: 

__Library File__

* libOCComunicationLibrary.a (Library) 

__Library Classes__

* OCComunication.h (Accesors) Import in the communication clases
* OCErrorMsg.h (Error messages) Import in the communication clases
* OCFileDto.h (File/Folder object) Import when you use readFolder and readFile methods
* OCFileDto.m
* OCFrameworkConstants.h (Customize constants)

__Step 2.__  Add the library file in your project.  Linked the library file in your project target. "build phases" -> "Link binary with libraries" and tap in "+" and select the library file.

  
__Step 3.__  We have to add the path of the library headers. In your project target "build settings" in the option "Header Search Paths" add the path.

__Step 4.__  In your project target "build settings" add the flag "-Obj-C" to the "Other Linker Flag" option


#####Method 2: Subprojects

__Step 1.__ Add the file OCCommunicationLib.xcodeproj to your project using drag and drop.


__Step 2.__ In your project target go to "build phases" -> "Target Dependencies" and tap in "+" and select the library target.

__Step 3.__ Now linked the library file in your project target. "build phases" -> "Link binary with libraries" and tap in "+" and select the library file.

__Step 4.__ In your project target "build settings" add the flag "-Obj-C" to the "Other Linker Flag" option

__Step 5.__ And finally we have to add the path of the library headers. In your project target "build settings" in the option "Header Search Paths" add the path.

__Source:__

RayWenderlich.com <http://www.raywenderlich.com/41377/creating-a-static-library-in-ios-tutorial>
 
Apple.com <https://developer.apple.com/library/ios/technotes/iOSStaticLibraries/Articles/configuration.html#/apple_ref/doc/uid/TP40012554-CH3-SW2>

###  License

ownCloud webDAV Library for iOS has MIT License. 
 
Copyright (c) 2014 ownCloud (http://www.owncloud.org/)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

#### Third part libraries

ownCloud webDAV library for iOS use AFNetworking version 1.3.0 which is not the latest one. AFNetworking is available under the MIT license. 

ownCloud webDAV library for iOS use some classes based in  https://github.com/zwaldowski/DZWebDAVClient. Copyright (c) 2012 Zachary Waldowski, Troy Brant, Marcus Rohrmoser, and Sam Soffes.


### Compatibility

ownCloud webDAV library for iOS support iOS 6/ iOS 7 and works in Xcode 5.

ownCloud webDAV library support server since version 4.5.




