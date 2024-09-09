-- http://projects.haskell.org/xmobar/

Config {
    font = "xft:LiterationMono Nerd Font:weight=bold:pixelsize=14:antialias=true:hinting=true"
    , bgColor = "#0e1019"
    , fgColor = "#fffaf4"
    , lowerOnStart = True
    , hideOnStart = False
    , allDesktops = True
    , persistent = True
    , alpha = 255
    , commands = [ 
           Run Date "<fc=#fb8c00>  %d %b %Y %H:%M </fc>" "date" 10
         , Run Com "volume" [] "volume" 10
         , Run Com "battery" [] "battery" 10
         , Run Com "brightness" [] "brightness" 10
         , Run Com "/home/kaisererwin/.config/xmobar/trayer-padding-icon.sh" [] "trayerpad" 600
         , Run UnsafeStdinReader
      ]
    , alignSep = "}{"
    , template = "<fc=#b303ff>   </fc> %UnsafeStdinReader% }{ \
        \<fc=#ffb900> %brightness%</fc>\
        \<fc=#43a047> %battery%</fc>\
        \<fc=#00acc1> %volume% </fc>\
        \%date%\
        \%trayerpad%"
}
