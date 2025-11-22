format  ELF64

ACTIVE_COLOR        equ 0x00ff00
INACTIVE_COLOR      equ 0x3a3a3a

XCB_MOD_MASK_1      equ 8                       ; Alt
XCB_MOD_MASK_SHIFT  equ 1

XK_Tab              equ 0xff09
XK_q                equ 0x0071
XK_Return           equ 0xff0d
XK_d                equ 0xffff
XK_h                equ 0x0068
XK_j                equ 0x006a
XK_k                equ 0x006b
XK_l                equ 0x006c

XCB_GRAB_MODE_ASYNC equ 1

extrn   xcb_connect
extrn   xcb_disconnect
extrn   xcb_connection_has_error
extrn   xcb_get_setup
extrn   xcb_setup_roots_iterator
extrn   xcb_intern_atom
extrn   xcb_intern_atom_reply
extrn   xcb_change_window_attributes_checked
extrn   xcb_request_check
extrn   xcb_key_symbols_alloc
extrn   xcb_key_symbols_get_keycode
extrn   xcb_grab_key
extrn   xcb_alloc_color
extrn   xcb_alloc_color_reply
extrn   xcb_key_symbols_free

extrn   free
extrn   write

section '.text' executable

public  _start
public  _start.debug
_start:
    ; connect to X server
    xor         edi, edi                    ; display name
    xor         esi, esi                    ; screenp
    call        xcb_connect
    mov         [XConnection], rax

    mov         rdi, rax                    ; x connection
    call        xcb_connection_has_error
    test        eax, eax
    jnz         .errorOpenDisplay

    ; get screen
    mov         rdi, [XConnection]
    call        xcb_get_setup
    mov         rdi, rax                    ; xcb setup
    call        xcb_setup_roots_iterator
    mov         [XScreen], rax              ; xcb_screen_t*

    mov         eax, [rax]                  ; screen->root
    mov         [XWindowRoot], eax          ; xcb_window_t

    call        _setup_atoms

.debug:
    mov         edi, ACTIVE_COLOR
    call        get_color_pixel
    mov         [active_color_pixel], eax

    mov         rdi, [XConnection]
    call        xcb_disconnect
    jmp         .done

    ; check if another WM is running
    mov         rdi, [XConnection]
    mov         esi, [XWindowRoot]
    mov         edx, 2048                   ; XCB_CW_EVENT_MASK
    lea         rcx, [XMaskValues]
    call        xcb_change_window_attributes_checked

    mov         rdi, [XConnection]
    mov         esi, eax
    call        xcb_request_check
    test        rax, rax
    jnz         .errorAnotherWMRunning

    mov         edi, ACTIVE_COLOR
    call        get_color_pixel
    mov         [active_color_pixel], eax

    mov         edi, INACTIVE_COLOR
    call        get_color_pixel
    mov         [inactive_color_pixel], eax

    call        _grab_keys

    mov         rdi, [XConnection]
    call        xcb_disconnect
    jmp         .done

.errorOpenDisplay:
    mov         edi, 2      ; stderr
    lea         rsi, [E1]   ; add
    mov         edx, 34     ; length
    call        write
    jmp         .done

.errorAnotherWMRunning:
    mov         edi, 2
    lea         rsi, [E2]
    mov         edx, 41
    call        write

.done:
    mov         eax, 60
    xor         edi, edi
    syscall

get_color_pixel:
    push        r12

    mov         edx, edi                    ; hex_color
    shr         edx, 16
    and         edx, 0xFF
    imul        edx, edx, 257               ; red

    mov         ecx, edi
    shr         ecx, 8
    and         ecx, 0xFF
    imul        ecx, ecx, 257               ; green

    mov         r8d, edi
    and         r8d, 0xFF
    imul        r8d, r8d, 257               ; blue

    mov         rdi, [XConnection]          ; connection
    mov         rsi, [XScreen]
    mov         esi, [rsi + 4]              ; screen->colormap
    call        xcb_alloc_color

    mov         rdi, [XConnection]          ; connection
    mov         esi, eax                    ; cookie
    xor         edx, edx
    call        xcb_alloc_color_reply

    test        rax, rax
    jz          .error

    mov         r12d, dword [rax + 16]      ; pixel

    mov         rdi, rax
    call        free

    mov         eax, r12d
    jmp         .done

.error:
    mov         edi, 2
    lea         rsi, [E1]
    mov         edx, 36
    call        write

    xor         eax, eax

.done:
    pop         r12
    ret

    ; leave
    ; ret

_grab_keys:
    push        r12
    push        r13
    sub         rsp, 8 ; sudah align rsp % 16 = 0

    ; xcb_key_symbols_t *keysyms = xcb_key_symbols_alloc(conn);
    mov         rdi, [XConnection]
    call        xcb_key_symbols_alloc
    mov         r12, rax                    ; r12 = keysyms

    ; MOD + Tab
    mov         rdi, r12                    ; keysyms
    mov         esi, XK_Tab
    call        xcb_key_symbols_get_keycode
    mov         r13, rax                    ; keycode
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + q
    mov         rdi, r12
    mov         esi, XK_q
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + Shift + q
    mov         rdi, r12
    mov         esi, XK_q
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    or          ecx, XCB_MOD_MASK_SHIFT
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + Return
    mov         rdi, r12
    mov         esi, XK_Return
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + d
    mov         rdi, r12
    mov         esi, XK_d
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + h
    mov         rdi, r12
    mov         esi, XK_h
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + j
    mov         rdi, r12
    mov         esi, XK_j
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + k
    mov         rdi, r12
    mov         esi, XK_k
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + l
    mov         rdi, r12
    mov         esi, XK_l
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + Shift + h
    mov         rdi, r12
    mov         esi, XK_h
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    or          ecx, XCB_MOD_MASK_SHIFT
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + Shift + j
    mov         rdi, r12
    mov         esi, XK_j
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    or          ecx, XCB_MOD_MASK_SHIFT
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + Shift + k
    mov         rdi, r12
    mov         esi, XK_k
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    or          ecx, XCB_MOD_MASK_SHIFT
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    ; MOD + Shift + l
    mov         rdi, r12
    mov         esi, XK_l
    call        xcb_key_symbols_get_keycode
    mov         r13, rax
    mov         rdi, [XConnection]
    mov         esi, 1
    mov         edx, [XWindowRoot]
    mov         ecx, XCB_MOD_MASK_1
    or          ecx, XCB_MOD_MASK_SHIFT
    mov         r8, [r13]
    mov         r9d, XCB_GRAB_MODE_ASYNC
    mov         dword [rsp], XCB_GRAB_MODE_ASYNC
    call        xcb_grab_key
    mov         rdi, r13
    call        free

    mov         rdi, r12
    call        xcb_key_symbols_free

    add         rsp, 8
    pop         r13
    pop         r12
    ret

_setup_atoms:
    sub         rsp, 8                      ; padding

    ; cookie - WM_PROTOCOLS
    mov         rdi, [XConnection]          ; x connection
    xor         esi, esi                    ; atom exist
    mov         edx, 12                     ; name length (WM_PROTOCOLS)
    lea         rcx, [wm_protocols]         ; name
    call        xcb_intern_atom
    mov         [rsp], eax

    ; cookie - WM_DELETE_WINDOW
    mov         rdi, [XConnection]
    xor         esi, esi
    mov         edx, 16
    lea         rcx, [wm_delete_window]
    call        xcb_intern_atom
    mov         [rsp + 4], eax

    ; cookie reply - WM_PROTOCOLS
    mov         rdi, [XConnection]          ; x connection
    mov         esi, [rsp]                  ; cookie
    xor         edx, edx                    ; xcb_generic_error
    call        xcb_intern_atom_reply
    test        rax, rax
    jz          .done
   
    ; free reply - WM_PROTOCOLS
    mov         edi, dword [rax + 8]        ; reply->atom
    mov         [atom_wm_protocols], edi
    mov         rdi, rax
    call        free

    ; cookie reply - WM_DELETE_WINDOW
    mov         rdi, [XConnection]
    mov         esi, [rsp + 4]
    xor         edx, edx
    call        xcb_intern_atom_reply
    test        rax, rax
    jz          .done

    ; free reply - WM_DELETE_WINDOW
    mov         edi, dword [rax + 8]        ; reply->atom
    mov         [atom_wm_delete_window], edi
    mov         rdi, rax
    call        free

.done:
    add         rsp, 8
    ret




public XConnection
public XScreen

section '.data' writeable
active_color_pixel      dd 0
inactive_color_pixel    dd 0


section '.bss'
XConnection             rq 1
XScreen                 rq 1
XWindowRoot             rd 1
atom_wm_protocols       rd 1
atom_wm_delete_window   rd 1


section 'rodata'
align 4
; XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT  = 1048576
; XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY    = 524288
; XCB_EVENT_MASK_BUTTON_PRESS           = 4
; XCB_EVENT_MASK_BUTTON_RELEASE         = 8
; XCB_EVENT_MASK_POINTER_MOTION         = 64
; XCB_EVENT_MASK_KEY_PRESS              = 1
XMaskValues             dd (1048576 or 524288 or 4 or 8 or 64 or 1)

wm_protocols            db "WM_PROTOCOLS"
wm_delete_window        db "WM_DELETE_WINDOW"

E1                      db "[ERROR]: Could not open display!", 0xa, 0x0
E2                      db "[ERROR]: Another WM is already running!", 0xa, 0x0
E3                      db "[ERROR]: Could not allocate color!", 0xa, 0x0


section '.note.GNU-stack'


