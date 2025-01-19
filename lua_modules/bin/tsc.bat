@echo off
setlocal
set "LUAROCKS_SYSCONFDIR=C:\Program Files\luarocks"
"D:\DevTools\lua\5.3.2\src\\lua.exe" -e "package.path=\"D:\\LUA_CODE\\lua_json\\lua_modules\\share\\lua\\5.3\\?.lua;D:\\LUA_CODE\\lua_json\\lua_modules\\share\\lua\\5.3\\?\\init.lua;\"..package.path;package.cpath=\"D:\\LUA_CODE\\lua_json\\lua_modules\\lib\\lua\\5.3\\?.dll;\"..package.cpath;local k,l,_=pcall(require,'luarocks.loader') _=k and l.add_context('telescope','0.6.0-1')" "D:\LUA_CODE\lua_json\lua_modules\lib\luarocks\rocks-5.3\telescope\0.6.0-1\bin\tsc" %*
exit /b %ERRORLEVEL%
