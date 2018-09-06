# Distributing an app with embedded Python on a Mac

This document explains how to embed an isolated Python distribution in an application on MacOS. Certain aspects of this guide might only apply to Python 3.

We have two main goals:

1. That users can run release builds regardless of which (if any) Python distributions exist on their system
2. That developers can build against Python headers and shared library in the project directory, so the same Xcode project works on different systems


## Gathering the Python resources

First create a directory called `PythonResources` alongside the `.xcodeproj` file in your project's root directory. We'll copy everything we need into that directory.

Starting with version 3.5, CPython now distributes an official embeddable zip file that contains minified versions of all of its external resources. Unfortunately, they only seem to think this is useful on Windows, so all the binary resources it contains are useless on MacOS. However we can still use the collection of Python standard library bytecode they have compiled for us. Download the official embeddable zip file, and extract its zipped standard library file.

    wget https://www.python.org/ftp/python/3.6.1/python-3.6.1-embed-amd64.zip
    unzip python-3.6.1-embed-amd64.zip python36.zip -d PythonResources
    rm python-3.6.1-embed-amd64.zip

We removed the zip file at the end, because that was all we needed from it.

The next step is to copy headers and shared library files from our system's Python installation. If you have installed Python with the CPython installer, you should find it in a directory such as:

    /Library/Frameworks/Python.framework/Versions/3.6

You might want to store that directory in a shell variable called `$pydist`.

    cp -r $pydist/Headers PythonResources/include
    cp -r $pydist/Python PythonResources

We also need (some of) the contents of Python's `lib-dynload` directory. It contains shared object files for libraries like `zlib` and `cmath`. In the end we can reduce the size of this directory (from ~12 MB to less than 1) by removing libraries we don't need. But for now just copy the whole thing:

    cp -r $pydist/lib/python3.6/lib-dynload PythonResources

Your `PythonResources` directory should now contain the following files:

    Python
    include
    lib-dynload
    python36.zip

In order to use the Python shared library on a different system, we need to bundle it with the application. We also need to modify the shared library itself to reflect its new location in the bundle. We are eventually going to copy this library to the application bundle's `Contents/Resources` directory. So, we need to rename the shared library's `id` attribute to reflects its new location relative to application bundle:

    install_name_tool -id @loader_path/Resources/Python PythonResources/Python


## Configuring Xcode

Configuring Xcode to use our local Python resources involves four main steps:

1. Make Python headers available to compiled code
2. Link against our local Python shared library
3. Copy the Python runtime resources to the application bundle on build
4. Tell the interpreter where to find the runtime resources
