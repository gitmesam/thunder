import qbs
import qbs.FileInfo

Project {
    id: glsl
    property stringList srcFiles: [
        "glslang/GenericCodeGen/**/*.cpp",
        "glslang/MachineIndependent/**/*.cpp",
        "glslang/Public/**/*.cpp",
        "SPIRV/**/*.cpp",
        "glslang/GenericCodeGen/**/*.h",
        "glslang/MachineIndependent/**/*.h",
        "glslang/Public/**/*.h",
        "glslang/Include/**/*.h",
        "glslang/OSDependent/**/*.h",
        "SPIRV/**/*.h",
        "OGLCompilersDLL/*.cpp"
    ]

    property stringList incPaths: [
        "OGLCompilersDLL"
    ]

    StaticLibrary {
        name: "glsl"
        condition: glsl.desktop
        files: glsl.srcFiles
        Depends { name: "cpp" }
        bundle.isBundle: false

        cpp.includePaths: glsl.incPaths
        cpp.libraryPaths: [ ]
        cpp.cxxLanguageVersion: "c++14"
        cpp.minimumMacosVersion: "10.12"
        cpp.cxxStandardLibrary: "libc++"

        Properties {
            condition: qbs.targetOS.contains("windows")
            files: outer.concat(["glslang/OSDependent/Windows/ossource.cpp"])
        }
        
        Properties {
            condition: qbs.targetOS.contains("unix")
            files: outer.concat(["glslang/OSDependent/Unix/ossource.cpp"])
        }
    }
}
