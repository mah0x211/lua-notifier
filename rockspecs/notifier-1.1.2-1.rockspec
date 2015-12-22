package = "notifier"
version = "1.1.2-1"
source = {
    url = "git://github.com/mah0x211/lua-notifier.git",
    tag = "v1.1.2"
}
description = {
    summary = "event notification module",
    homepage = "https://github.com/mah0x211/lua-notifier", 
    license = "MIT/X11",
    maintainer = "Masatoshi Teruya"
}
dependencies = {
    "lua >= 5.1",
    "halo >= 1.1.5",
    "util >= 1.5.1"
}
build = {
    type = "builtin",
    modules = {
        notifier = "notifier.lua"
    }
}
