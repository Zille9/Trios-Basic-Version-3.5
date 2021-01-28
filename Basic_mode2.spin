{{      Mode2-VGA-Treiber Micromite+TRIOS-BASIC für Hive
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Reinhard Zielinski                                                                            │
│ Copyright (c) 2014 Reinhard Zielinski                                                                │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : zille9@googlemail.com
System          : Hive
Name            : Mode4-VGA-Treiber 160x120 Pixel
Chip            : Bellatrix
Typ             : Treiber
Version         : 01
Subversion      : 00
Funktion        : VGA-Pixel-Text- und Tastatur-Treiber

Dieser Bellatrix-Code kann als Stadardcode im EEPROM gespeichert werden - Textbildschirm
und Tastaturfunktionen. Mit dem integrierten Loader kann Bellatrix
mit einem beliebigen anderen Code geladen werden.

Komponenten     : Mode4-VGA-Treiber für Micromite+TRIOS-Basic
                  PS/2 Keyboard Driver v1.0.1     Chip Gracey, ogg   MIT

COG's           : MANAGMENT     1 COG
                  VGA           1 COG
                  KEYB          1 COG
                  -------------------
                                3 COG's

Logbuch         :

05-04-2015      -Funktionalität entsprechend Mode2 und 3
                -Textausgabe extrem langsam, da ein Zeichen aus 64 Pixel zusammengebaut werden muss, das dauert entsprechend lange
                -es geht aber haupsächlich um die 64 Farben je Pixel-Darstellung
                -1239 Longs frei
Notizen:

}}


CON

_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000

'signaldefinitionen bellatrixix

#0,     D0,D1,D2,D3,D4,D5,D6,D7                         'datenbus
#8,     BEL_VGABASE                                     'vga-signale (8pin)
#16,    BEL_KEYBC,BEL_KEYBD                             'keyboard-signale
#18,    BEL_MOUSEC,BEL_MOUSED                           'maus-signale
#20,    BEL_VIDBASE                                     'video-signale(3pin)
#23,    BEL_SELECT                                      'belatrix-auswahlsignal
#24,    HBEAT                                           'front-led
        BUSCLK                                          'bustakt
        BUS_WR                                          '/wr - schreibsignal
        BUS_HS '                                        '/hs - quittungssignal
#41,    RTC_GETSECONDS                              'Returns the current second (0 - 59) from the real time clock.
        RTC_GETMINUTES                              'Returns the current minute (0 - 59) from the real time clock.
        RTC_GETHOURS                                'Returns the current hour (0 - 23) from the real time clock.
'                   +----------
'                   |  +------- system     
'                   |  |  +---- version    (änderungen)
'                   |  |  |  +- subversion (hinzufügungen)
'CHIP_VER        = $00_01_02_01
'
'                                           +---------- 
'                                           | +-------- 
'                                           | |+------- vektor
'                                           | ||+------ grafik
'                                           | |||+----- text
'                                           | ||||+---- maus
'                                           | |||||+--- tastatur
'                                           | ||||||+-- vga
'                                           | |||||||+- tv
CHIP_SPEC       = %00000000_00000000_00000000_00110110


KEYB_DPORT   = BEL_KEYBD                               'tastatur datenport
KEYB_CPORT   = BEL_KEYBC                               'tastatur taktport
mouse_dport  = BEL_MOUSED
mouse_cport  = BEL_MOUSEC

'          hbeat   --------+                            
'          clk     -------+|                            
'          /wr     ------+||                            
'          /hs     -----+||| +------------------------- /cs
'                       |||| |                 -------- d0..d7
DB_IN            = %00001000_00000000_00000000_00000000 'maske: dbus-eingabe
DB_OUT           = %00001000_00000000_00000000_11111111 'maske: dbus-ausgabe

M1               = %00000010_00000000_00000000_00000000
M2               = %00000010_10000000_00000000_00000000 'busclk=1? & /cs=0?

M3               = %00000000_00000000_00000000_00000000
M4               = %00000010_00000000_00000000_00000000 'busclk=0?

_pinGroup = 1
_startUpWait = 2

'' Terminal Vars
   CHAR_W	      = 80
   CHAR_H	      = 30

  Bel_Treiber_Ver=171                                                                                       'Bellatrix-Treiberversion Micromite-Mode2 Pixel-Treiber
  'tiles    = vga#xtiles * vga#ytiles
  'tiles32  = tiles * 16'32

  linelen  = 79


  #$FC, Light_Grey, #$A8, Grey, #$54, Dark_Grey
  #$C0, Light_Red, #$80, Red, #$40, Dark_Red
  #$30, Light_Green, #$20, Green, #$10, Dark_Green
  #$1F, Light_Blue, #$09, Blue, #$04, Dark_Blue
  #$F0, Light_Orange, #$E6, Orange, #$92, Dark_Orange
  #$CC, Light_Purple, #$88, Purple, #$44, Dark_Purple
  #$3C, Light_Teal, #$28, Teal, #$14, Dark_Teal
  #$FF, White, #$00, Black

OBJ
  vga        : "VGA64_PixEngine"'"VGA_640x240_Bitmap"'"vga_pixel"'
  keyb       : "bel-keyb"
  fl         : "float32-Bas"'"fme"
  gc         : "glob-con"

VAR
  long	params[6]
  long  keycode                                                                                          'letzter tastencode
  long  plen, base                                                                                       'länge datenblock loader
  'long  sync, pixels[tiles32]
  'word  colors[tiles]
  long  x_pos,y_pos

  byte proghdr[16]                                                                                       'puffer für objektkopf
  byte vordergrund,hintergrund
  byte cursor,cback[64],putback[64],x_old,y_old

CON ''------------------------------------------------- BELLATRIX

PUB main | zeichen,a,b,c                             'chip: kommandointerpreter
''funktionsgruppe               : chip
''funktion                      : kommandointerpreter
''eingabe                       : -
''ausgabe                       : -

  init_subsysteme                                                                                        'bus/vga/keyboard/maus initialisieren

  repeat

    zeichen := bus_getchar                                                                               '1. zeichen empfangen
    if zeichen                                                                                           ' > 0

          chr(zeichen)
    else
      zeichen := bus_getchar                                                                             '2. zeichen kommando empfangen
      case zeichen
        gc#BEL_KEY_STAT         : key_stat                                                                                      '1: Tastaturstatus senden
        gc#BEL_KEY_CODE         : key_code                                                                                      '2: Tastaturzeichen senden
        gc#BEL_DPL_SETY         : cursor_rest
                                  y_pos:=bus_getchar*8
        gc#BEL_KEY_SPEC         : key_spec                                                                                      '4: Statustasten ($100..$1FF) abfragen
        gc#BEL_SCR_CHAR         : qchar(bus_getchar)                                                                            'char ohne Steuerzeichen
        gc#BEL_KEY_INKEY        : bus_putchar(keyb.taster)
                                  keyb.clearkeys
        gc#BEL_DPL_SETX         : cursor_rest
                                  x_pos:=bus_getchar*8                                                                             '8: x-position setzen
        gc#BEL_CLS              : vga.CLS(hintergrund)
                                  vga.plotbox(hintergrund,0,0,159,119)
        gc#BEL_CLEARKEY         : keyb.clearkeys                                                                                'tastaturpuffer loeschen
        gc#BEL_GETLINELEN       : bus_putchar(linelen)                                                                          '16 Zeilenlänge in diesem Treiber
        gc#BEL_CURSORRATE       : cursor:=bus_getchar & 1                                                                       'Cursor On/Off
        gc#BEL_BOXCOLOR         : a:=bus_getchar
                                  vordergrund:=bus_getchar                                                                     'Vorder-und Hintergrundfarbe
                                  hintergrund:=bus_getchar
                                 'wordfill(@colors,vordergrund << 8 | hintergrund,tiles)
        gc#BEL_SCROLLUP         : vga.scrollup(bus_getchar,bus_getchar,hintergrund)
        gc#BEL_SCROLLDOWN       : vga.scrolldown(bus_getchar,bus_getchar,hintergrund)
        gc#BEL_REDEFINE         : redefine
        gc#BEL_DPL_SETPOS       : locate(bus_getchar,bus_getchar)                                                              'Locate
        gc#BEL_TESTXY           : a:=ptest(bus_getword,bus_getword)
                                  bus_putchar(a)                                                                               'PTest, testet, ob ein Pixel gesetzt ist
        gc#BEL_GETX             : bus_putchar(x_pos/8)                                                                                          'Cursor-X-Position abfragen
        gc#BEL_GETY             : bus_putchar(y_pos/8)                                                                                          'Cursor-Y-Position abfragen
        gc#BEL_DPL_LINE         : line(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar,bus_getchar)                            'line
        gc#BEL_DPL_PIXEL        : Plot(bus_getword,bus_getword,bus_getchar)                                                    'Plot
        gc#BEL_DPL_CIRCLE       : circle(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar,bus_getchar)                          'Kreis
        gc#BEL_RECT             : rect(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar,bus_getchar)                             'Rect
        gc#BEL_DPL_PALETTE      : Displaypalette'bus_getchar                                                                                  'Displaypalette existiert nicht ->dummy-bytes
                                  'bus_getchar
        gc#BEL_VGAPUT           : putchar(bus_getchar,bus_getchar,bus_getchar)
        gc#BEL_DISPLAYPOINT     : a:=bus_getword
                                  b:=bus_getword
                                  c:=a+b*160
                                  bus_putchar(vga.displaypoint(c))
        gc#BEL_POINTDISPLAY     : a:=bus_getword
                                  b:=bus_getchar
                                  vga.pointdisplay(a,b)
        gc#BEL_SEND_BLOCK        : a:=bus_getword
                                  BMP_SHOW(a)
        'gc#BEL_WRITE_RAM        : a:=bus_getchar
        '                          VGA.RAMW(a)

        'gc#BEL_READ_RAM         : a:=bus_getchar
        '                          VGA.RAMR(a)


'       ----------------------------------------------  CHIP-MANAGMENT
'        gc#BMGR_FLASHLOAD       : Flash_loader
        gc#BMGR_GETCOGS         : mgr_getcogs                                                                                   'freie cogs abfragen
        gc#BMGR_LOAD            : mgr_load                                                                                      'neuen bellatrix-code laden
        gc#BMGR_GETVER          : mgr_bel                                                                                       'Rückgabe Grafiktreiber 64
        gc#BMGR_REBOOT          : reboot                                                                                        'bellatrix neu starten

{
            1: key_stat                                                                                      '1: Tastaturstatus senden
            2: key_code                                                                                      '2: Tastaturzeichen senden
            3: cursor_rest
               y_pos:=bus_getchar*8
            4: key_spec                                                                                      '4: Statustasten ($100..$1FF) abfragen
            6: qchar(bus_getchar)                                                                            'char ohne Steuerzeichen
            7: bus_putchar(keyb.taster)
               keyb.clearkeys
            8: cursor_rest
               x_pos:=bus_getchar*8                                                                             '8: x-position setzen
           12: vga.CLS(hintergrund)
               vga.plotbox(hintergrund,0,0,159,119)
           13: keyb.clearkeys                                                                                'tastaturpuffer loeschen
           16: bus_putchar(linelen)                                                                          '16 Zeilenlänge in diesem Treiber
           17: cursor:=bus_getchar & 1                                                                       'Cursor On/Off
           18: a:=bus_getchar
               vordergrund:=bus_getchar                                                                     'Vorder-und Hintergrundfarbe
               hintergrund:=bus_getchar
              'wordfill(@colors,vordergrund << 8 | hintergrund,tiles)
           20: vga.scrollup(bus_getchar,bus_getchar,hintergrund)
           21: vga.scrolldown(bus_getchar,bus_getchar,hintergrund)
           25: redefine
           31: locate(bus_getchar,bus_getchar)                                                              'Locate
           32: a:=ptest(bus_getword,bus_getword)
               bus_putchar(a)                                                                               'PTest, testet, ob ein Pixel gesetzt ist
           37: bus_putchar(x_pos/8)                                                                                          'Cursor-X-Position abfragen
           38: bus_putchar(y_pos/8)                                                                                          'Cursor-Y-Position abfragen
           39: line(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar,bus_getchar)                            'line
           40: Plot(bus_getword,bus_getword,bus_getchar)                                                    'Plot
           41: circle(sub_getword,sub_getword,sub_getword,sub_getword,bus_getchar,bus_getchar)                          'Kreis
           42: rect(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar,bus_getchar)                             'Rect
           54: bus_getchar                                                                                  'Displaypalette existiert nicht ->dummy-bytes
               bus_getchar
           63: putchar(bus_getchar,bus_getchar,bus_getchar)
          '64: bmp_load'(bus_getchar,bus_getchar,bus_getchar,bus_getchar)
          '65: bmp_save
           66: a:=bus_getword
               b:=bus_getword
               c:=a+b*160
               bus_putchar(vga.displaypoint(c))
           67: a:=bus_getword
               b:=bus_getchar
               vga.pointdisplay(a,b)
           68: a:=bus_getword
               BMP_SHOW(a)
'       ----------------------------------------------  CHIP-MANAGMENT
           96: mgr_getcogs                                                                                   'freie cogs abfragen
           87: mgr_load                                                                                      'neuen bellatrix-code laden
           98: mgr_bel                                                                                       'Rückgabe Grafiktreiber 64
           99: reboot                                                                                        'bellatrix neu starten
}

PUB init_subsysteme|i',x,y,tn,tmp                                   'chip: initialisierung des bellatrix-chips
''funktionsgruppe               : chip
''funktion                      : - initialisierung des businterface
''                              : - vga & keyboard-treiber starten
''eingabe                       : -
''ausgabe                       : -
  repeat i from 0 to 7                                                                                   'evtl. noch laufende cogs stoppen
      ifnot i == cogid
            cogstop(i)


  dira := db_in                                                                                          'datenbus auf eingabe schalten
'  outa[24]:=0
'  outa[22.20]:=%111
  outa[bus_hs] := 1                                                                                      'handshake inaktiv

  keyb.start(keyb_dport,keyb_cport)                                                                      'tastaturport starten
  waitcnt(clkfreq/5 + cnt)

  vga.PIXEngineStart(1)

  vordergrund:=orange
  hintergrund:=black
  vga.cls(hintergrund)
  vga.plotbox(hintergrund,0,0,159,119)
  plot(0,0,1)
  waitcnt(clkfreq+cnt)
  fl.start
  bytefill(@cback,hintergrund,64)
  cursor:=1
  bus_putchar(88)

PUB bus_putchar(zeichen)                                'chip: ein byte an regnatix senden
''funktionsgruppe               : chip
''funktion                      : ein byte an regnatix senden
''eingabe                       : byte
''ausgabe                       : -

  waitpeq(M1,M2,0)                                      'busclk=1? & prop2=0?
  dira := db_out                                        'datenbus auf ausgabe stellen
  outa[7..0] := zeichen                                 'daten ausgeben
  outa[bus_hs] := 0                                     'daten gültig
  waitpeq(M3,M4,0)                                      'busclk=0?
  dira := db_in                                         'bus freigeben
  outa[bus_hs] := 1                                     'daten ungültig

PUB bus_getchar : zeichen                               'chip: ein byte von regnatix empfangen
''funktionsgruppe               : chip
''funktion                      : ein byte von regnatix empfangen
''eingabe                       : -
''ausgabe                       : byte
   'outa[hbeat]~~
   waitpeq(M1,M2,0)                                     'busclk=1? & prop2=0?fhjgfjhgf
   zeichen := ina[7..0]                                 'daten einlesen
   outa[bus_hs] := 0                                    'daten quittieren
   waitpeq(M3,M4,0)                                     'busclk=0?
   outa[bus_hs] := 1
   'outa[hbeat]~
PUB bus_getword:wert                                    'sub: long empfangen
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 32bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2][get.byte3][get.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

  wert := bus_getchar << 8
  wert := wert + bus_getchar
con'--------------------------------------------------- VGA-Funktionen -----------------------------------------------------------------------------------------------------------
PUB plot(x,y,s) | i

  if x => 0 and x < 160 and y => 0 and y < 120
    if s
       vga.plotPixel(s, x, y)                           'set
    else
       vga.plotPixel(hintergrund, x, y)                 'unset

pub ptest(x,y)|b
  result:=1
  b:=x+(y*160)
  if x => 0 and x < 160 and y => 0 and y < 120
     if vga.displaypoint(b)==hintergrund | $3        'get
        result:=0
pub BMP_SHOW(count)|i
    i:=0
    repeat count
           vga.pointdisplay(i++,bus_getchar)

{PUB BMP_Load|i,n
    i:=0
    repeat 4800
         n:=sub_getlong
         vga.displaylong(i++,n)
}
{PUB BMP_SAVE|i
    i:=0
    repeat 4800
         sub_putlong(vga.readdisplaylong(i++))
}
PUB putchar(character,x,y)| x1,y1,c,i'' 12 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Draws a character on screen starting at the specified coordinace from the internal character rom.                        │
'' │                                                                                                                          │
'' │ This function is very slow at drawing onscreen. It is here to show only how to do so.                                    │
'' │                                                                                                                          │
'' │ Characters are ploted with %%0 pixels for their background and %%1 pixels for their foreground.                          │
'' │                                                                                                                          │
'' │ Character - The character to display on screen from the internal rom. There are 256 characters avialable.                │
'' │ XPixel    - The X cartesian pixel coordinate to start drawing at, will stop when drawing off screen, same for Y.         │
'' │ YPixel    - The Y cartesian pixel coordinate. Note that this axis is inverted like on all other graphics drivers.        │
'' │ XScaling  - Scales the character pixel image horizontally to increase the size of the character. Between 0 and 3.        │
'' │ YScaling  - Scales the character pixel image vertically to increase the size of the character. Between 0 and 3.          │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


  i:=character*8
'  c:=font[i]
  x*=8
  x1:=x
  y*=8
  repeat 8
       c:=font[i++]><8
       repeat 8

            vga.plotPixel(hintergrund,x,y)
            if c & $80
               vga.plotPixel(vordergrund,x,y)
            c:=c<<1
            x++
       y++
       x:=x1

pub fill(x,y,yy,f)|i,a,b,c,d
    a:=x
    b:=x+1
    c:=0
    repeat i from y to yy
       repeat while (not c or not d)
          ifnot ptest(a,i)
                plot(a,i,f)
                a:=a-1
          else
              c:=1
          ifnot ptest(b,i)
                plot(b,i,f)
                b:=b+1
          else
              d:=1
       d:=c:=0
       a:=x
       b:=x+1

pub locate(y,x)
    cursor_rest
    x_pos:=x*8
    y_pos:=y*8
    scan_limit
    Show_Cursor

PUB line(x0, y0, x1, y1,n,dummy) | dX, dY, x, y, err, stp
  result := ((||(y1 - y0)) > (||(x1 - x0)))
  if(result)
    swap(@x0, @y0)
    swap(@x1, @y1)
  if(x0 > x1)
    swap(@x0, @x1)
    swap(@y0, @y1)
  dX := (x1 - x0)
  dY := (||(y1 - y0))
  err := (dX >> 1)
  stp := ((y0 => y1) | 1)
  y := y0
  repeat x from x0 to x1
    if(result)
      plot(y, x,n)
    else
      plot(x, y,n)
    err -= dY
    if(err < 0)
      y += stp
      err += dX

PRI swap(x, y)
  result  := long[x]
  long[x] := long[y]
  long[y] := result

PUB circle(x,y,r,r2,set,fil)|i,xp,yp,rp,a,b,c,d,hd
    d:=630 '(2*pi*100)
    hd:=fl.ffloat(100)
    xp:=x
    yp:=y
    rp:=r2
    x:=fl.ffloat(x)
    y:=fl.ffloat(y)
    r:=fl.ffloat(r)
    r2:=fl.ffloat(r2)

    repeat i from 0 to d 'step 2
          c:=fl.fdiv(fl.ffloat(i),hd)
          a:=fl.fadd(x,fl.fmul(fl.cos(c),r))
          b:=fl.fadd(y,fl.fmul(fl.sin(c),r2))
          Plot(fl.FRound(a),fl.FRound(b),set)
    if fil
       fill(xp,(yp+1)-rp,(yp+rp)-1,set)

PUB rect(x0, y0, x1, y1,n,fil)

    line(x0, y0, x1, y0,n,0)
    line(x0, y0, x0, y1,n,0)
    line(x0, y1, x1, y1,n,0)
    line(x1, y0, x1, y1,n,0)
    if fil
       vga.plotBox(n, x0, y0, x1, y1)'fill(x0,y0,y1-1,n)

pub qchar(c)
    put(c,vordergrund)   'qChar
    x_pos+=8
    scan_limit
pub cursor_rest
    if cursor
       charbackup(0,0)                 'zeichen unter dem Cursor wiederherstellen
PUB put(character,col)| x,y,c,i,d'' 12 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Draws a character on screen starting at the specified coordinace from the internal character rom.                        │
'' │                                                                                                                          │
'' │ This function is very slow at drawing onscreen. It is here to show only how to do so.                                    │
'' │                                                                                                                          │
'' │ Characters are ploted with %%0 pixels for their background and %%1 pixels for their foreground.                          │
'' │                                                                                                                          │
'' │ Character - The character to display on screen from the internal rom. There are 256 characters avialable.                │
'' │ XPixel    - The X cartesian pixel coordinate to start drawing at, will stop when drawing off screen, same for Y.         │
'' │ YPixel    - The Y cartesian pixel coordinate. Note that this axis is inverted like on all other graphics drivers.        │
'' │ XScaling  - Scales the character pixel image horizontally to increase the size of the character. Between 0 and 3.        │
'' │ YScaling  - Scales the character pixel image vertically to increase the size of the character. Between 0 and 3.          │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


  i:=character*8
  x:=x_pos
  y:=y_pos
  'c:=font[i]

  repeat 8
       c:=font[i++]><8
       repeat 8

            vga.plotPixel(hintergrund,x,y)
            if c & $80
                vga.plotPixel(col,x,y)
            c:=c<<1
            x++
       y++
       x:=x_pos
  x_pos+=8

pub settab(n)|v,ccol
    n/=8
    case n
         0..4:v:=4
         5..9:v:=9
         10..14:v:=14
    x_pos:=v*8
PUB chr(ch)|x,y,g
    Cursor_rest
    case ch
        2:charbackup(1,1)
        5:x_pos -=8
        6:x_pos +=8
        '4:y_pos++              'wird nicht benutzt
        '5:y_pos--              'wird nicht benutzt
        7:x_pos:=0              'Home
          y_pos:=0
        8:x_pos-=8            'Backspace
          if x_pos<1
             x_pos:=0
          put(32,vordergrund)
        9:x_pos += (8 - ((x_pos/8) & $7))        'Tab
        10:
        12:vga.cls(hintergrund)                  'CLS
           vga.plotbox(hintergrund,0,0,159,119)
           x_pos:=y_pos:=0
        13:Cursor_rest
           y_pos+=8              'Return
           x_pos:=0
           charbackup(1,0)
        other:put(ch,vordergrund)'x_pos,y_pos)   'Char
              'x_pos++
    scan_limit

pub scan_limit
    if x_pos<0
       x_pos:=152
       y_pos-=8
    if x_pos>152
       x_pos:=0
       y_pos+=8
    if y_pos>115
       vga.scrollup(1,0,hintergrund)
       y_pos:=112
    if y_pos<0
       y_pos:=0
    show_cursor

pub show_cursor
    if cursor
       charbackup(1,0)
       put(127,vordergrund)
       x_pos-=8

pub charbackup(n,x)|i,b,a
    b := x_pos + x + (y_pos * 160)
    i:=0
    a:=0
  repeat 8
    repeat a from 0 to 7
       if n
          cback[i++] := vga.displaypoint(b+a)                'backup
       else
          vga.pointdisplay(b+a,cback[i++])                   'restore
    b += 160


pub redefine|n,c
    c:=bus_getchar
    c*=8
    repeat 8
        font[c++]:=bus_getchar

pub Displaypalette|farbe,hy,hx,a
    hx:=bus_getchar
    hy:=bus_getchar
    a:=hx
    farbe:=0
    repeat 4
        repeat 16
             locate(hy,hx)
             put(127,farbe)
             hx++
             farbe+=4
        hx:=a
        hy++
CON ''------------------------------------------------- SUBPROTOKOLL-FUNKTIONEN

PUB sub_putlong(wert)                                   'sub: long senden       
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert an regnatix zu senden
''eingabe                       : 32bit wert der gesendet werden soll
''ausgabe                       : -
''busprotokoll                  : [put.byte1][put.byte2][put.byte3][put.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

   bus_putchar(wert >> 24)                              '32bit wert senden hsb/lsb
   bus_putchar(wert >> 16)
   bus_putchar(wert >> 8)
   bus_putchar(wert)

PUB sub_getlong:wert                                    'sub: long empfangen    
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 32bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2][get.byte3][get.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

  wert :=        bus_getchar << 24                      '32 bit empfangen hsb/lsb
  wert := wert + bus_getchar << 16
  wert := wert + bus_getchar << 8
  wert := wert + bus_getchar

PUB sub_putword(wert)                                   'sub: long senden
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert an regnatix zu senden
''eingabe                       : 32bit wert der gesendet werden soll
''ausgabe                       : -
''busprotokoll                  : [put.byte1][put.byte2][put.byte3][put.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

   bus_putchar(wert >> 8)
   bus_putchar(wert)

PUB sub_getword:wert                                    'sub: long empfangen
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 32bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2][get.byte3][get.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

  wert := bus_getchar << 8
  wert := wert + bus_getchar

CON ''------------------------------------------------- CHIP-MANAGMENT-FUNKTIONEN

pub mgr_bel
    sub_putlong(Bel_Treiber_Ver)                                                                         'rückgabe 65 für tile-driver 64 farben stark geänderte Version

PUB mgr_getcogs: cogs |i,c,cog[8]                                                                        'cmgr: abfragen wie viele cogs in benutzung sind
''funktionsgruppe               : cmgr
''funktion                      : abfrage wie viele cogs in benutzung sind
''eingabe                       : -
''ausgabe                       : cogs - anzahl der cogs
''busprotokoll                  : [0][096][put.cogs]
''                              : cogs - anzahl der belegten cogs

  cogs := i := 0
  repeat                                                                                                 'loads as many cogs as possible and stores their cog numbers
    c := cog[i] := cognew(@entry, 0)
    if c=>0
      i++
  while c => 0
  cogs := i
  repeat                                                                                                 'unloads the cogs and updates the string
    i--
    if i=>0
      cogstop(cog[i])
  while i=>0
  bus_putchar(cogs)

PUB mgr_load|i                                          'cmgr: bellatrix-loader
''funktionsgruppe               : cmgr
''funktion                      : funktion um einen neuen code in bellatrix zu laden
''
''bekanntes problem: einige wenige bel-dateien werden geladen aber nicht korrekt gestartet
''lösung: diese datei als eeprom-image speichern

' kopf der bin-datei einlesen                           ------------------------------------------------------
  repeat i from 0 to 15                                                                                  '16 bytes --> proghdr
    byte[@proghdr][i] := bus_getchar

  plen := 0
  plen :=        byte[@proghdr + $0B] << 8
  plen := plen + byte[@proghdr + $0A]
  plen := plen - 8

' objektlänge an regnatix senden
  bus_putchar(plen >> 8)                                                                                 'hsb senden
  bus_putchar(plen & $FF)                                                                                'lsb senden

  repeat i from 0 to 7                                                                                   'alle anderen cogs anhalten
    ifnot i == cogid
      cogstop(i)

  dira := 0                                                                                              'diese cog vom bus trennen
  cognew(@loader, plen)

  cogstop(cogid)                                                                                         'cog 0 anhalten

DAT
                        org     0

loader
                        mov     outa,    M_0               'bus inaktiv
                        mov     dira,    DINP              'bus auf eingabe schalten
                        mov     reg_a,   PAR               'parameter = plen
                        mov     reg_b,   #0                'adresse ab 0

                        ' datenblock empfangen
loop
                        call    #get                       'wert einlesen
                        wrbyte  in,      reg_b             'wert --> hubram
                        add     reg_b,   #1                'adresse + 1
                        djnz    reg_a,   #loop

                        ' neuen code starten

                        rdword  reg_a,   #$A               ' Setup the stack markers.
                        sub     reg_a,   #4                '
                        wrlong  SMARK,   reg_a             '
                        sub     reg_a,   #4                '
                        wrlong  SMARK,   reg_a             '

                        rdbyte  reg_a,   #$4               ' Switch to new clock mode.
                        clkset  reg_a                                             '

                        coginit SINT                       ' Restart running new code.


                        cogid   reg_a
                        cogstop reg_a                      'cog hält sich selbst an


get
                        waitpeq M_1,      M_2              'busclk=1? & /cs=0?
                        mov     in,       ina              'daten einlesen
                        and     in,       DMASK            'wert maskieren
                        mov     outa,     M_3              'hs=0
                        waitpeq M_3,      M_4              'busclk=0?
                        mov     outa,     M_0              'hs=1
get_ret                 ret


'     hbeat   --------+
'     clk     -------+|
'     /wr     ------+||
'     /hs     -----+|||+------------------------- /cs
'                  |||||                 -------- d0..d7
DINP    long  %00001000000000000000000000000000  'constant dinp hex  \ bus input
DOUT    long  %00001000000000000000000011111111  'constant dout hex  \ bus output

M_0     long  %00001000000000000000000000000000  'bus inaktiv

M_1     long  %00000010000000000000000000000000
M_2     long  %00000010100000000000000000000000  'busclk=1? & /cs=0?

M_3     long  %00000000000000000000000000000000
M_4     long  %00000010000000000000000000000000  'busclk=0?


DMASK   long  %00000000000000000000000011111111  'datenmaske

SINT    long    ($0001 << 18) | ($3C01 << 4)                       ' Spin interpreter boot information.
SMARK   long    $FFF9FFFF                                          ' Stack mark used for spin code.

in      res   1
reg_a   res   1
reg_b   res   1



CON ''------------------------------------------------- KEYBOARD-FUNKTIONEN

PUB key_stat                                                                                             'key: tastaturstatus abfragen

  bus_putchar(keyb.gotkey)

PUB key_code                                                                                             'key: tastencode abfragen

  keycode := keyb.key
  case keycode
    $c8: keycode := $08                                                                                  'backspace wandeln
  bus_putchar(keycode)

PUB key_spec                                                                                             'key: statustaten vom letzten tastencode abfragen

  bus_putchar(keycode >> 8)

DAT


                        org
'
' Entry: dummy-assemblercode fuer cogtest
'
entry                   jmp     entry                   'just loops

font byte $03,$04,$02,$01,$07,$00,$00,$00       ' 2  0
     byte $0C,$08,$0B,$08,$00,$00,$00,$00       ' -1 1
     byte $03,$04,$02,$04,$03,$00,$00,$00       '3 2

     byte $18,$7C,$36,$7C,$D8,$D8,$7E,$18       '$ 3
     byte $00,$63,$33,$18,$0C,$66,$63,$00       '% 4
     byte $1C,$36,$1C,$6E,$3B,$33,$6E,$00       '& 5
     byte $38,$30,$18,$00,$00,$00,$00,$00       ' ' 6
     byte $18,$0C,$06,$06,$06,$0C,$18,$00       '( 7
     byte $06,$0C,$18,$18,$18,$0C,$06,$00       ') 8
     byte $00,$66,$3C,$FF,$3C,$66,$00,$00       '* 9
     byte $00,$0C,$0C,$3F,$0C,$0C,$00,$00       '+ 10
     byte $00,$00,$00,$00,$00,$38,$30,$18       ', 11
     byte $00,$00,$00,$7F,$00,$00,$00,$00       '- 12
     byte $00,$00,$00,$00,$00,$0C,$0C,$00       '. 13
     byte $60,$30,$18,$0C,$06,$03,$01,$00       '/ 14
     byte $3C,$7E,$FF,$FF,$FF,$FF,$7E,$3C       '• 15

     byte $00,$00,$08,$14,$22,$41,$7F,$00       'Δ 16
     byte $00,$00,$3E,$14,$14,$14,$16,$00       'π 17
     byte $3F,$21,$02,$04,$02,$21,$3F,$00       'Σ 18
     byte $00,$3E,$63,$63,$36,$36,$77,$00       'Ω 19

     byte $3F,$03,$1F,$30,$30,$33,$1E,$00       '5 20

     byte $70,$10,$10,$16,$14,$1C,$18,$00       '√ 21

     byte $3F,$33,$30,$18,$0C,$0C,$0C,$00       '7 22
     byte $1E,$33,$33,$1E,$33,$33,$1E,$00       '8 23
     byte $1E,$33,$33,$3E,$30,$18,$0E,$00       '9 24
     byte $00,$00,$0C,$0C,$00,$0C,$0C,$00       ': 25
     byte $00,$00,$0C,$0C,$00,$0C,$0C,$06       '; 26
     byte $18,$0C,$06,$03,$06,$0C,$18,$00       '< 27
     byte $00,$00,$3F,$00,$3F,$00,$00,$00       '= 28
     byte $06,$0C,$18,$30,$18,$0C,$06,$00       '> 29
     byte $1E,$33,$30,$18,$0C,$00,$0C,$00       '? 30
     byte $3E,$63,$7B,$7B,$7B,$03,$1E,$00       '@ 31

     byte $00,$00,$00,$00,$00,$00,$00,$00       'Space  32
     byte $0C,$0C,$0C,$0C,$0C,$00,$0C,$00       '!      33
     byte $EE,$CC,$66,$00,$00,$00,$00,$00       ' "     34
     byte $6C,$6C,$7F,$36,$7F,$1B,$1B,$00       '# 35
     byte $18,$7C,$36,$7C,$D8,$D8,$7E,$18       '$ 36
     byte $00,$63,$33,$18,$0C,$66,$63,$00       '% 37
     byte $1C,$36,$1C,$6E,$3B,$33,$6E,$00       '& 38
     byte $38,$30,$18,$00,$00,$00,$00,$00       ' ' 39
     byte $18,$0C,$06,$06,$06,$0C,$18,$00       '( 40
     byte $06,$0C,$18,$18,$18,$0C,$06,$00       ') 41
     byte $00,$66,$3C,$FF,$3C,$66,$00,$00       '* 42
     byte $00,$0C,$0C,$3F,$0C,$0C,$00,$00       '+ 43
     byte $00,$00,$00,$00,$00,$38,$30,$18       ', 44
     byte $00,$00,$00,$7F,$00,$00,$00,$00       '- 45
     byte $00,$00,$00,$00,$00,$0C,$0C,$00       '. 46
     byte $60,$30,$18,$0C,$06,$03,$01,$00       '/ 47
     byte $3E,$63,$73,$7B,$6F,$67,$3E,$00       '0 48
     byte $0C,$0E,$0C,$0C,$0C,$0C,$3F,$00       '1 49
     byte $1E,$33,$30,$1C,$06,$33,$3F,$00       '2 50
     byte $3F,$18,$0C,$1E,$30,$33,$1E,$00       '3 51
     byte $38,$3C,$36,$33,$7F,$30,$78,$00       '4 52
     byte $3F,$03,$1F,$30,$30,$33,$1E,$00       '5 53
     byte $1C,$06,$03,$1F,$33,$33,$1E,$00       '6 54
     byte $3F,$33,$30,$18,$0C,$0C,$0C,$00       '7 55
     byte $1E,$33,$33,$1E,$33,$33,$1E,$00       '8 56
     byte $1E,$33,$33,$3E,$30,$18,$0E,$00       '9 57
     byte $00,$00,$0C,$0C,$00,$0C,$0C,$00       ': 58
     byte $00,$00,$0C,$0C,$00,$0C,$0C,$06       '; 59
     byte $18,$0C,$06,$03,$06,$0C,$18,$00       '< 60
     byte $00,$00,$3F,$00,$3F,$00,$00,$00       '= 61
     byte $06,$0C,$18,$30,$18,$0C,$06,$00       '> 62
     byte $1E,$33,$30,$18,$0C,$00,$0C,$00       '? 63
     byte $3E,$63,$7B,$7B,$7B,$03,$1E,$00       '@ 64
     byte $0C,$1E,$33,$33,$3F,$33,$33,$00       'A 65
     byte $3F,$66,$66,$3E,$66,$66,$3F,$00       'B 66
     byte $3C,$66,$03,$03,$03,$66,$3C,$00       'C 67
     byte $1F,$36,$66,$66,$66,$36,$1F,$00       'D 68
     byte $7F,$46,$16,$1E,$16,$46,$7F,$00       'E 69
     byte $7F,$46,$16,$1E,$16,$06,$0F,$00       'F 70
     byte $3C,$66,$03,$03,$73,$66,$3C,$00       'G 71
     byte $33,$33,$33,$3F,$33,$33,$33,$00       'H 72
     byte $1E,$0C,$0C,$0C,$0C,$0C,$1E,$00       'I 73
     byte $78,$30,$30,$30,$33,$33,$1E,$00       'J 74
     byte $67,$66,$36,$0E,$36,$66,$67,$00       'K 75
     byte $0F,$06,$06,$06,$46,$66,$7F,$00       'L 76
     byte $63,$77,$7F,$6B,$63,$63,$63,$00       'M 77
     byte $63,$67,$6F,$7B,$73,$63,$63,$00       'N 78
     byte $1C,$36,$63,$63,$63,$36,$1C,$00       'O 79
     byte $3F,$66,$66,$3E,$06,$06,$0F,$00       'P 80
     byte $1E,$33,$33,$33,$33,$3B,$1E,$38       'Q 81
     byte $3F,$66,$66,$3E,$36,$66,$67,$00       'R 82
     byte $3E,$63,$0F,$3C,$70,$63,$3E,$00       'S 83
     byte $3F,$2D,$0C,$0C,$0C,$0C,$1E,$00       'T 84
     byte $33,$33,$33,$33,$33,$33,$1E,$00       'U 85
     byte $33,$33,$33,$1E,$1E,$0C,$0C,$00       'V 86
     byte $63,$63,$63,$6B,$7F,$77,$63,$00       'W 87
     byte $63,$63,$36,$1C,$36,$63,$63,$00       'X 88
     byte $33,$33,$33,$1E,$0C,$0C,$1E,$00       'Y 89
     byte $7F,$63,$31,$18,$4C,$66,$7F,$00       'Z 90
     byte $3C,$0C,$0C,$0C,$0C,$0C,$3C,$00       '[ 91
     byte $18,$18,$18,$18,$18,$18,$18,$00       '| 92
     byte $3C,$30,$30,$30,$30,$30,$3C,$00       '] 93
     byte $08,$1C,$36,$63,$00,$00,$00,$00       '^ 94
     byte $00,$00,$00,$00,$00,$00,$00,$FF       '_ 95
     byte $18,$18,$18,$18,$18,$18,$18,$18       '96    (162)
     byte $00,$00,$1E,$30,$3E,$33,$6E,$00       'a 97
     byte $07,$06,$3E,$66,$66,$66,$3B,$00       'b 98
     byte $00,$00,$1E,$33,$03,$33,$1E,$00       'c 99
     byte $38,$30,$3E,$33,$33,$33,$6E,$00       'd 100
     byte $00,$00,$1E,$33,$3F,$03,$1E,$00       'e 101
     byte $1C,$36,$06,$0F,$06,$06,$0F,$00       'f 102
     byte $00,$00,$6E,$33,$33,$3E,$30,$1F       'g 103
     byte $07,$06,$36,$6E,$66,$66,$67,$00       'h 104
     byte $0C,$00,$0E,$0C,$0C,$0C,$3F,$00       'i 105
     byte $30,$00,$38,$30,$30,$33,$33,$1E       'j 106
     byte $07,$66,$36,$1E,$16,$36,$67,$00       'k 107
     byte $0E,$0C,$0C,$0C,$0C,$0C,$3F,$00       'l 108
     byte $00,$00,$33,$7F,$7F,$6B,$63,$00       'm 109
     byte $00,$00,$1F,$33,$33,$33,$33,$00       'n 110
     byte $00,$00,$1E,$33,$33,$33,$1E,$00       'o 111
     byte $00,$00,$3B,$66,$66,$3E,$06,$0F       'p 112
     byte $00,$00,$6E,$33,$33,$3E,$30,$78       'q 113
     byte $00,$00,$3B,$6E,$66,$06,$0F,$00       'r 114
     byte $00,$00,$3E,$03,$1E,$30,$1F,$00       's 115
     byte $08,$0C,$3E,$0C,$0C,$2C,$18,$00       't 116
     byte $00,$00,$33,$33,$33,$33,$6E,$00       'u 117
     byte $00,$00,$33,$33,$33,$1E,$0C,$00       'v 118
     byte $00,$00,$63,$6B,$7F,$7F,$36,$00       'w 119
     byte $00,$00,$63,$36,$1C,$36,$63,$00       'x 120
     byte $00,$00,$33,$33,$33,$3E,$30,$1F       'y 121
     byte $00,$00,$3F,$19,$0C,$26,$3F,$00       'z 122
     byte $80,$40,$40,$20,$40,$40,$80,$03       '{123
     byte $10,$10,$10,$10,$10,$10,$10,$00       '|124
     byte $01,$02,$02,$04,$02,$02,$01,$00       '}125
     byte $00,$00,$00,$26,$19,$00,$00,$00       '~126
     byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF       '‣127

'############## Platz für Sonderzeichen KC87 Zeichensatz ######################
     byte $03,$04,$08,$08,$08,$08,$04,$03       '128
     byte $C0,$20,$10,$10,$10,$10,$20,$C0       '129
     byte $81,$81,$42,$3C,$00,$00,$00,$00       '130
     byte $00,$00,$00,$00,$3C,$42,$81,$81       '131
     byte $08,$08,$04,$03,$00,$00,$00,$00       '132
     byte $10,$10,$20,$C0,$00,$00,$00,$00       '133
     byte $00,$00,$00,$00,$C0,$20,$10,$10       '134
     byte $00,$00,$00,$00,$03,$04,$08,$08       '135
     byte $01,$01,$01,$01,$01,$01,$01,$FF       '136
     byte $FF,$80,$80,$80,$80,$80,$80,$80       '137
     byte $00,$08,$14,$22,$41,$22,$14,$08       '138
     byte $FF,$F7,$E3,$C1,$80,$C1,$E3,$F7       '139
     byte $3C,$42,$81,$81,$81,$81,$42,$3C       '140
     byte $C3,$81,$00,$00,$00,$00,$81,$C3       '141
     byte $FF,$7F,$3F,$1F,$0F,$07,$03,$01       '142
     byte $01,$03,$07,$0F,$1F,$3F,$7F,$FF       '143
     byte $80,$40,$20,$10,$08,$04,$02,$01       '144
     byte $01,$02,$04,$08,$10,$20,$40,$80       '145
     byte $00,$00,$00,$00,$C0,$30,$0C,$03       '146
     byte $C0,$30,$0C,$03,$00,$00,$00,$00       '147
     byte $C0,$30,$0C,$03,$03,$0C,$30,$C0       '148
     byte $00,$00,$00,$00,$03,$0C,$30,$C0       '149
     byte $03,$0C,$30,$C0,$00,$00,$00,$00       '150
     byte $03,$0C,$30,$C0,$C0,$30,$0C,$03       '151
     byte $08,$08,$04,$04,$02,$02,$01,$01       '152
     byte $80,$80,$40,$40,$20,$20,$10,$10       '153
     byte $81,$81,$42,$42,$24,$24,$18,$18       '154
     byte $01,$01,$02,$02,$04,$04,$08,$08       '155
     byte $10,$10,$20,$20,$40,$40,$80,$80       '156
     byte $18,$18,$24,$24,$42,$42,$81,$81       '157
     byte $FF,$00,$00,$00,$00,$00,$00,$00       '158
     byte $01,$01,$01,$01,$01,$01,$01,$01       '159
     byte $00,$00,$00,$FF,$FF,$00,$00,$00       '160
     byte $00,$00,$00,$00,$00,$00,$00,$00       'Cursor leer 161
'     byte $18,$18,$18,$18,$18,$18,$18,$18       '162
     byte $18,$18,$18,$FF,$FF,$00,$00,$00       '162
     byte $18,$18,$18,$F8,$F8,$18,$18,$18       '163
     byte $00,$00,$00,$FF,$FF,$18,$18,$18       '164
     byte $18,$18,$18,$1F,$1F,$18,$18,$18       '165
     byte $18,$18,$18,$FF,$FF,$18,$18,$18       '166
     byte $18,$18,$18,$F8,$F8,$00,$00,$00       '167
     byte $00,$00,$00,$F8,$F8,$18,$18,$18       '168
     byte $00,$00,$00,$1F,$1F,$18,$18,$18       '169
     byte $18,$18,$18,$1F,$1F,$00,$00,$00       '170
     byte $01,$01,$01,$02,$02,$04,$18,$E0       '171
     byte $80,$80,$80,$40,$40,$20,$18,$07       '172
     byte $07,$18,$20,$40,$40,$80,$80,$80       '173
     byte $E0,$18,$04,$02,$02,$01,$01,$01       '174
     byte $81,$42,$24,$18,$18,$24,$42,$81       '175
     byte $0F,$0F,$0F,$0F,$00,$00,$00,$00       '176
     byte $F0,$F0,$F0,$F0,$00,$00,$00,$00       '177
     byte $00,$00,$00,$00,$F0,$F0,$F0,$F0       '178
     byte $00,$00,$00,$00,$0F,$0F,$0F,$0F       '179
     byte $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F       '180
     byte $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0       '181
     byte $FF,$FF,$FF,$FF,$00,$00,$00,$00       '182
     byte $00,$00,$00,$00,$FF,$FF,$FF,$FF       '183
     byte $0F,$0F,$0F,$0F,$F0,$F0,$F0,$F0       '184
     byte $F0,$F0,$F0,$F0,$0F,$0F,$0F,$0F       '185
     byte $F0,$F0,$F0,$F0,$FF,$FF,$FF,$FF       '186
     byte $0F,$0F,$0F,$0F,$FF,$FF,$FF,$FF       '187
     byte $FF,$FF,$FF,$FF,$0F,$0F,$0F,$0F       '188
     byte $FF,$FF,$FF,$FF,$F0,$F0,$F0,$F0       '189
     byte $80,$C0,$E0,$F0,$F8,$FC,$FE,$FF       '190
     byte $FF,$FE,$FC,$F8,$F0,$E0,$C0,$80       '191
     byte $80,$80,$80,$80,$80,$80,$80,$80       '192
     byte $FF,$01,$01,$01,$01,$01,$01,$01       '193
     byte $FF,$01,$01,$39,$39,$39,$01,$01       '194
     byte $FF,$FF,$FF,$E7,$E7,$FF,$FF,$FF       '195
     byte $18,$3C,$7E,$3C,$18,$3C,$7E,$FF       '196
     byte $FF,$00,$FF,$00,$FF,$00,$FF,$00       '197
     byte $55,$55,$55,$55,$55,$55,$55,$55       '198
     byte $55,$AA,$55,$AA,$55,$AA,$55,$AA       '199
     byte $80,$80,$80,$80,$80,$80,$80,$FF       '200
     byte $00,$08,$1C,$3E,$7F,$3E,$1C,$08       '201
     byte $1C,$08,$49,$7F,$49,$08,$1C,$3E       '202
     byte $00,$36,$7F,$7F,$7F,$3E,$1C,$08       '203
     byte $08,$1C,$3E,$7F,$7F,$3E,$08,$3E       '204
     byte $E7,$E7,$42,$FF,$FF,$42,$E7,$E7       '205
     byte $DB,$FF,$DB,$18,$18,$DB,$FF,$DB       '206
     byte $3C,$7E,$FF,$FF,$FF,$FF,$7E,$3C       '207
     byte $03,$03,$00,$00,$00,$00,$00,$00       '208
     byte $0C,$0C,$00,$00,$00,$00,$00,$00       '209
     byte $30,$30,$00,$00,$00,$00,$00,$00       '210
     byte $C0,$C0,$00,$00,$00,$00,$00,$00       '211
     byte $00,$00,$03,$03,$00,$00,$00,$00       '212
     byte $00,$00,$0C,$0C,$00,$00,$00,$00       '213
     byte $00,$00,$30,$30,$00,$00,$00,$00       '214
     byte $00,$00,$C0,$C0,$00,$00,$00,$00       '215
     byte $00,$00,$00,$00,$03,$03,$00,$00       '216
     byte $00,$00,$00,$00,$0C,$0C,$00,$00       '217
     byte $00,$00,$00,$00,$30,$30,$00,$00       '218
     byte $00,$00,$00,$00,$C0,$C0,$00,$00       '219
     byte $00,$00,$00,$00,$00,$00,$03,$03       '220
     byte $00,$00,$00,$00,$00,$00,$0C,$0C       '221
     byte $00,$00,$00,$00,$00,$00,$30,$30       '222
     byte $00,$00,$00,$00,$00,$00,$C0,$C0       '223
     byte $00,$00,$00,$00,$00,$00,$F0,$F0       '224
     byte $00,$00,$00,$00,$00,$00,$FC,$FC       '225
     byte $00,$00,$00,$00,$00,$00,$FF,$FF       '226
     byte $00,$00,$00,$00,$00,$00,$3F,$3F       '227
     byte $00,$00,$00,$00,$00,$00,$0F,$0F       '228
     byte $00,$00,$00,$00,$00,$00,$03,$03       '229
     byte $00,$00,$00,$00,$03,$03,$03,$03       '230
     byte $00,$00,$03,$03,$03,$03,$03,$03       '231
     byte $03,$03,$03,$03,$03,$03,$03,$03       '232
     byte $03,$03,$03,$03,$03,$03,$00,$00       '233
     byte $03,$03,$03,$03,$00,$00,$00,$00       '234
     byte $03,$03,$00,$00,$00,$00,$00,$00       '235
     byte $0F,$0F,$00,$00,$00,$00,$00,$00       '236
     byte $3F,$3F,$00,$00,$00,$00,$00,$00       '237
     byte $FF,$FF,$00,$00,$00,$00,$00,$00       '238
     byte $FC,$FC,$00,$00,$00,$00,$00,$00       '239
     byte $F0,$F0,$00,$00,$00,$00,$00,$00       '240
     byte $C0,$C0,$00,$00,$00,$00,$00,$00       '241
     byte $C0,$C0,$C0,$C0,$00,$00,$00,$00       '242
     byte $C0,$C0,$C0,$C0,$C0,$C0,$00,$00       '243
     byte $C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0       '244
     byte $00,$00,$C0,$C0,$C0,$C0,$C0,$C0       '245
     byte $00,$00,$00,$00,$C0,$C0,$C0,$C0       '246
     byte $00,$00,$00,$00,$00,$00,$C0,$C0       '247
     byte $00,$00,$00,$00,$00,$00,$00,$FF       '248
     byte $00,$00,$00,$00,$00,$00,$FF,$FF       '249
     byte $00,$00,$00,$00,$00,$FF,$FF,$FF       '250
     byte $00,$00,$00,$00,$FF,$FF,$FF,$FF       '251
     byte $00,$00,$00,$FF,$FF,$FF,$FF,$FF       '252
     byte $00,$00,$FF,$FF,$FF,$FF,$FF,$FF       '253
     byte $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF       '254
     byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF       '255



DAT
     
{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
