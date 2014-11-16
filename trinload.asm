; TrinLoad 1.0
;
; Quazar Trinity Network Code Loader
;
; By Simon Owen <simon@simonowen.com>

            org &6000
            dump $
            autoexec

LEPR:       equ &80                     ; Low External Page Register
HMPR:       equ &fb                     ; High Memory Page Register

ROM_LDIR:   equ &008f                   ; LDIR in ROM is ~8% faster
JSETSTRM:   equ &0112                   ; ROM set output stream
JCLSBL:     equ &014E                   ; ROM CLS

start:
            xor a
            call JCLSBL                 ; CLS
            ld  a,&fe
            call JSETSTRM               ; output to upper screen

            call chk_trinity
            ld  hl,msg_trinity          ; "Trinity not detected."
            jp  nz, print_msg

            ld  a,1
            ld  (part),a                ; part 1
            ld  (total),a               ; of 1
            ld  hl,trin_chunk           ; "Trinity Network "
            ld  de,name
            ld  bc,16
            ldir
            call find_index             ; find index entry for chunk
            ld  a,(value)
            and a
            ld  hl,msg_misscfg          ; "Network settings missing."
            jp  z,print_msg
            call read_chunk             ; read chunk contents
            ld  a,(value)
            and a
            ld  hl,msg_flashrd          ; "Flash read failed!"
            jp  z,print_msg

            ld  a,(sam_mac+0)           ; first byte of MAC
            ld  b,a
            ld  a,(sam_ip+6)            ; first byte of IP
            or  b                       ; both zero?
            ld  hl,msg_misscfg          ; "Network settings missing."
            jp  z,print_msg

            ld  hl,chunk+0              ; SAM MAC from settings
            call drv_init
            dec c
            ld  hl,msg_drvinit          ; "ENC28J60 init failed."
            jp  nz,print_msg

            ld  hl,msg_waiting          ; "TrinLoad 1.0: Ready..."
            call print_msg
read_loop:
            ld  a,&f7
            in  a,(&f9)
            bit 5,a                     ; Esc pressed?
            jp  z,drv_exit              ; if so, exit via network disable

            ld  hl,packet
            call drv_read               ; read network packet
            ld  a,b
            or  c
            jr  z,read_loop             ; loop if nothing available


            ld  a,(packet+12)           ; Ethernet frame type
            cp  &08                     ; IPv4 or ARP?
            jr  nz,read_loop

            ld  a,(packet+13)
            cp  &06                     ; ARP?
            jr  nz,try_ipv4

            ld  a,(packet+21)
            cp  &01                     ; request?
            jr  nz,read_loop
            inc a                       ; convert to reply
            ld  (packet+21),a

            ld  hl,(packet+38)          ; requested IP (first 2 bytes)
            ld  de,(sam_ip)             ; our IP
            sbc hl,de
            jr  nz,read_loop            ; jump if not for us

            ld  hl,(packet+40)          ; second 2 bytes of IP
            ld  de,(sam_ip+2)
            and a
            sbc hl,de
            jr  nz,read_loop            ; jump if not for us

            call return_eth
            call return_arp

            ld  hl,packet
            ld  bc,42
            call drv_write
            jp  read_loop

try_ipv4:
            and a                       ; IPv4?
            jp  nz,read_loop

            ld  a,(packet+20)           ; IP flags
            and %00100000               ; fragmented?
            jp  nz,read_loop            ; ignore, we don't support reassembly

            ld  a,(packet+23)
            cp  &01                     ; ICMP?
            jr  nz,try_udp

            ld  a,(packet+34)
            cp  &08                     ; echo request?
            jp  nz,read_loop
            xor a
            ld  (packet+34),a           ; convert to echo reply

            call return_eth
            call return_ip

            call checksum_ip
            call checksum_icmp

            ld  hl,packet
            call ip_to_eth_len
            call drv_write
            jp  read_loop

try_udp:
            cp  &11                     ; UDP?
            jp  nz,read_loop

            ld  de,(packet+36)          ; destination port
            ld  hl,&b0ed                ; port EDB0
            sbc hl,de
            jp  nz,read_loop            ; ignore if not for us

            ld  a,(packet+42)
            cp  "?"                     ; query?
            jr  nz,try_data

            ld  a,"!"
            ld  (packet+42),a           ; reply as "!"
            ld  bc,1
            call ack_len
            jp  read_loop

try_data:
            cp  "@"                     ; data block?
            jr  nz,try_exec

            ld  a,"."
            rst 16                      ; output '.'

            ld  ix,packet+14+20         ; start of UDP header
            ld  a,(ix+5)                ; UDP length LSB
            sub 8                       ; subtract UDP header size
            ld  c,a
            ld  a,(ix+4)                ; UDP length MSB
            sbc a,0                     ; carry from LSB subtraction
            ld  b,a

            ld  a,(ix+9)                ; page
            out (HMPR),a                ; set HMPR

            ld  hl,packet+14+20+8+4
            ld  e,(ix+10)
            ld  d,(ix+11)               ; target offset
            set 7,d                     ; adjust for top 32K
            call ROM_LDIR               ; move block

            ld  c,4
            call ack_len
            jp  read_loop

try_exec:
            cp  "X"                     ; execute instruction?
            jp  nz,read_loop

            rst 16                      ; output 'X'

            ld  bc,4
            call ack_len

            call drv_exit
            ld  hl,start
            push hl                     ; return via start

            ld  ix,packet+14+20+8
            ld  a,(ix+1)                ; page for HMPR
            out (HMPR),a
            ld  l,(ix+2)                ; execute address LSB
            ld  h,(ix+3)                ; execute address MSB
            jp  (hl)

; Ack a received UDP packet by returning part of it (possibly modified)
; BC holds UDP data length to return
ack_len:
            call set_udp_data_len
            push bc

            call return_eth
            call return_ip
            call return_udp

            call checksum_ip
            call checksum_udp

            ld  hl,packet
            pop bc
            jp  drv_write

; Set the UDP data length, updating the IP header
; BC returns with the total Ethernet frame length
set_udp_data_len:
            ld  ix,packet
            ld  hl,8                    ; UDP header length
            add hl,bc
            ld  (ix+38),h               ; set total UDP length
            ld  (ix+39),l
            ld  bc,20                   ; IP header length
            add hl,bc
            ld  (ix+16),h               ; set total IP length
            ld  (ix+17),l
            ld  bc,14                   ; Ethernet header length
            add hl,bc                   ; form full frame length
            ld  b,h
            ld  c,l
            ret

; Calculate ethernet frame length using the IP header
; BC holds length in bytes on return
ip_to_eth_len:
            ld  a,(packet+17)
            add a,6+6+2                 ; Ethernet header (src MAC + dst MAC + type/len)
            ld  c,a
            ld  a,(packet+16)
            adc a,0
            ld  b,a
            ret

; Swap MAC and IP in ARP header
return_arp:
            ld  hl,packet+22
            ld  de,packet+32
            ld  bc,6+4
            ldir                        ; copy sender MAC+IP to target
            ld  hl,sam_mac
            ld  de,packet+22
            ld  c,6
            ldir                        ; copy SAM MAC to sender
            ld  hl,sam_ip
            ld  c,4
            ldir                        ; copy SAM IP to sender
            ret

; Swap MAC addresses in Ethernet header
return_eth:
            ld  hl,packet+6             ; source MAC
            ld  de,packet               ; destination MAC
            ld  bc,6
            ldir
            ld  hl,sam_mac
            ld  c,6
            ldir
            ret

; Swap addresses in IP header
return_ip:
            ld  hl,packet+26            ; source IP address
            ld  de,packet+30            ; destination IP address
            ld  bc,4
            ldir
            ld  hl,sam_ip
            ld  de,packet+26
            ld  c,4
            ldir
            ret

; Swap ports in UDP header
return_udp:
            ld  hl,(packet+34)          ; source port
            ld  de,(packet+36)          ; destination port
            ld  (packet+36),hl
            ld  (packet+34),de
            ret

; Calculate checksum for IP header
checksum_ip:
            ld  ix,packet+14
            ld  a,(ix)
            and &0f                     ; DWORDs in header
            add a,a                     ; now WORDs
            ld  c,a
            ld  b,0
            ld  (ix+10),b               ; clear checksum for calculation
            ld  (ix+11),b
            call chksum_blk
            ld  (ix+10),h               ; note: big endian!
            ld  (ix+11),l
            ret

; Calculate checksum for ICMP header+data
checksum_icmp:
            ld  e,0                     ; zero for various uses below
            ld  ix,packet+6+6+2+20      ; ICMP header

            ld  a,(ix-20)               ; IP type + header length
            and &0f                     ; number of DWORDs
            add a,a
            add a,a                     ; number of bytes
            ld  d,a
            ld  a,(ix-17)               ; total length LSB
            sub d                       ; subtract IP header size
            ld  c,a
            ld  a,(ix-18)               ; total length MSB
            sbc a,e                     ; carry from LSB subtraction
            ld  b,a

            ld  hl,packet+6+6+2+20      ; start of ICMP header
            add hl,bc                   ; position after ICMP data
            ld  (hl),e                  ; clear in case checksum uses it

            inc bc                      ; round up for word count below
            srl b                       ; / 2 to give word count
            rr  c

            ld  (ix+2),e                ; clear checksum for calculation
            ld  (ix+3),e
            call chksum_blk
            ld  (ix+2),h                ; note: big endian!
            ld  (ix+3),l
            ret

; Calculate checksum for UDP header+data
checksum_udp:
            ld  hl,0                    ; UDP checksum is optional :)
            ld  (packet+40),hl
            ret

; Internet checksum from RFC 1071, summed words with carry, then inverted.
; IX points to start of block, BC holds block length in words.
chksum_blk:
            push ix
            ld  hl,0                    ; checksum initialised to 0

            ld  a,c                     ; swap byte order to invert loops
            ld  c,b                     ; below for small speed-up
            ld  b,a
            inc c                       ; MSB needs to be 1 extra
            and a                       ; clear carry for ADC below
chksum_loop:
            ld  d,(ix)                  ; big endian WORD
            ld  e,(ix+1)
            adc hl,de
            inc ix
            inc ix
            djnz chksum_loop
            dec c
            jr  nz,chksum_loop
            jr  nc,chk_end
            inc hl                      ; final carry
chk_end:
            ld  a,h
            cpl                         ; invert MSB
            ld  h,a
            ld  a,l
            cpl                         ; invert LSB
            ld  l,a
            pop ix
            ret

; Print message to current output stream
; HL points to null-terminated string
print_msg:
            ld  a,(hl)
            and a                       ; null terminator?
            ret z
            rst 16                      ; print character
            inc hl
            jr  print_msg

msg_trinity:defm "Trinity not detected."
            defb 13, 0
msg_misscfg:defm "Network settings missing."
            defb 13, 0
msg_flashrd:defm "Flash read failed!"
            defb 13, 0
msg_drvinit:defm "ENC28J60 init failed."
            defb 13,0
msg_waiting:defm "TrinLoad 1.0: Ready..."
            defb 0

            include "encdrv.asm"        ; Trinity ethernet functions
            include "eeprom.asm"        ; Trinity EEPROM functions

sam_mac:    equ chunk+0                 ; points to loaded flash chunk
sam_ip:     equ chunk+6

trin_chunk: defm "Trinity Network "     ; Flash chunk name containing network settings

packet:     defs 1518                   ; 6 MAC + 6 MAC + 2 len + 1500 data + 4 checksum

length:     equ $ - start               ; code length
