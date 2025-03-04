; 
; Expat License
; 
; Copyright (c) 2015-2024 Lior Halphon
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
; 

IF !DEF(SAMEBOY_INC)
DEF SAMEBOY_INC EQU 1

include "hardware.inc"

DEF rKEY0 EQU $FF4C
DEF rBANK EQU $FF50

DEF rJOYP EQU rP1


MACRO lb ; r16, high, low
    ld \1, LOW(\2) << 8 | LOW(\3)
ENDM


MACRO header_section ; name, address
    PUSHS
    SECTION "\1", ROM0[\2]
    \1:
    POPS
ENDM
    header_section EntryPoint,       $0100
    header_section NintendoLogo,     $0104
    header_section NintendoLogoEnd,  $0134
    header_section Title,            $0134
    header_section ManufacturerCode, $013F
    header_section CGBFlag,          $0143
    header_section NewLicenseeCode,  $0144
    header_section SGBFlag,          $0146
    header_section CartridgeType,    $0147
    header_section ROMSize,          $0148
    header_section RAMSize,          $0149
    header_section DestinationCode,  $014A
    header_section OldLicenseeCode,  $014B
    header_section MaskRomVersion,   $014C
    header_section HeaderChecksum,   $014D
    header_section GlobalChecksum,   $014E

ENDC
