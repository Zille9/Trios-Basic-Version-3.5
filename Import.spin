con
{{
 ---------------------------------------------------------------------------------------------------------

Hive-Computer-Projekt

Name            : TRIOS-Basic
Chip            : Regnatix-Code
Version         : 2.108
Dateien         :

Beschreibung    : Importmodul für Text-Dateien ->importiert ein, als Textdatei vorliegendes Basic-Programm von SD-Karte in den Speicher

Notes:
01-05-2014      -erste funktionierende Version
                -um die Sache optisch besser zu gestalten, wird noch ein Hinweisfenster mit dem System-Tile-Font erstellt
                -6761 Longs frei

11-05-2014      -Laderoutine durch Sicherheitsabfrage ergänzt, es wird überprüft, ob es sich bei der zu ladenden Datei um eine Textdatei handelt
                -überflüssige Variablen entfernt
                -PI und Wurzelzeichen in der Abfrage gültiger Zeichen hinzugefügt
                -6798 Longs frei
}}
obj
  ios    :"reg-ios-bas"
  gc     :"glob-con"

con
_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000
   version   = 2.108

   fEof      = $FF                     ' dateiende-kennung
   linelen   = 85                      ' Maximum input line length
   quote     = 34                      ' Double quote
   caseBit   = !32                     ' Uppercase/Lowercase bit
   point     = 46                      ' point
   STR_LEN   = 34                      ' Stringlänge von Stringvariablen in Arrays
   FIELD_LEN = 512                     ' Array-Feldgröße (max Feldgröße 8x8x8 -> Dim a(7,7,7)
   DIR_ENTRY = 546                     ' max.Anzahl mit DIR-Befehl gefundener Einträge
   STR_MAX   = 41                      ' maximale Stringlänge für Printausgaben und font
   DPL_CNT   = 1200                    ' Map-und Bildschirm-Shadow-Speicher-Zähler (40Spalten*30Zeilen=1200-Tiles)
'*****************Speicherbereiche**********************************************
   maxstack  = 20                      ' Maximum stack tiefe fuer gosub
   userPtr   = $1FFFF                  ' Ende Programmspeicher  128kb
   TMP_RAM   = $20000 '....$3FFFF      ' Bearbeitungsspeicher   128kb (fuer die Zeileneditierung bzw.Einfuegung von Zeilen)
   TILE_RAM  = $40000 '....$667FF      ' hier beginnt der Tile-Speicher fuer 14 Tiledateien
   SYS_FONT  = $66800 '....$693FF      ' ab hier liegt der System-Font 11kb
   MOUSE_RAM = $69400 '....$6943F      ' User-Mouse-Pointer 64byte
   DIR_RAM   = $69440 '....$6AFFF      ' Puffer fuer Dateinamen 7103Bytes fuer 546 Dateinamen
   VAR_RAM   = $6B000 '....$77FFF      ' Variablen-Speicher fuer Array-Variablen a[0...511]-z[0...511] (13312 moegliche Variablen)
   MAP_RAM   = $78000 '....$79C27      ' Shadow-Display (Pseudo-Kopie des Bildschirmspeichers)
   'FREI_RAM   $79C28 .... $79FFF      ' freier RAM-Bereich 984 Bytes auch für Shadow-Display

   DATA_RAM = $7A000 '.... $7DFFF      ' 16kB DATA-Speicher

   BUTT_RAM = $7E000 '.... $7E4FF      ' ca.1kB Button Puffer
   WTILE_RAM= $7E500 '.... $7E5FF      ' Win-Tile Puffer hier können die Tiles, aus denen die Fenster gebaut werden geändert werden
   FUNC_RAM = $7E600 '.... $7EFFF      ' Funktions-Speicher, hier werden die selbstdefinierten Funktionen gespeichert

   ERROR_RAM = $7F000 '....$7FAFF      ' ERROR-Texte
   DIM_VAR   = $7FB00 '....$7FBFF      ' Variablen-Array-Dimensionstabelle
   DIM_STR   = $7FC00 '....$7FCFF      ' String-Array-Dimensionstabelle
   BACK_RAM  = $7FD00 '....$7FDFF      ' BACKUP RAM-Bereich 256 Bytes für Ladebalken
   'Frei-Ram = $7FE00  ....$7FEFF      ' noch freier Bereich 256 Bytes
   PMARK_RAM = $7FFF0                  ' Flag für Reclaim           Wert= 161
   BMARK_RAM = $7FFF1                  ' Flag für Basic-Warm-Start  Wert= 121
   SMARK_RAM = $7FFF2                  ' Flag für übergebenen Startparameter Wert = 222

   STR_ARRAY = $80000 '....$EE7FF      ' Stringarray-Speicher
   USER_RAM  = $EE800 '....$FFEFF      ' Freier Ram-Bereich, für Anwender, Backup-Funktion usw.

   ADM_SPEC       = gc#A_FAT|gc#A_LDR|gc#A_SID|gc#A_LAN|gc#A_RTC|gc#A_PLX'%00000000_00000000_00000000_11110011
'***************** Button-Anzahl ************************************************
   BUTTON_CNT   = 32                       'Anzahl der möglichen Button
'******************Farben ********************************************************
  #$FC, Light_Grey, #$A8, Grey, #$54, Dark_Grey
  #$C0, Light_Red, #$80, Red, #$40, Dark_Red
  #$30, Light_Green, #$20, Green, #$10, Dark_Green
  #$1F, Light_Blue, #$09, Blue, #$04, Dark_Blue
  #$F0, Light_Orange, #$E6, Orange, #$92, Dark_Orange
  #$CC, Light_Purple, #$88, Purple, #$44, Dark_Purple
  #$3C, Light_Teal, #$28, Teal, #$14, Dark_Teal
  #$FF, White, #$00, Black

'*****************Tastencodes*****************************************************
   ENTF_KEY  = 186
   bspKey    = $C8                     ' PS/2 keyboard backspace key
   breakKey  = $CB                     ' PS/2 keyboard escape key
   fReturn   = 13
   fLinefeed = 10
   KEY_LEFT  = 2
   KEY_RIGHT = 3
   KEY_UP    = 4
   KEY_DOWN  = 5

   MIN_EXP   = -999999
   MAX_EXP   =  999999

var
   long tp, nextlineloc                                                       'Kommandozeile,Zeilenadresse
   long speicheranfang,speicherende                                           'Startadresse-und Endadresse des Basic-Programms
   byte tline[linelen]                                                        'Eingabezeilen-Puffer

dat

   tok0  byte "IF",0                                                                       '128    getestet
   tok1  byte "THEN",0                                                                     '129    getestet
   tok110 byte "ELSE",0                                                                    '238    getestet
   tok2  byte "INPUT",0    ' INPUT {"<prompt>";} <var> {,<var>}                            '130    getestet
   tok3  byte "PRINT",0    ' PRINT                                                         '131    getestet
   tok88 byte "ON",0       ' ON GOSUB GOTO                                                  216    getestet
   tok4  byte "GOTO",0                                                                     '132    getestet
   tok5  byte "GOSUB", 0                                                                   '133    getestet
   tok6  byte "RETURN", 0                                                                  '134    getestet
   tok7  byte "REM", 0                                                                     '135    getestet
   tok8  byte "NEW", 0                                                                     '136    getestet
   tok9  byte "LIST", 0     'list <expr>,<expr> listet von bis zeilennummer                 137    getestet      NICHT AENDERN Funktionstaste!!
   tok10 byte "RUN", 0                                                                     '138    getestet      NICHT AENDERN Funktionstaste!!
   tok26 byte "FOR", 0      ' FOR <var> = <expr> TO <expr>                                  154    getestet
   tok27 byte "TO", 0                                                                      '155    getestet
   tok28 byte "STEP", 0     ' optional STEP <expr>                                          156    getestet
   tok29 byte "NEXT", 0     ' NEXT <var>                                                    157    getestet
   tok52 byte "END", 0      '                                                               180    getestet
   tok53 byte "PAUSE", 0    ' PAUSE <time ms> {,<time us>}                                  181    getestet
   tok58 byte "DUMP", 0     ' DUMP <startadress>,<anzahl zeilen>,<0..1> (0 Hram,1 Eram)     186    getestet
   tok86 byte "BYE",0       ' Basic beenden                                                 214    getestet      NICHT AENDERN Funktionstaste!!
   tok84 byte "INKEY",0     'Auf Tastendruck warten Rueckgabe ascii wert                    212    getestet
   tok85 byte "CLEAR",0     'alle Variablen loeschen                                        213    getestet
   tok87 byte "PEEK",0      'Byte aus Speicher lesen momentan nur eram                      215    getestet
   tok80 byte "POKE",0      'Byte in Speicher schreiben momentan nur eram                   208    getestet
   tok89 byte "BEEP",0      'beep oder beep <expr> piepser in versch.Tonhoehen              217    getestet
   tok92 byte "EDIT",0      'Zeile editieren                                                220    getestet
   tok61 byte "RENUM",0     'Renumberfunktion                                               189    getestet

'************************** Dateioperationen **************************************************************
   tok12 byte "OPEN", 0     ' OPEN " <file> ",<mode>                                        140    getestet
   tok13 byte "FREAD", 0     ' FREAD <var> {,<var>}                                         141    getestet
   tok14 byte "WRITE", 0    ' WRITE <"text"> :                                              142    getestet
   tok15 byte "CLOSE", 0    ' CLOSE                                                         143    getestet
   tok16 byte "DEL", 0      ' DELETE " <file> "                                             144    getestet
   tok17 byte "REN", 0      ' RENAME " <file> "," <file> "                                  145    getestet
   tok102 byte "CHDIR",0    ' Verzeichnis wechseln                                          230    getestet      kann nicht CD heissen, kollidiert sonst mit Hex-Zahlen-Auswertung in getanynumber
   tok18 byte "DIR", 0      ' dir anzeige                                                   146    getestet      NICHT AENDERN Funktionstaste!!
   tok19 byte "SAVE", 0     ' SAVE or SAVE [<expr>] or SAVE "<file>"                        147    getestet      NICHT AENDERN Funktionstaste!!
   tok20 byte "LOAD", 0     ' LOAD or LOAD [<expr>] or LOAD "<file>" ,{<expr>}              148    getestet      NICHT AENDERN Funktionstaste!!
   tok54 byte "FILE", 0     ' FILE wert aus datei lesen oder in Datei schreiben             182    getestet
   tok24  byte "GFILE",0    ' GETFILE rueckgabe der mit Dir gefundenen Dateien ,Dateinamen  152    getestet
   tok78 byte "MKDIR",0     ' Verzeichnis erstellen                                         206    getestet
   tok112 byte "GATTR",0    ' Dateiattribute auslesen                                       240    getestet
   tok90 byte "BLOAD",0      'Bin Datei laden                                               218    getestet
   tok57 byte "MKFILE", 0    'Datei erzeugen                                                185    getestet

'************************* logische Operatoren **********************************************************************
   tok21 byte "NOT" ,0      ' NOT <logical>                                                '139    getestet
   tok22 byte "AND" ,0      ' <logical> AND <logical>                                      '150    getestet
   tok23 byte "OR", 0       ' <logical> OR <logical>                                       '151    getestet
'************************* mathematische Funktionen *****************************************************************
   tok11 byte "RND", 0       'Zufallszahl von x                                            '139    getestet
   tok46 byte "PI",0          'Kreiszahl PI                                                '174    getestet
   tok83 byte "FN",0       'mathematische Benutzerfunktionen                                211    getestet
   tok117 byte "ABS",0                                               '                      245    getestet
   tok118 byte "SIN",0                                                                     '246    getestet
   tok119 byte "COS",0                                                                     '247    getestet
   tok120 byte "TAN",0                                                                  '   248    getestet
   tok121 byte "ATN",0                                                                     '249    getestet
   tok122 byte "LN",0                                                                   '   250    getestet
   tok123 byte "SGN",0                                                                   '  251    getestet
   tok124 byte "SQR",0                                                                   '  252    getestet
   tok125 byte "EXP",0                                                                  '   253    getestet
   tok126 byte "INT",0                                                                     '254    getestet

'******************************** Mouse Befehle *********************************************************************
   tok93 byte "MGET",0      'Mouse-xyz-position                                           ' 221    getestet
   tok97 byte "MB",0        'Mouse-Button                                                 ' 225    getestet
   tok63 byte "MOUSE",0     'Mouse on off  Mouse on,farbe                                 ' 191    getestet
   tok96 byte "MBOUND",0    'Mouse-Bereich definieren                                     ' 224    getestet

'************************* Bildschirmbefehle ***********************************************************************
   tok59 byte "COLOR",0       'Farbe setzen  1,2 Vordergrund,Hintergrund                    187    getestet
   tok60 byte "CLS",0       'Bildschirm loeschen cursor oberste Zeile Pos1                  188    getestet
   tok62 byte "POS",0       'Cursor an Pos x,y setzen -> Locate(x,y)                        190    getestet
   tok65 byte "GETX",0      'x-Cursorposition                                              '193    getestet
   tok66 byte "SCRDN",0     'n Zeilen runterscrollen -> Scrdown(n)                          194    getestet
   tok67 byte "SCRUP",0     'n Zeilen hochscrollen   -> Scrup(n)                            195    getestet
   tok68 byte "CUR",0       'Cursor ein/ausschalten                                         196    getestet
   tok45 byte "GETY",0      'y-Cursorposition                                              '173    getestet
   tok107 byte "HEX",0      'Ausgabe von Hexzahlen mit Print                               '235    getestet
   tok73 byte "BIN",0       'Ausgabe von Binärzahlen mit Print                             '201    getestet
   tok82 byte "LINE",0      'Linie zeichnen                                                 210    getestet M0,M1,M2,M3
   tok43 byte "RECT",0      'Rechteck                                                       171    getestet M0,M1,M2,M3
   tok64 byte "PSET",0      'Pixel setzen                                                   192    getestet M0,M1,M2,M3

''************************* Modus0   ***********************************************************************
   tok39 byte "WIN", 0      'Fenster C,T,S,R erstellen                                      167 *  getestet M0,M1
   tok74 byte "BUTTON",0    'Button erzeugen                                                202    getestet
   tok103 byte "BOX",0       '2dbox zeichnen                                                231    getestet M0,M1
   tok75 byte "RECOVER",0    'Bildschirmbereich wiederherstellen                           '203    getestet M0,M1
   tok94 byte "BACKUP",0     'Bildschirmbereich sichern                                    '222    getestet M0,M1

'************************* Modus1-3  ***********************************************************************
   tok81 byte "CIRC",0      'Kreis zeichnen                                                 209    getestet M1,M2,M3
   tok44 byte "PTEST",0     'Pixeltest                                                      172    getestet M1,M2,M3

'************************* Datum und Zeit funktionen ***************************************************************
   tok70 byte "STIME",0    'Stunde:Minute:Sekunde setzen ->                                 198    getestet
   tok71 byte "SDATE",0    'Datum setzen                                                    199    getestet
   tok76 byte "GTIME",0    'Zeit   abfragen                                                 204    getestet
   tok77 byte "GDATE",0    'Datum abfragen                                                  205    getestet
   tok111 byte "TIMER",0   'Timer-Funktionen  set,read,clear?,entry,delete                  239    getestet

'**************************** STRINGFUNKTIONEN ********************************************************************
   tok35 byte "LOWER$", 0     'String in Kleinbuchstaben zurückgeben                        163 *  getestet
   tok104 byte "UPPER$",0     'String in Großbuchstaben zurückgeben                        '232    getestet
   tok72 byte "LEFT$",0     'linken Teilstring zurückgeben                                 '200    getestet
   tok101 byte "MID$",0     'Teilstring ab Position n Zeichen zurückgeben                  '229    getestet
   tok98 byte "RIGHT$",0    'rechten Teilstring zurückgeben                                '226    getestet
   tok36 byte "COMP$", 0    'Stringvergleich                                                164    getestet
   tok37 byte "LEN", 0      'Stringlänge zurueckgeben                                       165    getestet
   tok48 byte "CHR$", 0     'CHR$(expr)                                                     176    getestet
   tok105 byte "ASC",0      'ASCII-Wert einer Stringvariablen zurueckgeben                  233    getestet
   tok56  byte "TAB", 0     'Tabulator setzen                                               184    getestet
   tok113 byte "VAL",0      'String in FLOAT-Zahlenwert umwandeln                           241    getestet
   tok108 byte "STRING$",0   'Zeichenwiederholung                                           236    getestet
   tok109 byte "DIM",0       'Stringarray dimensionieren                                    237    getestet
   tok116 byte "INSTR",0    'Zeichenkette in einer anderen Zeichenkette suchen            ' 244    getestet

'**************************** Grafik-Tile-Befehle NUR MODUS 0 ****************************************************
   tok34  byte "TLOAD", 0    'Tileset in eram laden                                         162    getestet
   tok51  byte "TILE", 0     'Tileblock aus aktuellem Tileset anzeigen                      179    getestet
   tok50  byte "STILE", 0    'tileset in bella laden                                        178    getestet
   tok100 byte "TPIC",0      'komplettes Tileset als Bild anzeigen                          228    getestet
   tok25  byte "MAP", 0      'MAP-Befehle L=load,S=Save,D=Display,W=Write in Ram          ' 153 *  getestet
   tok91 byte "PLAYER",0     'Spielerfigur-Parameter p,k,g(parameter,Keys,collision,get)    219 *  getestet
   tok114 byte "PLAYXY",0    'Spielerbewegung                                               242    getestet
   tok95 byte "SPRITE",0     'Sprite-Parameter p, m, s(parameter, move,speed,usw)          '223 *  getestet

'**************************** Daten-Befehle *****************************************************************
   tok38 byte "READ", 0      'Data Lesen                                                   '166    getestet
   tok40 byte "DATA", 0      'Data-Anweisung                                               '168    getestet
   tok47 byte "RESTORE", 0   'Data-Zeiger zurücksetzen                                      175    getestet

'**************************** Funktionen der seriellen Schnittstelle **********************************************
   tok115 byte "COM",0                                                                     '243 *  getestet

'***********************SID-Synth-Befehle**************************************************************************
   tok30 byte "SID", 0       'SID_Soundbefehle                                              158    getestet
   tok31 byte "PLAY", 0      'SID DMP-Player                                               '159    getestet
   tok32 byte "GDMP", 0      'SID DMP-Player-Position                                      '160    getestet

'************************ Port-Funktionen *************************************************************************
   tok79 byte "PORT",0       'Port-Funktionen      Port s,i,o,p                             207 *  getestet
   tok55 byte "JOY",0        'Joystick abfragen für 2 Joysticks                             183    getestet
   tok106 byte "XBUS",0      'Zugriff auf System-Funktionen                                 234    getestet
'************************ ende Basic-Befehle **********************************************************************


'************************ Befehle in der Testphase ****************************************************************
   tok33 byte "PUT", 0       'einzelnes Zeichen an x,y-Position ausgeben                   '161    gestestet           - Verbleib noch offen
   tok41 byte "RDEF",0       'Font umdefinieren                                            '169
   tok42 byte "SYS",0        'Systemfunktionen z.Bsp.anderer Grafikmodus                   '170
   tok99 byte "BMP",0        'Bitmap laden, speichern, anzeigen (nur Mode4)                '227

'******************************************************************************************************************

'******************************* freie Befehle für Erweiterungen **************************************************
   tok49 byte "FREI1",0       'Frei                                                           177
   tok69 byte "FREI2",0       '                                                              '197


'        ---------------------------- Mehr Befehle sind nicht möglich --------------------------
'******************************************************************************************************************

   toks  word @tok0, @tok1, @tok2, @tok3, @tok4, @tok5, @tok6, @tok7
         word @tok8, @tok9, @tok10, @tok11, @tok12, @tok13, @tok14, @tok15
         word @tok16, @tok17, @tok18, @tok19, @tok20, @tok21, @tok22, @tok23
         word @tok24, @tok25, @tok26, @tok27, @tok28, @tok29, @tok30, @tok31
         word @tok32, @tok33, @tok34, @tok35, @tok36, @tok37, @tok38, @tok39
         word @tok40, @tok41, @tok42, @tok43, @tok44, @tok45, @tok46, @tok47
         word @tok48, @tok49, @tok50, @tok51, @tok52, @tok53, @tok54, @tok55
         word @tok56, @tok57, @tok58, @tok59, @tok60, @tok61, @tok62, @tok63
         word @tok64, @tok65, @tok66, @tok67, @tok68, @tok69, @tok70, @tok71
         word @tok72, @tok73, @tok74, @tok75, @tok76, @tok77, @tok78, @tok79
         word @tok80, @tok81, @tok82, @tok83, @tok84, @tok85, @tok86, @tok87
         word @tok88, @tok89, @tok90, @tok91, @tok92, @tok93, @tok94, @tok95
         word @tok96, @tok97, @tok98, @tok99, @tok100, @tok101, @tok102,@tok103
         word @tok104, @tok105, @tok106, @tok107, @tok108, @tok109, @tok110
         word @tok111, @tok112, @tok113, @tok114, @tok115, @tok116, @tok117
         word @tok118, @tok119, @tok120, @tok121, @tok122, @tok123, @tok124
         word @tok125, @tok126

   tokx  word


dat
     BASIC byte "BASIC.BIN",0

pub main
    ios.start
    speicheranfang:=$0                                                            'Programmspeicher beginnt ab adresse 0 im eRam
    speicherende:=$2                                                              'Programmende-marke
    read_filename
    ios.sdmount
    ios.sdopen("R",@tline)
    processload
    ios.sdclose
    ios.sdopen("r",@basic)
    ios.ldbin(@basic)
    ios.sdclose
    ios.stop

pri read_filename|i,adr
    adr:=ios#PARAM
    i:=0
    repeat while tline[i++]:=ios.ram_rdbyte(adr++)
    tline[i]:=0

PRI processLoad | a,b,c,e,l',pr

   b:=0
   e:=ios.sdfattrib(0)
   l:=1
   repeat
      a := 0
      repeat
         c := ios.sdgetc
      '############### Überprüfung auf gültige Zeichen ###############
         if (c<32 or c>125) and not c==13 and not c==10 and not c==17 and not c==21
            ios.ram_wrbyte(0,PMARK_RAM)
            ios.print(string("Wrong Fileformat!"))
            'ios.printdec(l)
            ios.sid_beep(0)
            return
      '###############################################################
         b++
         if c == fReturn or b==e                                                'c==ios.sdeof  sdeof funktioniert nicht so richtig
            tline[a] := 0
            tp := @tline
            quit
         elseif c == fLinefeed
            next
         elseif c < 0
            quit
         elseif a < linelen-1
            tline[a++] := c
      if b==e and tline[a] == 0                                                 'c==ios.sdeof sdeof funktioniert nicht so richtig
         quit
      if c < 0
         ios.ram_wrbyte(0,PMARK_RAM)
         ios.print(string("Error while loading file!"))
         ios.sid_beep(0)
         return
      tp := @tline
      a := spaces

      if a=>"0" and a =< "9"
            ios.printchar(46)                                                    'Punkt als Fortschrittsanzeige
            writeram                                                            'normaler Programmload
            Prg_End_Pos

      else
         if a <> 0
            ios.ram_wrbyte(0,PMARK_RAM)
            ios.print(string("Missing Linenumber!"))
            ios.sid_beep(0)
            return

   RAM_CLEAR                                                                    'Programmspeicher hinter dem Programm loeschen
   ios.printnl

pri binsave|datadresse,count
   datadresse:= 0
   count:=speicherende-2
   ios.sdxputblk(datadresse,count)
   ios.sdclose

PRI writeendekennung(adr)
    ios.ram_wrword($FFFF,adr)                                                   'Programmendekennung schreiben
    speicherende:=adr+2                                                         'neues Speicherende

PRI Prg_End_Pos                                                                 'letztes Zeichen der letzten Zeile (Programmende)
    nextlineloc := speicherende - 2

PRI findline(lineno):at
   at := speicheranfang
   repeat while ios.ram_rdword(at) < lineno and at < speicherende-2             'Zeilennummer
          at:=ios.ram_keep(at+2)'+1                                                     'zur nächsten zeile springen

PRI eram_rw(beginn,adr)|temp,zaehler
'******************** Bereich nach der bearbeiteten Zeile in Bearbeitungsspeicher verschieben **************************
    temp:=TMP_RAM                                        'Anfang Bearbeitungsbereich
    zaehler:=speicherende-2-adr
    if adr<speicherende-2
       ios.ram_copy(adr,TMP_RAM,zaehler)
'******************** Bereich aus dem Bearbeitungsspeicher wieder in den Programmspeicher verschieben ******************
    if zaehler>0                                         'wenn nicht die letzte Zeile
       ios.ram_copy(TMP_RAM,beginn,zaehler)
    writeendekennung(beginn+zaehler)

PRI einfuegen(adr,diff,mode)|anfang
'*********************** aendern und einfuegen von Zeilen funktioniert*************************************************
    anfang:=adr

    if mode>0
       adr:=ios.ram_keep(adr+2)                          'eigentliche Zeile beginnt nach der Adresse
       '****** letzte Zeile? *************
       if ios.ram_rdword(adr)==$FFFF                     'Ueberpruefung, ob es die letzte Zeile ist
          if mode==2                                     'Zeile loeschen
             writeendekennung(anfang)                    'an alte Adresse Speicherendekennung schreiben
             return                                      'und raus
       '*********************************
    eram_rw(anfang+diff,adr)                             'schreibe geaenderten Bereich neu

PRI insertline2 | lineno, fc, loc, locat, newlen, neuesende
   lineno := parseliteral

   neuesende:=0                                                                 'Marker, das Programmende schon geschrieben wurde auf null setzen
   if lineno < 0 or lineno => 65535                                             'Ueberpruefung auf gueltige Zeilennummer
      ios.sdclose
      'errortext(2,1)'@ln
   tokenize                                                                     'erstes Zeichen nach der Zeilennummer ist immer ein Token, diesen lesen
   fc := spaces                                                                 'Zeichen nach dem Token lesen

   loc := findline(lineno)                                                      'adresse der basic-zeile im eram, die gesucht wird
   locat := ios.ram_rdword(loc)                                                 'zeilennummer holen
   newlen := strsize(tp)+1                                                      'laenge neue zeile im speicher 1 fuer token + laenge des restes (alles was nach dem befehl steht)

   if locat == lineno                                                           'zeilennummer existiert schon

      if fc == 0                                                                'zeile loeschen
        einfuegen(loc,0,2)                                                      'Zeile hat null-laenge also loeschen
        neuesende:=1                                                            'Marker, das Programmende schon geschrieben wurde

      else                                                                      'zeile aendern
        einfuegen(loc,newlen+2,1)                                               'platz fuer geaenderte Zeile schaffen +2 fuer Zeilennummer wenn es nicht die letzte Zeile ist sonst muss die 2 weg
        neuesende:=1                                                            'Marker, das Programmende schon geschrieben wurde

   if fc                                                                        'zeilennummer existiert noch nicht
      if locat <65535 and locat > lineno                                        'Zeile einfuegen zwischen zwei Zeilen
         einfuegen(loc,newlen+2,0)                                              'Platz fuer neue Zeile schaffen
         neuesende:=1                                                           'Marker, das Programmende schon geschrieben wurde
      ios.ram_wrword(lineno,loc)                                                'Zeilennummer schreiben
      loc+=2

      repeat newlen
             ios.ram_wrbyte(byte[tp++],loc++)                                        'neue Zeile schreiben entweder ans ende(neuesende=0) oder in die lücke (neuesende=1)

      if neuesende==0                                                           'Marker, das Programmende noch nicht geschrieben wurde (zBsp.letzte Zeile ist neu)
         writeendekennung(loc)                                                  'Programmendekennung schreiben

   RAM_CLEAR                                                                    'Programmspeicher hinter dem Programm loeschen


PRI writeram | lineno
   lineno := parseliteral
   if lineno < 0 or lineno => 65535
      ios.sdclose
      'errortext(2,1)'@ln
   tokenize
   ios.ram_wrword(lineno,nextlineloc)                                           'zeilennummer schreiben
   nextlineloc+=2
   skipspaces                                                                   'leerzeichen nach der Zeilennummer ueberspringen
   repeat strsize(tp)+1
        ios.ram_wrbyte(byte[tp++],nextlineloc++)                                     'Zeile in den Programmspeicher uebernehmen

   writeendekennung(nextlineloc)                                                'Programmende setzen

PRI tokenize | tok, c, at, put, state, i, j, ntoks
   ntoks :=Get_toks                                                             'anzahl token
   at := tp
   put := tp
   state := 0
   repeat while c := byte[at]                                                   'solange Zeichen da sind schleife ausführen
      if c == quote                                                             'text in Anführungszeichen wird ignoriert
         if state == "Q"                                                        'zweites Anführungszeichen also weiter
            state := 0
         elseif state == 0
            state := "Q"                                                        'erstes Anführungszeichen

      if state == 0                                                             'keine Anführungszeichen mehr, also text untersuchen
         repeat i from 0 to ntoks-1                                             'alle Kommandos abklappern
            tok := @@toks[i] '@token'                                           'Kommandonamen einlesen
            j := 0
            repeat while byte[tok] and ((byte[tok] ^ byte[j+at]) & caseBit) == 0'zeichen werden in Grossbuchstaben konvertiert und verglichen solange 0 dann gleich
               j++
               tok++

            if byte[tok] == 0 and not isvar(byte[j+at])                         'Kommando keine Variable?
               byte[put++] := 128 + i                                           'dann wird der Token erzeugt
               at += j
               if i == 7                                                        'REM Befehl
                  state := "R"
               else
                  repeat while byte[at] == " "
                     at++
                  state := "F"
               quit
         if state == "F"
            state := 0
         else
            byte[put++] := byte[at++]
      else
         byte[put++] := byte[at++]
   byte[put] := 0                                                               'Zeile abschliessen

pri Get_toks                                                                    'Tokenanzahl ermitteln
    result:=(@tokx - @toks) / 2

PRI spaces | c
   'einzelnes zeichen lesen
   repeat
      c := byte[tp]
      if c==21 or c==17                                                         'Wurzelzeichen und Pi-Zeichen
         return c
      if c == 0 or c > " "
         return c
      tp++

PRI skipspaces
   if byte[tp]
      tp++
   return spaces

PRI parseliteral | r, c                                                         'extrahiere Zahlen aus der Basiczeile
   r := 0
   repeat
      c := byte[tp]
      if c < "0" or c > "9"
         return r
      r := r * 10 + c - "0"
      tp++

PRI fixvar(c)                                                                   'wandelt variablennamen in Zahl um (z.Bsp. a -> 0)
   if c => "a"
      c -= 32
   return c - "A"

PRI isvar(c)                                                                    'Ueberpruefung ob Variable im gueltigen Bereich
   c := fixvar(c)
   return c => 0 and c < 26
PRI RAM_CLEAR
    ios.ram_fill(speicherende,$20000-speicherende,0)                            'Programmspeicher hinter dem Programm loeschen

