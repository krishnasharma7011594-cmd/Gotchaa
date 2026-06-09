cmake_minimum_required(VERSION 3.10.2)

project("beauty_engine")

# Note: The user will need to download the OpenCV Android SDK and set this path
# set(OpenCV_DIR "path/to/opencv/sdk/native/jni")
# find_package(OpenCV REQUIRED)

add_library( # Sets the name of the library.
             beauty_engine

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             BeautyEngine.cpp )

# target_link_libraries( # Links the target library to the log library
#                        # included in the NDK.
#                        beauty_engine
#                        ${OpenCV_LIBS}
#                        log )
