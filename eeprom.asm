
; --------------------------------------------------------------
;
; Trinity EEPROM functions by Colin Piggot
;
; --------------------------------------------------------------

;               ORG  32768
;               DUMP 32768

; BASIC jump table

               JP   count_empty          ; 32768
               JP   find_empty           ; 32771
               JP   find_index           ; 32774
               JP   delete_index         ; 32777
               JP   read_index           ; 32780
               JP   read_chunk           ; 32783
               JP   write_index          ; 32786
               JP   write_chunk          ; 32789

; Input and return value

value:         DEFB 0                    ; 32792

; 64 byte index header

part:          DEFB 0                    ; 32793
total:         DEFB 0
name:          DEFS 16                   ; 32795
description:   DEFS 46

; 1024 byte data chunk

chunk:         DEFS 1024                 ; 32857


; --------------------------------------------------------------
;
; count_empty - count the number of free chunks in the EEPROM
;               and return the number in 'value'

count_empty:
               XOR  A
               LD   (value),A

               LD   HL,0
               LD   B,120
               LD   DE,64
               LD   C,&DD
empty_loop:
               CALL eeprom_enable
               LD   A,&03
               OUT  (C),A
               CALL wait_ready
               XOR  A
               OUT  (C),A
               CALL wait_ready
               OUT  (C),H
               CALL wait_ready
               OUT  (C),L
               CALL wait_ready
               OUT  (C),A
               CALL wait_ready
               IN   A,(C)
               CP   0
               JR   Z,empty_yes
               CP   255
               JR   NZ,empty_skip
empty_yes:
               LD   A,(value)
               INC  A
               LD   (value),A
empty_skip:
               CALL eeprom_disable
               ADD  HL,DE
               DJNZ empty_loop
               RET



; --------------------------------------------------------------
;
; find_empty - find the first free chunk in the EEPROM and
;              return the number in 'value'. 0 is returned if
;              no empty space

find_empty:
               LD   A,1
               LD   (value),A
               LD   HL,0
               LD   B,120
               LD   DE,64
               LD   C,&DD
find_loop:
               CALL eeprom_enable
               LD   A,&03
               OUT  (C),A
               CALL wait_ready
               XOR  A
               OUT  (C),A
               CALL wait_ready
               OUT  (C),H
               CALL wait_ready
               OUT  (C),L
               CALL wait_ready
               OUT  (C),A
               CALL wait_ready
               IN   A,(C)
               CP   0
               JP   Z,exit
               CP   255
               JP   Z,exit

               CALL eeprom_disable
               LD   A,(value)
               INC  A
               LD   (value),A
               ADD  HL,DE
               DJNZ find_loop
               XOR  A
               LD   (value),A
               RET




; --------------------------------------------------------------
;
; find_index - search the index table to match the part number,
;              total number and name and return the number.
;              0 is returned if not found.

find_index:
               LD   A,1
               LD   (value),A
               LD   HL,0
               LD   B,120
               LD   DE,64
               LD   C,&DD
index_loop:
               CALL eeprom_enable
               LD   A,&03
               OUT  (C),A
               CALL wait_ready
               XOR  A
               OUT  (C),A
               CALL wait_ready
               OUT  (C),H
               CALL wait_ready
               OUT  (C),L
               CALL wait_ready

               PUSH BC
               PUSH HL

               LD   HL,index_store
               LD   B,18

index_loop2:   OUT  (C),D
               CALL wait_ready
               INI
               LD   A,B
               JR   NZ,index_loop2

               POP  HL
               POP  BC

               CALL eeprom_disable
               JP   check_index

index_back:
               LD   A,(value)
               INC  A
               LD   (value),A
               ADD  HL,DE
               DJNZ index_loop
               XOR  A
               LD   (value),A
               RET

check_index:
               PUSH BC
               PUSH HL
               PUSH DE

               LD   DE,index_store
               LD   HL,part
               LD   B,18
check_loop:
               LD   A,(DE)
               CP   (HL)
               JR   NZ,check_return

               INC  HL
               INC  DE
               DJNZ check_loop

               POP  DE
               POP  HL
               POP  BC
               RET

check_return:
               POP  DE
               POP  HL
               POP  BC
               JP   index_back

index_store:   DEFS 18

; --------------------------------------------------------------
;
; delete_index - delete a chunk entry from the index table

delete_index:
               LD   A,(value)
               CALL get_index

               CALL write_enable
               CALL eeprom_enable

               LD   C,&DD
               LD   A,&02
               OUT  (C),A
               CALL wait_ready
               XOR  0
               OUT  (C),A
               CALL wait_ready
               OUT  (C),H
               CALL wait_ready
               OUT  (C),L
               CALL wait_ready
               XOR  A
               OUT  (C),A
               CALL wait_ready
               OUT  (C),A
               CALL wait_ready

               CALL eeprom_disable
               CALL write_delay
               RET

; --------------------------------------------------------------
;
; read_index - read the part, total, name and description for
;              for the chunk number in 'value'

read_index:
               LD   A,(value)
               CALL get_index
               CALL eeprom_enable

               LD   BC,&40DD
               LD   E,0

               LD   A,&03
               OUT  (C),A
               CALL wait_ready
               XOR  A
               OUT  (C),A
               CALL wait_ready
               OUT  (C),H
               CALL wait_ready
               OUT  (C),L
               CALL wait_ready

               LD   HL,part
read_iloop:
               OUT  (C),E
               CALL wait_ready
               INI
               CALL wait_ready
               LD   A,B
               CP   0
               JR   NZ,read_iloop

               JP   exit

; --------------------------------------------------------------
;
; read_chunk - read the 1K data chunk for the chunk number in
;              in 'value'

read_chunk:
               LD   A,(value)
               CALL get_chunk
               CALL eeprom_enable

               LD   BC,&00DD
               LD   DE,&0400

               LD   A,&03
               OUT  (C),A
               CALL wait_ready
               OUT  (C),H
               CALL wait_ready
               OUT  (C),L
               CALL wait_ready
               OUT  (C),E
               CALL wait_ready

               LD   HL,chunk
read_cloop:
               OUT  (C),E
               CALL wait_ready
               INI
               LD   A,B
               CP   0
               JR   NZ,read_cloop
               DEC  D
               JR   NZ,read_cloop

               JP   exit


; --------------------------------------------------------------
;
; write_index - write an index extry for chunk number in 'value'
;               using data from part, total, name, description

write_index:
               LD   A,(value)
               CALL get_index

               CALL write_enable
               CALL eeprom_enable

               LD   BC,&40DD

               LD   A,&02
               OUT  (C),A
               CALL wait_ready
               XOR  A
               OUT  (C),A
               CALL wait_ready
               OUT  (C),H
               CALL wait_ready
               OUT  (C),L
               CALL wait_ready

               LD   HL,part
write_iloop:
               OUTI
               CALL wait_ready
               LD   A,B
               CP   0
               JR   NZ,write_iloop

               CALL eeprom_disable
               CALL write_delay
               RET




; --------------------------------------------------------------
;
; write_chunk - write 1K data chunk, in chunk number from
;               'value'

write_chunk:
               LD   A,(value)
               CALL get_chunk

               LD   DE,chunk
               CALL write_256
               INC  L
               CALL write_256
               INC  L
               CALL write_256
               INC  L
               CALL write_256
               RET

write_256:
               CALL write_enable
               CALL eeprom_enable
               LD   BC,&00DD

               LD   A,&02
               OUT  (C),A
               CALL wait_ready
               OUT  (C),H
               CALL wait_ready
               OUT  (C),L
               CALL wait_ready
               XOR  A
               OUT  (C),A
               CALL wait_ready

               EX   DE,HL
write_cloop1:
               OUTI
               CALL wait_ready
               LD   A,B
               CP   0
               JR   NZ,write_cloop1

               CALL eeprom_disable
               CALL write_delay
               EX   DE,HL
               RET


; --------------------------------------------------------------
;
; Common sub routines used by the main functions above for
; controlling EEPROM operation on the Trinity interface

eeprom_enable:
               LD   A,&11
               OUT  (&DC),A
               JP   wait_ready

eeprom_disable:
               LD   A,&10
               OUT  (&DC),A
               JP   wait_ready

exit:
               CALL eeprom_disable
               CALL write_disable
               JP   wait_ready

;wait_ready:
;               IN   A,(&DC)
;               AND  &08
;               JR   NZ,wait_ready
;               RET

get_index:
               LD   HL,-64
               LD   DE,64
               LD   B,A
get_loop:
               ADD  HL,DE
               DJNZ get_loop
               RET

get_chunk:
               LD   HL,28
               LD   DE,4
               LD   B,A
chunk_loop:
               ADD  HL,DE
               DJNZ chunk_loop
               RET

write_delay:
               PUSH BC
               LD   BC,16
delay_loop:
               DJNZ delay_loop
               DEC  C
               JR   NZ,delay_loop
               POP  BC
               RET

write_enable:
               CALL eeprom_enable
               LD   A,&06
               OUT  (&DD),A
               CALL wait_ready
               CALL eeprom_disable
               RET

write_disable:
               CALL eeprom_enable
               LD   A,&04
               OUT  (&DD),A
               CALL wait_ready
               CALL eeprom_disable
               RET
