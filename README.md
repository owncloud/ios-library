# ownCloud iOS Library v 0.9.1

### Introduction
Using ownCloud iOS library it will be the easiest way to communicate with ownCloud servers.
Add this library in your project and integrate your application with ownCloud seamlessly.

### Install Library
#### 2.1. Information how to get the library
Get this code and compile with Xcode 5. In the repository it is not only the library project “ownCloud iOS library” but also the example project “OCLibraryExample”. Thanks to the “OCLibraryExample” you will learn how to use the library.
#### 2.2. Add library to your project
There are two ways of adding this library to your code:

Method 1. Reference the headers and the library binary file (.a) directly.

Method 2. Include the library project as a Subproject.

Choosing one method or the other one just depends on your own preferences as well as whether you have the source code and the project file of the static library at your disposal.

#####Method 1: Header and library binary files
__Step 1__.  Compile the "ownCloud iOS library" and run the project, the libownCloudiOS.a will be generated. 

You need these files: 

__Library File__

* libownCloudiOS.a (Library) 

__Library Classes__

* OCComunication.h (Accesors) Import in the communication classes
* OCErrorMsg.h (Error messages) Import in the communication classes
* OCFileDto.h (File/Folder object) Import when you use readFolder and readFile methods
* OCFileDto.m
* OCFrameworkConstants.h (Customize constants)

__Step 2.__  Add the library file in your project.  Link the library file in your project target. "build phases" -> "Link binary with libraries" and tap in "+" and select the library file.

  
__Step 3.__  Add the path of the library headers. In your project target "build settings" in the option "Header Search Paths" add the path.

__Step 4.__  In your project target "build settings" add the flag "-Obj-C" to the "Other Linker Flag" option


#####Method 2: Subprojects

__Step 1.__ Add the file "ownCloud iOS library.xcodeproj" to your project using drag and drop.


__Step 2.__ In your project target go to "build phases" -> "Target Dependencies" and tap in "+" and select the library target.

__Step 3.__ Now link the library file in your project target. "build phases" -> "Link binary with libraries" and tap in "+" and select the library file.

__Step 4.__ In your project target "build settings" add the flag "-Obj-C" to the "Other Linker Flag" option

__Step 5.__ And finally, add the path of the library headers. In your project target "build settings" in the option "Header Search Paths" add the path.

__Source:__

RayWenderlich.com <http://www.raywenderlich.com/41377/creating-a-static-library-in-ios-tutorial>
 
Apple.com <https://developer.apple.com/library/ios/technotes/iOSStaticLibraries/Articles/configuration.html#/apple_ref/doc/uid/TP40012554-CH3-SW2>

###  Branching strategy

The repository holds two main branches with an infinite lifetime:

- master
- develop 

Branch __origin/master__ is considered the main branch where the source code of HEAD always reflects a production-ready state.

Branch __origin/develop__ is considered the main branch where the source code of HEAD always reflects a state with the latest delivered development changes for the next release.

When the source code in the develop branch reaches a stable point and is ready to be released, all of the changes should be merged back into master somehow and then tagged with a release number. 

Other branches, some supporting branches are used to aid parallel development between team members, ease tracking of features, prepare for production releases and to assist in quickly fixing live production problems. Unlike the main branches, these branches always have a limited life time, since they will be removed eventually.

The different types of branches we may use are:

- Branch __perNewFeature__    
- Branch  __releaseBranches__

Both of them branch off from develop and must merge back into develo branch through a Pull Request in Github. Once the PR is approved and merged, the US branch may be deleted

Source: http://nvie.com/posts/a-successful-git-branching-model  

###  License

ownCloud iOS library is available under the MIT License. 
 
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

#### Third party libraries

ownCloud iOS library uses AFNetworking version 2.2.4. AFNetworking is available under the MIT license. 

ownCloud iOS library uses some classes based in  https://github.com/zwaldowski/DZWebDAVClient. Copyright (c) 2012 Zachary Waldowski, Troy Brant, Marcus Rohrmoser, and Sam Soffes under the MIT license.


### Compatibility

ownCloud iOS library supports both iOS 6 and iOS 7 and works in Xcode 5.

ownCloud iOS library supports ownCloud server from version 4.5.




