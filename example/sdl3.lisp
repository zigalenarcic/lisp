
(if (== (load-dynamic-library "libSDL3") 0)
  (load-dynamic-library "SDL3"))

(define SDL_INIT_AUDIO      0x00000010) /**< `SDL_INIT_AUDIO` implies `SDL_INIT_EVENTS` */
(define SDL_INIT_VIDEO      0x00000020) /**< `SDL_INIT_VIDEO` implies `SDL_INIT_EVENTS`, should be initialized on the main thread */
(define SDL_INIT_JOYSTICK   0x00000200) /**< `SDL_INIT_JOYSTICK` implies `SDL_INIT_EVENTS` */
(define SDL_INIT_HAPTIC     0x00001000)
(define SDL_INIT_GAMEPAD    0x00002000) /**< `SDL_INIT_GAMEPAD` implies `SDL_INIT_JOYSTICK` */
(define SDL_INIT_EVENTS     0x00004000)
(define SDL_INIT_SENSOR     0x00008000) /**< `SDL_INIT_SENSOR` implies `SDL_INIT_EVENTS` */
(define SDL_INIT_CAMERA     0x00010000) /**< `SDL_INIT_CAMERA` implies `SDL_INIT_EVENTS` */


/* SDL_WindowFlags */
(define SDL_WINDOW_FULLSCREEN           0x0000000000000001)    /**< window is in fullscreen mode */
(define SDL_WINDOW_OPENGL               0x0000000000000002)    /**< window usable with OpenGL context */
(define SDL_WINDOW_OCCLUDED             0x0000000000000004)    /**< window is occluded */
(define SDL_WINDOW_HIDDEN               0x0000000000000008)    /**< window is neither mapped onto the desktop nor shown in the taskbar/dock/window list; SDL_ShowWindow() is required for it to become visible */
(define SDL_WINDOW_BORDERLESS           0x0000000000000010)    /**< no window decoration */
(define SDL_WINDOW_RESIZABLE            0x0000000000000020)    /**< window can be resized */
(define SDL_WINDOW_MINIMIZED            0x0000000000000040)    /**< window is minimized */
(define SDL_WINDOW_MAXIMIZED            0x0000000000000080)    /**< window is maximized */
(define SDL_WINDOW_MOUSE_GRABBED        0x0000000000000100)    /**< window has grabbed mouse input */
(define SDL_WINDOW_INPUT_FOCUS          0x0000000000000200)    /**< window has input focus */
(define SDL_WINDOW_MOUSE_FOCUS          0x0000000000000400)    /**< window has mouse focus */
(define SDL_WINDOW_EXTERNAL             0x0000000000000800)    /**< window not created by SDL */
(define SDL_WINDOW_MODAL                0x0000000000001000)    /**< window is modal */
(define SDL_WINDOW_HIGH_PIXEL_DENSITY   0x0000000000002000)    /**< window uses high pixel density back buffer if possible */
(define SDL_WINDOW_MOUSE_CAPTURE        0x0000000000004000)    /**< window has mouse captured (unrelated to MOUSE_GRABBED) */
(define SDL_WINDOW_MOUSE_RELATIVE_MODE  0x0000000000008000)    /**< window has relative mode enabled */
(define SDL_WINDOW_ALWAYS_ON_TOP        0x0000000000010000)    /**< window should always be above others */
(define SDL_WINDOW_UTILITY              0x0000000000020000)    /**< window should be treated as a utility window, not showing in the task bar and window list */
(define SDL_WINDOW_TOOLTIP              0x0000000000040000)    /**< window should be treated as a tooltip and does not get mouse or keyboard focus, requires a parent window */
(define SDL_WINDOW_POPUP_MENU           0x0000000000080000)    /**< window should be treated as a popup menu, requires a parent window */
(define SDL_WINDOW_KEYBOARD_GRABBED     0x0000000000100000)    /**< window has grabbed keyboard input */
(define SDL_WINDOW_VULKAN               0x0000000010000000)    /**< window usable for Vulkan surface */
(define SDL_WINDOW_METAL                0x0000000020000000)    /**< window usable for Metal view */
(define SDL_WINDOW_TRANSPARENT          0x0000000040000000)    /**< window with transparent buffer */
(define SDL_WINDOW_NOT_FOCUSABLE        0x0000000080000000)    /**< window should not be focusable */


(define SDL_PIXELFORMAT_XRGB8888 0x16161804) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_XRGB, SDL_PACKEDLAYOUT_8888, 24, 4), */
(define SDL_PIXELFORMAT_RGBX8888 0x16261804) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_RGBX, SDL_PACKEDLAYOUT_8888, 24, 4), */
(define SDL_PIXELFORMAT_XBGR8888 0x16561804) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_XBGR, SDL_PACKEDLAYOUT_8888, 24, 4), */
(define SDL_PIXELFORMAT_BGRX8888 0x16661804) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_BGRX, SDL_PACKEDLAYOUT_8888, 24, 4), */
(define SDL_PIXELFORMAT_ARGB8888 0x16362004) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_ARGB, SDL_PACKEDLAYOUT_8888, 32, 4), */
(define SDL_PIXELFORMAT_RGBA8888 0x16462004) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_RGBA, SDL_PACKEDLAYOUT_8888, 32, 4), */
(define SDL_PIXELFORMAT_ABGR8888 0x16762004) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_ABGR, SDL_PACKEDLAYOUT_8888, 32, 4), */
(define SDL_PIXELFORMAT_BGRA8888 0x16862004) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_BGRA, SDL_PACKEDLAYOUT_8888, 32, 4), */

(define SDL_GL_RED_SIZE 0)                    /**< the minimum number of bits for the red channel of the color buffer; defaults to 8. */
(define SDL_GL_GREEN_SIZE 1)                  /**< the minimum number of bits for the green channel of the color buffer; defaults to 8. */
(define SDL_GL_BLUE_SIZE 2)                   /**< the minimum number of bits for the blue channel of the color buffer; defaults to 8. */
(define SDL_GL_ALPHA_SIZE 3)                  /**< the minimum number of bits for the alpha channel of the color buffer; defaults to 8. */
(define SDL_GL_BUFFER_SIZE 4)                 /**< the minimum number of bits for frame buffer size; defaults to 0. */
(define SDL_GL_DOUBLEBUFFER 5)                /**< whether the output is single or double buffered; defaults to double buffering on. */
(define SDL_GL_DEPTH_SIZE 6)                  /**< the minimum number of bits in the depth buffer; defaults to 16. */
(define SDL_GL_STENCIL_SIZE 7)                /**< the minimum number of bits in the stencil buffer; defaults to 0. */
(define SDL_GL_ACCUM_RED_SIZE 8)              /**< the minimum number of bits for the red channel of the accumulation buffer; defaults to 0. */
(define SDL_GL_ACCUM_GREEN_SIZE 9)            /**< the minimum number of bits for the green channel of the accumulation buffer; defaults to 0. */
(define SDL_GL_ACCUM_BLUE_SIZE 10)             /**< the minimum number of bits for the blue channel of the accumulation buffer; defaults to 0. */
(define SDL_GL_ACCUM_ALPHA_SIZE 11)            /**< the minimum number of bits for the alpha channel of the accumulation buffer; defaults to 0. */
(define SDL_GL_STEREO 12)                      /**< whether the output is stereo 3D; defaults to off. */
(define SDL_GL_MULTISAMPLEBUFFERS 13)          /**< the number of buffers used for multisample anti-aliasing; defaults to 0. */
(define SDL_GL_MULTISAMPLESAMPLES 14)          /**< the number of samples used around the current pixel used for multisample anti-aliasing. */
(define SDL_GL_ACCELERATED_VISUAL 15)          /**< set to 1 to require hardware acceleration, set to 0 to force software rendering; defaults to allow either. */
(define SDL_GL_RETAINED_BACKING 16)            /**< not used (deprecated). */
(define SDL_GL_CONTEXT_MAJOR_VERSION 17)       /**< OpenGL context major version. */
(define SDL_GL_CONTEXT_MINOR_VERSION 18)       /**< OpenGL context minor version. */
(define SDL_GL_CONTEXT_FLAGS 19)               /**< some combination of 0 or more of elements of the SDL_GLContextFlag enumeration; defaults to 0. */
(define SDL_GL_CONTEXT_PROFILE_MASK 20)        /**< type of GL context (Core, Compatibility, ES). See SDL_GLProfile; default value depends on platform. */
(define SDL_GL_SHARE_WITH_CURRENT_CONTEXT 21)  /**< OpenGL context sharing; defaults to 0. */
(define SDL_GL_FRAMEBUFFER_SRGB_CAPABLE 22)    /**< requests sRGB capable visual; defaults to 0. */
(define SDL_GL_CONTEXT_RELEASE_BEHAVIOR 23)    /**< sets context the release behavior. See SDL_GLContextReleaseFlag; defaults to FLUSH. */
(define SDL_GL_CONTEXT_RESET_NOTIFICATION 24)  /**< set context reset notification. See SDL_GLContextResetNotification; defaults to NO_NOTIFICATION. */
(define SDL_GL_CONTEXT_NO_ERROR 25)
(define SDL_GL_FLOATBUFFERS 26)
(define SDL_GL_EGL_PLATFORM 27)

(define SDL_EVENT_QUIT            0x100) /**< User-requested quit */

(define SDL_EVENT_KEY_DOWN        0x300) /**< Key pressed */
(define SDL_EVENT_KEY_UP          0x301) /**< Key released */

/* Mouse events */
(define SDL_EVENT_MOUSE_MOTION      0x400) /**< Mouse moved */
(define SDL_EVENT_MOUSE_BUTTON_DOWN 0x401) /**< Mouse button pressed */
(define SDL_EVENT_MOUSE_BUTTON_UP   0x402) /**< Mouse button released */
(define SDL_EVENT_MOUSE_WHEEL       0x403) /**< Mouse wheel motion */

/* SDL SCANCODES complete */

(define SDL_SCANCODE_UNKNOWN 0)

/**
*  \name Usage page 0x07
*
*  These values are from usage page 0x07 (USB keyboard page).
*/
/* @{ */

(define SDL_SCANCODE_A 4)
(define SDL_SCANCODE_B 5)
(define SDL_SCANCODE_C 6)
(define SDL_SCANCODE_D 7)
(define SDL_SCANCODE_E 8)
(define SDL_SCANCODE_F 9)
(define SDL_SCANCODE_G 10)
(define SDL_SCANCODE_H 11)
(define SDL_SCANCODE_I 12)
(define SDL_SCANCODE_J 13)
(define SDL_SCANCODE_K 14)
(define SDL_SCANCODE_L 15)
(define SDL_SCANCODE_M 16)
(define SDL_SCANCODE_N 17)
(define SDL_SCANCODE_O 18)
(define SDL_SCANCODE_P 19)
(define SDL_SCANCODE_Q 20)
(define SDL_SCANCODE_R 21)
(define SDL_SCANCODE_S 22)
(define SDL_SCANCODE_T 23)
(define SDL_SCANCODE_U 24)
(define SDL_SCANCODE_V 25)
(define SDL_SCANCODE_W 26)
(define SDL_SCANCODE_X 27)
(define SDL_SCANCODE_Y 28)
(define SDL_SCANCODE_Z 29)

(define SDL_SCANCODE_1 30)
(define SDL_SCANCODE_2 31)
(define SDL_SCANCODE_3 32)
(define SDL_SCANCODE_4 33)
(define SDL_SCANCODE_5 34)
(define SDL_SCANCODE_6 35)
(define SDL_SCANCODE_7 36)
(define SDL_SCANCODE_8 37)
(define SDL_SCANCODE_9 38)
(define SDL_SCANCODE_0 39)

(define SDL_SCANCODE_RETURN 40)
(define SDL_SCANCODE_ESCAPE 41)
(define SDL_SCANCODE_BACKSPACE 42)
(define SDL_SCANCODE_TAB 43)
(define SDL_SCANCODE_SPACE 44)

(define SDL_SCANCODE_MINUS 45)
(define SDL_SCANCODE_EQUALS 46)
(define SDL_SCANCODE_LEFTBRACKET 47)
(define SDL_SCANCODE_RIGHTBRACKET 48)
(define SDL_SCANCODE_BACKSLASH 49) /**< Located at the lower left of the return
*   key on ISO keyboards and at the right end
*   of the QWERTY row on ANSI keyboards.
*   Produces REVERSE SOLIDUS (backslash) and
*   VERTICAL LINE in a US layout, REVERSE
*   SOLIDUS and VERTICAL LINE in a UK Mac
*   layout, NUMBER SIGN and TILDE in a UK
*   Windows layout, DOLLAR SIGN and POUND SIGN
*   in a Swiss German layout, NUMBER SIGN and
*   APOSTROPHE in a German layout, GRAVE
*   ACCENT and POUND SIGN in a French Mac
*   layout, and ASTERISK and MICRO SIGN in a
*   French Windows layout.
*/
(define SDL_SCANCODE_NONUSHASH 50) /**< ISO USB keyboards actually use this code
*   instead of 49 for the same key, but all
*   OSes I've seen treat the two codes
*   identically. So, as an implementor, unless
*   your keyboard generates both of those
*   codes and your OS treats them differently,
*   you should generate SDL_SCANCODE_BACKSLASH
*   instead of this code. As a user, you
*   should not rely on this code because SDL
*   will never generate it with most (all?)
*   keyboards.
*/
(define SDL_SCANCODE_SEMICOLON 51)
(define SDL_SCANCODE_APOSTROPHE 52)
(define SDL_SCANCODE_GRAVE 53) /**< Located in the top left corner (on both ANSI
                                                                       *   and ISO keyboards). Produces GRAVE ACCENT and
*   TILDE in a US Windows layout and in US and UK
*   Mac layouts on ANSI keyboards, GRAVE ACCENT
*   and NOT SIGN in a UK Windows layout, SECTION
*   SIGN and PLUS-MINUS SIGN in US and UK Mac
*   layouts on ISO keyboards, SECTION SIGN and
*   DEGREE SIGN in a Swiss German layout (Mac:
                                           *   only on ISO keyboards), CIRCUMFLEX ACCENT and
*   DEGREE SIGN in a German layout (Mac: only on
                                         *   ISO keyboards), SUPERSCRIPT TWO and TILDE in a
*   French Windows layout, COMMERCIAL AT and
*   NUMBER SIGN in a French Mac layout on ISO
*   keyboards, and LESS-THAN SIGN and GREATER-THAN
*   SIGN in a Swiss German, German, or French Mac
*   layout on ANSI keyboards.
*/
(define SDL_SCANCODE_COMMA 54)
(define SDL_SCANCODE_PERIOD 55)
(define SDL_SCANCODE_SLASH 56)

(define SDL_SCANCODE_CAPSLOCK 57)

(define SDL_SCANCODE_F1 58)
(define SDL_SCANCODE_F2 59)
(define SDL_SCANCODE_F3 60)
(define SDL_SCANCODE_F4 61)
(define SDL_SCANCODE_F5 62)
(define SDL_SCANCODE_F6 63)
(define SDL_SCANCODE_F7 64)
(define SDL_SCANCODE_F8 65)
(define SDL_SCANCODE_F9 66)
(define SDL_SCANCODE_F10 67)
(define SDL_SCANCODE_F11 68)
(define SDL_SCANCODE_F12 69)

(define SDL_SCANCODE_PRINTSCREEN 70)
(define SDL_SCANCODE_SCROLLLOCK 71)
(define SDL_SCANCODE_PAUSE 72)
(define SDL_SCANCODE_INSERT 73) /**< insert on PC, help on some Mac keyboards (but
                                                                                does send code 73, not 117) */
(define SDL_SCANCODE_HOME 74)
(define SDL_SCANCODE_PAGEUP 75)
(define SDL_SCANCODE_DELETE 76)
(define SDL_SCANCODE_END 77)
(define SDL_SCANCODE_PAGEDOWN 78)
(define SDL_SCANCODE_RIGHT 79)
(define SDL_SCANCODE_LEFT 80)
(define SDL_SCANCODE_DOWN 81)
(define SDL_SCANCODE_UP 82)

(define SDL_SCANCODE_NUMLOCKCLEAR 83) /**< num lock on PC, clear on Mac keyboards
*/
(define SDL_SCANCODE_KP_DIVIDE 84)
(define SDL_SCANCODE_KP_MULTIPLY 85)
(define SDL_SCANCODE_KP_MINUS 86)
(define SDL_SCANCODE_KP_PLUS 87)
(define SDL_SCANCODE_KP_ENTER 88)
(define SDL_SCANCODE_KP_1 89)
(define SDL_SCANCODE_KP_2 90)
(define SDL_SCANCODE_KP_3 91)
(define SDL_SCANCODE_KP_4 92)
(define SDL_SCANCODE_KP_5 93)
(define SDL_SCANCODE_KP_6 94)
(define SDL_SCANCODE_KP_7 95)
(define SDL_SCANCODE_KP_8 96)
(define SDL_SCANCODE_KP_9 97)
(define SDL_SCANCODE_KP_0 98)
(define SDL_SCANCODE_KP_PERIOD 99)

(define SDL_SCANCODE_NONUSBACKSLASH 100) /**< This is the additional key that ISO
*   keyboards have over ANSI ones,
*   located between left shift and Z.
*   Produces GRAVE ACCENT and TILDE in a
*   US or UK Mac layout, REVERSE SOLIDUS
*   (backslash) and VERTICAL LINE in a
*   US or UK Windows layout, and
*   LESS-THAN SIGN and GREATER-THAN SIGN
*   in a Swiss German, German, or French
*   layout. */
(define SDL_SCANCODE_APPLICATION 101) /**< windows contextual menu, compose */
(define SDL_SCANCODE_POWER 102) /**< The USB document says this is a status flag,
*   not a physical key - but some Mac keyboards
*   do have a power key. */
(define SDL_SCANCODE_KP_EQUALS 103)
(define SDL_SCANCODE_F13 104)
(define SDL_SCANCODE_F14 105)
(define SDL_SCANCODE_F15 106)
(define SDL_SCANCODE_F16 107)
(define SDL_SCANCODE_F17 108)
(define SDL_SCANCODE_F18 109)
(define SDL_SCANCODE_F19 110)
(define SDL_SCANCODE_F20 111)
(define SDL_SCANCODE_F21 112)
(define SDL_SCANCODE_F22 113)
(define SDL_SCANCODE_F23 114)
(define SDL_SCANCODE_F24 115)
(define SDL_SCANCODE_EXECUTE 116)
(define SDL_SCANCODE_HELP 117)    /**< AL Integrated Help Center */
(define SDL_SCANCODE_MENU 118)    /**< Menu (show menu) */
(define SDL_SCANCODE_SELECT 119)
(define SDL_SCANCODE_STOP 120)    /**< AC Stop */
(define SDL_SCANCODE_AGAIN 121)   /**< AC Redo/Repeat */
(define SDL_SCANCODE_UNDO 122)    /**< AC Undo */
(define SDL_SCANCODE_CUT 123)     /**< AC Cut */
(define SDL_SCANCODE_COPY 124)    /**< AC Copy */
(define SDL_SCANCODE_PASTE 125)   /**< AC Paste */
(define SDL_SCANCODE_FIND 126)    /**< AC Find */
(define SDL_SCANCODE_MUTE 127)
(define SDL_SCANCODE_VOLUMEUP 128)
(define SDL_SCANCODE_VOLUMEDOWN 129)
/* not sure whether there's a reason to enable these */
/*     (define SDL_SCANCODE_LOCKINGCAPSLOCK 130)  */
/*     (define SDL_SCANCODE_LOCKINGNUMLOCK 131) */
/*     (define SDL_SCANCODE_LOCKINGSCROLLLOCK 132) */
(define SDL_SCANCODE_KP_COMMA 133)
(define SDL_SCANCODE_KP_EQUALSAS400 134)

(define SDL_SCANCODE_INTERNATIONAL1 135) /**< used on Asian keyboards, see
footnotes in USB doc */
(define SDL_SCANCODE_INTERNATIONAL2 136)
(define SDL_SCANCODE_INTERNATIONAL3 137) /**< Yen */
(define SDL_SCANCODE_INTERNATIONAL4 138)
(define SDL_SCANCODE_INTERNATIONAL5 139)
(define SDL_SCANCODE_INTERNATIONAL6 140)
(define SDL_SCANCODE_INTERNATIONAL7 141)
(define SDL_SCANCODE_INTERNATIONAL8 142)
(define SDL_SCANCODE_INTERNATIONAL9 143)
(define SDL_SCANCODE_LANG1 144) /**< Hangul/English toggle */
(define SDL_SCANCODE_LANG2 145) /**< Hanja conversion */
(define SDL_SCANCODE_LANG3 146) /**< Katakana */
(define SDL_SCANCODE_LANG4 147) /**< Hiragana */
(define SDL_SCANCODE_LANG5 148) /**< Zenkaku/Hankaku */
(define SDL_SCANCODE_LANG6 149) /**< reserved */
(define SDL_SCANCODE_LANG7 150) /**< reserved */
(define SDL_SCANCODE_LANG8 151) /**< reserved */
(define SDL_SCANCODE_LANG9 152) /**< reserved */

(define SDL_SCANCODE_ALTERASE 153)    /**< Erase-Eaze */
(define SDL_SCANCODE_SYSREQ 154)
(define SDL_SCANCODE_CANCEL 155)      /**< AC Cancel */
(define SDL_SCANCODE_CLEAR 156)
(define SDL_SCANCODE_PRIOR 157)
(define SDL_SCANCODE_RETURN2 158)
(define SDL_SCANCODE_SEPARATOR 159)
(define SDL_SCANCODE_OUT 160)
(define SDL_SCANCODE_OPER 161)
(define SDL_SCANCODE_CLEARAGAIN 162)
(define SDL_SCANCODE_CRSEL 163)
(define SDL_SCANCODE_EXSEL 164)

(define SDL_SCANCODE_KP_00 176)
(define SDL_SCANCODE_KP_000 177)
(define SDL_SCANCODE_THOUSANDSSEPARATOR 178)
(define SDL_SCANCODE_DECIMALSEPARATOR 179)
(define SDL_SCANCODE_CURRENCYUNIT 180)
(define SDL_SCANCODE_CURRENCYSUBUNIT 181)
(define SDL_SCANCODE_KP_LEFTPAREN 182)
(define SDL_SCANCODE_KP_RIGHTPAREN 183)
(define SDL_SCANCODE_KP_LEFTBRACE 184)
(define SDL_SCANCODE_KP_RIGHTBRACE 185)
(define SDL_SCANCODE_KP_TAB 186)
(define SDL_SCANCODE_KP_BACKSPACE 187)
(define SDL_SCANCODE_KP_A 188)
(define SDL_SCANCODE_KP_B 189)
(define SDL_SCANCODE_KP_C 190)
(define SDL_SCANCODE_KP_D 191)
(define SDL_SCANCODE_KP_E 192)
(define SDL_SCANCODE_KP_F 193)
(define SDL_SCANCODE_KP_XOR 194)
(define SDL_SCANCODE_KP_POWER 195)
(define SDL_SCANCODE_KP_PERCENT 196)
(define SDL_SCANCODE_KP_LESS 197)
(define SDL_SCANCODE_KP_GREATER 198)
(define SDL_SCANCODE_KP_AMPERSAND 199)
(define SDL_SCANCODE_KP_DBLAMPERSAND 200)
(define SDL_SCANCODE_KP_VERTICALBAR 201)
(define SDL_SCANCODE_KP_DBLVERTICALBAR 202)
(define SDL_SCANCODE_KP_COLON 203)
(define SDL_SCANCODE_KP_HASH 204)
(define SDL_SCANCODE_KP_SPACE 205)
(define SDL_SCANCODE_KP_AT 206)
(define SDL_SCANCODE_KP_EXCLAM 207)
(define SDL_SCANCODE_KP_MEMSTORE 208)
(define SDL_SCANCODE_KP_MEMRECALL 209)
(define SDL_SCANCODE_KP_MEMCLEAR 210)
(define SDL_SCANCODE_KP_MEMADD 211)
(define SDL_SCANCODE_KP_MEMSUBTRACT 212)
(define SDL_SCANCODE_KP_MEMMULTIPLY 213)
(define SDL_SCANCODE_KP_MEMDIVIDE 214)
(define SDL_SCANCODE_KP_PLUSMINUS 215)
(define SDL_SCANCODE_KP_CLEAR 216)
(define SDL_SCANCODE_KP_CLEARENTRY 217)
(define SDL_SCANCODE_KP_BINARY 218)
(define SDL_SCANCODE_KP_OCTAL 219)
(define SDL_SCANCODE_KP_DECIMAL 220)
(define SDL_SCANCODE_KP_HEXADECIMAL 221)

(define SDL_SCANCODE_LCTRL 224)
(define SDL_SCANCODE_LSHIFT 225)
(define SDL_SCANCODE_LALT 226) /**< alt, option */
(define SDL_SCANCODE_LGUI 227) /**< windows, command (apple), meta */
(define SDL_SCANCODE_RCTRL 228)
(define SDL_SCANCODE_RSHIFT 229)
(define SDL_SCANCODE_RALT 230) /**< alt gr, option */
(define SDL_SCANCODE_RGUI 231) /**< windows, command (apple), meta */

(define SDL_SCANCODE_MODE 257)    /**< I'm not sure if this is really not covered
*   by any of the above, but since there's a
*   special SDL_KMOD_MODE for it I'm adding it here
*/

/* @} *//* Usage page 0x07 */

/**
*  \name Usage page 0x0C
*
*  These values are mapped from usage page 0x0C (USB consumer page).
*
*  There are way more keys in the spec than we can represent in the
*  current scancode range, so pick the ones that commonly come up in
*  real world usage.
*/
/* @{ */

(define SDL_SCANCODE_SLEEP 258)                   /**< Sleep */
(define SDL_SCANCODE_WAKE 259)                    /**< Wake */

(define SDL_SCANCODE_CHANNEL_INCREMENT 260)       /**< Channel Increment */
(define SDL_SCANCODE_CHANNEL_DECREMENT 261)       /**< Channel Decrement */

(define SDL_SCANCODE_MEDIA_PLAY 262)          /**< Play */
(define SDL_SCANCODE_MEDIA_PAUSE 263)         /**< Pause */
(define SDL_SCANCODE_MEDIA_RECORD 264)        /**< Record */
(define SDL_SCANCODE_MEDIA_FAST_FORWARD 265)  /**< Fast Forward */
(define SDL_SCANCODE_MEDIA_REWIND 266)        /**< Rewind */
(define SDL_SCANCODE_MEDIA_NEXT_TRACK 267)    /**< Next Track */
(define SDL_SCANCODE_MEDIA_PREVIOUS_TRACK 268) /**< Previous Track */
(define SDL_SCANCODE_MEDIA_STOP 269)          /**< Stop */
(define SDL_SCANCODE_MEDIA_EJECT 270)         /**< Eject */
(define SDL_SCANCODE_MEDIA_PLAY_PAUSE 271)    /**< Play / Pause */
(define SDL_SCANCODE_MEDIA_SELECT 272)        /* Media Select */

(define SDL_SCANCODE_AC_NEW 273)              /**< AC New */
(define SDL_SCANCODE_AC_OPEN 274)             /**< AC Open */
(define SDL_SCANCODE_AC_CLOSE 275)            /**< AC Close */
(define SDL_SCANCODE_AC_EXIT 276)             /**< AC Exit */
(define SDL_SCANCODE_AC_SAVE 277)             /**< AC Save */
(define SDL_SCANCODE_AC_PRINT 278)            /**< AC Print */
(define SDL_SCANCODE_AC_PROPERTIES 279)       /**< AC Properties */

(define SDL_SCANCODE_AC_SEARCH 280)           /**< AC Search */
(define SDL_SCANCODE_AC_HOME 281)             /**< AC Home */
(define SDL_SCANCODE_AC_BACK 282)             /**< AC Back */
(define SDL_SCANCODE_AC_FORWARD 283)          /**< AC Forward */
(define SDL_SCANCODE_AC_STOP 284)             /**< AC Stop */
(define SDL_SCANCODE_AC_REFRESH 285)          /**< AC Refresh */
(define SDL_SCANCODE_AC_BOOKMARKS 286)        /**< AC Bookmarks */

/* @} *//* Usage page 0x0C */


/**
*  \name Mobile keys
*
*  These are values that are often used on mobile phones.
*/
/* @{ */

(define SDL_SCANCODE_SOFTLEFT 287) /**< Usually situated below the display on phones and
used as a multi-function feature key for selecting
a software defined function shown on the bottom left
of the display. */
(define SDL_SCANCODE_SOFTRIGHT 288) /**< Usually situated below the display on phones and
used as a multi-function feature key for selecting
a software defined function shown on the bottom right
of the display. */
(define SDL_SCANCODE_CALL 289) /**< Used for accepting phone calls. */
(define SDL_SCANCODE_ENDCALL 290) /**< Used for rejecting phone calls. */

/* @} *//* Mobile keys */

/* Add any other keys here. */

(define SDL_SCANCODE_RESERVED 400)    /**< 400-500 reserved for dynamic keycodes */

(define SDL_SCANCODE_COUNT 512) /**< not a key, just marks the number of scancodes for array bounds */

