import qbs

Project {
    id: angelscript
    property stringList srcFiles: [
        "source/*.cpp"
    ]

    property stringList incPaths: [
        "include"
    ]

    DynamicLibrary {
        name: "angelscript-editor"
        condition: angelscript.desktop
        files: angelscript.srcFiles
        Depends { name: "cpp" }
        bundle.isBundle: false

        cpp.defines: [ "ANGELSCRIPT_EXPORT" ]
        cpp.includePaths: angelscript.incPaths
        cpp.libraryPaths: [ ]
        cpp.dynamicLibraries: [ ]
        cpp.cxxLanguageVersion: "c++14"

        Properties {
            condition: qbs.targetOS.contains("darwin")
            cpp.sonamePrefix: "@executable_path"
        }

        Group {
            name: "Install Dynamic Platform"
            fileTagsFilter: ["dynamiclibrary", "dynamiclibrary_import"]
            qbs.install: true
            qbs.installDir: angelscript.BIN_PATH + "/" + angelscript.bundle
            qbs.installPrefix: angelscript.PREFIX
        }

    }

    StaticLibrary {
        name: "angelscript"
        files: angelscript.srcFiles
        Depends { name: "cpp" }
        Depends { name: "bundle" }
        bundle.isBundle: false

        cpp.defines: [ "ANGELSCRIPT_EXPORT", "AS_NO_COMPILER" ]
        cpp.includePaths: angelscript.incPaths
        cpp.cxxLanguageVersion: "c++14"

        Properties {
            condition: qbs.targetOS.contains("android")
            Android.ndk.appStl: "gnustl_shared"
        }

        Group {
            name: "Install Static angelscript"
            fileTagsFilter: product.type
            qbs.install: true
            qbs.installDir: angelscript.SDK_PATH + "/" + qbs.targetOS[0] + "/" + qbs.architecture + "/lib"
            qbs.installPrefix: angelscript.PREFIX
        }
    }
}
