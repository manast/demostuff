; Svga Stuff




VgaInfoBlock    STRUC
      VESASignature   db   'VESA'      ; 4 signature bytes
      VESAVersion     dw   ?           ; VESA version number
      OEMStringPtr    dd   ?           ; Pointer to OEM string
      Capabilities    db   4 dup(?)    ; capabilities of the video environment
      VideoModePtr    dd   ?           ; pointer to supported Super VGA modes
      TotalMemory     dw   ?           ; Number of 64kb memory blocks on board
      Reserved        db   236 dup(?)  ; Remainder of VgaInfoBlock
VgaInfoBlock    ENDS

ModeInfoBlock   STRUC

; mandatory information

        ModeAttributes      dw  ?  ; mode attributes
        WinAAttributes      db  ?  ; window A attributes
        WinBAttributes      db  ?  ; window B attributes
        WinGranularity      dw  ?  ; window granularity
        WinSize             dw  ?  ; window size
        WinASegment         dw  ?  ; window A start segment
        WinBSegment         dw  ?  ; window B start segment
        WinFuncPtr          dd  ?  ; pointer to windor function
        BytesPerScanLine    dw  ?  ; bytes per scan line

; formerly optional information (now mandatory)

        XResolution         dw  ?  ; horizontal resolution
        YResolution         dw  ?  ; vertical resolution
        XCharSize           db  ?  ; character cell width
        YCharSize           db  ?  ; character cell height
        NumberOfPlanes      db  ?  ; number of memory planes
        BitsPerPixel        db  ?  ; bits per pixel
        NumberOfBanks       db  ?  ; number of banks
        MemoryModel         db  ?  ; memory model type
        BankSize            db  ?  ; bank size in kb
        NumberOfImagePages  db  ?  ; number of images
        Reserved            db  1  ; reserved for page function

                      VESA Super VGA Standard VS911022-15

; new Direct Color fields

        RedMaskSize         db  ?  ; size of direct color red mask in bits
        RedFieldPosition    db  ?  ; bit position of LSB of red mask
        GreenMaskSize       db  ?  ; size of direct color green mask in bits
        GreenFieldPosition  db  ?  ; bit position of LSB of green mask
        BlueMaskSize        db  ?  ; size of direct color blue mask in bits
        BlueFieldPosition   db  ?  ; bit position of LSB of blue mask
        RsvdMaskSize        db  ?  ; size of direct color reserved mask in bits
        DirectColorModeInfo db  ?  ; Direct Color mode attributes
        Reserved            db  216 dup(?)      ; remainder of ModeInfoBlock
ModeInfoBlock   ENDS

