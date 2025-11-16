format  ELF64

extrn   xcb_connect
extrn   xcb_disconnect
extrn   xcb_connection_has_error
extrn   xcb_get_setup
extrn   xcb_setup_roots_iterator
extrn   xcb_intern_atom
extrn   xcb_intern_atom_reply
extrn   xcb_change_window_attributes_checked
extrn   xcb_request_check

extrn   free
extrn   write

section '.text' executable

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


section '.note.GNU-stack'


