add_rules("mode.debug", "mode.release")

target("rte_add")
   set_kind("static")
   add_files("src/add.cc")
   add_headerfiles("src/*.h")

