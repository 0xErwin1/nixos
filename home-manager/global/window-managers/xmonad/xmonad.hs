{-# OPTIONS_GHC -Wno-deprecations #-}

-- Data
import Data.Char (isSpace, toUpper)
import qualified Data.Map as M
import Data.Maybe (isJust)
import Data.Monoid
import Data.Tree
import System.Exit (exitSuccess)
import System.IO (hPutStrLn)
import XMonad
import XMonad.Actions.CopyWindow (kill1)
import XMonad.Actions.CycleWS (nextScreen, prevScreen)
import XMonad.Actions.MouseResize
import XMonad.Actions.UpdatePointer
import XMonad.Actions.WithAll (sinkAll)
-- Hooks
import XMonad.Hooks.DynamicLog (PP (..), dynamicLogWithPP, shorten, wrap, xmobarColor, xmobarPP)
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.InsertPosition
import XMonad.Hooks.ManageDocks (ToggleStruts (..), avoidStruts, docksEventHook, manageDocks)
import XMonad.Hooks.ManageHelpers (doFullFloat, isFullscreen)
import XMonad.Hooks.SetWMName
import XMonad.Hooks.WorkspaceHistory
-- Layouts
import XMonad.Layout.GridVariants (Grid (Grid))
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows)
import XMonad.Layout.MultiToggle (EOT (EOT), mkToggle, single, (??))
import qualified XMonad.Layout.MultiToggle as MT (Toggle (..))
import XMonad.Layout.MultiToggle.Instances (StdTransformers (MIRROR, NBFULL, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed (Rename (Replace), renamed)
import XMonad.Layout.ResizableTile
import XMonad.Layout.ShowWName
import XMonad.Layout.SimplestFloat
import XMonad.Layout.Spacing
import XMonad.Layout.ThreeColumns
import qualified XMonad.Layout.ToggleLayouts as T (ToggleLayout (Toggle), toggleLayouts)
import XMonad.Layout.WindowArranger (WindowArrangerMsg (..), windowArrange)
import qualified XMonad.StackSet as W
-- Utilities
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.SpawnOnce

--------------- |  Variables | -------------
-- Super
myModMask = mod4Mask :: KeyMask

-- Border Width
myBorderWidth = 2 :: Dimension

-- Font
myFont = "xft:LiterationSans Nerd Font Mono:regular:size=12:antialias=true:hinting=true" :: String

-- Colors
-- Normal
myNormColor = "#00acc1" :: String

-- Focus
myFocusColor = "#43a047" :: String

windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset :: X (Maybe String)

myStartupHook :: X ()
myStartupHook = do
  spawnOnce "trayer --edge top  --monitor 1 --widthtype pixel --width 130 --heighttype pixel --height 18 --align right --transparent true --alpha 0 --tint 0x0e1019 --iconspacing 3 --distance 1 &"
  --spawnOnce "~/.xmonad/polybar/launch.sh"
  spawnOnce "~/.xmonad/autostart.sh"
  -- spawn "polybar xmonad -c ~/.config/polybar/material.ini"
  setWMName "LG3D"

mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

-- Layouts definition
myLayout =
  renamed [Replace "tall"] $
    limitWindows 12 $
      mySpacing 6 $
        ResizableTall 1 (3 / 100) (1 / 2) []

mirrorTall =
  renamed [Replace "tall"] $
    limitWindows 12 $
      mySpacing 7 $
        Mirror (Tall 1 (3 / 100) (3 / 5))

monocle = renamed [Replace "monocle"] $ mySpacing 5 $ limitWindows 20 Full

grid =
  renamed [Replace "grid"] $
    limitWindows 12 $
      mySpacing 6 $
        mkToggle (single MIRROR) $
          Grid (16 / 10)

floats = renamed [Replace "floats"] $ limitWindows 20 simplestFloat

myLayoutHook =
  avoidStruts $
    smartBorders $
      mouseResize $
        windowArrange $
          T.toggleLayouts floats $
            mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefalutLayout
  where
    myDefalutLayout =
      noBorders monocle
        ||| grid
        ||| mirrorTall

xmobarEscape :: String -> String
xmobarEscape = concatMap doubleLts
  where
    doubleLts '<' = "<<"
    doubleLts x = [x]

myWorspaces :: [String]
myWorspaces =
  clickable . map xmobarEscape $
    ["\xf268 ", "\58911 ", "\61728 ", "\xf269 ", "\58879 ", "\58901 ", "\62150 ", "\61884 ", "\xf198 "]
  where
    clickable l = ["<action=xdotool key super+" ++ show i ++ "> " ++ ws ++ "</action>" | (i, ws) <- zip [1 .. 9] l]

-- myWorspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook =
  composeAll
    [ -- 1
      (className =? "Brave-browser" <||> title =? "Firefox Developer Edition" <||> className =? "firefox")
        --> doShift (head myWorspaces),
      -- 2

      -- 3

      -- 4
      -- 5
      className =? "Thunar" --> doShift (myWorspaces !! 5),
      -- 6
      className =? "TelegramDesktop" --> doShift (myWorspaces !! 6),
      className =? "WhatsappDesktop" --> doShift (myWorspaces !! 6),
      className =? "Thunderbird" --> doShift (myWorspaces !! 6),
      (className =? "zoom " <||> className =? "Zoom Cloud Meetings") --> doShift (myWorspaces !! 5),
      -- 7
      (className =? "Spotify" <||> className =? "spotify") --> doShift (myWorspaces !! 7),
      className =? "Pulseaudio-equalizer-gtk" --> doShift (myWorspaces !! 7),
      className =? "Pavucontrol" --> doShift (myWorspaces !! 7),
      -- 8
      className =? "Slack" --> doShift (myWorspaces !! 8),
      -- 9
      -- Float
      className =? "Lxappearance" --> doFloat,
      className =? "Nitrogen" --> doFloat,
      className =? "wpa_gui" --> doFloat,
      className =? "Zathura" --> doFloat,
      (className =? "firefox" <&&> resource =? "Dialog") --> doFloat,
      (className =? "firefox" <&&> resource =? "Places") --> doFloat,
      (className =? "firefoxdeveloperedition" <&&> resource =? "Dialog") --> doFloat,
      (className =? "firefoxdeveloperedition" <&&> resource =? "Places") --> doFloat,
      (className =? "Brave-browser" <&&> resource =? "Places") --> doFloat,
      (className =? "Brave-browser" <&&> resource =? "pop-up") --> doFloat,
      (className =? "Brave-browser-beta" <&&> resource =? "Places") --> doFloat,
      (className =? "Brave-browser-beta" <&&> resource =? "pop-up") --> doFloat,
      (className =? "Google-chrome" <&&> resource =? "pop-up") --> doFloat,
      (className =? "Google-chrome" <&&> resource =? "pop-up") --> doFloat,
      (className =? "Thunar" <&&> resource =? "Dialog") --> doFloat,
      (className =? "pcmanfm" <&&> resource =? "Dialog") --> doFloat,
      className =? "lxappearance" --> doFloat,
      className =? "SpeedCrunch" --> doFloat,
      className =? "Piper" --> doFloat,
      className =? "Pulseaudio-equalizer-gtk" --> doFloat,
      className =? "Pavucontrol" --> doFloat,
      className =? "Blueman-manager" --> doFloat,
      className =? "NordPass" --> doFloat,
      className =? "Arandr" --> doFloat,
      className =? "Postman" --> doFloat,
      className =? "Java" --> doFloat,
      className =? "TelegramDesktop" --> doFloat,
      className =? "whatsapp-nativefier-d40211" --> doFloat,
      (className =? "cpupower-gui" <||> className =? "Cpupower-gui") --> doFloat,
      (className =? "Zoom Meeting" <||> className =? "zoom ") --> doFloat,
      (className =? "Settings") --> doFloat,
      (className =? "protonvpn" <||> className =? "Protonvpn") --> doFloat,
      className =? "C++" --> doFloat
    ]

xmonadKey conf@(XConfig {XMonad.modMask = myModMask}) =
  M.fromList $
    [ ((m .|. myModMask, k), windows $ f i)
      | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9],
        (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
    ]
      ++ [ ((m .|. myModMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
           | (key, sc) <- zip [xK_w, xK_e, xK_r] [0 ..],
             (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
         ]

myKeys :: [(String, X ())]
myKeys =
  -- Xmonad
  [ -- ("M-C-r", spawn "xmonad --recompile") -- Recompile xmonad
    ("M-S-r", spawn "xmonad --recompile && xmonad --restart"), -- Restart xmonad
    ("M-S-q", io exitSuccess), -- Quits xmonad

    -- Kill windows
    ("M-w", kill1), -- Kill the currently focused client
    -- Move focus to the next window
    ("M-j", windows W.focusDown),
    -- Move focus to the provious window
    ("M-k", windows W.focusUp),
    -- Swap focused window with next window
    ("M-S-j", windows W.swapDown),
    -- Swap focused window with prev window
    ("M-S-k", windows W.swapUp),
    ------------------ Layouts ---------------------

    -- Switch focus to next monitor
    ("M-.", nextScreen),
    -- Switch focus to prev monitor
    ("M-,", prevScreen),
    -- Switch to next layout
    ("M-<Tab>", sendMessage NextLayout),
    -- Switch to first layout
    ("M-S-<Tab>", sendMessage FirstLayout),
    -- Toggles noborder/full
    ("M-<Space>", sendMessage (MT.Toggle NBFULL) >> sendMessage ToggleStruts),
    -- Toggles noborder
    ("M-S-n", sendMessage $ MT.Toggle NOBORDERS),
    -- Shrink horizontal wondow width
    ("M-S-h", sendMessage Shrink),
    -- Expand horizontal window width
    ("M-S-l", sendMessage Expand),
    -- Shrink vertical window width
    ("M-C-j", sendMessage MirrorShrink),
    -- Expand vertical window width
    ("M-C-k", sendMessage MirrorExpand),
    ("M-z", decWindowSpacing 4),
    ("M-S-z", incWindowSpacing 4),
    ----------------- Float windows -----------------
    -- Toggles 'floats' layout
    ("M-f", sendMessage (T.Toggle "floats")),
    -- Push floating window back to tile
    ("M-S-f", withFocused $ windows . W.sink),
    -- Push all floating windows to tile
    ("M-C-f", sinkAll),
    ----------------- App ------------------------
    -- Menu
    ("M-m", spawn "rofi -show drun"),
    -- Window Nav
    ("M-S-m", spawn "rofi -show"),
    -- Browser
    ("M-C-b", spawn "brave"),
    ("M-S-b", spawn "google-chrome-stable"),
    ("M-b", spawn "firefox"),
    -- Explore
    ("M-e", spawn "pcmanfm"),
    -- Redshift
    ("M-r", spawn "redshift -O 5000"),
    ("M-C-r", spawn "redshift -x"),
    -- Terminal
    ("M-S-<Return>", spawn "kitty"),
    ("M-<Return>", spawn "alacritty"),
    ("M-C-<Return>", spawn "tilix"),
    -- Calculator
    ("M-s", spawn "speedcrunch"),
    -- ScreenShot
    ("M-p", spawn "scrot -s 'screenshot_%Y-%m-%d-%T_$wx$h.png' -e 'mkdir -p ~/Pictures/screenshots/ | mv $f ~/Pictures/screenshots/'"),

    -- Lock screen
    ("M-C-=", spawn "betterlockscreen -l blur"),
    --------------------- Hardware ---------------------

    -- Volume
    ("<XF86AudioLowerVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ -5%"),
    ("<XF86AudioRaiseVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ +5%"),
    ("<XF86AudioMute>", spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle"),
    ("<XF86AudioPlay>", spawn "playerctl play-pause"),
    ("<XF86AudioNext>", spawn "playerctl next"),
    ("<XF86AudioPrev>", spawn "playerctl previous"),
    -- Brightness
    ("<XF86MonBrightnessUp>", spawn "brightnessctl set +10%"),
    ("<XF86MonBrightnessDown>", spawn "brightnessctl set 10%-")
  ]

-- Main
main :: IO ()
main = do
  -- Xmobar
  xmobarLaptop <- spawnPipe "xmobar -x 1 ~/.config/xmobar/secondary.hs"
  xmobarMonitor <- spawnPipe "xmobar -x 0 ~/.config/xmobar/primary.hs"
  -- Xmonad
  xmonad $
    ewmh
      def
        { manageHook = (isFullscreen --> doFullFloat) <+> myManageHook <+> manageDocks,
          handleEventHook = handleEventHook defaultConfig <+> docksEventHook,
          startupHook = myStartupHook,
          layoutHook = myLayoutHook,
          workspaces = myWorspaces,
          modMask = myModMask,
          -- keys = xmonadKey,
          borderWidth = myBorderWidth,
          normalBorderColor = myNormColor,
          focusedBorderColor = myFocusColor,
          logHook =
            workspaceHistoryHook
              <+> dynamicLogWithPP
                xmobarPP
                  { ppOutput = \x -> hPutStrLn xmobarLaptop x >> hPutStrLn xmobarMonitor x,
                    -- Current workspace in xmonbar
                    ppCurrent = xmobarColor "#fdd835" "" . wrap "[" " ]",
                    -- Visible but not current workspaces
                    ppVisible = xmobarColor "#1e88e5" "",
                    -- Hidden workspaces in xmobar
                    ppHidden = xmobarColor "#00d8eb" "",
                    -- Hidden workspaces (no windows)
                    ppHiddenNoWindows = xmobarColor "#6d43a6" "",
                    -- Title of active window in xmobar
                    ppTitle = xmobarColor "#ffffff" "" . shorten 55,
                    -- Separators in xmobar
                    ppSep = "<fc=#546e7a> | </fc>",
                    -- Urgent workspace
                    ppUrgent = xmobarColor "#e53935" "" . wrap "" "!",
                    -- Number of windows in current workspace
                    ppExtras = [windowCount],
                    ppOrder = \(ws : l : t : ex) -> [ws, l] ++ ex ++ [t]
                  }
              >> updatePointer (0.5, 0.5) (0.5, 0.5)
        }
      `additionalKeysP` myKeys
