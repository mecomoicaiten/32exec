.arm
.balign 4
.global _LC32Dlsym
_LC32Dlsym:
    movw r12, #1001
    svc #0x80
    bx lr

.global _LC32InvokeHostCRet32
_LC32InvokeHostCRet32:
    movw r12, #1002
    svc #0x80
    bx lr

.global _LC32GuestToHostCString
_LC32GuestToHostCString:
    movw r12, #1003
    svc #0x80
    bx lr

.global _LC32GuestToHostCStringFree
_LC32GuestToHostCStringFree:
    movw r12, #1004
    svc #0x80
    bx lr

.global _LC32GetHostSelector
_LC32GetHostSelector:
    movw r12, #1005
    svc #0x80
    bx lr

.global _LC32InvokeHostSelector
_LC32InvokeHostSelector:
    movw r12, #1006
    svc #0x80
    bx lr

.global _LC32GetHostObject
_LC32GetHostObject:
    movw r12, #1007
    svc #0x80
    bx lr

.global _LC32HostToGuestCopyClassName
_LC32HostToGuestCopyClassName:
    movw r12, #1008
    svc #0x80
    bx lr

.global _LC32InvokeGuestC
_LC32InvokeGuestC:
    blx r12
    movw r12, #1009
    svc #0x80
    bkpt

