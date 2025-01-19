@echo off
setlocal
set "LUAROCKS_SYSCONFDIR=C:\Program Files\luarocks"
"D:\DevTools\LuaRocks\luarocks-3.11.1-windows-64\luarocks.exe" --project-tree D:\LUA_CODE\lua_json\lua_modules %*
exit /b %ERRORLEVEL%
