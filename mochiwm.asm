format  ELF64

ACTIVE_COLOR        equ 0xf4f4f4
INACTIVE_COLOR      equ 0x3a3a3a

XCB_MOD_MASK_1      equ 8                       ; Alt

XK_Tab              equ 0xff09
XK_q                equ 0x0071

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

extrn   free
extrn   write

section '.text' executable

_get_color_pixel:
    push        r12

    mov         edx, edi
    shl         edx, 16
    and         edx, 0xFF
    imul        edx, edx, 257

    mov         ecx, edi
    shl         ecx, 16
    and         ecx, 0xFF
    imul        ecx, ecx, 257

    mov         r8d, edi
    and         r8d, 0xFF
    imul        r8d, r8d, 257

    mov         rdi, [XConnection]
    mov         esi, dword [XScreen + 4]
    call        xcb_alloc_color

    mov         rdi, [XConnection]
    mov         esi, eax
    xor         edx, edx
    call        xcb_alloc_color_reply

    test        rax, rax
    jz          .error

    mov         r12d, dword [rax + 16]      ; reply->pixel

    mov         rdi, rax
    call        free

    mov         eax, r12d
    jmp         .done

.error:
    mov         edi, 2
    lea         rsi, [E3]
    mov         edx, 36
    call        write
    
    xor         eax, eax

.done:
    pop         r12
    ret

_grab_keys:
    push        r12
    push        r13
    sub         rsp, 8 ; sudah align rsp % 16 = 0

    ; xcb_key_symbols_t *keysyms = xcb_key_symbols_alloc(conn);
    mov         rdi, [XConnection]
    call        xcb_key_symbols_alloc
    mov         r12, rax                    ; r12 = keysyms

    ; keycode = xcb_key_symbols_get_keycode(keysyms, XK_Tab);
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

    add         rsp, 8
    pop         r13
    pop         r12
    ret

_setup_atoms:
    sub         rsp, 8

    ; WM_PROTOCOLS
    mov         rdi, [XConnection]
    xor         esi, esi
    mov         edx, 12
    lea         rcx, [wm_protocols]
    call        xcb_intern_atom
    mov         [rsp], eax

    ; WM_DELETE_WINDOW
    mov         rdi, [XConnection]
    xor         esi, esi
    mov         edx, 16
    lea         rcx, [wm_delete_window]
    call        xcb_intern_atom
    mov         [rsp + 4], eax

    mov         rdi, [XConnection]
    mov         esi, [rsp]
    xor         edx, edx
    call        xcb_intern_atom_reply
    test        rax, rax
    jz          .done
    
    mov         edi, dword [rax + 8]             ; reply->atom
    mov         [atom_wm_protocols], edi
    mov         rdi, rax
    call        free

    mov         rdi, [XConnection]
    mov         esi, [rsp + 4]
    xor         edx, edx
    call        xcb_intern_atom_reply
    test        rax, rax
    jz          .done

    mov         edi, dword [rax + 8]             ; reply->atom
    mov         [atom_wm_delete_window], edi
    mov         rdi, rax
    call        free

.done:
    add         rsp, 8
    ret

public  _start
_start:
    xor         edi, edi
    xor         esi, esi
    call        xcb_connect
    mov         [XConnection], rax

    mov         rdi, rax
    call        xcb_connection_has_error
    test        eax, eax
    jnz         .errorOpenDisplay

    mov         rdi, [XConnection]
    call        xcb_get_setup

    mov         rdi, rax                    ; xcb setup
    call        xcb_setup_roots_iterator
    mov         [XScreen], rax              ; iter.data
    mov         eax, [rax]                  ; screen->root
    mov         [XWindowRoot], eax

    call        _setup_atoms

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
    call        _get_color_pixel
    mov         [active_color_pixel], eax

    mov         edi, INACTIVE_COLOR
    call        _get_color_pixel
    mov         [inactive_color_pixel], eax

    mov         rdi, [XConnection]
    call        xcb_disconnect
    jmp         .done

.errorOpenDisplay:
    mov         edi, 2
    lea         rsi, [E1]
    mov         edx, 34
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


