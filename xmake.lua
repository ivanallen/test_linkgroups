add_rules("mode.debug", "mode.release")

add_includedirs("src")
add_includedirs("$(buildir)/proto/src/proto")

add_requires("protobuf-cpp 3.15.8", {configs = {zlib = true}})
add_requires("grpc", {system = false})

rule("protobuf.py")
    set_extensions(".proto")
    before_buildcmd_file(function (target, batchcmds, sourcefile_proto, opt)
        local prefixdir
        local autogendir
        local public
        local fileconfig = target:fileconfig(sourcefile_proto)
        if fileconfig then
            public = fileconfig.proto_public
            prefixdir = fileconfig.proto_rootdir
            autogendir = fileconfig.proto_autogendir
            grpc_cpp_plugin = fileconfig.proto_grpc_cpp_plugin
        end

        local rootdir = autogendir and autogendir or path.join(target:autogendir(), "rules", "protobuf")
        local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_proto)
        local output_dir = path.join(rootdir, "python", "src/proto")

        local protoc_args =  {
            "-m",
            "grpc_tools.protoc",
            path(sourcefile_proto),
            path(prefixdir and prefixdir or path.directory(sourcefile_proto), function (p) return "-I" .. p end),
            path(output_dir, function (p) return ("--python_out=") .. p end)
        }

        if grpc_cpp_plugin then
            table.insert(protoc_args, path(output_dir, function (p) return ("--grpclib_python_out=") .. p end))
        end

        batchcmds:mkdir(output_dir)
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.proto.py %s", sourcefile_proto)
        batchcmds:vrunv("python3", protoc_args)
    end)
rule_end()

target("echo")
   set_kind("static")
   add_packages("grpc")
   add_packages("protobuf-cpp", {public = true})
   add_rules("protobuf.cpp")
   add_rules("protobuf.py")
   add_files("src/proto/spring/echo.proto", { proto_rootdir = "src/proto", proto_autogendir = path.join(os.projectdir(), "build", "proto"), proto_public = true, proto_grpc_cpp_plugin = true })

   add_headerfiles("$(buildir)/proto/src/proto/(spring/**.h)")
   add_installfiles("$(buildir)/proto/python/src/proto/(spring/**.py)", {prefixdir = "python"})

target("add")
   set_kind("static")
   add_files("src/add.cpp")
   add_headerfiles("src/*.h")

target("test")
    set_kind("binary")
    add_files("src/main.cpp")
    add_deps("add")
    add_deps("echo")

