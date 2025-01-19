@echo off
setlocal
IF "%*"=="" (set I=-i) ELSE (set I=)
set "LUAROCKS_SYSCONFDIR=C:\Program Files\luarocks"
"D:\DevTools\lua\5.3.2\src\\lua.exe" -e "package.path=\"D:\\LUA_CODE\\lua_json\\lua_modules\\share\\lua\\5.3\\?.lua;D:\\LUA_CODE\\lua_json\\lua_modules\\share\\lua\\5.3\\?\\init.lua;D:\\DevTools\\LuaRocks\\luarocks\\share\\lua\\5.3\\?.lua;D:\\DevTools\\LuaRocks\\luarocks\\share\\lua\\5.3\\?\\init.lua;\"..package.path;package.cpath=\"D:\\LUA_CODE\\lua_json\\lua_modules\\lib\\lua\\5.3\\?.dll;D:\\DevTools\\LuaRocks\\luarocks\\lib\\lua\\5.3\\?.dll;\"..package.cpath" %I% %*
exit /b %ERRORLEVEL%
