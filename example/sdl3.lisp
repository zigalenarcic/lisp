
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

/** typedef enum SDL_EventType */

    (define SDL_EVENT_FIRST 0)     /**< Unused (do not remove) */

    /* Application events */
    (define SDL_EVENT_QUIT 0x100) /**< User-requested quit */

    /* These application events have special meaning on iOS and Android, see README-ios.md and README-android.md for details */
    (define SDL_EVENT_TERMINATING 0x101)      /**< The application is being terminated by the OS. This event must be handled in a callback set with SDL_AddEventWatch().
                                     Called on iOS in applicationWillTerminate()
                                     Called on Android in onDestroy()
                                */
    (define SDL_EVENT_LOW_MEMORY 0x102)       /**< The application is low on memory, free memory if possible. This event must be handled in a callback set with SDL_AddEventWatch().
                                     Called on iOS in applicationDidReceiveMemoryWarning()
                                     Called on Android in onTrimMemory()
                                */
    (define SDL_EVENT_WILL_ENTER_BACKGROUND 0x103) /**< The application is about to enter the background. This event must be handled in a callback set with SDL_AddEventWatch().
                                     Called on iOS in applicationWillResignActive()
                                     Called on Android in onPause()
                                */
    (define SDL_EVENT_DID_ENTER_BACKGROUND 0x104) /**< The application did enter the background and may not get CPU for some time. This event must be handled in a callback set with SDL_AddEventWatch().
                                     Called on iOS in applicationDidEnterBackground()
                                     Called on Android in onPause()
                                */
    (define SDL_EVENT_WILL_ENTER_FOREGROUND 0x105) /**< The application is about to enter the foreground. This event must be handled in a callback set with SDL_AddEventWatch().
                                     Called on iOS in applicationWillEnterForeground()
                                     Called on Android in onResume()
                                */
    (define SDL_EVENT_DID_ENTER_FOREGROUND 0x106) /**< The application is now interactive. This event must be handled in a callback set with SDL_AddEventWatch().
                                     Called on iOS in applicationDidBecomeActive()
                                     Called on Android in onResume()
                                */

    (define SDL_EVENT_LOCALE_CHANGED 0x107)  /**< The user's locale preferences have changed. */

    (define SDL_EVENT_SYSTEM_THEME_CHANGED 0x108) /**< The system theme changed */

    /* Display events */
    /* 0x150 was SDL_DISPLAYEVENT, reserve the number for sdl2-compat */
    (define SDL_EVENT_DISPLAY_ORIENTATION 0x151)   /**< Display orientation has changed to data1 */
    (define SDL_EVENT_DISPLAY_ADDED 0x152)                 /**< Display has been added to the system */
    (define SDL_EVENT_DISPLAY_REMOVED 0x153)               /**< Display has been removed from the system */
    (define SDL_EVENT_DISPLAY_MOVED 0x154)                 /**< Display has changed position */
    (define SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED 0x155)  /**< Display has changed desktop mode */
    (define SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED 0x156)  /**< Display has changed current mode */
    (define SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED 0x157) /**< Display has changed content scale */
    (define SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED 0x158) /**< Display has changed usable bounds */
    (define SDL_EVENT_DISPLAY_FIRST SDL_EVENT_DISPLAY_ORIENTATION)
    (define SDL_EVENT_DISPLAY_LAST SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED)

    /* Window events */
    /* 0x200 was SDL_WINDOWEVENT, reserve the number for sdl2-compat */
    /* 0x201 was SDL_SYSWMEVENT, reserve the number for sdl2-compat */
    (define SDL_EVENT_WINDOW_SHOWN 0x202)     /**< Window has been shown */
    (define SDL_EVENT_WINDOW_HIDDEN 0x203)            /**< Window has been hidden */
    (define SDL_EVENT_WINDOW_EXPOSED 0x204)           /**< Window has been exposed and should be redrawn, and can be redrawn directly from event watchers for this event.
                                             data1 is 1 for live-resize expose events, 0 otherwise. */
    (define SDL_EVENT_WINDOW_MOVED 0x205)             /**< Window has been moved to data1, data2 */
    (define SDL_EVENT_WINDOW_RESIZED 0x206)           /**< Window has been resized to data1xdata2 */
    (define SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED 0x207)/**< The pixel size of the window has changed to data1xdata2 */
    (define SDL_EVENT_WINDOW_METAL_VIEW_RESIZED 0x208)/**< The pixel size of a Metal view associated with the window has changed */
    (define SDL_EVENT_WINDOW_MINIMIZED 0x209)         /**< Window has been minimized */
    (define SDL_EVENT_WINDOW_MAXIMIZED 0x20a)         /**< Window has been maximized */
    (define SDL_EVENT_WINDOW_RESTORED 0x20b)          /**< Window has been restored to normal size and position */
    (define SDL_EVENT_WINDOW_MOUSE_ENTER 0x20c)       /**< Window has gained mouse focus */
    (define SDL_EVENT_WINDOW_MOUSE_LEAVE 0x20d)       /**< Window has lost mouse focus */
    (define SDL_EVENT_WINDOW_FOCUS_GAINED 0x20e)      /**< Window has gained keyboard focus */
    (define SDL_EVENT_WINDOW_FOCUS_LOST 0x20f)        /**< Window has lost keyboard focus */
    (define SDL_EVENT_WINDOW_CLOSE_REQUESTED 0x210)   /**< The window manager requests that the window be closed */
    (define SDL_EVENT_WINDOW_HIT_TEST 0x211)          /**< Window had a hit test that wasn't SDL_HITTEST_NORMAL */
    (define SDL_EVENT_WINDOW_ICCPROF_CHANGED 0x212)   /**< The window's ICC profile has changed */
    (define SDL_EVENT_WINDOW_DISPLAY_CHANGED 0x213)   /**< Window has been moved to display data1 */
    (define SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED 0x214) /**< Window display scale has been changed */
    (define SDL_EVENT_WINDOW_SAFE_AREA_CHANGED 0x215) /**< The window safe area has been changed */
    (define SDL_EVENT_WINDOW_OCCLUDED 0x216)          /**< The window has been occluded */
    (define SDL_EVENT_WINDOW_ENTER_FULLSCREEN 0x217)  /**< The window has entered fullscreen mode */
    (define SDL_EVENT_WINDOW_LEAVE_FULLSCREEN 0x218)  /**< The window has left fullscreen mode */
    (define SDL_EVENT_WINDOW_DESTROYED 0x219)         /**< The window with the associated ID is being or has been destroyed. If this message is being handled
                                             in an event watcher, the window handle is still valid and can still be used to retrieve any properties
                                             associated with the window. Otherwise, the handle has already been destroyed and all resources
                                             associated with it are invalid */
    (define SDL_EVENT_WINDOW_HDR_STATE_CHANGED 0x21a) /**< Window HDR properties have changed */
    (define SDL_EVENT_WINDOW_SETTINGS_CHANGED 0x21b)  /**< Window settings have changed (on visionOS) */
    (define SDL_EVENT_WINDOW_FIRST SDL_EVENT_WINDOW_SHOWN)
    (define SDL_EVENT_WINDOW_LAST SDL_EVENT_WINDOW_SETTINGS_CHANGED)

    /* Keyboard events */
    (define SDL_EVENT_KEY_DOWN 0x300) /**< Key pressed */
    (define SDL_EVENT_KEY_UP 0x301)                  /**< Key released */
    (define SDL_EVENT_TEXT_EDITING 0x302)            /**< Keyboard text editing (composition) */
    (define SDL_EVENT_TEXT_INPUT 0x303)              /**< Keyboard text input */
    (define SDL_EVENT_KEYMAP_CHANGED 0x304)          /**< Keymap changed due to a system event such as an
                                            input language or keyboard layout change. */
    (define SDL_EVENT_KEYBOARD_ADDED 0x305)          /**< A new keyboard has been inserted into the system */
    (define SDL_EVENT_KEYBOARD_REMOVED 0x306)        /**< A keyboard has been removed */
    (define SDL_EVENT_TEXT_EDITING_CANDIDATES 0x307) /**< Keyboard text editing candidates */
    (define SDL_EVENT_SCREEN_KEYBOARD_SHOWN 0x308)   /**< The on-screen keyboard has been shown */
    (define SDL_EVENT_SCREEN_KEYBOARD_HIDDEN 0x309)  /**< The on-screen keyboard has been hidden */
    (define SDL_EVENT_KEYBOARD_FIRST SDL_EVENT_KEY_DOWN)
    (define SDL_EVENT_KEYBOARD_LAST SDL_EVENT_SCREEN_KEYBOARD_HIDDEN)

    /* Mouse events */
    (define SDL_EVENT_MOUSE_MOTION 0x400) /**< Mouse moved */
    (define SDL_EVENT_MOUSE_BUTTON_DOWN 0x401)       /**< Mouse button pressed */
    (define SDL_EVENT_MOUSE_BUTTON_UP 0x402)         /**< Mouse button released */
    (define SDL_EVENT_MOUSE_WHEEL 0x403)             /**< Mouse wheel motion */
    (define SDL_EVENT_MOUSE_ADDED 0x404)             /**< A new mouse has been inserted into the system */
    (define SDL_EVENT_MOUSE_REMOVED 0x405)           /**< A mouse has been removed */
    (define SDL_EVENT_MOUSE_FIRST SDL_EVENT_MOUSE_MOTION)
    (define SDL_EVENT_MOUSE_LAST SDL_EVENT_MOUSE_REMOVED)

    /* Joystick events */
    (define SDL_EVENT_JOYSTICK_AXIS_MOTION 0x600) /**< Joystick axis motion */
    (define SDL_EVENT_JOYSTICK_BALL_MOTION 0x601)          /**< Joystick trackball motion */
    (define SDL_EVENT_JOYSTICK_HAT_MOTION 0x602)           /**< Joystick hat position change */
    (define SDL_EVENT_JOYSTICK_BUTTON_DOWN 0x603)          /**< Joystick button pressed */
    (define SDL_EVENT_JOYSTICK_BUTTON_UP 0x604)            /**< Joystick button released */
    (define SDL_EVENT_JOYSTICK_ADDED 0x605)                /**< A new joystick has been inserted into the system */
    (define SDL_EVENT_JOYSTICK_REMOVED 0x606)              /**< An opened joystick has been removed */
    (define SDL_EVENT_JOYSTICK_BATTERY_UPDATED 0x607)      /**< Joystick battery level change */
    (define SDL_EVENT_JOYSTICK_UPDATE_COMPLETE 0x608)      /**< Joystick update is complete */
    (define SDL_EVENT_JOYSTICK_FIRST SDL_EVENT_JOYSTICK_AXIS_MOTION)
    (define SDL_EVENT_JOYSTICK_LAST SDL_EVENT_JOYSTICK_UPDATE_COMPLETE)

    /* Gamepad events */
    (define SDL_EVENT_GAMEPAD_AXIS_MOTION 0x650) /**< Gamepad axis motion */
    (define SDL_EVENT_GAMEPAD_BUTTON_DOWN 0x651)          /**< Gamepad button pressed */
    (define SDL_EVENT_GAMEPAD_BUTTON_UP 0x652)            /**< Gamepad button released */
    (define SDL_EVENT_GAMEPAD_ADDED 0x653)                /**< A new gamepad has been inserted into the system */
    (define SDL_EVENT_GAMEPAD_REMOVED 0x654)              /**< A gamepad has been removed */
    (define SDL_EVENT_GAMEPAD_REMAPPED 0x655)             /**< The gamepad mapping was updated */
    (define SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN 0x656)        /**< Gamepad touchpad was touched */
    (define SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION 0x657)      /**< Gamepad touchpad finger was moved */
    (define SDL_EVENT_GAMEPAD_TOUCHPAD_UP 0x658)          /**< Gamepad touchpad finger was lifted */
    (define SDL_EVENT_GAMEPAD_SENSOR_UPDATE 0x659)        /**< Gamepad sensor was updated */
    (define SDL_EVENT_GAMEPAD_UPDATE_COMPLETE 0x65a)      /**< Gamepad update is complete */
    (define SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED 0x65b)  /**< Gamepad Steam handle has changed */
    (define SDL_EVENT_GAMEPAD_CAPSENSE_TOUCH 0x65c)       /**< Gamepad capsense was touched */
    (define SDL_EVENT_GAMEPAD_CAPSENSE_RELEASE 0x65d)     /**< Gamepad capsense was released */
    (define SDL_EVENT_GAMEPAD_FIRST SDL_EVENT_GAMEPAD_AXIS_MOTION)
    (define SDL_EVENT_GAMEPAD_LAST SDL_EVENT_GAMEPAD_CAPSENSE_RELEASE)

    /* Touch events */
    (define SDL_EVENT_FINGER_DOWN 0x700)
    (define SDL_EVENT_FINGER_UP 0x701)
    (define SDL_EVENT_FINGER_MOTION 0x702)
    (define SDL_EVENT_FINGER_CANCELED 0x703)
    (define SDL_EVENT_FINGER_FIRST SDL_EVENT_FINGER_DOWN)
    (define SDL_EVENT_FINGER_LAST SDL_EVENT_FINGER_CANCELED)

    /* Pinch events */
    (define SDL_EVENT_PINCH_BEGIN 0x710)     /**< Pinch gesture started */
    (define SDL_EVENT_PINCH_UPDATE 0x711)                 /**< Pinch gesture updated */
    (define SDL_EVENT_PINCH_END 0x712)                    /**< Pinch gesture ended */
    (define SDL_EVENT_PINCH_FIRST SDL_EVENT_PINCH_BEGIN)
    (define SDL_EVENT_PINCH_LAST SDL_EVENT_PINCH_END)

    /* 0x800, 0x801, and 0x802 were the Gesture events from SDL2. Do not reuse these values! sdl2-compat needs them! */

    /* Clipboard events */
    (define SDL_EVENT_CLIPBOARD_UPDATE 0x900) /**< The clipboard changed */
    (define SDL_EVENT_CLIPBOARD_FIRST SDL_EVENT_CLIPBOARD_UPDATE)
    (define SDL_EVENT_CLIPBOARD_LAST SDL_EVENT_CLIPBOARD_UPDATE)

    /* Drag and drop events */
    (define SDL_EVENT_DROP_FILE 0x1000) /**< The system requests a file open */
    (define SDL_EVENT_DROP_TEXT 0x1001)                 /**< text/plain drag-and-drop event */
    (define SDL_EVENT_DROP_BEGIN 0x1002)                /**< A new set of drops is beginning (NULL filename) */
    (define SDL_EVENT_DROP_COMPLETE 0x1003)             /**< Current set of drops is now complete (NULL filename) */
    (define SDL_EVENT_DROP_POSITION 0x1004)             /**< Position while moving over the window */
    (define SDL_EVENT_DROP_FIRST SDL_EVENT_DROP_FILE)
    (define SDL_EVENT_DROP_LAST SDL_EVENT_DROP_POSITION)

    /* Audio hotplug events */
    (define SDL_EVENT_AUDIO_DEVICE_ADDED 0x1100)  /**< A new audio device is available */
    (define SDL_EVENT_AUDIO_DEVICE_REMOVED 0x1101)         /**< An audio device has been removed. */
    (define SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED 0x1102)  /**< An audio device's format has been changed by the system. */
    (define SDL_EVENT_AUDIO_DEVICE_FIRST SDL_EVENT_AUDIO_DEVICE_ADDED)
    (define SDL_EVENT_AUDIO_DEVICE_LAST SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED)

    /* Sensor events */
    (define SDL_EVENT_SENSOR_UPDATE 0x1200)     /**< A sensor was updated */
    (define SDL_EVENT_SENSOR_FIRST SDL_EVENT_SENSOR_UPDATE)
    (define SDL_EVENT_SENSOR_LAST SDL_EVENT_SENSOR_UPDATE)

    /* Pressure-sensitive pen events */
    (define SDL_EVENT_PEN_PROXIMITY_IN 0x1300)  /**< Pressure-sensitive pen has become available */
    (define SDL_EVENT_PEN_PROXIMITY_OUT 0x1301)          /**< Pressure-sensitive pen has become unavailable */
    (define SDL_EVENT_PEN_DOWN 0x1302)                   /**< Pressure-sensitive pen touched drawing surface */
    (define SDL_EVENT_PEN_UP 0x1303)                     /**< Pressure-sensitive pen stopped touching drawing surface */
    (define SDL_EVENT_PEN_BUTTON_DOWN 0x1304)            /**< Pressure-sensitive pen button pressed */
    (define SDL_EVENT_PEN_BUTTON_UP 0x1305)              /**< Pressure-sensitive pen button released */
    (define SDL_EVENT_PEN_MOTION 0x1306)                 /**< Pressure-sensitive pen is moving on the tablet */
    (define SDL_EVENT_PEN_AXIS 0x1307)                   /**< Pressure-sensitive pen angle/pressure/etc changed */
    (define SDL_EVENT_PEN_FIRST SDL_EVENT_PEN_PROXIMITY_IN)
    (define SDL_EVENT_PEN_LAST SDL_EVENT_PEN_AXIS)

    /* Camera hotplug events */
    (define SDL_EVENT_CAMERA_DEVICE_ADDED 0x1400)  /**< A new camera device is available */
    (define SDL_EVENT_CAMERA_DEVICE_REMOVED 0x1401)         /**< A camera device has been removed. */
    (define SDL_EVENT_CAMERA_DEVICE_APPROVED 0x1402)        /**< A camera device has been approved for use by the user. */
    (define SDL_EVENT_CAMERA_DEVICE_DENIED 0x1403)          /**< A camera device has been denied for use by the user. */
    (define SDL_EVENT_CAMERA_DEVICE_FIRST SDL_EVENT_CAMERA_DEVICE_ADDED)
    (define SDL_EVENT_CAMERA_DEVICE_LAST SDL_EVENT_CAMERA_DEVICE_DENIED)

    /* Notification events */
    (define SDL_EVENT_NOTIFICATION_ACTION_INVOKED 0x1500) /**< A user response to a system notification was received. */
    (define SDL_EVENT_NOTIFICATION_FIRST SDL_EVENT_NOTIFICATION_ACTION_INVOKED)
    (define SDL_EVENT_NOTIFICATION_LAST SDL_EVENT_NOTIFICATION_ACTION_INVOKED)

    /* Render events */
    (define SDL_EVENT_RENDER_TARGETS_RESET 0x2000) /**< The render targets have been reset and their contents need to be updated */
    (define SDL_EVENT_RENDER_DEVICE_RESET 0x2001) /**< The device has been reset and all textures need to be recreated */
    (define SDL_EVENT_RENDER_DEVICE_LOST 0x2002) /**< The device has been lost and can't be recovered. */
    (define SDL_EVENT_RENDER_FIRST SDL_EVENT_RENDER_TARGETS_RESET)
    (define SDL_EVENT_RENDER_LAST SDL_EVENT_RENDER_DEVICE_LOST)

    /* Reserved events for private platforms */
    (define SDL_EVENT_PRIVATE0 0x4000)
    (define SDL_EVENT_PRIVATE1 0x4001)
    (define SDL_EVENT_PRIVATE2 0x4002)
    (define SDL_EVENT_PRIVATE3 0x4003)

    /* Internal events */
    (define SDL_EVENT_POLL_SENTINEL 0x7F00) /**< Signals the end of an event poll cycle */

    /** Events SDL_EVENT_USER through SDL_EVENT_LAST are for your use,
     *  and should be allocated with SDL_RegisterEvents()
     */
    (define SDL_EVENT_USER 0x8000)

    /**
     *  This last event is only for bounding internal arrays
     */
    (define SDL_EVENT_LAST 0xFFFF)

    /* This just makes sure the enum is the size of Uint32 */
    (define SDL_EVENT_ENUM_PADDING 0x7FFFFFFF)

/** } SDL_EventType; */

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

