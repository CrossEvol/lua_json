package = "lua_json"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {
   "lua >= 5.3",
   "say >= 1.0"
}
build = {
   type = "builtin",
   modules = {
      add = "src\\add.lua"
   }
}
