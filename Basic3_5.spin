{{ ---------------------------------------------------------------------------------------------------------

Hive-Computer-Projekt

Name            : TRIOS-Basic
Chip            : Regnatix-Code 
Version         : 3.5
Dateien         :

Beschreibung    : Modifiziertes, stark erweitertes FemtoBasic für den Hive.

Eigenschaften   : -Benutzung externer Ram, Stringverarbeitung, Array-Verwaltung
                  -Gleitkommafuktion, Tile-Grafikunterstützung
                  -SID-Sound-Unterstützung
                  -3 Grafik-Modi
                  -0=64-Farb-VGA-Treiber;
                  -1=320x256 Pixel 31-Vordergrund und 8 Hintergrundfarben;
                  -2=160x120 Pixel 64 Farben pro Pixel
                  -Maus-Unterstützung, Button-Verwaltung
                  -Fensterverwaltung
                  -durch Tile-Fonts, verschiedene Schriftarten und Fensterstile
                  -bewegte Tile-Sprites
                  -lange Variablennamen
                  -dynamische Variablen-Verwaltung
                  -Pixelgrafik im Modus 1 und 2

Logbuch         :


'############################################################ Version 3.5 ######################################################################################################
07-01-2021      -Nach langer Zeit geht es wieder weiter
                -den Befehl BMP mit den Parametern W (E-Ram-Bilddaten auf SD schreiben) und R (E-Ram-Bilddaten von SD lesen erweitert
                -damit können im Mode4 Bilder schneller geladen werden, da die Bilddaten nicht mehr konvertiert werden müssen
                -somit sinkt die Ladezeit auf ca.4 Sekunden (statt über 30 sek.)
                -600 Longs frei

13-01-2021      -einige Optimierungen durchgeführt
                -Grafiktreiber über clob-con mit Flash-Variante in Einklang gebracht, jetzt sind beide Varianten von der gleichen glob-con abhängig
                -Venatrix-Funktionen entfernt - kein Interesse - mehr Platz
                -650 Longs frei

14-01-2021      -Grafikmodus 2 und 3 entfernt - kaum sinnvolle Nutzung (manchmal ist weniger mehr)
                -671 Longs frei

22-01-2021      -Routine READ_PARAMETER deaktiviert, war wohl mal als Batchfunktion gedacht um Basic mit Startbefehlen zu starten (Basic Befehlszeile...)
                -machte Probleme, wenn keine oder falsche Werte im Ram standen
                -dadurch wieder etwas Platz gespart
                -705 Longs frei

19-02-2021      -Dump-Befehl nur Hub und E-Ram, das reicht
                -710 Longs frei
 --------------------------------------------------------------------------------------------------------- }}

obj
  ios    :"reg-ios-bas"
  FS     :"BasFloatString2"
  TMRS   :"timer"
  Fl     :"BasF32.spin"
  gc     :"glob-con"

con

_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000

   version   = 3.5

   fEof      = $FF                     ' dateiende-kennung
   linelen   = 85                      ' Maximum input line length
   quote     = 34                      ' Double quote
   caseBit   = !32                     ' Uppercase/Lowercase bit
   point     = 46                      ' point
   FIELD_LEN = 64000                   ' Array-Feldgröße (max Feldgröße 40x40x40 -> Dim a(39,39,39)
   DIR_ENTRY = 546                     ' max.Anzahl mit DIR-Befehl gefundener Einträge
   STR_MAX   = linelen                 ' maximale Stringlänge für Printausgaben und Rom
   DPL_CNT   = 1200                    ' Map-und Bildschirm-Shadow-Speicher-Zähler (40Spalten*30Zeilen=1200-Tiles)
'*****************Speicherbereiche**********************************************
   maxstack  = 20                      ' Maximum stack tiefe fuer gosub
   userptr   = $1FFFF                  ' Ende Programmspeicher  128kb
   TMP_RAM   = $20000 '....$3FFFF      ' Bearbeitungsspeicher   128kb (fuer die Zeileneditierung bzw.Einfuegung von Zeilen)
   TILE_RAM  = $40000 '....$667FF      ' hier beginnt der Tile-Speicher fuer 14 Tiledateien(Modus0) oder 8 BMP-Bilder(Modus4)
   SYS_FONT  = $66800 '....$693FF      ' ab hier liegt der System-Font 11kb
   MOUSE_RAM = $69400 '....$6943F      ' User-Mouse-Pointer 64byte
   DIR_RAM   = $69440 '....$6AFFF      ' Puffer fuer Dateinamen 7103Bytes fuer 546 Dateinamen
   MAP_RAM   = $6B000 '....$6CC27      ' Shadow-Display (Pseudo-Kopie des Bildschirmspeichers)

   'FREI_RAM   $6D000 .... $7A3FF      ' freier RAM-Bereich 54272 Bytes (53kB)

   DATA_RAM = $7A400 '.... $7E3FF      ' 16kB DATA-Speicher

   BUTT_RAM = $7E400 '.... $7E8FF      ' ca.1kB Button Puffer

   WTILE_RAM= $7E900 '.... $7E9FF      ' Win-Tile Puffer hier können die Tiles, aus denen die Fenster gebaut werden geändert werden

   FUNC_RAM = $7EA00 '.... $7F3FF      ' Funktions-Speicher, hier werden die selbstdefinierten Funktionen gespeichert

   ERROR_RAM = $7F400 '....$7FEFF      ' ERROR-Texte

   PMARK_RAM = $7FFF0                  ' Flag für Reclaim           Wert= 161
   BMARK_RAM = $7FFF1                  ' Flag für Basic-Warm-Start  Wert= 121
   SMARK_RAM = $7FFF2                  ' Flag für übergebenen Startparameter Wert = 222
   MMARK_RAM = $7FFF3                  ' Flag für Grafikmode

   STR_ARRAY = $80000 '....$EE7FF      ' Variablen und Stringarray-Speicher

   USER_RAM  = $EE800 '....$FAFFF      ' Freier Ram-Bereich, für Anwender, Backup-Funktion usw. 51200Bytes 50kb

   VAR_TBL   = $FB000 '....$FCFFF      ' Variablen-Tabelle
   STR_TBL   = $FD000 '....$FEFFF      ' String-Tabelle


   ADM_SPEC       = gc#A_FAT|gc#A_LDR|gc#A_SID|gc#A_RTC|gc#A_PLX'%00000000_00000000_00000000_11110011
'***************** Button-Anzahl ************************************************
   BUTTON_CNT   = 32                       'Anzahl der möglichen Button
'******************Farben Mode0,2,3,4 *******************************************
  #$FC, Light_Grey, #$A8, Grey, #$54, Dark_Grey
  #$C0, Light_Red, #$80, Red, #$40, Dark_Red
  #$30, Light_Green, #$20, Green, #$10, Dark_Green
  #$1F, Light_Blue, #$09, Blue, #$04, Dark_Blue
  #$F0, Light_Orange, #$E6, Orange, #$92, Dark_Orange
  #$CC, Light_Purple, #$88, Purple, #$44, Dark_Purple
  #$3C, Light_Teal, #$28, Teal, #$14, Dark_Teal
  #$FF, White, #$00, Black


'Farben im Mode1
{
Vordergrundfarben
  0-schwarz
  1-dunkelblau
  2-dunkelgruen
  3-blau
  4-Gruen
  5-hellblau
  6-hellgruen
  7-Türkis
  8-rot
  9-lila
  10-orange
  11-pink
  12-teal
  13-hellgrau
  14-gelbgruen
  15-blaugruen

Hintergrundfarben
  1-Blau
  2-Gruen
  3-Türkis
  4-rot
  5-Lila
  6-Gelb
  7-Weiß
}
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

   MIN_EXP   = -99999
   MAX_EXP   =  999999

   set_x        =gc#BEL_DPL_SETX
   Cursor_set   =gc#BEL_CURSORRATE
   Del_button   =gc#BEL_ERS_3DBUTTON'19
   Thirdcolor   =gc#BEL_THIRDCOLOR'28
   Print_Window =gc#BEL_DPL_WIN'33
   SPEED        =gc#BEL_SPRITE_SPEED'48
   MOVE         =gc#BEL_SPRITE_MOVE'47

   _Line        =gc#BEL_DPL_LINE
   _Circ        =gc#BEL_DPL_CIRCLE
   _Rect        =gc#BEL_RECT


'   _IMPORT      =72'8 '(Speicherstelle im Flashrom der IMPORT-DLL)
'   _EXPORT      =73'9 '(Speicherstelle im Flashrom der Export-Dll)

var
   long sp, tp, nextlineloc, rv, curlineno, pauseTime                         'Goto,Gosub-Zähler,Kommandozeile,Zeilenadresse,Random-Zahl,aktuelle Zeilennummer, Pausezeit
   long stack[maxstack],speicheranfang,speicherende                           'Gosub,Goto-Puffer,Startadresse-und Endadresse des Basic-Programms
   long forStep[26], forLimit[26], forLoop[26]                                'Puffer für For-Next Schleifen
   long prm[10]                                                               'Befehlszeilen-Parameter-Feld (hier werden die Parameter der einzelnen Befehle eingelesen)
   long gototemp,gotobuffer,gosubtemp,gosubbuffer                             'Gotopuffer um zu verhindern das bei Schleifen immer der Gesamte Programmspeicher nach der Zeilennummer durchsucht werden muss
   long datapointer                                                           'aktueller Datapointer
   long restorepointer                                                        'Zeiger für den Beginn des aktuellen DATA-Bereiches
   long usermarker,basicmarker                                                'Dir-Marker-Puffer für Datei-und Verzeichnis-Operationen
   long tp_back                                                               'sicherheitskopie von tp ->für Input
   long Var_Neu_Platz                                                         'nächste freie Variablen-Adresse

   word tilecounter                                                           'Zaehler fuer Anzahl der Tiles in einer Map
   word filenumber                                                            'Anzahl der mit Dir gefundenen Dateien
   word VAR_NR                                                                'Variablenzähler
   word STR_NR                                                                'Stringzähler
   byte var_arr[3]                                                            'temp array speicher varis-funktion für direkten Zugriff
   byte var_tmp[3]                                                            'temp array speicher varis-funktion für zweite Variable (in pri factor) um Rechenoperationen u.a. auszuführen
   byte var_temp[3]                                                           'temp array speicher erst mit dem dritten Speicher funktioniert die Arrayverwaltung korrekt

   byte prm_typ[10]                                                           'parametertyp variable oder string
   byte workdir[12]                                                           'aktuelles Verzeichnis
   byte fileOpened,tline[linelen]',tline_back[linelen]                         'File-Open-Marker,Eingabezeilen-Puffer,Sicherheitskopie für tline ->Input-Befehl
   byte debug                                                                 'debugmodus Tron/Troff
   byte cursor                                                                'cursor on/off
   byte win                                                                   'Fensternummer
   byte farbe,hintergr                                                        'vorder,hintergrundfarbe
   byte file1[12],dzeilen,xz,yz,buff[8],modus                                 'Dir-Befehl-variablen   extension[12]
   byte volume,play                                                           'sidcog-variablen
   byte xtiles[16]                                                            'xtiles fuer tilenr der Tile-Dateien       '
   byte ytiles[16]                                                            'ytiles fuer tilenr der Tile-Dateien
   byte str0[STR_MAX],strtmp[STR_MAX]                                         'String fuer Fontfunktion in Fenstern
   byte aktuellestileset                                                      'nummer des aktuellen tilesets
   byte font[STR_MAX]                                                         'Stringpuffer fuer Font-Funktion und str$-funktion
   byte mapram                                                                'Map-Schreibmarker
   byte ongosub                                                               'on gosub variable
   byte actionkey[5]                                                          'Belegung der Spielertasten -> nach Bella verschoben
   byte item[6]                                                               'von Spielerfigur einsammelbare Gegenstände
   byte block[10]                                                             'tiles, die nicht überquert werden können
   byte collision[6]                                                          'tiles mit denen man kollidieren kann
   byte itemersatz[30]                                                        'Item-Ersatztiles, die das eingesammelte item im Display-Ram und auf dem Bildschirm ersetzen
   byte f0[STR_MAX]                                                           'Hilfsstring
   byte ADDA,PORT                                                             'Puffer der Portadressen der Sepia-Karte
   byte returnmarker                                                          'Abbruchmarker für Zeileneditor
   byte editmarker                                                            'Editmarker für Zeileneditor
   byte actorpos[2]                                                           'Zwischenspeicher für x,y-Position des Spieler-Tiles
   byte button_art[BUTTON_CNT]                                                'Puffer für die Art des Buttons (Text-oder Icon)
   'byte sid_command[7]                                                        'SID-Sound-Kommando

   byte GMode                                                                 'Grafikmodus
   byte Big_Font                                                              'Font-Modus (0=Tile/1=ROM)

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
   tok13 byte "FREAD", 0    ' FREAD <var> {,<var>}                                          141    getestet
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
   tok69 byte "SCRLEFT",0   'Bildschirmausschnitt y-yy nach links scrollen                 '197
   tok45 byte "GETY",0      'y-Cursorposition                                              '173    getestet
   tok107 byte "HEX",0      'Ausgabe von Hexzahlen mit Print                               '235    getestet
   tok73 byte "BIN",0       'Ausgabe von Binärzahlen mit Print                             '201    getestet
   tok82 byte "LINE",0      'Linie zeichnen                                                 210    getestet M0,M1
   tok43 byte "RECT",0      'Rechteck                                                       171    getestet M0,M1
   tok64 byte "PSET",0      'Pixel setzen                                                   192    getestet M0,M1

''************************* Modus0   ***********************************************************************
   tok39 byte "WIN", 0      'Fenster C,T,S,R erstellen                                      167 *  getestet M0,M1
   tok74 byte "BUTTON",0    'Button erzeugen                                                202    getestet
   tok103 byte "BOX",0       '2dbox zeichnen                                                231    getestet M0,M1
   tok75 byte "RECOVER",0    'Bildschirmbereich wiederherstellen                           '203    getestet M0,M1
   tok94 byte "BACKUP",0     'Bildschirmbereich sichern                                    '222    getestet M0,M1

'************************* Modus1-3  ***********************************************************************
   tok81 byte "CIRC",0      'Kreis zeichnen                                                 209    getestet M1,M2
   tok44 byte "PTEST",0     'Pixeltest                                                      172    getestet M1,M2

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


Dat '*************** Verschiedene Grafikmodi **************************

   Gmode0 byte "mode0.sys" 'Tiletreiber 64Farben 40x30 Zeichen bzw.Tiles
   Gmode1 byte "mode1.sys" 'Pixeltreiber 32 Vordergrund- (16+16 blinkend) und 8 Hintergrundfarben 320x256 Pixel 40x32 Zeichen Farbblock 8x4Pixel
   Gmode2 byte "mode2.sys" 'Pixeltreiber 64 Farben 20x15 Zeichen 160x120 Pixel Farbblock 1Pixel'"mode2.sys" 'Pixeltreiber 64 Farben 64x48 Zeichen 512x384 Pixel Farbblock 4x4Zeichen

   Gmodes word @Gmode0,@Gmode1,@Gmode2',@Gmode3,@Gmode4
   GmodeLine byte 39,39,19  'Spaltenanzahl-1 der Treiber
   Gmodey byte 29,31,14     'Zeilenanzahl-1 der Treiber
   gmodexw word 640,320,160 'x-weite des Treibers
   gmodeyw word 480,256,120 'y-weite des Treibers
   gmodepicsize word 4800,10240,19200 'Bildgröße
   gmodeoffset word 4800,10240,19040 'Speicheroffset für letzte Bild-Zeile

DAT
   ext5          byte "*.*",0                                                   'alle Dateien anzeigen
   tile          byte "Tile",0                                                  'tile-Verzeichnis
   adm           byte "adm.sys",0                                               'Administra-Treiber
   sysfont       byte "sysfontb.dat",0                                          'system-font
   errortxt      byte "errors.txt",0                                            'Error-Texte
   importfile    byte "import.sys",0                                            'externe Funktion Import
   exportfile    byte "export.sys",0                                            'externe Funktion Export
   basicdir      byte "BASIC",0

   windowtile byte 135,137,136,7,141,134,132,130,128,8,129,133,0,131,8,8,8      'Fenster-Tiles für WIN-Funktion im Modus 0

con'****************************************** Hauptprogramm-Schleife *************************************************************************************************************
PUB main | sa

   init                                                                         'Startinitialisierung

   sa := 0                                                                      'startparameter
   curlineno := -1                                                              'startparameter

   repeat
      \doline(sa)                                                               'eine kommandozeile verarbeiten
      sa  := 0                                                                  'Zeile verwerfen da abgearbeitet

con'****************************************** Initialisierung *********************************************************************************************************************
PRI init |pmark,newmark,x,y,i

  ios.start
  ios.sdmount                                                                   'SD-Karte Mounten
  activate_dirmarker(0)                                                         'in's Rootverzeichnis
  ios.sdchdir(@basicdir)                                                        'in's Basicverzeichnis wechseln
  basicmarker:= get_dirmarker                                                   'usermarker von administra holen
  usermarker:=basicmarker

  pmark:=ios.ram_rdbyte(PMARK_RAM)                                              'Programmarker abfragen, wenn 161 dann reclaim ausführen um Programm im Speicher wieder herzustellen


  FS.SetPrecision(6)                                                            'Präzision der Fliesskomma-Arithmetik setzen
  FL.Start
'*********************************** Timer-Cog starten ********************************************************************************************************
  TMRS.start(10)                                                                'Timer-Objekt starten mit 1ms-Aufloesung
'**************************************************************************************************************************************************************
'*********************************** EEPROM-I2C Treiber starten ***********************************************************************************************
  'ios.start_i2c(%000)
'*********************************** Startparameter ***********************************************************************************************************
  pauseTime := 0                                                                'pause wert auf 0
  fileOpened := 0                                                               'keine datei geoeffnet
  volume:=15                                                                    'sid-cog auf volle lautstaerke
  speicheranfang:=$0                                                            'Programmspeicher beginnt ab adresse 0 im eRam
  speicherende:=$2                                                              'Programmende-marke
  mapram:=0                                                                     'Map-Schreibmarker auf 0
  farbe:=orange                                                                  'Schreibfarbe
  hintergr:=black                                                               'Hintergrundfarbe
'***************************************************************************************************************************************************************

'******************* Speicher löschen oder wiederherstellen *****************
                                                                                'zum Bsp nach aufruf der Hilfefunktion
  newmark:=ios.ram_rdbyte(BMARK_RAM)                                                  'Marker steht auf 121, wenn Basic schonmal gestartet wurde
  ios.ram_wrbyte(121,BMARK_RAM)                                                      'Marker setzen,das Basic gestartet wurde

'******************* Rückkehr aus Unterprogramm Import.sys oder Export.sys *************************************************************************************
  if pmark==161
     reclaim                                                                        'Programm im Speicher wieder hestellen
     ios.ram_wrbyte(0,PMARK_RAM)                                                    'Reclaim-Marker löschen
     GMode:=ios.ram_rdbyte(MMARK_RAM)                                               'Flag für Grafikmodus lesen
  else
'*********************************** Abfrage welche Administra und Bellatrix- Codes geladen sind *************************************************************
          'Diese Funktionen sorgen dafür, das die Treiber nur geladen werden, wenn sie noch nicht vorhanden sind und Basic noch nicht gestartet wurde also nicht bei jedem Start

     if ios.admgetspec<>ADM_SPEC
        ios.admload(@adm)                                                          'administra-code laden, springt nach dem booten ins Root (falls man aus einem Unterverzeichnis startet,

     activate_dirmarker(basicmarker)                                               'usermarker wieder in administra setzen
     ios.belload(@@gmodes[0])                                                      'Basic-Grafiktreiber Mode0
     Mode_Ready                                                                    'Treiber-bereit-Meldung abwarten

'**************************************************************************************************************************************************************

     ios.ram_fill(ERROR_RAM,$BF0,0)                                                'Errortext-Speicher loeschen

     mount
     ios.sdopen("R",@errortxt)
     fileload(ERROR_RAM)                                                           'Error-Text einlesen
     if newmark<>121                                                               'Basic wurde noch nicht gestartet
        ios.ram_fill($0,userPtr,0)                                                 'Basic-Programmspeicher löschen
        ios.ram_fill(TMP_RAM,userPtr,0)                                            'Bearbeitungsspeicher loeschen
        clearall                                                                   'alle Variablen, Strings ,Window-Parameter,Mapdaten usw.löschen,Zeiger zurücksetzen
     else
        clearing                                                                   'nur Variablen,Strings,Mapdaten und Window-Parameter löschen

'************************** Startbildschirm ***********************************************************************************************************************************

  '*************** Bildschirmaufbau ***********************************

     ios.window(0,farbe,hintergr,farbe,0,0,0,0,0,0,0,29,39,1,0)
     ios.printchar(12)                                                             'cls
     LoadTiletoRam(15,@sysfont,16,11)                                              'Logo und Font in eram laden

     loadtile(15)                                                                  'Logo und Font in den Puffer laden

 '*************** Logo anzeigen **************************************
     x:=y:=0
     ios.plotfunc(0,0,10,0,light_blue,0,_Line)
     ios.plotfunc(0,1,9,1,light_orange,0,_Line)
     ios.plotfunc(0,2,8,2,light_red,0,_Line)

     repeat i from 144 to 151
          ios.displayTile(i,light_blue,0,0,y,x)
          ios.displayTile(i+8,light_red,0,0,y+2,x)
          ios.displayTile(i+16,light_orange,0,0,y+1,x)
          ios.displayTile(i+16+8,light_green,0,0,y+3,x)
          x++

     ios.setpos(0,13)
     errortext(40,0)                                                               'Versionsanzeige
     ios.setpos(2,10)

     ios.print(string("* "))
     ios.printdec(userptr-speicherende)                                            'freie bytes anzeigen usrptr-speicherende
     errortext(42,0)                                                               'Basic-Bytes Free

     ios.displaymouse(0,0)                                                         'Maus abschalten, falls an
     GMode:=0
     ios.ram_wrbyte(GMode,MMARK_RAM)

  win:=0                                                                           'aktuelle fensternummer 0 ist das Hauptfenster
  cursor:=3                                                                        'cursormarker für Cursor on
  ios.set_func(cursor,Cursor_Set)
  ios.set_func(0,Print_Window)

'*******************************************************************************************************************************************************************************

  '******************************************************************************************************************************************************
  ios.sid_resetregisters                                                           'SID Reset
  ios.sid_beep(1)

   '************ startparameter fuer Dir-Befehl *********************************************************************************************************
  dzeilen:=18
  xz     :=2
  yz     :=4
  modus  :=2                                                                       'Modus1=compact, 2=lang 0=unsichtbar

   '*****************************************************************************************************************************************************
  ios.printchar(13)
  ios.printchar(13)

  '******************************************************************************************************************************************************
  ios.setactionkey(2,3,4,5,32)                                                     'Cursorsteuerung-Standardbelegung
  actionkey[0]:=2                                                                  'links
  actionkey[1]:=3                                                                  'rechts
  actionkey[2]:=4                                                                  'hoch
  actionkey[3]:=5                                                                  'runter
  actionkey[4]:=32                                                                 'feuer
  ADDA:=$48                                                                        'Portadressen und AD-Adresse für Sepia-Karte vorbelegen
  PORT:=$38
  ios.set_plxAdr(ADDA,PORT)

  'READ_PARAMETER                                                                   'eventuelle Startparameter einlesen
  Big_Font:=0

pri Mode_Ready

         repeat while ios.bus_getchar2<>88                                         'warten auf Grafiktreiber


obj '************************** Datei-Unterprogramme ******************************************************************************************************************************
con '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PRI ifexist(dateiname)                                                          'abfrage,ob datei schon vorhanden, wenn ja Überschreiben-Sicherheitsabfrage
   ios.printchar(13)
   mount

   if ios.sdopen("W",dateiname)==0                                              'existiert die dateischon?
      errortext(8,0)                                                            '"File exist! Overwrite? y/n"    'fragen, ob ueberschreiben
      if ios.keywait=="y"
         if ios.sddel(dateiname)                                                'wenn ja, alte Datei loeschen, bei nein ueberspringen
            close
            return 0
         ios.sdnewfile(dateiname)
         ios.sdopen("W",dateiname)
      else
          ios.printchar(13)
          return 2                                                              'datei nicht ueberschreiben
   else                                                                         'wenn die Datei noch nicht existiert
      if ios.sdnewfile(dateiname)
         close
         return 0
      ios.sdopen("W",dateiname)
   ios.printchar(13)
   return 1

PRI close
   ios.sdclose
   ios.sdunmount

PRI mount
     playerstatus
     ios.sdmount
     activate_dirmarker(usermarker)
     if strsize(@workdir)>0
        if strcomp(@workdir,string("\"))                                        'ins Root-Verzeichnis
           activate_dirmarker(0)
        else
           ios.sdchdir(@workdir)
        usermarker:=get_dirmarker

con '********************************** Speicher und Laderoutinen der Basic-Programme als Binaerdateien, ist erheblich schneller *************************
pri binsave|datadresse,count
   datadresse:= 0
   count:=speicherende-2
   ios.sdxputblk(datadresse,count)
   close

PRI binload(adr)|count
    count:=fileload(adr)
    writeendekennung (adr+count)
    RAM_CLEAR

PRI RAM_CLEAR
    ios.ram_fill(speicherende,$20000-speicherende,0)                            'Programmspeicher hinter dem Programm loeschen

con '********************************** Fehler-und System-Texte in den eRam laden ****************************************************************************************************************
PRI fileload(adr): cont
    cont:=ios.sdfattrib(0)                                                      'Anzahl der in der Datei existierenden Zeichen
    ios.sdxgetblk(adr,cont)
    close

PRI errortext(nummer,ton)|ad                                                    'Fehlertext anzeigen
    ad:=ERROR_RAM
    ram_txt(nummer,ad)
    if ton<2                                                                    'alle fehlertexte mit 0 und 1
       ios.print(@font)                                                         'fehlertext
    if ton==1                                                                   'mit system-beep bei Ton==0 wird nur der Text ausgegeben und kein Beep erzeugt (bei Systemtexten)
       sysbeep
       if curlineno>0                                                           'Ausgabe der Zeilennummer bei Programmmodus (im Kommandomodus wird keine Zeilennummer ausgegeben)
          errortext(10,0)
          ios.printdec(curlineno)
       ios.printchar(13)
       Prg_End_Pos
       close
       abort
    clearstr                                                                    'Stringpuffer löschen


PRI sysbeep
    ios.sid_dmpstop
    ios.sid_beep(0)

PRI ram_txt(nummer,ad)|c,i
    i:=0
    repeat nummer
         repeat while (c:=ios.ram_rdbyte(ad++))<>10
                if nummer==1 and c>13
                    byte[@font][i++]:=c
         nummer--
    byte[@font][i]:=0

con '********************************** Basic-Programm als TXT-Datei von SD-Card Importieren oder Exportieren ******************************************************************
pri import(mode)|i,adr
    adr:=ios#PARAM
    i:=0
    ios.ram_wrbyte(GMode,MMARK_RAM)                                                  'Grafikmode merken

    repeat strsize(@f0)
          ios.ram_wrbyte(f0[i++],adr++)
    ios.ram_wrbyte(0,adr++)

    if mode
       ios.ram_wrlong(speicherende-2,adr++)
    else
       ios.ram_wrlong(0,adr++)

    ios.ram_wrbyte(161,PMARK_RAM)                                                    'Programmmarker wird bei rüeckkehr abgefragt und das Programm im Speicher wieder hergestellt
    mount
    activate_dirmarker(basicmarker)                                             'ins Basic Stammverzeichnis
    if mode
       ios.sdopen("r",@exportfile)
       ios.ldbin(@exportfile)
    else
       ios.sdopen("r",@importfile)
       ios.ldbin(@importfile)

    close

con '************************************* Basic beenden **************************************************************************************************************************
PRI ende
   ios.admreset
   ios.belreset
   reboot

con'**************************************** Basic-Zeile aus dem Speicher lesen und zur Abarbeitung uebergeben ********************************************************************
PRI doline(s) | c,i,xm
   curlineno := -1                                                              'erste Zeile
   i:=0

   if ios.key == ios#CHAR_ESC                                                   'Wenn escape gedrueck dann?
        cursor:=3
        ios.set_func(cursor,Cursor_Set)                                         'Cursor einschalten
        ios.set_func(2,MOVE)                                                    'sprites anhalten
        playerstatus                                                            'stoppe Player falls er laeuft
        errortext(4,0)                                                          'Break in Line ausgeben
        sysbeep                                                                 'Systemsignal
        Prg_End_Pos                                                             'ans Programmende springen, um das Programm abzubrechen
        ios.printdec(xm)                                                        'Ausgabe der Zeilennummer bei der gestoppt wurde
        abort


   if nextlineloc < speicherende-2                                              'programm abarbeiten

      curlineno :=xm:=ios.ram_rdword(nextlineloc)                               'Zeilennummer holen

'**********************TRON-Funktion*************************************************
      if debug == 1                                                             'bei eingeschaltetem Debugmodus wird
         ios.printchar(60)                                                      'die aktuell bearbeitete Zeilennummer
         ios.printdec(curlineno)                                                'ausgegeben
         ios.printchar(62)
'*******************ende TRON-Funktion***********************************************

'*******************Zeile aus eram holen*********************************************
      nextlineloc+=2
               repeat while tline[i++]:=ios.ram_rdbyte(nextlineloc++)

      tline[i]:=0
      tp:= @tline

      texec                                                                     'befehl abarbeiten

   else
      pauseTime := 0                                                            'oder eingabezeile

      if s
         bytemove(tp:=@tline,s,strsize(s))                                      'Zeile s in tp verschieben
      else
         if nextlineloc == speicherende - 2 and returnmarker==0                 'nächste Zeile, wenn Programm zu ende und nicht Return gedrückt wurde (da bei Eingabezeile ebenfalls ein Zeilenvorschub erzeugt wird)
            ios.printchar(13)
         returnmarker:=0
         ios.print(string("OK>"))                                               'Promt ausgeben
         getline(0)                                                             'Zeile lesen und
      c := spaces
      if c=>"1" and c =< "9"                                                    'ueberprüfung auf Zeilennummer
         insertline2                                                            'wenn programmzeile dann in den Speicher schreiben
         Prg_End_Pos                                                            'nächste freie position im speicher hinter der neuen Zeile
      else
         tokenize                                                               'keine Programm sondern eine Kommandozeile
         if spaces
            texec                                                               'dann sofort ausfuehren

con'************************************* Basic-Zeile uebernehmen und Statustasten abfragen ***************************************************************************************
PRI getline(laenge):e | i,f, c , x,y,t,m,a                                       'zeile eingeben
   i := laenge
   f:=0'laenge
   e:=0

   repeat
'********************* Playerstatus abfragen, wenn er laeuft und am ende des Titels stoppen und SD-Card freigeben********************************
      if play:=1 and ios.sid_dmppos<20                                          'Player nach abgespielten Titel stoppen
         playerstatus
'************************************************************************************************************************************************

      c := ios.keywait
      case c

                       008:if i > 0                                             'bei backspace ein zeichen zurueck 'solange wie ein zeichen da ist
                              x:=ios.getx
                              y:=ios.gety
                              ios.printchar(8)'printbs                          'funktion backspace ausfueren
                              laenge--
                              i--
                              x--
                              if laenge=>i                                      'dies Abfrage verhindert ein einfrieren bei laenge<1
                                 bytemove(@tline[i],@tline[i+1],laenge-i)
                                 tline[laenge]:=0
                                 ios.print(@tline[i])
                                 ios.printchar(32)
                              if x<0
                                 x:=GmodeLine[gmode]
                                 y--
                              if y<1
                                 y:=0
                              ios.setpos(y,x)
                              ios.printchar(2)                                  'Treiber 0 braucht das, um die Cursorposition zu aktualisieren

                       002:if i>0                                               'Pfeiltaste links
                              ios.printchar(5)'printleft
                              i--

                       003:if i < linelen-1
                              ios.printchar(6)'printright                       'Pfeiltaste rechts
                              i++

                       162,7,5:repeat while i<laenge                            'Ende,Bild runter,Cursor runter-Taste ans ende der Basiczeile springen
                                   ios.printchar(6)'printright
                                   i++
                       160,6,4:repeat i                                         'POS1,Bild hoch,Cursor hoch-Taste an den Anfang der Basic-Zeile springen
                                   ios.printchar(5)'printleft
                               i:=0
                       027:ios.printchar(13)'printnl                            'Abbruch
                           editmarker:=0
                           e:=1                                                 'Abbruchmarker
                           quit
                       186:'Entf
                            x:=ios.getx
                            y:=ios.gety
                            if laenge>i
                               bytemove(@tline[i],@tline[i+1],laenge-i)
                               laenge--
                               tline[laenge]:=0
                               ios.print(@tline[i])
                               ios.printchar(32)
                               ios.setpos(y,x)
                               ios.printchar(2)

'******************* Funktionstasten abfragen *************************
                       157..159:'m:=159-c                                       'Nummer des GModes Alt-Gr + F1-F4
                                Load_Gmode(159-c)                               'Grafikmodus laden
                                ios.print(string("OK>"))                        'Promt ausgeben
                       218:if gmode==0
                              loadtile(15)                                      'F11 Fontsatz zurücksetzen (nur Mode0)
                       219:ende                                                 'F12 basic beenden
                       214:i := put_command(@tok92,0)                           'F7 edit
                       215:ios.print(string("TRON"))                            'F8 TRON
                           debug:=1
                           return
                       216:ios.print(string("TROFF"))                           'F9 TROFF
                           debug:=0
                           return
                       217:ios.print(string("RECLAIM"))                         'F10 Reclaim
                           reclaim
                           return

                       213:i := put_command(@tok9,1)                            'F6 list in doline
                           tline[i]:=0
                           tp:=@tline
                           return

                       212:i := put_command(@tok10,1)                           'F5 RUN
                           tline[i]:=0
                           tp := @tline
                           return
                       211:
                           h_dir(dzeilen,modus,@ext5)                           'taste F4 DIR aufrufen
                       210:i := put_command(@tok19,0)                           'save  F3
                       209:i := put_command(@tok20,0)                           'Load  F2
                       208:repeat a from 46 to 61                               'Funktionstastenbelegung F1
                              errortext(a,0)
                              ios.printnl
                           return
'**********************************************************************
                       13:Returnmarker:=1                                       'wenn return gedrueckt
                           ios.printnl
                           tline[laenge] := 0                                   'statt i->laenge, so wird immer die komplette Zeile übernommen
                           tp := @tline                                         'tp bzw tline ist die gerade eingegebene zeile
                           return
                       32..126:
                           if i < linelen-1
                              if i<laenge and laenge<linelen-1
                                 x:=ios.getx
                                 y:=ios.gety
                                 t:=0
                                 bytemove(@tline[i+1],@tline[i],laenge-i)
                                 tline[i]:=c
                                 x++
                                 laenge++
                                 tline[laenge+1]:=0
                                 ios.print(@tline[i])
                                 if y==Gmodey[gmode] and (x+laenge-i-1)>GmodeLine[gmode]          'scroll hoch->dann y-position -1
                                    t:=1
                                 if x>GmodeLine[gmode]                                            'x>Zeilenlänge des Treibers
                                    y+=1
                                    x:=0
                                 ios.setpos(y-t,x)
                                 ios.printchar(2)
                                 i++
                              else
                                 ios.printchar(c)
                                 tline[i++] :=c
                              if i>laenge
                                 laenge:=i                                                          'laenge ist immer die aktuelle laenge der zeile


PRI put_command(stradr,mode)                                                    'Kommandostring nach tp senden
    result:=strsize(stradr)
    ios.print(stradr)
    if mode==1
       ios.printnl
    bytemove(@tline[0],stradr,result)

con '****************************** Basic-Token erzeugen **************************************************************************************************************************
PRI tokenize | tok, c, at, put, state, i, j', ntoks
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
         repeat i from 0 to 126'ntoks-1                                         'alle Kommandos abklappern
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

con '*********************************** Routinen zur Programmzeilenverwaltung im E-Ram********************************************************************************************
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
      close
      errortext(2,1)'@ln
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
      close
      errortext(2,1)'@ln
   tokenize
   ios.ram_wrword(lineno,nextlineloc)                                           'zeilennummer schreiben
   nextlineloc+=2
   skipspaces                                                                   'leerzeichen nach der Zeilennummer ueberspringen
   repeat strsize(tp)+1
        ios.ram_wrbyte(byte[tp++],nextlineloc++)                                     'Zeile in den Programmspeicher uebernehmen

   writeendekennung(nextlineloc)                                                'Programmende setzen

PRI reclaim |a,rc,f                                                             'Programm-Recovery-Funktion
    rc:=0                                                                       'adresszähler
    f:=0                                                                        'fehlermerker
       repeat
                  if rc>$1FFFF                                                  'nur den Programmspeicher durchsuchen
                     errortext(7,1)                                             'Fehler, wenn kein Programm da ist
       until (a:=ios.ram_rdlong(rc++))==$FFFF00                                 'Speicherendekennung suchen $FFFF0000
       speicherende:=rc+2                                                       'Speicherendezaehler neu setzen
       Prg_End_Pos

con '******************************** Variablenspeicher-Routinen ******************************************************************************************************************
PRI clearvars
   clearing
   nextlineloc := speicheranfang                                                'Programmadresse auf Anfang
   sp := 0
   clearstr                                                                     'Stringpuffer löschen

PRI clearing |i
   ios.ram_fill(DIR_RAM,$38FF,0)                                                'Variablen,Dir-Speicher,Map-Speicher-Shadow-Bildschirmspeicher bis $79C27  loeschen beginnend mit dem Dir-Speicher
   ios.ram_fill(STR_ARRAY,$6E800,0)                                             'Stringarray-Speicher loeschen
   ios.ram_fill(VAR_TBL,$4000,0)                                                'Variablen-Tabellen löschen
   repeat i from 0 to 961
       ios.ram_wrbyte(10,VAR_TBL+(i*8)+4)
       ios.ram_wrbyte(10,STR_TBL+(i*8)+4)

   pauseTime := 0
   gototemp:=gosubtemp  :=0                                                     'goto-Puffer loeschen
   gotobuffer:=gosubbuffer:=0
   restorepointer:=0                                                            'Restore-Zeiger löschen
   datapointer:=0                                                               'Data-Zeiger löschen
   ios.serclose                                                                 'serielle Schnittstelle schliessen
   'serial:=0
   DATA_POKE(1,0)                                                               'erste Data-Zeile suchen, falls vorhanden
   VAR_NR:=0                                                                    'Variablenzähler zurücksetzen
   STR_NR:=0                                                                    'Stringzähler zurücksetzen
   if restorepointer                                                            'DATA-Zeilen vorhanden
      DATA_POKE(0,restorepointer)                                               'Datazeilen in den E-Ram schreiben
   Var_Neu_Platz:=STR_ARRAY

PRI newprog
   speicherende := speicheranfang + 2
   nextlineloc := speicheranfang
   writeendekennung(speicheranfang)
   sp := 0                                                                      'stack loeschen

PRI clearall
   newprog
   clearvars

PRI pushstack                                                                   'Gosub-Tiefe max. 20
   if sp => constant(maxstack-1)
      errortext(12,1)
   stack[sp++] := nextlineloc                                                   'Zeile merken

PRI klammers                                                                    'Arraydimensionen lesen (bis zu 3 Dimensionen)
bytefill(@var_arr,0,3)

if spaces=="("
       tp++
       var_arr[0]:=get_array_value
       var_arr[1]:=wennkomma
       var_arr[2]:=wennkomma
       klammerzu

PRI wennkomma:b
    if spaces==","
          tp++
          b:=get_array_value

PRI get_array_value|tok,c,ad                                                    'Array-Koordinaten lesen und zurückgeben
   tok := spaces                                                                'Zeichen lesen
   tp++
   case tok

      "a".."z","A".."Z":                                                        'Wert von Variablen a-z
          ad:=readvar_name(tok)
          c:=fl.ftrunc(varis_neu(ad,0,0,0,0,0,VAR_TBL))                         'pos,wert,r/w,x,y,z
          return c                                                              'und zurueckgeben
      "#","%","0".."9":                                                         'Zahlenwerte
          --tp
          c:=fl.ftrunc(getAnyNumber)
          return c

obj '******************************************STRINGS*****************************************************************************************************************************
con'************************************** neuer Versuch langer Variablennamen ****************************************************************************************************
pri readvar_name(c):varname                                             'Variablennamen lesen und Typ zurückgeben
    varname:=0
    varname:=fixvar(c)                                                  '1.Zeichen in Großbuchtaben umwandeln und nach links schieben
    c:=spaces
    if isvar(c)
       varname+=(fixvar(c)+1)*26                                        '2.Zeichen ist ein Buchstabe
    elseif isnum(c)
       varname:=701+fixnum(c)+(10*varname)                              '2.Zeichen ist eine Zahl
    'weitere Zeichen überspringen
    repeat
           if isvar(c)                                                  'Buchstaben überspringen
              c:=skipspaces
           elseif isnum(c)                                              'Zahlen überspringen
              c:=skipspaces
           else
              quit
    return varname

PRI varis_neu(var_name,wert,rw,x,y,z,tab):adress|c,ad ,tb                                                    'Arrayverwaltung im eRam (Ram_Start_Adresse,Buchstabe, Wert, lesen oder schreiben,Arraytiefenwert 0-255)
    adress:=vari_adr_neu(var_name,x,y,z,tab)
    tb:=0
    if tab==VAR_TBL
       tb:=1
    if rw
         if adress<STR_ARRAY                                                                                  'existiert die Variable noch nicht, wird sie angelegt und ein Feld von 11 Einträgen angelegt
            ad:=tab+(var_name*8)                                                                              'da die Grunddimensionierung 10 (11 Einträge ) ist
            Felddimensionierung(var_name,tb,ios.ram_rdbyte(ad+4),ios.ram_rdbyte(ad+5),ios.ram_rdbyte(ad+6))
            adress:=vari_adr_neu(var_name,x,y,z,tab)
         if tab==STR_TBL
            stringfunc(1,adress)
         else
            ios.ram_wrlong(wert,adress)                                                    'Array schreiben
    else
         ifnot adress
               if tab==STR_TBL
                  return
               else
                  return 0
         else
            if tb
               c:=ios.ram_rdlong(adress)                                                      'Array lesen
               return c

pri vari_adr_neu(n,x,y,z,tab):adress|ad,adr,ln                                                 'adresse der numerischen Variablen im Ram
     ad:=tab+(n*8)
     adr:=ios.ram_rdlong(ad)
     if tab==VAR_TBL
        ln:=4
     else
        ln:=linelen
     adress:=scandimension_neu(adr,ln,x,y,z,ios.ram_rdbyte(ad+4),ios.ram_rdbyte(ad+5),ios.ram_rdbyte(ad+6))

PRI scandimension_neu(startpos,laenge,x,y,z,varx,vary,varz) :Position        'Überprüfung auf Dimensionswerte und Feldpositionsberechnung
    if x>varx+1 or y>vary+1 or z>varz+1
       errortext(16,1)
   'Feldposition im Ram    y-Position   x-Position       z-Position
    Position:=startpos+((varx+1)*y*laenge)+(x*laenge)+((varx+1)*(vary+1)*laenge*z)

con '************************************* Stringverarbeitung *********************************************************************************************************************
PRI getstr:a|nt,b,str ,f                                                          'string in Anführungszeichen oder Array-String einlesen
    a:=0
    nt:=spaces
    bytefill(@font,0,STR_MAX)
    case nt
         quote:
              scanfilename(@font,0,quote)                                       'Zeichenkette in Anführungszeichen
         152: skipspaces
              a:=expr(1)                                                        'Gfile mit Parameter
              if a>filenumber
                 errortext(3,1)
              b:=(a-1)*13
              a:=DIR_RAM+b                                                      'Adresse Dateiname im eRam
              stringlesen(a)
         163,200,226,229,232:
               skipspaces
               stringfunc2(nt)
         176: skipspaces                                                        'Chr$-Funktion
              a:=klammer(1)
              byte[@font][0]:=a
              byte[@font][1]:=0
         236: stringwiederholung                                                'String$-Funktion
         234: skipspaces
              Bus_Funktionen                                                    'Stringrückgabe von XBUS-Funktion
         "a".."z","A".."Z":                                                     'konvertiert eine Variable a(0..255)-z(0..255) in einen String
              skipspaces
              f:=readvar_name(nt)
              if dollar
                 klammers
                 b:=varis_neu(f,0,0,var_arr[0],var_arr[1],var_arr[2],STR_TBL)   'Stringarray lesen
                 stringlesen(b)
              else
                 klammers
                 b:=varis_neu(f,0,0,var_arr[0],var_arr[1],var_arr[2],VAR_TBL)   'Arrayvariable aus eRam holen
                 str:=zahlenformat(b)

                 bytemove(@font,str,strsize(str))

Pri Input_String
       getstr
       bytemove(@f0,@font,strsize(@font))                                       'string nach f0 kopieren

pri Get_Input_Read(anz):b |nt,c,tb,ad                                                   'Eingabe von gemischten Arrays für INPUT und FREAD

                b:=0
                nt:=spaces
                c:=0
                bytefill(@prm_typ,0,10)

             repeat
                  '***************** Zahlen ***************************************
                  if isvar(nt)
                     skipspaces
                     ad:=readvar_name(nt)
                     if dollar
                        tb:=STR_TBL
                        c:=1
                     else
                        tb:=VAR_TBL
                     klammers
                     prm[b]:=varis_neu(ad,0,1,var_arr[0],var_arr[1],var_arr[2],tb)
                     prm_typ[b++]:=c
                     c:=0
                     if spaces==","
                        nt:=skipspaces
                     else
                        quit
                     if anz==b
                        quit
                  '************************
                  else
                     errortext(19,1)


PRI clearstr
    bytefill(@font,0,STR_MAX)
    bytefill(@str0,0,STR_MAX)

PRI stringfunc(pr,v) | a7,identifier                                              'stringfunktion auswaehlen
   identifier:=0
   a7:=v

   getstr                                                                        'welche Funktion soll ausgeführt werden?

   bytemove(@str0,@font,strsize(@font))
   identifier:=spaces                                                           'welche Funktion kommt jetzt?
   if identifier==43                                                            'Pluszeichen?
      skipspaces
      stringfunktionen(a7,identifier,pr)
   else                                                                         'keine Funktion dann
      stringschreiben(a7,0,@str0,pr)'-1                                          'String schreiben

PRI stringschreiben(adre,chr,strkette,pr) | c9,zaehler
    zaehler:=0

    case pr
         0:if chr>0
              ios.printchar(chr)
           else
              ios.print(strkette)

         1:if chr==0
              repeat strsize(strkette)
                    zaehler++
                    c9:= byte[strkette++]
                    if zaehler=<linelen-1
                       ios.ram_wrbyte(c9,adre++)
                    else
                       quit
           else
              ios.ram_wrbyte(chr,adre++)                                        'chr-Funktion
           ios.ram_wrbyte(0,adre++)                                             'null schreiben fuer ende string
         2:ios.sdputstr(strkette)                                               'auf SD-Card schreiben
    clearstr                                                                    'stringpuffer löschen
    return adre

PRI stringfunktionen(a,identifier,pr)                                           'Strings addieren
     repeat
          if identifier==43
                '************* funktioniert ******************                                                                                '+ Zeichen Strings addieren
                getstr
                if (strsize(@str0)+strsize(@font))<linelen-1
                   bytemove(@str0[strsize(@str0)],@font,strsize(@font))            'verschiebe den String in den Schreibstring-Puffer
                   identifier:=spaces
                   skipspaces
                else
                   quit
          else
             quit
     stringschreiben(a,0,@str0,pr)'-1                                          'keine Zeichen mehr String schreiben

PRI stringwiederholung|a,b                                                      'String$-Funktion
    skipspaces
    klammerauf
        a:=expr(1)                                                              'anzahl wiederholungen
        komma
        getstr
    klammerzu
    bytefill(@strtmp,0,STR_MAX)                                                 'Stringpuffer löschen
    bytemove(@strtmp,@font,strsize(@font))                                      'String, der wiederholt werden soll merken
    bytefill(@font,0,STR_MAX)                                                   'Stringpuffer löschen
    b:=0
    repeat a
        if b>STR_MAX
           byte [@font][STR_MAX-1]:=0
           quit
        bytemove(@font[b],@strtmp,strsize(@strtmp))                             'Anzahl a Wiederholungen in Stringpuffer schreiben
        b:=strsize(@font)

PRI stringfunc2(function)|a8,b8,c8,a,b                                          'die Stringfunktionen (left, right, mid,upper, lower)

    klammerauf
          getstr                                                                'String holen
          a8:=strsize(@font)
          if function==200 or function==226 or function==229
             komma
             b8:=expr(1)                                                        'anzahl zeichen fuer stringoperation
             if function==229                                                   'midstr
                komma
                c8:=expr(1)
    klammerzu

   case function
        200:a:=0                                                                'left
                b:=b8
        229:a:=b8-1                                                             'midstr
                b:=c8
        226:a:=a8-b8                                                            'right
                b:=b8
        232:charactersUpperLower(@font,0)                                       'upper
                return
        163:charactersUpperLower(@font,1)                                       'lower
                return

        other:
             errortext(3,1)

   bytemove(@font,@font[a],b)
   byte[@font][b]:=0

PRI charactersUpperLower(characters,mode) '' 4 Stack Longs

'' ┌───────────────────────────────────────────────────────────────────────────┐
'' │ Wandelt die Buchstaben in Groß (mode=0) oder Klein(mode=1) um.            │
'' └───────────────────────────────────────────────────────────────────────────┘

  repeat strsize(characters--)

    result := byte[++characters]
    if mode
       if((result > 64) and (result < 91))                                      'nur A -Z in Kleinbuchstaben
          byte[characters] := (result + 32)
    else
       if(result > 96)                                                          'nur a-z in Großbuchstaben
          byte[characters] := (result - 32)


PRI stringlesen(num) | p,i
    i:=0
    repeat while p:=ios.ram_rdbyte(num++)                                       'string aus eram lesen und in @font schreiben
          byte[@font][i++]:=p
    byte[@font][i]:=0
    return num

PUB strpos (searchAddr,strAddr,offset)| searchsize                              'durchsucht strAddr nach auftreten von searchAddr und gibt die Position zurück
  searchsize := strsize(searchAddr)
  repeat until offset  > strsize(strAddr)
    if (strcomp(substr(strAddr, offset++, searchsize), searchAddr))             'if string search found
        return offset
  return 0
PUB substr (strAddr, start, count)                                              'gibt einen Teilstring zurück von start mit der Anzahl Zeichen count
  bytefill(@strtmp, 0, STR_MAX)
  bytemove(@strtmp, strAddr + start, count)                                     'just move the selected section
  return @strtmp
obj '*********************************************** TIMER-FUNKTIONEN ***********************************************************************************************************
con' *********************************************** Verwaltung der acht Timer und 4 Counter ************************************************************************************
PRI timerfunction:b|a,c,function
       function:=spaces
       skipspaces

       case function                                                            'Timerfunktionen mit Werterueckgabe
               "c","C":'isclear?                                                'Timer abgelaufen?
                       a:=klammer(1)'expr
                       return TMRS.isclr(a-1)
               "r","R":'read                                                    'Timerstand abfragen
                          a:=klammer(1)'expr
                          return TMRS.read(a-1)                                 'Timer 1-12 lesen

               "s","S":'timerset                                                'Timer 1-12 setzen

                          klammerauf
                          a:=expr(1)
                          komma
                          c:=expr(1)
                          klammerzu
                          TMRS.set(a-1,c)

               other:
                       errortext(3,1)'@syn

con '********************************* Befehle, welche mit Printausgaben arbeiten *************************************************************************************************
PRI factor | tok, a,b,c,d,e,g,f,fnum                                            'Hier werden nur Befehle ohne Parameter behandelt
   tok := spaces
   e:=0
   tp++
   ifnot gmode
      case tok
          167:'Window
              return fl.ffloat(ios.get_window)
          219:'Player
               c:=expr(1)
               if c==1
                  a:=Kollisionserkennung
                     if a==0
                        a:=ios.get_collision
               else
                  a:=Item_sammeln

               return fl.ffloat(a)

          221:'MGET
               b:=klammer(1)
               return fl.ffloat(lookup(b:ios.mousex,ios.mousey,ios.mousez))


          225:'MB
              a:=klammer(1)
              b:=ios.mouse_button(a)
              if b>0 and b<BUTTON_CNT and a==0
                 Buttonpress_on(b)                                                  'Buttonpress-Effekt
              return fl.ffloat(b)

   case tok
      "(":
         a := expr(0)
         if spaces <> ")"
            errortext(1,1)
         tp++
         return a

      "a".."z","A".."Z":
             fnum:=readvar_name(tok)
             c:=getvar(fnum,VAR_TBL)
             return c                                                              'und zurueckgeben

      152:'GFile                                                                'Ausgabe Anzahl, mit Dir-Filter gefundener Dateieintraege
          ifnot spaces
                return fl.ffloat(filenumber)


      160:'gdmp playerposition
           return fl.ffloat(ios.sid_dmppos)


      164:'COMP$
          klammerauf
          Input_String
          bytemove(@str0,@f0,strsize(@f0))                                      'in 2.Puffer merken
          komma
          Input_String
          c:=strcomp(@str0,@f0)                                                 'beide vergleichen -1=gleich 0=ungleich
          klammerzu
          return fl.ffloat(c)

      165:'LEN
          klammerauf
          Input_String
          a:=strsize(@f0)
          klammerzu
          return fl.ffloat(a)

      170:'SYS
           a:=klammer(1)
           case a
                0:b:=userptr-speicherende   'freier Speicher
                1:b:=speicherende-2         'benutzter Speicher
                2:b:=USER_RAM-STR_ARRAY     'freier Variablenspeicher
                3:b:=Var_Neu_Platz-STR_ARRAY'benutzter Variablenspeicher
                4:return version            'Version
                5:b:=Big_Font               'Fontsatz?
                6:b:=gmode                  'Grafikmodus?
                7:b:=gmodexw[gmode]         'x-Pixel
                8:b:=gmodeyw[gmode]         'y-Pixel
                9:b:=GmodeLine[gmode]+1     'Spalten
                10:b:=Gmodey[gmode]+1       'Zeilen
                22:b:=VAR_NR                'Variablenanzahl
                23:b:=STR_NR                'Stringanzahl
                30:b:=ios.admgetcogs        'freie Cogs in Administra
                31:b:=ios.belgetcogs        'freie Cogs in Bella
                32:b:=ios.reggetcogs        'freie Cogs in Regnatix

           return fl.ffloat(b)


      172:'PTest
          if gmode
             klammerauf
             param(1)
             klammerzu
             return fl.ffloat(ios.ptest(prm[0],prm[1]))


      173:'GEXTY                                                                'Cursorposition y lesen
          a:=klammer(1)
          if a==1
             return fl.ffloat(ios.gety)
          elseif a==2
             return fl.ffloat(ios.get_actor_pos(2))                             'Playerposition

      182: ' FILE
           return fl.ffloat(ios.sdgetc)

      183:'JOY
          a:=klammer(1)
          return fl.ffloat(ios.Joy(3+a))

      193:'GETX                                                                 'Cursorposition x lesen
          a:=klammer(1)
          if a==1
             return fl.ffloat(ios.getx)
          elseif a==2
             return fl.ffloat(ios.get_actor_pos(1))                             'Playerposition

      204:'gtime
          a:=klammer(1)
          return fl.ffloat(lookup(a:ios.getHours,ios.getMinutes,ios.getSeconds))

      205:'gdate
          a:=klammer(1)
          return fl.ffloat(lookup(a:ios.getDate,ios.getMonth,ios.getYear,ios.getday))

      207: 'Port
          return fl.ffloat(Port_Funktionen)

      211:'FN
           a:=spaces
           if isvar(a)
              skipspaces
              a:=fixvar(a)                                                      'Funktionsvariable
              c:=FUNC_RAM+(a*56)                                                'Adresse der Funktion im E-Ram 4Variablen(x4Bytes)+34Zeichen String=50 Bytes (+6 reserve)
              klammerauf
              b:=expr(0)                                                        'Operandenwert der Operandenvariablen
              d:=ios.ram_rdlong(c)                                              'Adresse der Operandenvariablen aus Funktionsram lesen
              ios.ram_wrlong(b,d)                                               'Operandenwert an die Adresse der Operanden-Variablen schreiben
              g:=c
              repeat 3
                 g+=4
                 f:=ios.ram_rdlong(g)                                           'Adresse des nächsten Operanden
                 if spaces==","
                    skipspaces
                    e:=expr(0)                                                  'nächster Variablenwert
                    if f=>STR_ARRAY                                             'Variable nicht null, also vorhanden
                       ios.ram_wrlong(e,f)                                      'Variablenwert schreiben, wenn vorhanden
                    else
                       errortext(25,1)                                          'Variable zuviel
                 else
                    quit
              klammerzu
              stringlesen(c+16)                                                 'Funktionszeile aus dem E-Ram lesen und nach @font schreiben
              tp := @font                                                       'Zeile nach tp übergeben
              d:=expr(0)                                                        'Funktion ausführen
              return d                                                          'berechneter Wert wird zurückgegeben
           else
              errortext(25,1)

      212:'inkey
           return fl.ffloat(ios.inkey)

      215:'PEEK
          a:=expr(1)                                                            'adresse
          komma
          b:=expr(1)                             '1-byte, 2-word, 4-long
          return fl.ffloat(lookup(b:ios.ram_rdbyte(a),ios.ram_rdword(a),0,ios.ram_rdlong(a)))


      233:'asc
           klammerauf
           b:=spaces
           if isvar(b)
              skipspaces
              c:=readvar_name(b)
              if dollar
                 a:=getvar(c,STR_TBL)
                 c:=fl.ffloat(ios.ram_rdbyte(a))
           elseif b==quote
                  c:=fl.ffloat(skipspaces) 'Zeichen
                  skipspaces                     'Quote überspringen
                  skipspaces
           klammerzu
           return c

      234:'Bus-Funktionen
          return Bus_Funktionen

      239:'timer
           return fl.ffloat(timerfunction)
      240:'GATTR
           a:=klammer(1)
           return fl.ffloat(ios.sdfattrib(a))


      241:'VAL
           klammerauf
           Input_String
           fnum:=fs.StringToFloat(@f0)
           klammerzu
           return fnum
      243:'COM
           return Comfunktionen
      244:'INSTR
          klammerauf
          Input_String
          bytefill(@str0,0,STR_MAX)
          bytemove(@str0,@f0,strsize(@f0))                                      'in 2.Puffer merken
          komma
          Input_String
          c:=strpos(@str0,@f0,0)                                                'beide vergleichen -1=gleich 0=ungleich
          klammerzu
          return fl.ffloat(c)

      245:'ABS
           return fl.fabs(klammer(0))
      246:'sin
           return fl.sin(klammer(0))
      247:'cos
           return fl.cos(klammer(0))
      248:'tan
           return fl.tan(klammer(0))
      249:'ATN
           return fl.ATAN(klammer(0))
      250:'LN
           return fl.LOG(klammer(0))
      251:'SGN
           a:=klammer(0)                                                       'SGN-Funktion +
            if a>0
               a:=1
            elseif a==0
                   a:=0
            elseif a<0
                   a:=-1
            a:=fl.ffloat(a)
           return a
      252:'SQR
           return fl.fsqr(klammer(0))
      253:'EXP
           return fl.exp(klammer(0))

      254:'INT
           return fl.ffloat(fl.FTrunc(klammer(0)))                                'Integerwert
'****************************ende neue befehle********************************

      139: ' RND <factor>
           a:=klammer(1)
           a*=1000
           b:=((rv? >>1)**(a<<1))
           b:=fl.ffloat(b)
           return fl.fmul(fl.fdiv(b,fl.ffloat(10000)),fl.ffloat(10))

      "-":
          return fl.FNeg(factor)                                                 'negativwert ->factor, nicht expr(0) verwenden

      174:'Pi
          return pi

      "#","%", quote,"0".."9":
         --tp
         return getAnyNumber

      167,219,221,225: errortext(44,1)'Fehler, wenn mode>0

      other:

           errortext(1,1)

pri getvar(name,tbl):ad                                                         'ermitteln der Variablen-Adresse
    klammers
    bytemove(@var_tmp,@var_arr,3)
    ad:=varis_neu(name,0,0,var_tmp[0],var_tmp[1],var_tmp[2],tbl)

Con '******************************************* Operatoren *********************************************************************************************************************
PRI bitTerm | tok, t
   t := factor

   repeat
      tok := spaces
      if tok == "^"                                                             'Power  y^x   y hoch x entspricht y*y (x-mal)
         tp++
         t := fl.pow(t,factor)
      else
         return t

PRI term | tok, t,a
   t := bitTerm
   repeat
      tok := spaces
     if tok == "*"
           tp++
           t := fl.FMUL(t,bitTerm)                                              'Multiplikation
     elseif tok == "/"
        if byte[++tp] == "/"
           tp++
           t := fl.FMOD(t,bitTerm)                                              'Modulo
        else
           a:=bitTerm
           if a<>0
              t  :=fl.FDIV(t,a)                                                 'Division
           else
              errortext(35,1)
     else
        return t

PRI arithExpr | tok, t
   t := term
   repeat
      tok := spaces
      if tok == "+"
         tp++
         t := fl.FADD(t,term)                                                   'Addition
      elseif tok == "-"
         tp++
         t := fl.FSUB(t,term)                                                   'Subtraktion
      else
         return t

PRI compare | op,a,c,left,right,oder

   a := arithExpr
   op:=left:=right:=oder:=0
   'spaces
   repeat
      c := byte[tp]

      case c
         "<": op |= 1                                   '>
              if right                                  '><
                 op|=64
              if left                                   '>>
                 op|=128
              left++
              tp++
         ">": op |= 2                                   '<
              if right                                  '<<
                 op|=64
              right++
              tp++
         "=": op |= 4
              tp++
         "|": op |= 8                                   '|
              if oder                                   '||
                 op|=32
              oder++
              tp++
         "~": op |=16
              tp++
         "&": op |=16                                   '&
              tp++
         other: quit


   case op
      0: return a
      1: return a<arithExpr
      2: return a > arithExpr
      3: return a <> arithExpr
      4: return a == arithExpr
      5: return a =< arithExpr
      6: return a => arithExpr
      8: return fl.ffloat(fl.ftrunc(a)| fl.fTrunc(arithExpr)) 'or
      16:return fl.ffloat(fl.ftrunc(a)& fl.fTrunc(arithExpr)) 'and
      17:return fl.ffloat(fl.ftrunc(a)<- fl.fTrunc(arithExpr))'rotate left
      18:return fl.ffloat(fl.ftrunc(a)-> fl.fTrunc(arithExpr))'rotate right
      40:return fl.ffloat(fl.ftrunc(a)^ fl.fTrunc(arithExpr)) 'xor
      66:return fl.ffloat(fl.ftrunc(a)>> fl.fTrunc(arithExpr))'shift right
      67:return fl.ffloat(fl.ftrunc(a)>< fl.fTrunc(arithExpr))'reverse
      129:return fl.ffloat(fl.ftrunc(a)<< fl.fTrunc(arithExpr))'shift left
      other:errortext(13,1)


PRI logicNot | tok
   tok := spaces
   if tok == 149 ' NOT
      tp++
      return not compare
   return compare

PRI logicAnd | t, tok
   t := logicNot
   repeat
      tok := spaces
      if tok == 150 ' AND
         tp++
         t := t and logicNot
      else
         return t

PRI expr(mode) | tok, t
   t := logicAnd
   repeat
      tok := spaces
      if tok == 151 ' OR
         tp++
            t := t or logicAnd
      else
         if mode==1                                                             'Mode1, wenn eine Integerzahl gebraucht wird
            t:=fl.FTrunc(t)
         return t

PRI SID_SOUND(cmd)|a,b
    klammerauf
    case cmd
          "N":'NT
             param(1)
             a:=prm[0]
             b:=prm[1]
             if b
                ios.sid1_noteon(a,b)
             else
                ios.sid1_noteOff(a)

          "V":'vol
            volume:=expr(1)
            ios.sid1_setVolume(volume)

          "A":'ADSR
             param(4)
             ios.sid1_setADSR(prm[0],prm[1],prm[2],prm[3],prm[4])

          "W":'WAVE
             a:=expr(1)
             komma
             b:=expr(1)
             b+=3
             b:=1<<b
             ios.sid1_setWaveform(a,b)

          "F":'FILTER
             param(2)
             ios.sid1_setFilterType(prm[0],prm[1],prm[2])

          "M":'FMASK
             param(2)
             ios.sid1_setFilterMask(prm[0],prm[1],prm[2])
          "R":'RGMOD
             param(2)
             ios.sid1_enableRingmod(prm[0],prm[1],prm[2])
          "C":'CUT
             a:=expr(1)
             komma
             b:=expr(1)
             ios.sid1_setCutoff(a)
             ios.sid1_setResonance(a)
          "P":'PWM
             param(1)
             ios.sid1_setPWM(prm[0],prm[1])
          "S":'SYNC
             param(2)
             ios.sid1_enableSynchronization(prm[0],prm[1],prm[2])

          other:errortext(25,1)

    klammerzu



con '*************************************** Dateinamen extrahieren **************************************************************************************************************
PRI scanFilename(f,mode,kennung):chars| c

   chars := 0
   if kennung==quote
      tp++                                                                      'überspringe erstes Anführungszeichen
   repeat while (c := byte[tp++]) <> kennung
      if chars++ < STR_MAX                                                      'Wert stringlänge ist wegen Stringfunktionen
         if mode==1                                                             'im Modus 1 werden die Buchstaben in Grossbuchstanben umgewandelt
            if c>96
               c^=32
         byte[f++] := c
   byte[f] := 0
con '*************************************** Programmlisting ausgeben **************************************************************************************************************

PRI listout|a,b,c,d,e,f,rm,states,fr,qs,ds,rs,blau,gruen,orang,rot,hellblau,grau,lila,gelb,weiss,schwarz

               if gmode==1
                  weiss:=0'7
                  blau:=1
                  gruen:=4
                  orang:=10
                  rot:=8
                  hellblau:=5
                  grau:=13
                  lila:=9
                  gelb:=12
                  schwarz:=3'0
               else
                  weiss:=black
                  blau:=blue
                  gruen:=dark_green
                  orang:=dark_orange
                  rot:=red
                  hellblau:=light_blue
                  grau:=dark_grey
                  lila:=purple
                  gelb:=teal
                  schwarz:=orange

               b := 0                                                                                    'Default line range
               c := 65535                                                                                'begrenzt auf 65535 Zeilen
               f :=0                                                                                     'anzahl Zeilen
               qs:=ds:=0
               if spaces <> 0                                                                            'At least one parameter
                  b := c := expr(1)

                  if spaces == ","
                     skipspaces
                     c := expr(1)

               a := speicheranfang
               repeat while a < speicherende-2
                  d := ios.ram_rdword(a)                                                                 'zeilennummer aus eram holen
                  e:=a+2                                                                                 'nach der Zeilennummer adresse der zeile
                  if d => b and d =< c                                                                   'bereich von bis zeile
                                                                                                         'nur im Modus0 wird farbig ausgegeben
                     ios.printBoxColor(0,weiss,schwarz)
                     ios.printdec(d)                                                                     'zeilennummer ausgeben
                     ios.printchar(" ")                                                                  'freizeichen
                     rs:=0
                     repeat while rm:=ios.ram_rdbyte(e++)                                                'gesuchte Zeilen ausgeben
                            if rm=> 128
                               rm-=128
                                  ios.printBoxColor(0,gruen,weiss)
                                  ios.print(@@toks[rm])                                                  'token zurueckverwandeln
                                  if rm<117 and not rm==46                                               'bei math.Funktionen kein Leerzeichen nach dem Tokennamen
                                     ios.printchar(" ")

                            '****************************** Farbausgabe *********************************************************************
                                  case rm
                                       25,30,39,79,111,115       : states:="F"                           'Befehlsoptionen haben die gleiche Farbe, wie der Grundbefehl
                                                                   ds:=rs:=0


                                       40                        :'DATA
                                                                   ds:=1
                                                                   fr:=orang
                                       7                         : 'REM
                                                                   rs:=1
                                                                   fr:=gelb
                                       other                     : ds:=rs:=0
                                                                   states:=0
                            else
                               if ds<1 and rs<1
                                     case rm
                                             32:                    states:=0
                                          quote:                    if qs                                    'Texte in Anführungszeichen sind rot
                                                                       qs:=0
                                                                    else
                                                                       qs:=1
                                                                       fr:=rot
                                          "$"  :                    fr:=rot                                  'Strings sind rot
                                          "0".."9","."    :         ifnot qs                                 'numerische Werte sind blau
                                                                          ifnot states=="V"                  'Zahlen in Variablennamen sind blau
                                                                                fr:=blau
                                                                          states:=0
                                          "%","#"         :         ifnot qs                                 'numerische Werte sind blau
                                                                          states:="N"
                                                                          fr:=blau
                                          44,58,59,"(",")","[","]": ifnot qs                                 'Befehlstrennzeichen (:) ist hellblau
                                                                          fr:=hellblau
                                                                          states:=0
                                          "a".."z","A".."Z":                                                  'Variablen sind lila
                                                                    ifnot qs
                                                                          fr:=lila

                                                                          ifnot states=="F"
                                                                              if states=="N"
                                                                                 fr:=blau
                                                                              else
                                                                                 states:="V"
                                                                          else                                'Befehlsoptionen sind gruen
                                                                              fr:=gruen
                                          other            :        ifnot qs                                  'Operatoren sind grau
                                                                          fr:=grau
                                                                          states:=0


                            '****************************** Farbausgabe *********************************************************************
                               'if gmode<2 or gmode>3                                                   'nur im Modus 0 und 1 wird farbig ausgegeben
                               ios.printBoxColor(0,fr,weiss)
                               ios.printchar(rm)                                                        'alle anderen Zeichen ausgeben

                     ios.printnl                                                                         'naechste Zeile
                     states:=0
                     f++                                                                                 'Zeilenanzahl
                     if f==12                                                                            'nach 10 Zeilen Ausgabe pausieren
                        ios.set_func(6,Cursor_Set)                                                       'Cursor blinkt schneller
                        if ios.keywait==27                                                               ' mit ESC raus
                           ios.set_func(cursor,Cursor_Set)
                           quit
                        else
                           f:=0
                           ios.set_func(cursor,Cursor_Set)

                  else
                     e:=ios.ram_keep(e)'+1                                                               'zur nächsten zeile springen

                  a := e                                                                                 'adresse der naechsten Zeile
  farbe:=orange
  hintergr:=black
  ios.printBoxColor(0,farbe,hintergr)
con '************************************ Eingabezeile sichern/wiederherstellen für Input-Funktion *************************************************************************
pub Backup_Restore_line(m)                                             'fertigt eine Kopie der aktuellen Befehlszeile an bzw. schreibt sie zurück
    if m
        tp_back:=tp                                                    'Kopie der Adresse,der aktuellen Position
        bytemove(@strtmp,@tline,strsize(@tline))                       'Kopie der Eingabezeile, da im nächsten Schritt überschrieben wird
    else
        bytemove(@tline,@strtmp,strsize(@strtmp))                      'Befehlszeile wieder aus dem Backupspeicher übernehmen
        tp:=tp_back                                                    'Position innerhalb der Zeile zurückschreiben

con '************************************ Laden der Grafik-Mode-Treiber 0-2 ************************************************************************************************
pub Load_Gmode(n)
    mount
    activate_dirmarker(basicmarker)                               'ins Basicverzeichnis
    ifnot ios.sdopen("r",@@Gmodes[n])                       'Treiber vorhanden?
          ios.belload(@@Gmodes[n])
          Mode_Ready                                        'Treiber-bereit-Meldung
    else
          errortext(22,1)
    gmode:=n
    if gmode==0
       loadtile(15)                                      'systemfont laden
    ios.set_func(cursor,Cursor_Set)
    close

con '***************************************** Befehlsabarbeitung ****************************************************************************************************************
PRI texec | ht, nt, restart,a,b,c,d,e,f,h,elsa,fvar,tab_typ


   bytefill(@f0,0,STR_MAX)
   restart := 1
   a:=0
   b:=0
   c:=0
   repeat while restart
      restart := 0
      ht := spaces
      if ht == 0
         return
      skipspaces
      if isvar(ht)                                                              'Variable?
         fvar:=readvar_name(ht)
         if dollar                                                              'String?
            tab_typ:=STR_TBL
         else
            tab_typ:=VAR_TBL
         klammers                                                               'Array? dann arrayfeld einlesen
         bytemove(@var_temp,@var_arr,3)                                         'kopie des Arrayfeldes
         nt := spaces
         if nt == "="
            tp++
            if tab_typ==STR_TBL
               varis_neu(fvar,0,1,var_temp[0],var_temp[1],var_temp[2],tab_typ)
            elseif tab_typ==VAR_TBL
               varis_neu(fvar,expr(0),1,var_temp[0],var_temp[1],var_temp[2],tab_typ)


      elseif ht => 128
          ifnot gmode                                                             'Befehle, die nur im Grafikmodus 0 gültig sind
             case ht

                153:'MAP                                                            Map d=Map anzeigen, MAP w=Map in eram schreiben, Map s=Map auf sd-card schreiben, Map l=Map von sd-laden
                     Map_function

                162:'tload
                   a:=expr(1)
                   a&=15
                   komma
                   if is_string                                                    'test auf String
                      Input_String
                   komma
                   param(1)
                   'b:=prm[0]
                   'c:=prm[1]
                   if (prm[0]*prm[1])>176
                      errortext(16,1)
                   if a==15                                                        'Tileset 15 ist die Mauszeigerdatei
                      LoadTiletoRam(16,@f0,1,1)                                    'Mauszeigerdatei
                   else
                      LoadTiletoRam(a,@f0,prm[0],prm[1])                           'Tile-Datei in den Ram schreiben
                177:'FRAME

                178:'STILE
                    a:=expr(1)
                    if a&15
                       loadtile(a)                                                  'tileset aus eram in bella laden
                    else
                       errortext(16,1)

                179:'Tile
                    param(5)                                                        'nr,farbe1,farbe2,farbe3,x,y
                                                                                    'tileblock-nr aus aktuellem tileset anzeigen
                    ios.displayTile(prm[0],prm[1],prm[2],prm[3],prm[5],prm[4])
                    if mapram==1
                       tilecounter++
                       ios.ram_wrword(tilecounter,MAP_RAM)                          'tilecounter in ram schreiben
                       a:=MAP_RAM+8+((prm[4]*6)+(prm[5]*40*6))                      'berechnung der speicheradresse
                       repeat b from 0 to 5
                            ios.ram_wrbyte(prm[b],a++)

                191:'Mouse
                    param(1)
                    prm[0]&=1
                    prm[1]&=255
                    ios.displaymouse(prm[0],prm[1])


                202:'Button
                     Buttons

                224:'MBound
                    param(3)
                    ios.mousebound(prm[0],prm[1],prm[2],prm[3])

                223:'Sprite-Settings
                     spritesettings

                228:'TPIC                                                           'komplettes Tileset anzeigen
                    param(4)                                                        'farbe1,farbe2,farbe3,x,y
                    ios.displaypic(prm[0],prm[1],prm[2],prm[4],prm[3],ytiles[aktuellestileset],xtiles[aktuellestileset])


                242:'PLAYXY  Spielerfigur bewegen
                    a:=expr(1)
                    playerposition(a)

          else


          case ht
             128: 'IF THEN ELSE
                a := expr(0)
                elsa:=0                                                          'else-marker loeschen -> neue if then zeile
                if spaces <> 129
                   errortext(14,1)
                skipspaces
                if not a                                                         'Bedingung nicht erfuellt dann else marker setzen
                      elsa:=1
                      return
                restart := 1
             238:'ELSE
                 if elsa==1
                    elsa:=0
                    restart := 1

             130: ' INPUT {"<prompt>";} <var> {, <var>}
                 if is_string                                                   'Eingabeprompt-String
                    input_string

                 if spaces <> ";"
                    errortext(18,1)'@syn
                 nt := skipspaces
                 ios.print(@f0)                                                 'Eingabepromt-String ausgeben
                 b:=Get_Input_READ(9)
                 Backup_restore_Line(1)                                         'Backup der aktuellen Zeile
                 if getline(0)==0 and strsize(@tline)>0                         'nur weitermachen, wenn nicht esc-gedrückt wurde und die Eingabezeile größer null war
                    FILL_ARRAY(b,0)                                             'Daten in die entsprechenden Arrays schreiben
                 Backup_restore_line(0)                                         'Restore der aktuellen Zeile

             131: ' PRINT
                a := 0
                repeat
                   nt := spaces
                   if nt ==0 or nt==":"
                      quit
                   case nt

                       152,163,176,236,234,200,226,229,232,quote:stringfunc(0,0) 'Strings
                       204:ios.time                                              'Time-Ausgabe
                           quit
                       184:skipspaces                                            'TAB
                           a:=klammer(1)
                           ios.set_func(a,set_x)

                       235,201:skipspaces
                               a:=klammer(1)
                               d:=a
                               c:=1                                              'Hex-Ausgabe Standard 1 Stelle
                               e:=4                                              'Bin-Ausgabe Standard 4 Stellen
                               repeat while (b:=d/16)>0                          'Anzahl Stellen für Ausgabe berechnen
                                     c++
                                     e+=4
                                     d:=b
                               if nt==235
                                  ios.printhex(a,c)                              'Hex
                               if nt==201
                                  ios.printbin(a,e)                              'Bin

                       other:a:=tp
                             b:=spaces
                             skipspaces
                             fvar:=readvar_name(b)
                             if dollar
                                tp:=a
                                stringfunc(0,0)
                             else
                                tp:=a
                                ios.print(zahlenformat(expr(0)))

                   nt := spaces
                   case nt
                         ";": tp++
                         ",": a:=ios.getx
                              ios.set_func(a+8,set_x)
                              tp++
                         ":",0:ios.printchar(fReturn)
                               quit


             216: 'ON Gosub,Goto
                  ongosub:=0
                  ongosub:=expr(1)
                  if spaces < 132 or spaces >133                                 'kein goto oder gosub danach
                     errortext(1,1)
                  if not ongosub                                                 'on 0 gosub wird ignoriert (Nullwerte werden nicht verwendet)
                       return
                  restart := 1

             132, 133: ' GOTO, GOSUB
                e:=0
                a:=expr(1)
                if ongosub>0
                   e:=1
                   repeat while spaces=="," and e<ongosub
                          skipspaces
                          e++
                          a := expr(1)
                ongosub:=0
                if a < 0 or a => 65535
                   errortext(2,1)'@ln
                '*************** diese routine verhindert,das bei gleichen Schleifendurchlaeufen immer der gesammte Speicher nach der Zeilennummer durchsucht werden muss ******
                if gototemp<>a                                                   'sonst zeilennummer merken fuer naechsten durchlauf
                   gotobuffer:=findline(a)                                       'adresse merken fuer naechsten durchlauf
                   gototemp:=a
                if ht==133
                   pushstack
                nextlineloc := gotobuffer

                '***************************************************************************************************************************************************************

             134: ' RETURN
                if sp == 0
                   errortext(15,1)
                nextlineloc := stack[--sp]

             135,168: ' REM,DATA
                    repeat while skipspaces

             136: ' NEW
                ios.ram_fill(0,$20000,0)
                clearall

             137: ' LIST {<expr> {,<expr>}}
                  Listout

             138: ' RUN
                   clearvars                                                     'alle variablen loeschen
                   ios.clearkey                                                  'Tastaturpuffer löschen

             140: ' OPEN " <file> ", R/W/A
                 Input_String
                 if spaces <> ","
                    Errortext(20,1)'@syn
                 d:=skipspaces
                 tp++
                 mount
                 if ios.sdopen(d,@f0)
                    errortext(22,1)
                 fileOpened := true

             141: 'FREAD <var> {, <var> }
                 b:=Get_Input_Read(9)
                 repeat                                                          'Zeile von SD-Karte in tline einlesen
                      c := ios.sdgetc
                      if c < 0
                         errortext(6,1)                                          'Dateifehler
                      elseif c == fReturn or c == ios.sdeof                      'Zeile oder Datei zu ende?
                         tline[a] := 0                                           'tline-String mit Nullbyte abschliessen
                         tp := @tline                                            'tline an tp übergeben
                         quit
                      elseif c == fLinefeed                                      'Linefeed ignorieren
                         next
                      elseif a < linelen-1                                       'Zeile kleiner als maximale Zeilenlänge?
                         tline[a++] := c                                         'Zeichen in tline schreiben
                 Fill_Array(b,0)                                                 'Daten in die entsprechenden Arrays schreiben

             142: ' WRITE ...
                b:=0                                                             'Marker zur Zeichenketten-Unterscheidung (String, Zahl)
                repeat
                   nt := spaces                                                  'Zeichen lesen
                   if nt == 0 or nt == ":"                                       'raus, wenn kein Zeichen mehr da ist oder Doppelpunkt auftaucht
                      quit
                   if is_string                                                  'handelt es sich um einen String?
                      input_string                                               'String einlesen
                      b:=1                                                       'es ist ein String
                      stringschreiben(0,0,@font,2)                             'Strings schreiben
                   elseif b==0                                                   'kein String, dann eine Zahl
                      stringschreiben(0,0,zahlenformat(expr(0)),2)             'Zahlenwerte schreiben
                   nt := spaces
                   case nt
                        ";": tp++                                                'Semikolon bewirkt, das keine Leerzeichen zwischen den Werten geschrieben werden
                        ",":ios.sdputc(",")                                      'Komma schreiben
                            tp++
                        0,":":ios.sdputc(fReturn)                                'ende der Zeile wird mit Doppelpunkt oder kein weiteres Zeichen markiert
                              ios.sdputc(fLinefeed)
                              quit
                        other:errortext(1,1)

             143: ' CLOSE
                fileOpened := false
                close

             144: ' DELETE " <file>
                Input_String
                mount
                if ios.sddel(@f0)
                   errortext(23,1)
                close

             145: ' REN " <file> "," <file> "
                Input_String
                bytemove(@file1, @f0, strsize(@f0))                              'ergebnis vom ersten scanfilename in file1 merken
                komma                                                            'fehler wenn komma fehlt
                Input_String
                mount
                if ios.sdrename(@file1,@f0)                                      'rename durchfuehren
                    errortext(24,1)                                              'fehler wenn rename erfolglos
                close

             146: ' DIR
                 b:=spaces
                 if is_String
                    Input_String
                    komma
                    a:=expr(1)
                    charactersUpperLower(@f0,0)                                 'in Großbuchstaben umwandeln
                    h_dir(dzeilen,a,@f0)
                 elseifnot b
                      h_dir(dzeilen,modus,@ext5)                                 'directory ohne parameter nur anzeigen
                 else
                      param(1)
                      dzeilen:=prm[0]
                      modus:=prm[1]
                      h_dir(dzeilen,modus,@ext5)


             147: ' SAVE or SAVE "<filename>"
                if is_String                                                     'Dateiname? dann normales Speichern
                   Input_String
                   a:=0
                   if spaces==","                                                'speichern ohne zurueckverwandelte token
                      komma
                      a:=expr(1)
                   d:=ifexist(@f0)
                   if d==1                                                       'datei speichern
                         if a==4
                            import(1)                                            'Basic-Programm als Textdatei speichern
                         else
                            binsave
                ios.printnl
                close

             148: ' LOAD or LOAD "<filename>"
                 mount
                 if is_String
                   Input_String
                   a:=0
                   if spaces==","                                                'Autostartfunktion ? (Load"name.ext",1)
                      komma
                      a:=expr(1)
                   if ios.sdopen("R",@f0)                                        'Open requested file
                      errortext(22,1)

                   case a
                        0:newprog                                                  'Programm normal laden -> Rückkehr zum Promt
                          binload(0)
                          Prg_End_Pos

                        1:newprog                                                  'Basic-Datei laden mit Autostart
                          binload(0)
                          clearvars
                        2:                                                         'Append-Funktion (Datei anhängen)
                          binload(speicherende-2)

                        3:   c:=nextlineloc                                        'Replace-Funktion (Dateiteil ersetzen)
                             Prg_End_Pos
                             b:=klammer(1)                                            'Zeilen an Zeilenposition schreiben
                             binload(findline(b))
                             nextlineloc := c                                      'Programmadresse zurückschreiben
                             restart:=1                                            'Programm fortsetzen
                        4:Import(0)                                                'als Textdatei vorliegendes Basic-File importieren

                 close



             154: ' FOR <var> = <expr> TO <expr> {STEP <expr>}                   For-Next Schleifen funktionieren nicht mit arrays als Operanden
                ht := spaces
                if ht == 0
                   errortext(27,1)
                skipspaces
                a := readvar_name(ht) 'fixvar(ht)
                nt:=spaces
                if not isvar(ht) or nt <> "="
                   errortext(19,1)
                skipspaces

                varis_neu(a,expr(0),1,0,0,0,VAR_TBL)
                if spaces <> 155                                                 'TO Save FOR limit
                   errortext(28,1)
                skipspaces
                forLimit[a] := expr(0)
                if spaces == 156 ' STEP                                          'Save step size
                   skipspaces
                   forStep[a] := expr(0)
                else
                   forStep[a] := fl.ffloat(1)                                    'Default step is 1
                forLoop[a] := nextlineloc                                        'Save address of line
                c:=varis_neu(a,0,0,0,0,0,VAR_TBL)
                if forStep[a] < 0                                                'following the FOR
                   b := fl.Fcmp(c,forLimit[a])'c=>forLimit[a]
                else                                                             'Initially past the limit?
                   b := fl.Fcmp(forLimit[a],c)'c=< forLimit[a]
                if not b                                                         'Search for matching NEXT
                   repeat while nextlineloc < speicherende-2
                      curlineno := ios.ram_rdword(nextlineloc)
                      tp := nextlineloc + 2
                      nextlineloc := tp + strsize(tp) + 1
                      if spaces == 157                                           'NEXT <var>
                         nt := skipspaces                                        'Variable has to agree
                         if not isvar(nt)
                            errortext(19,1)
                         skipspaces
                         fvar:=readvar_name(nt)
                         if fvar == a                                            'If match, continue after
                            quit                                                 'the matching NEXT
             157: ' NEXT <var>
                nt := spaces
                if not isvar(nt)
                   errortext(19,1)
                skipspaces
                a := readvar_name(nt)'fixvar(nt)
                c:=varis_neu(a,0,0,0,0,0,VAR_TBL)
                h:=fl.fadd(c,forStep[a])                                         'Increment or decrement the
                varis_neu(a,h,1,0,0,0,VAR_TBL)                                               'neuen wert fuer vars[a]
                if forStep[a] < 0                                                'FOR variable and check for
                   b := fl.Fcmp(h,forLimit[a]) 'h=> forLimit[a]
                else                                                             'the limit value
                   b := fl.Fcmp(forLimit[a],h)
                if b==1 or b==0                                                  'If continuing loop, go to
                   nextlineloc := forLoop[a]                                     'statement after FOR
                   quit

             158:'SID
                 a:=spaces
                 skipspaces
                 SID_SOUND(a&caseBit)

             159:'PLAY
                   if is_string
                      input_string
                      mount
                      if ios.sdopen("R",@f0)
                         errortext(22,1)
                      play:=1
                      ios.sid_sdmpplay(@f0)                                      'in stereo
                   elseif spaces == "0"
                          playerstatus'ios.sid_dmpstop
                          play:=0
                          close
                   elseif spaces == "1"
                          ios. sid_dmppause
             161:'PUT
                  param(2)
                  ios.put(prm[0],prm[1],prm[2])

             166:'READ (DATA)
                  if restorepointer
                     DATA_READ
                  else
                     errortext(5,1)

             167:'Window                                                        'Window funktioniert nur im Modus 0 und 1
                  'if gmode<2
                   Window_Function

             169:'REDEFINE
                 if gmode                                                       'nur Mode1-4
                    param(8)
                    ios.redefine(prm[0],prm[1],prm[2],prm[3],prm[4],prm[5],prm[6],prm[7],prm[8])
                 else
                    errortext(44,1)

             170:'SYS(6) - Grafikmodus ändern
                  a:=klammer(1)
                  if a==5 or a==6
                     if spaces=="="
                        skipspaces
                        b:=expr(1)
                        if a==6
                           if b>-1 and b<3
                              if gmode <> b                                              'Mode nur laden, wenn der aktuelle Grafikmodus ein anderer ist
                                 load_Gmode(b)
                        elseif a==5
                           ios.bigfont(b&1)
                           BIG_Font:=b&1
                     else
                        errortext(1,1)
                  else
                     errortext(3,1)

             171:'RECT
                  param(5)                                                      'x,y,xx,yy,farbe,fill
                  ios.plotfunc(prm[0],prm[1],prm[2],prm[3],prm[4],prm[5],_RECT)      'x,y,xx,yy,set


             175:'RESTORE (DATA)
                 ifnot spaces
                       DATA_POKE(1,0)                                            'erste Data-Zeile suchen, falls vorhanden
                       if restorepointer                                         'DATA-Zeilen vorhanden
                          DATA_POKE(0,restorepointer)                            'Datazeilen in den E-Ram schreiben
                          datapointer:=0
                       else
                          errortext(5,1)                                         'kein DATA, dann Fehler
                 else
                    SET_RESTORE(expr(1))



             180: ' END
                 Prg_End_Pos
                 return

             181: ' PAUSE <expr> {,<expr>}
                   pauseTime := expr(1)
                   waitcnt((clkfreq /1000*pausetime) +cnt)

             182:
              ' FILE = <expr>
                 if spaces <> "="
                    errortext(38,1)'@syn
                 skipspaces
                 if ios.sdputc(expr(1))
                    errortext(30,1)                                              'Dateifehler

             185:'MKFILE    Datei erzeugen
                 Input_String
                 mount
                 if ios.sdnewfile(@f0)
                    Errortext(26,1)'@syn
                 close

             186: ' DUMP <adr>,<zeilen> ,ram-typ
                 'DUMP_Function
                 param(2)
                 ios.dump(prm[0],prm[1],prm[2])
'******************************** neue Befehle ****************************
             190:'pos <expr>,<expr> cursor an position x,y
                 a:=expr(1)
                 komma
                 b:=expr(1)
                 ios.setpos(b,a)

             187:'Color <vordergr>,<hintergr>,<3.Color>(opt)
                 farbe:=expr(1)&255
                 komma
                 hintergr:=expr(1)&255

                 if spaces==44 and gmode==0
                    komma
                    a:=expr(1)&255
                    ios.set_func(a,Thirdcolor)                                   'setzt die dritte Tilefarbe für print
                 ios.printboxcolor(win,farbe,hintergr)

             188: 'CLS
                 ios.printchar(12)

             189:'Renum
                 ifnot spaces
                       renumber(0,speicherende-2,10,10)
                 else
                       param(3)
                       renumber(prm[0],prm[1],prm[2],prm[3])                     'renumber(start,end,step)

             192:'PSET
                 param(2) 'x,y,farbe
                 ios.PlotPixel(prm[0],prm[1],prm[2])


             194:'scrdn
                ifnot gmode
                      param(6)
                      ios.scrolldown(prm[0],prm[1],prm[3],prm[2],prm[5],prm[4],prm[6])
                else
                      param(1)
                      ios.scrolldown_M1(prm[0],prm[1])  'zeilen,rate

             195:'scrup                                                          scrollUp(lines, color, startRow, startColumn, endRow, endColumn,rate)
                ifnot gmode
                      param(6)   'farbe,x,y,xx,yy
                      ios.scrollup(prm[0],prm[1],prm[3],prm[2],prm[5],prm[4],prm[6])
                else
                      param(1)
                      ios.scrollup_M1(prm[0],prm[1])      'zeilen,rate

             196:'CURSOR
                a:=expr(1)
                cursor:=0
                if a
                   cursor:=3
                ios.set_func(cursor,Cursor_Set)

             197:'SCRLFT                                'Bildschirmausschnitt nach 1 Position nach links scrollen
                ifnot gmode
                      param(1)   'y,yy
                      ios.scrollLeft(prm[0],prm[1])
                'else
                '      param(1)
                '      ios.scrollup_M1(prm[0],prm[1])      'zeilen,rate

             198:'stime
                a:=expr(1)
                is_spaces(":",1)
                b:=expr(1)
                is_spaces(":",1)
                c:=expr(1)
                    ios.setHours(a)
                    ios.setMinutes(b)
                    ios.setSeconds(c)

             199:'sdate
                 param(3)
                 ios.setDate(prm[0])
                 ios.setMonth(prm[1])
                 ios.setYear(prm[2])
                 ios.setDay(prm[3])


             203:'Recover                                                        Bildschirmbereich zurückschreiben
                  param(4)
                  if gmode
                     ios.Backup_M1(prm[0],prm[1],prm[2],prm[3],prm[4],0)
                  else
                     ios.Restore_Area(prm[0],prm[1],prm[2],prm[3],prm[4])        'Restore_Area(x,y,xx,yy,adr)

             206:'MKDIR
                 input_string
                 mount
                 if ios.sdnewdir(@f0)
                    errortext(30,1)
                 close

             207:'PORT
                 Port_Funktionen

             208:'POKE                                                           Poke(adresse, wert, byte;word;long)
                 param(2)
                 if prm[2]==1
                    ios.ram_wrbyte(prm[1],prm[0])
                 elseif prm[2]==2
                    ios.ram_wrword(prm[1],prm[0])
                 else
                    ios.ram_wrlong(prm[1],prm[0])

             209:'Circle
                  if gmode
                     param(5)
                     ios.plotfunc(prm[0],prm[1],prm[2],prm[3],prm[4],prm[5],_Circ)  'x,y,r,r2,farbe,fill
                  else
                     errortext(44,1)

             210:'Line
                  param(4) 'x,y,xx,yy,farbe
                  ios.plotfunc(prm[0],prm[1],prm[2],prm[3],prm[4],0,_Line)          'x,y,xx,yy,farbe

             211:'FN
                 nt:=spaces
                 f:=0
                 e:=0
                 if isvar(nt)
                    skipspaces
                    a:=fixvar(nt)                                                'Funktionsvariablen-name (a..z)
                 else
                    errortext(25,1)                                              'Fehler, wenn was Anderes als a..z
                 klammerauf
                 f:=get_input_read(4)                                            'max.4 Variablen
                 klammerzu
                 is_spaces(61,25)   '=
                 is_spaces(91,25)   '[
                 scanfilename(@f0,0,93)                                          'Formelstring extrahieren
                 d:=FUNC_RAM+(a*56)                                              'Adresse der Function im Ram
                 ios.ram_wrlong(prm[0],d)                                        'Variablenadresse in Funktionsram schreiben
                 h:=1
                 e:=d
                 repeat 3
                   e+=4
                   if f>1
                      ios.ram_wrlong(prm[h++],e)                                 'Operandenadressen in den Funktionsram schreiben, wenn vorhanden
                      f--
                   else
                      ios.ram_wrlong(0,e)                                        'nicht benutzte Operanden mit 0 beschreiben

                 stringschreiben(d+16,0,@f0,1)                                   'Formel in den Funktionsram schreiben

             213:'clear
                 clearing

             214:'bye
                 ende                                                            'T-Basic beenden

             217:'BEEP
                 ifnot spaces                                                    'keine parameter
                    ios.sid_beep(0)
                 else
                    a:=expr(1)                                                   'Tonhoehe
                    ios.sid_beep(a)

             218:'BLOAD
                  Input_String
                  mount
                  if ios.sdopen("R",@f0)
                     errortext(22,1)
                  ios.ldbin(@f0)

             219: 'PLAYER
                  Playersettings

             220:'EDIT                                                           'Zeilen editieren bis ESC gedrückt wird
                  editmarker:=1
                  a:=Editline(expr(1))
                  repeat while editmarker
                         a:=Editline(a)
                  return

             222:'Backup                                                          Bildschirmbereich sichern
                  param(4)
                  if gmode
                     ios.Backup_M1(prm[0],prm[1],prm[2],prm[3],prm[4],1)
                  else
                     ios.Backup_Area(prm[0],prm[1],prm[2],prm[3],prm[4])          'Backup_Area(x,y,xx,yy,adr)

             227:'BMP                                                            'BMP funktioniert nur im Mode 2-4
                  if gmode==2'1
                     BMP_FUNCTION
                  else
                     errortext(44,1)

             230:'CHDIR
                 Input_String
                 bytefill(@workdir,0,12)
                 bytemove(@workdir,@f0,strsize(@f0))
                 mount
                 close
                 bytefill(@workdir,0,12)

             231:'box
                 if gmode<2
                    param(5)
                    ios.display2dbox(prm[4],prm[1],prm[0],prm[3],prm[2],prm[5])  'x,y,xx,yy,Farbe,Schatten ja/nein

             234:'XBUS-Funktionen
                  BUS_Funktionen

             239:'timer
                 timerfunction

             237:'Dim
                 repeat
                    b:=0
                    c:=spaces
                    if isvar(c)                                                  'Zahlen-Felddimensionierung
                       skipspaces
                       d:=readvar_name(c)                                        'Namen lesen
                       b:=1
                       if dollar
                          b:=2
                    else
                       errortext(18,1)
                    klammers                                                     'Klammerwerte lesen
                    Felddimensionierung(d,b,var_arr[0],var_arr[1],var_arr[2])    'a-x b-y c-z d-variable e-String oder Zahl}
                    if spaces==","
                       skipspaces
                    else
                       quit

             243:'COM
                 Comfunktionen

             153,162,178,179,191,197,202,223,224,228,242:if gmode
                                                            errortext(44,1)     'Fehler wenn modus>0

'****************************ende neue befehle********************************

      else
          errortext(1,1)'@syn
      if spaces == ":"                                                          'existiert in der selben zeile noch ein befehl, dann von vorn
         restart := 1
         tp++
con'******************************************** Bitmap-Funktionen ****************************************************************************************************************
PRI BMP_FUNCTION|a,b,adr,d                                                        'Bitmap-Lade-und Speicherfunktionen im Mode2-4
    a:=spaces

    skipspaces
    if a=="s" or a=="S"                                                         'speichert den Bildschirm als bmp
       Input_String
       BMP_Save(@f0,1,adr,0)
    else
       if gmode==2'4
          b:=klammer(1)
          if b<1 or b>8
             errortext(16,1)
          b-=1
          adr:=TILE_RAM+(b*gmodepicsize[gmode])                                  'Bildgröße
          case a
               "L","l":if gmode==2'4                                               'Bilder laden funktioniert nur im Modus 4
                          komma
                          Input_String                                           'BMP-Datei in den Speicher laden
                          komma
                          d:=expr(1)
                          bmp_save(@f0,0,adr,d)
               "D","d":ios.belputblk(adr,gmodepicsize[gmode])                    'BMP-Datei im Speicher anzeigen
               "r","R":komma                                                     'Rohdaten aus dem E-Ram auf SD-Karte speichern
                       Input_String
                       bmp_save(@f0,2,adr,d)
               "w","W":komma                                                     'Rohdaten in den E-Ram schreiben
                       input_String
                       bmp_save(@f0,3,adr,d)
               other:
                       errortext(1,1)
       else
          errortext(44,1)                                                        'Laden und Display nur im Mode4 Treiber

PRI BMP_Save(name,m,adr,d)|a
    mount

    if m==1 or m==3
       a:=ifexist(name)
       if a==0 or a==2                                                          'Abbruch Dateioperation
             return
    else
       if ios.sdopen("R",name)
          errortext(6,1)
    if m==2
       ios.sdxgetblk(adr,gmodepicsize[gmode])
    if m==3
       ios.sdxputblk(adr,gmodepicsize[gmode])                       'Bild als Rohdaten speichern
    if m==1 or m==0
       ios.SaveLoadBmp(m,adr,gmodexw[gmode],gmodeyw[gmode],gmodeoffset[gmode],d)
       'sysbeep                                                                  'Break in Line ausgeben
    close

con'******************************************* DATA-Funktion ********************************************************************************************************************
PRI DATA_READ|anz                                                               'READ-Anweisungen interpretieren, Data-Werte lesen und an die angegebenen Variablen verteilen
    anz:=0
    anz:=Get_input_read(9)                                                      'Array Adressen berechnen
    FILL_ARRAY(anz,1)                                                           'Arrays mit Daten füllen

pri data_write(adr,art)|adresse,a,c,i,f                                         'schreibt die Data-Anweisungen in die entsprechenden Variablen
    adresse:=DATA_RAM+datapointer
    a:=DATA_LESEN(adresse)
    datapointer:=a-DATA_RAM
    i:=0
    f:=strsize(@font)
    if f<1
       errortext(21,1) 'Out of Data Error
    if art==0
       repeat f                                                                 'String aus Data-Puffer lesen
              c:=byte[@font][i++]
              ios.ram_wrbyte(c,adr++)                                           'und nach String-Array schreiben
       ios.ram_wrbyte(0,adr++)                                                  'Null-string-Abschluss
    else
       c:=fs.StringToFloat(@font)                                               'String-Zahl in Float-Zahl umwandeln und im Array speichern
       ios.ram_wrlong(c,adr)

PRI DATA_LESEN(num) | p,i                                                       'Data-Wert im Eram lesen
    i:=0
    repeat
          p:=ios.ram_rdbyte(num++)                                              'string aus eram lesen und in @font schreiben egal, ob Zahl oder Zeichenkette
          if p==44 or p==0                                                      'komma oder null
             quit                                                               'dann raus
          byte[@font][i++]:=p
    byte[@font][i]:=0                                                           'String mit Nullbyte abschliessen
    return num                                                                  'Endadresse zurückgeben

PRI SET_RESTORE(lnr)|a                                                          'DATA-Zeiger setzen
    a:=findline(lnr)
    if ios.ram_rdbyte(a+2)==168                                                 'erste Data-Anweisung gefunden?
       restorepointer:=a                                                        'Restorepointer setzen
       data_poke(0,restorepointer)                                              'Data-Zeilen in den Data-Speicher schreiben
       datapointer:=0                                                           'Data-Pointer zurücksetzen
    else
       errortext(5,1)

PRI DATA_POKE(mode,pointer)|a,adr,b,c,d,merker                                  'DATA-Zeilen in den Ram schreiben
    a := pointer                                                                'entweder 0 oder Restore-Zeiger
    adr:=DATA_RAM
    repeat while a < speicherende-2
                 d := ios.ram_rdword(a)                                         'zeilennummer aus eram holen
                 a+=2                                                           'nach der Zeilennummer kommt der Befehl
                 c:= ios.ram_rdbyte(a)                                          '1.Befehl in der Zeile muss DATA heissen
                 if c==168                                                      'Befehl heisst DATA
                    if merker==1
                       ios.ram_wrbyte(44,b-1)                                   'komma setzen nach für nächste Data-Anweisung
                    if mode==1                                                  'Adresse der ersten Data-Zeile
                       restorepointer:=a-2
                       quit
                    merker:=1                                                   'erste DATA-Anweisung schreiben, ab jetzt wird nach jeder weiteren Anweisung ein Komma gesetzt
                    a+=1
                    a:=stringlesen(a)                                           'DATA-Zeile Lesen
                    b:=stringschreiben(adr,0,@font,1)                           'DATA-Zeile in den RAM schreiben
                    adr:=b
                 else
                    a:=ios.ram_keep(a)'+1                                       'zur nächsten zeile springen
    ios.ram_wrlong(0,adr)                                                       'abschließende nullen für Ende Databereich

Pri FILL_ARRAY(b,mode)|a,f

    repeat a from 1 to b                                                        'Arraywerte schreiben
          ifnot prm_typ[a-1]                                                    'Adresse im Array-Bereich?, dann Zahlenvariable
             if mode
                data_write(prm[a-1],1)
             else
                f:=getanynumber
                ios.ram_wrlong(f,prm[a-1])                                      'zahl im Array speichern
          else                                                                  'String
             if mode
                data_write(prm[a-1],0)
             else
                scanFilename(@f0,0,44)                                          'Zeilen-Teil bis Komma abtrennen
                stringschreiben(prm[a-1],0,@f0,1)                               'String im Stringarray speichern

          if a<b and mode==0                                                    'weiter, bis kein Komma mehr da ist, aber nicht bei DATA(da werden die Daten ohne Komma ausgelesen, kann also nicht abgefragt werden)
             if spaces==","
                skipspaces
             else
                quit

con'***************************************************** Fensterfunktionen *****************************************************************************************************
PRI Window_Function|w,wnr,n

    w:=spaces
    if w=>"0" and w<"8"                                 'Wset-Funktion ersetzt durch win 0..7
       n:=expr(1)
       ios.set_func(n,Print_Window)
       win:=n
       return

    skipspaces
    klammerauf
    wnr:=expr(1)
    ifnot wnr&7
       errortext(16,1)'falscher Parameter
    case w
              "c","C":'Create
                      komma
                      param(8) '0-vordergrundfarbe,1-hintergrundfarbe,2-cursorfarbe,3-x,4-y,5-xx,6-yy,7=Art,8=Schatten 0-nein 1-ja
                      komma
                      Input_String
                      prm[8]&=1     'nur 1 und Null gültig
                      ios.window(wnr,prm[0],prm[1],prm[2],prm[2],prm[2],prm[0],prm[2],prm[0],prm[4], prm[3], prm[6], prm[5],prm[7],prm[8])
                      ios.Set_Titel_Status(wnr,1,@f0)
                      win:=wnr                                                  'das aktuelle Fenster
              "t","T":'Titel
                      komma
                      Input_String
                      ios.Set_Titel_Status(wnr,1,@f0)

              "s","S":'Statustext
                      komma
                      Input_String
                      ios.Set_Titel_Status(wnr,2,@f0)
              "r","R":'Reset
                      ios.windel(wnr,gmode,WTILE_RAM)
                      win:=0
              other:
                    errortext(1,1)

    klammerzu

con'***************************************************** MAP-Funktionen *********************************************************************************************************
PRI Map_Function|a
    a:=spaces
                   case a
                      "d","D":
                            mapram:=0                                           'schreibmarker ausschalten
                            tilecounter:=ios.ram_rdword(MAP_RAM)
                            if tilecounter>0
                               DisplayMap                                       'Map anzeigen
                            return
                      "w","W":
                             mapram:=1                                          'schreibmarker fuer ram jeder Tilebefehl wird jetzt zusaetzlich in den Ram geschrieben
                             tilecounter:=0
                             ios.ram_wrbyte(farbe,MAP_RAM+2)                    'Header mit farbwerten fuellen
                             ios.ram_wrbyte(hintergr,MAP_RAM+3)
                             ios.ram_wrbyte(0,MAP_RAM+4)
                             ios.ram_wrbyte(0,MAP_RAM+5)
                             ios.ram_wrbyte(0,MAP_RAM+6)
                             ios.ram_wrbyte(0,MAP_RAM+7)                        'Rest des Headers mit nullen fuellen

                      "l","L":                                                  'map von sd-card in eram laden
                             skipspaces
                             Input_String
                             Lmap(@f0)

                      "s","S":                                                  'map aus eram auf sd-card speichern
                             skipspaces
                             Input_String
                             Smap(@f0)

                      "c","C":                                                  'Map-Ram_Shadow-BS-Speicher löschen
                              ios.ram_fill(MAP_RAM,$1C27,0)
                      other:
                            errortext(1,1)

con'***************************************************** XBUS-Funktionen *******************************************************************************************************
PRI BUS_Funktionen |pr,a,b,c,h,r,str,s

    pr:=0                                                                       'pr gibt zurück, ob es sich beim Rückgabewert um einen String oder eine Variable handelt, für die Printausgabe
    klammerauf
    a:=expr(1)                                                                  'Chipnummer (1-Administra,2-Bella,3-Venatrix)
    komma
    r:=expr(1)                                                                  'wird ein Rückgabewert erwartet? 0=nein 1=char 4=long 3=string
    s:=0
                 repeat
                      komma
                      if is_string
                         Input_String
                         s:=1
                      else
                           b:=expr(1)                                           'Kommando bzw Wert
                           if b>255
                              case a
                                   1:ios.bus_putlong1(b)
                                   2:ios.bus_putlong2(b)
                           else
                              case a
                                   1:ios.bus_putchar1(b)
                                   2:ios.bus_putchar2(b)

                      if s==1
                         lookup(a:ios.bus_putstr1(@f0),ios.bus_putstr2(@f0))
                         s:=0

                      if spaces==")"
                         quit

                 skipspaces

                 case r
                     0:pr:=0
                       bytefill(@font,0,STR_MAX)
                       bytefill(@f0,0,STR_MAX)
                       return
                     1:c:=lookup(a:ios.bus_getchar1,ios.bus_getchar2)
                     4:c:=lookup(a:ios.bus_getlong1,ios.bus_getlong2)
                     3:if a==1
                          str:=ios.bus_getstr1
                       bytemove(@font,str,strsize(str))
                       pr:=1
    if r==1 or r==4
       h:=fl.ffloat(c)
       str:=fs.floattostring(h)                                                 'Stringumwandlung für die Printausgabe
       bytemove(@font,str,strsize(str))
       return h


con'******************************************** Port-Funktionen der Sepia-Karte *************************************************************************************************
PRI PORT_Funktionen|function,a,b,c
    function:=spaces&caseBit
    skipspaces
    klammerauf
    a:=expr(1)                                                                  'Adresse bzw.ADDA Adresse
        case function
            "O"    :komma
                    b:=expr(1)                                                  'Byte-Wert, der gesetzt werden soll
                    klammerzu
                    if a<4 or a>6                                               'nur Digital-Port-Register können für die Ausgabe gesetzt werden
                       errortext(3,1)
                    c:=a-4                                                      'Portadresse generieren
                    a:=c+PORT                                                   'Port 4=Adresse+0 Port5=Adresse+1 usw. da nur Register 4-6 Ausgaberegister sind
                    ios.plxOut(a,b)                                             'wenn a=4 dann 28+4=32 entspricht Adresse$20 von Digital-Port1

            "I"    :'Port I                                                     'Byte von Port a lesen
                    klammerzu
                    return ios.getreg(a)                                        'Registerwert auslesen 0-6

            "S"    :'Port Set                                                   '*Adressen zuweisen
                     komma
                     b:=expr(1)                                                 '*Port-Adresse zuweisen
                     ADDA:=a
                     PORT:=b
                     klammerzu
                     ios.set_plxAdr(ADDA,PORT)

            "P"    :'Port-Ping                                                  'Port-Adresse anpingen
                     klammerzu
                     ios.plxHalt
                     b:=ios.plxping(a)
                     ios.plxrun
                     return b

            other:
                   errortext(3,1)

con'********************************************* serielle Schnittstellen-Funktionen *********************************************************************************************
PRI Comfunktionen|function,a,b
    function:=spaces&CaseBit
    skipspaces
        case function
            "S"    :klammerauf
                    a:=expr(1)                                                  'serielle Schnittstelle öffnen/schliessen
                    if a==1
                       komma                                                    'wenn öffnen, dann Baudrate angeben
                       b:=expr(1)
                       ios.seropen(b)
                    elseif a==0                                                 'Schnittstelle schliessen
                       ios.serclose
                    else
                       errortext(16,1)
                    klammerzu

            "G"    :'COM G                                                      'Byte von ser.Schnittstelle lesen ohne warten
                    return fl.ffloat(ios.serread)
            "R"    :'COM R                                                      'Byte von ser.Schnittstelle lesen mit warten
                    return fl.ffloat(ios.serget)
            "T"    :klammerauf
                    getstr
                    ios.serstr(@font)
                    klammerzu
            other:
                   errortext(3,1)
con '******************************************* Parameter des Player's und der Sprites *******************************************************************************************
PRI playersettings|f,i,e
    f:=spaces&CaseBit
    skipspaces
    klammerauf
    case f
        "P"    :param(5)                                                        'Spielerparameter
                ios.Actorset(prm[0],prm[1],prm[2],prm[3],prm[4],prm[5])         'Actorset(tnr1,col1,col2,col3,x,y)

        "K"    :param(4)                                                        'Spielertasten belegen
                ios.setactionkey(prm[0],prm[1],prm[2],prm[3],prm[4])            'links,rechts,hoch,runter,feuer
                repeat i from 0 to 4
                       actionkey[i]:=prm[i] 'links
        "B"    :param(9)                                                        'Blockadetiles einlesen (tnr1,....tnr10)
                repeat i from 0 to 9
                     block[i]:=prm[i]
                     ios.send_block(i,prm[i])
        "I"    :param(5)                                                        'Item-Tiles einlesen (tnr1,...tnr6)
                repeat i from 0 to 5
                     item[i]:=prm[i]
        "C"    :param(5)                                                        'Kollisions-Tiles  (tnr1,...tnr6)
                repeat i from 0 to 5
                     collision[i]:=prm[i]
        "E"    :param(4)                                                        'Ersatz-Item-Tiles (nr1-6,tnr,f1,f2,f3)
                e:=(prm[0]-1)*5
                f:=0
                repeat i from e to e+4
                     itemersatz[i]:=prm[f++]
        other:
               errortext(1,1)
    klammerzu

'PRI targetsettings                                                              'Settings für Gegner Ereignisse  - in Arbeit!!!

PRI playerposition(a)|b,c,d,i,bl                                                'Hier wird die Playerbewegung auf Blockadetiles überprüft
                bl:=0
                get_position
                b:=actorpos[0]
                c:=actorpos[1]
                if a==actionkey[0]
                   d:=ios.ram_rdbyte(MAP_RAM+8+((b-1)*6)+(c*40*6))
                elseif a==actionkey[1]
                   d:=ios.ram_rdbyte(MAP_RAM+8+((b+1)*6)+(c*40*6))
                elseif a==actionkey[2]
                   d:=ios.ram_rdbyte(MAP_RAM+8+((b*6)+((c-1)*40*6)))
                elseif a==actionkey[3]
                   d:=ios.ram_rdbyte(MAP_RAM+8+((b*6)+((c+1)*40*6)))
                elseif a==actionkey[4]
                    'Unterroutine Feuertaste, noch nicht vorhanden
                repeat i from 0 to 9
                   if block[i]==d
                      bl:=1
                if bl==0
                   ios.setactor_xy(a)

PRI Kollisionserkennung:a|d,i
    a:=0
    d:=get_position

    repeat i from 0 to 5
       if collision[i]==d
             a:=2                                                               'Kollision des Spielers mit Kollisionstiles
             quit

PRI get_position:d

    actorpos[0]:=ios.get_actor_pos(1) 'x-pos
    actorpos[1]:=ios.get_actor_pos(2) 'y-pos
    d:=ios.ram_rdbyte(MAP_RAM+8+((actorpos[0]*6)+(actorpos[1]*40*6)))                 'Tile an aktueller Position im Map-Speicher lesen

PRI Item_sammeln:a|d,i,e,f
    a:=0
    d:=get_position                                                             'item auf dem der Player gerade steht
    repeat i from 0 to 5
       if item[i]==d
             a:=1+i                                                             'Item-Nr zurückgeben
             e:=MAP_RAM+8+((actorpos[0]*6)+(actorpos[1]*40*6))
             f:=i*5
             ios.ram_wrbyte(itemersatz[f+1],e)'gesammeltes Item wird durch Ersatzitem im ERam ersetzt (um Doppeleinsammlung zu verhindern)
             ios.Change_Backuptile(itemersatz[f+1],itemersatz[f+2],itemersatz[f+3],itemersatz[f+4]) 'ersatzitem wird in Backuppuffer des Players geschrieben (ersetzt)
                                                                                                    'damit stimmt jetzt auch die Farbe des Ersatzitems
             quit

PRI spritesettings|f
    f:=spaces&Casebit
    skipspaces
    klammerauf
    case f
        "S"    :ios.set_func(expr(1),Speed)                                     'Speed
        "M"    :ios.set_func(expr(1),Move)                                      'move an aus reset
        "P"    :param(10)                                                       'Spriteparameter
                if prm[0]>8
                   errortext(16,1)
                ios.set_sprite(prm[0],prm[1],prm[2],prm[3],prm[4],prm[5],prm[6],prm[7],prm[8],prm[9],prm[10]) 'Nr,Tnr,Tnr2,f1,f2,f3,dir,strt,end,x,y)
        other:
              errortext(1,1)
    klammerzu

con'*************************************************************** Array-Dimensionierung ****************************************************************************************
PRI Felddimensionierung(variabl,var_str,x,y,z)|grenze,ort,len,ad

    grenze:=(z+1)*(y+1)*(x+1)

    if grenze>FIELD_LEN
       errortext(18,1)                                                          'Dimensionen dürfen die Grenze von 64000 nicht durchbrechen

    if var_str==1                                                               'Zahlenfelddimensionen speichern
       ort:=VAR_TBL+(variabl*8)
       VAR_NR++
       len:=4
    else                                                                        'String-Felddimensionen speichern
       ort:=STR_TBL+(variabl*8)
       len:=linelen
       STR_NR++
    ad:=Var_Neu_Platz+(grenze*len)
    if ad>$EFFFF
       errortext(45,1)                                                          'Out of Memory Error!

   'neu Adresse in Tabelle speichern
   ios.ram_wrlong(VAR_NEU_PLATZ,ort)
   ios.ram_wrbyte(x,ort+4)
   ios.ram_wrbyte(y,ort+5)
   ios.ram_wrbyte(z,ort+6)
   'naechster freier Platz
   Var_Neu_Platz+=(grenze*len)


con'*************************************************************** Zeilen-Editor**************************************************************************************************
PRI editline(Zeilennummer):nex|a,c,d,f,rm,i,x,y,bn,temp
if Zeilennummer<65535
               x:=0
               y:=0
               temp:=zeilennummer
               bytefill(@tline,0,85)
               a := speicheranfang
               bn:=0
               a:=findline(zeilennummer)                                        'Adresse der Zeilennummer feststellen
               d := ios.ram_rdword(a)                                           'Zeilennummer aus dem eram holen
               a+=2
               i := 1_000_000_000
                        repeat 10                                               'zahl zerlegen
                          if d => i
                             tline[x++] := d / i + 48
                             d //= i
                             bn~~
                          elseif bn or i == 1
                                 tline[x++] :=48
                          i /= 10
                        tline[x++] :=32                                         'freizeichen
                        repeat while rm:=ios.ram_rdbyte(a++)                    'gesuchte Zeile in tline schreiben
                            if rm => 128
                               rm-=128
                                  f:=strsize(@@toks[rm])
                                  bytemove(@tline[x],@@toks[rm],f)
                                  x+=f
                                  tline[x++]:=32                                'Leerzeichen nach dem Token
                                  y:=0                                          'Tok-Bytezaehler auf null setzen für nächsten Befehl
                            else
                                tline[x++]:=rm                                  'alle anderen Zeichen ausgeben
                        nex:=ios.ram_rdword(a)                                  'Adresse der nächsten Zeile

     ios.print(@tline)                                                          'Zeile auf dem Bildschirm ausgeben

     ifnot getline(strsize(@tline))                                             'wenn die Editierung nicht mit ESC abgebrochen wurde
           tp:=@tline                                                           'tp ist die eigentliche Basic-Arbeitszeile
           c := spaces
           if c=>"1" and c =< "9"                                               'Überprüfung auf gültige Zeilennummer
              insertline2                                                       'wenn programmzeile dann in den Speicher schreiben
              Prg_End_Pos                                                       'neues Speicherende
else
   editmarker:=0

con'********************************************  Renumberfunktion *****************************************************************************************************************
pub renumber(st,ed,nb,stp)|i                                                 'renumber(start,end,neustart,step)
    i:=findline(st)
    if ed<speicherende-2
       ed:=findline(ed)

    repeat while i=<ed
           if nb<65535
              ios.ram_wrword(nb,i)                                              'neue Zeilennummer schreiben
              i+=2
              nb+=stp                                                           'Zeilennummerierung mit Schrittweite addieren
              i:=ios.ram_keep(i)                                                'zur nächsten zeile springen
           else
              errortext(2,1)                                                    'Abbruch, wenn Zeilennummer >65534

con '******************************************* diverse Unterprogramme ***********************************************************************************************************
PRI spaces | c                                                                  'Zeichen lesen
   'einzelnes zeichen lesen
   repeat
      c := byte[tp]
      if c == 0 or c > " "
         return c
      tp++

PRI skipspaces                                                                  'Zeichen überspringen
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
   c&=caseBit
   return c - "A"

PRI isvar(c)                                                                    'Ueberpruefung ob Variable im gueltigen Bereich
   c := fixvar(c)
   return c => 0 and c < 26

pri fixnum(c)
    if c=>"0" and c=<"9"
       c-= 47
    return c

pri isnum(c)
    c:=fixnum(c)
    return c=>1 and c<11

PRI playerstatus
       ios.sid_dmpstop
       ios.sid_resetregisters
       play:=0
       close

PRI param(anzahl)|i
    i:=0
    repeat anzahl
        prm[i++]:=expr(1)                                                       'parameter mit kommatrennung
        komma
    prm[i++]:=expr(1)                                                           'letzter Parameter ohne skipspaces

pri is_string |b,c                                                                  'auf String überprüfen
    result:=0
    b:=tp
    c:=spaces
    if isvar(c)
       readvar_name(c)
    c:=spaces
    tp:=b

    case c
          quote,"$",152,163,176,200,226,229,232,236:result:=1


PRI komma
    is_spaces(",",1)

PRI is_spaces(zeichen,t)
    if spaces <> zeichen
       errortext(t,1)'@syn
    else
       skipspaces

PRI dollar
    if spaces=="$"
       skipspaces
       return 1

PRI klammer(m):b
         if spaces=="("
            skipspaces
            if m
               b:=expr(1)
            else
               b:=expr(0)
            if spaces<>")"
               errortext(1,1)
            skipspaces
         else
            errortext(1,1)

PRI klammerauf
    is_spaces(40,1)

PRI klammerzu
    is_spaces(41,1)

PRI getAnyNumber | c, t,i,punktmerker,d,zahl[20]

   case c := byte[tp]
      quote:
         if result := byte[++tp]
            if byte[++tp] == quote
              tp++
            else
               errortext(1,1)                                                   '("missing closing quote")
         else
            errortext(31,1)                                                     '("end of line in string")

      "#":
         c := byte[++tp]
         if (t := hexDigit(c)) < 0
            errortext(32,1)                                                     '("invalid hex character")
         result := t
         c := byte[++tp]
         repeat until (t := hexDigit(c)) < 0
            result := result << 4 | t
            c := byte[++tp]
         result:=fl.FFLOAT(result)

      "%":
         c := byte[++tp]
         if not (c == "0" or c == "1")
            errortext(33,1)                                                     '("invalid binary character")
         result := c - "0"
         c := byte[++tp]
         repeat while c == "0" or c == "1"
            result := result << 1 | (c - "0")
            c := byte[++tp]
         result:=fl.FFLOAT(result)

      "0".."9":
          i:=0
          punktmerker:=0
          c:=byte[tp++]
          repeat while c=="." or c=="e" or c=="E" or (c => "0" and c =< "9")    'Zahlen mit oder ohne punkt und Exponent
                 if c==point
                    punktmerker++
                 if punktmerker>1                                               'mehr als ein punkt
                    errortext(1,1)                                              'Syntaxfehler ausgeben
                 if c=="e" or c=="E"
                    d:=byte[tp++]
                    if d=="+" or d=="-"
                       byte[@zahl][i++]:=c
                       byte[@zahl][i++]:=d
                       c:=byte[tp++]
                       next
                 byte[@zahl][i++]:=c
                 c:=byte[tp++]
          byte[@zahl][i]:=0
          result:=fs.StringToFloat(@zahl)
          --tp

      other:
           errortext(34,1)                                                      '("invalid literal value")

PRI hexDigit(c)
'' Convert hexadecimal character to the corresponding value or -1 if invalid.
   if c => "0" and c =< "9"
      return c - "0"
   if c => "A" and c =< "F"
      return c - "A" + 10
   if c => "a" and c =< "f"
      return c - "a" + 10
   return -1

pri zahlenformat(h)|j
    j:=fl.ftrunc(h)
       if (j>MAX_EXP) or (j<MIN_EXP)                                            'Zahlen >999999 oder <-999999  werden in Exponenschreibweise dargestellt
           return FS.FloatToScientific(h)                                       'Zahlenwerte mit Exponent
       else
           return FS.FloatToString(h)                                           'Zahlenwerte ohne Exponent

con '****************************************** Directory-Anzeige-Funktion *******************************************************************************************************
PRI h_dir(z,modes,str) | stradr,n,i,dlen,dd,mm,jj,xstart,dr,ad,ps                 'hive: verzeichnis anzeigen
{{h_dir - anzeige verzeichnis}}                                                 'mode 0=keine Anzeige,mode 1=einfache Anzeige, mode 2=erweiterte Anzeige
  ios.set_func(0,Cursor_Set)                                                    'cursor ausschalten
  mount

  xstart:=ios.getx                                                              'Initial-X-Wert
  if strsize(str)<3
     str:=@ext5                                                                 'wenn kein string uebergeben wird, alle Dateien anzeigen
  else
     repeat 3                                                                   'alle Zeichen von STR in Großbuchstaben umwandeln
        if byte[str][i]>96
           byte[str][i]^=32
        i++

  ios.sddir                                                                     'kommando: verzeichnis öffnen
  n := 0                                                                        'dateizaehler
  i := 0                                                                        'zeilenzaehler
 repeat  while (stradr:=ios.sdnext)<>0                                          'wiederholen solange stradr <> 0


    dlen:=ios.sdfattrib(0)                                                      'dateigroesse
    dd:=ios.sdfattrib(10)                                                       'Aenderungsdatum tag
    mm:=ios.sdfattrib(11)                                                       'Aenderungsdatum monat
    jj:=ios.sdfattrib(12)                                                       'Aenderungsdatum Jahr
    dr:=ios.sdfattrib(19)                                                       'Verzeichnis?

      scanstr(stradr,1)                                                         'dateierweiterung extrahieren

      ifnot ios.sdfattrib(17)                                                   'unsichtbare Dateien ausblenden
        if strcomp(@buff,str) or strcomp(str,@ext5)                             'Filter anwenden
             n++

          '################## Bildschrirmausgabe ##################################
           if modes>0                                                           'wenn Verzeichnis,dann andere Farbe
               if dr and gmode==0
                  ios.printBoxColor(0,farbe+32,hintergr)
               ios.print(stradr)

               if modes==2
                  erweitert(xstart,dlen,dd,mm,jj)
               ios.printnl
               ios.set_func(xstart,set_x)
               i++
               ifnot gmode
                     ios.printBoxColor(0,farbe,hintergr)                           'wieder Standardfarben setzen
               if i==z                                                             '**********************************
                  if ios.keywait == ios#CHAR_ESC                                   'auf Taste warten, wenn ESC dann Ausstieg
                     ios.set_func(cursor,Cursor_Set)                               '**********************************
                     close                                                         '**********************************
                     filenumber:=n                                                 'Anzal der Dateien merken
                     abort                                                        '**********************************

                 i := 0                                                           '**********************************
                 ios.set_func(xstart,set_x)
           'if modes==0                                                           'in allen modis in den Ram schreiben
           if n<DIR_ENTRY                                                         'Begrenzung der Einträge auf die mit DIR_ENTRY vereinbarte
              ps:=(n-1)*13
              ad:=DIR_RAM+ps
              stringschreiben(ad,0,stradr,1)                                      'Dateiname zur spaeteren Verwendung in ERam speichern an adresse n

 if modes                                                                         'sichtbare Ausgabe
    ios.printdec(n)                                                               'Anzahl Dateien
    errortext(43,0)
    ios.printnl
 ios.set_func(cursor,Cursor_Set)
 filenumber:=n                                                                    'Anzal der Dateien merken
 close                                                                            'ins Root Verzeichnis ,SD-Card schliessen und unmounten
 abort

PRI erweitert(startx,laenge,tag,monat,jahr)                               'erweiterte Dateianzeige

         ios.set_func(startx+14,set_x)
         ios.printdec(laenge)
         ios.set_func(startx+21,set_x)
         ios.printdec(tag)
         ios.set_func(startx+24,set_x)
         ios.printdec(monat)
         ios.set_func(startx+27,set_x)
         ios.printdec(jahr)

PRI scanstr(f,mode) | z ,c                                                      'Dateiendung extrahieren
   if mode==1
      repeat while strsize(f)
             if c:=byte[f++] == point                                           'bis punkt springen
                quit
   z:=0
   repeat 3                                                                     'dateiendung lesen
        c:=byte[f++]
        buff[z++] := c
   buff[z++] := 0
   return @buff

PRI activate_dirmarker(mark)                                                    'USER-Marker setzen

     ios.sddmput(ios#DM_USER,mark)                                              'usermarker wieder in administra setzen
     ios.sddmact(ios#DM_USER)                                                   'u-marker aktivieren

PRI get_dirmarker:dm                                                            'USER-Marker lesen

    ios.sddmset(ios#DM_USER)
    dm:=ios.sddmget(ios#DM_USER)

con '********************************* Unterprogramme zur Tile-Verwaltung *********************************************************************************************************
PRI Win_Set_Tiles|i,a                                                           'Tiles, aus denen die Fenster bestehen, in den Ram schreiben
    i:=WTILE_RAM
    a:=0
    repeat 18
           ios.ram_wrbyte(windowtile[a++],i++)                                  'Standard-Wintiles in den Ram schreiben
    ios.windel(9,gmode,WTILE_RAM)                                               'alle Fensterparameter löschen und Win Tiles senden

PRI LoadTiletoRam(tilenr,datei,xtile,ytile)|adress ,count                       'tile:=tilenr,dateiname,xtile-zahl,ytilezahl

    xtiles[tilenr]:=xtile                                                       'xtiles fuer tilenr        '
    ytiles[tilenr]:=ytile                                                       'ytiles fuer tilenr
    count:=xtile*ytile*64                                                       'anzahl zu ladender Bytes (16*11*16*4=11264)
    if tilenr<16
       adress:=TILE_RAM+((tilenr-1)*$2C00)                                      'naechster Tilebereich immer 2816 longs (11264 Bytes) 14 Tilesets moeglich Tileset15 ist der Systemfont
    else
       adress:=MOUSE_RAM                                                        'Mouse-Pointer
       count:=64
    mount
    activate_dirmarker(basicmarker)                                             'ins Basic Stammverzeichnis
    ios.sdchdir(@tile)                                                          'ins tile verzeichnis wechseln
    if ios.sdopen("R",datei)                                                    'datei öffnen
       errortext(22,1)
       return
    ios.sdxgetblk(adress,count)                                                 'datei in den Speicher schreiben  (der blockbefehl ist viel schneller als der char-Befehl)
    close
    '####Mouse-Pointer############
    if tilenr==16
       ios.Mousepointer(MOUSE_RAM)                                              'neuen Mauszeiger übernehmen

PRI loadtile(tileset)|anzahl,adress                                             'tileset aus eram in bella laden
    if tileset==15                                                              'bei Systemfont, Fenstertiles wieder herstellen
       Win_Set_Tiles

    adress:=TILE_RAM+((tileset-1)*$2C00)                                        'naechster Tilebereich immer 2816 longs (11264 Bytes) 14 Tilesets moeglich

    anzahl:=ytiles[tileset]*xtiles[tileset]*16                                  'anzahl tilebloecke
    ios.loadtilebuffer(adress,anzahl)                                           'laden
    aktuellestileset:=tileset                                                   'zum aktuellen Tileset machen

con '************************************* Unterprogramme zur Map-Daten-Behandlung *****************************************************************************************************
PRI lmap(name)|datadresse,counters                                               'Map-datei von SD-Card in eram laden
    datadresse:=MAP_RAM
    mount
    activate_dirmarker(basicmarker)                                              'ins Basic Stammverzeichnis
    if ios.sdopen("R",name)                                                      'datei vorhanden?
       errortext(22,1)
       return
    counters:=DPL_CNT                                                            'anzahl speicherstellen
    counters*=6                                                                  'mit 6 multiplizieren da jedes Tile 6 parameter hat (nr,3xfarbe und x bzw.y)
    counters+=8                                                                  'plus header
    ios.sdxgetblk(datadresse,counters)                                           'Map in den Speicher laden
    close
    tilecounter:=ios.ram_rdword(MAP_RAM)                                        'tilecounter fuer anzeige setzen

PRI smap(name)|datadresse,a,count                                               'MAP-Datei auf SD-Card schreiben
   a:=ifexist(name)
   if a==0 or a==2                                                              'Fehler
      return
   ios.ram_wrword(tilecounter,MAP_RAM)                                          'counter schreiben
   datadresse:= MAP_RAM
   count:=(DPL_CNT*6)+8                                                         'counter mit 6 multiplizieren da jedes Tile 6 parameter hat (nr,farbe1-3,x,y), die ersten 8 stellen sind der Header
   ios.sdxputblk(datadresse,count)                                              'Map auf SD-Card speichern
   close

PRI DisplayMap|datadr,tnr,f1,f2,f3,tx,ty,contr                                  'Map-Datei aus eram lesen und anzeigen
    farbe      :=ios.ram_rdbyte(MAP_RAM+2)                                      'Bildschirmfarben lesen
    hintergr   :=ios.ram_rdbyte(MAP_RAM+3)
    ios.printboxcolor(win,farbe,hintergr)                                       'Fenster mit Bildschirmfarben erzeugen
    ios.printchar(12)
    datadr:=MAP_RAM+8                                                           'Start-Position im ERam
    repeat DPL_CNT
               tnr:=ios.ram_rdbyte(datadr++)                                          'Tilenr
               f1 :=ios.ram_rdbyte(datadr++)                                          'farbe1
               f2 :=ios.ram_rdbyte(datadr++)                                          'farbe2
               f3 :=ios.ram_rdbyte(datadr++)                                          'farbe3
               tx :=ios.ram_rdbyte(datadr++)                                          'x-position
               ty :=ios.ram_rdbyte(datadr++)                                          'y-position
               if contr:=tnr+f1+f2+f3                                           'Tile da?
                  ios.displayTile(tnr,f1,f2,f3,ty,tx)                           'einzelnes Tile anzeigen   ('displayTile(tnr,pcol,scol,tcol, row, column))
con'****************************************** Button-Routinen *************************************************************************************************************
Pri Buttons|a,c,bnr,adr,tv,tb
    tv:=farbe
    tb:=hintergr

    a:=spaces&CaseBit
    skipspaces
    klammerauf
    bnr:=expr(1)                                                                'Button-Nr
    if bnr>BUTTON_CNT or bnr<1
       errortext(3,1)
    adr:=BUTT_RAM+((bnr-1)*40)
    case a                    '    0        1       2     3
             "T":komma
                 param(3)     'vordergr,hintergr,x-pos,y-pos,Buttontext
                 komma
                 Input_String
                 prm[4]:=prm[2]+strsize(@f0)+1
                 ios.PlotFunc(prm[2], prm[3],prm[4],prm[3],prm[1],0,_Line)           'Button darstellen
                 ios.printBoxColor(0,prm[0],prm[1])
                 ios.setpos(prm[3],prm[2]+1)
                 ios.print(@f0)
                 c:=Buttonparameter(5,adr)                                      'Button-Parameter in den Ram schreiben
                 stringschreiben(c++,0,@f0,1)                                   'Button-Text in den Ram schreiben
                 button_art[bnr-1]:=1                                           'Art des Buttons 1=Text 2=Icon
                 ios.send_button_param(bnr,prm[2],prm[3],prm[4])                'Button-Koordinaten nach Bella senden zur Maus-Verarbeitung

             "I":'Icon-Button    0       1        2        3      4    5
                 komma
                 param(5)     'tilenr,vordergr,hintergr,3.Farbe,x pos,y-pos
                 ios.displayTile(prm[0],prm[1],prm[2],prm[3],prm[5],prm[4])     'einzelnes Tile anzeigen   ('displayTile(tnr,pcol,scol,tcol, row, column))
                 Buttonparameter(6,adr)
                 button_art[bnr-1]:=2                                           'Art des Buttons 1=Text 2=Icon
                 ios.send_button_param(bnr,prm[4],prm[5],prm[4])                'Button-Koordinaten nach Bella senden zur Maus-Verarbeitung
             "R":'Reset
                 ios.set_func(bnr,Del_Button)                                   'button löschen
                 button_art[bnr-1]:=0                                           'Button-Art löschen
         other:
               errortext(1,1)
    klammerzu
  farbe:=tv
  hintergr:=tb
  ios.printBoxColor(0,farbe,hintergr)
pri Buttonpress_on(h)|adr,a,b,c,d,e,f,tv,tb',g,tnr
  tv:=farbe
  tb:=hintergr
  adr:=BUTT_RAM+((h-1)*40)                                                      'Textbutton - Icon
  farbe:=a:=  ios.ram_rdbyte(adr++)                                                          'vordergr - tnr
  hintergr   :=b:=  ios.ram_rdbyte(adr++)                                                          'hintergrund - f1

  c:=  ios.ram_rdbyte(adr++)                                                          'tx - f2
  d:=  ios.ram_rdbyte(adr++)                                                          'ty - f3
  e:=  ios.ram_rdbyte(adr++)                                                          'txx - x

    if button_art[h-1]==1                                                       'Textbutton
       stringlesen(adr++)                                                       'Button-String holen
       ios.PlotFunc(c,d,e,d,a,0,_Line)                                               'Button revers zeichnen
       ios.printBoxColor(0,hintergr,farbe)
       ios.setpos(d,c+1)
       ios.print(@font)
       repeat while ios.mouse_button(0)
       ios.PlotFunc(c,d,e,d,b,0,_Line)                                                 'Button normal zeichnen
       ios.printBoxColor(0,farbe,hintergr)
       ios.setpos(d,c+1)
       ios.print(@font)

    if button_art[h-1]==2                                                       'Icon-Button
       f:=ios.ram_rdbyte(adr++)                                                       'y-Position des Icon
       ios.displayTile(a,c,b,d,f,e)                                             'einzelnes Tile revers anzeigen   ('displayTile(tnr,pcol,scol,tcol, row, column))
       repeat while ios.mouse_button(0)
       ios.displayTile(a,b,c,d,f,e)                                             'einzelnes Tile anzeigen   ('displayTile(tnr,pcol,scol,tcol, row, column))
  farbe:=tv
  hintergr:=tb
  ios.printBoxColor(0,farbe,hintergr)

pri buttonparameter(sl,adr):c|i                                                 'Buttonparameter in den Ram schreiben
    i:=0
    repeat sl
        ios.ram_wrbyte(prm[i++],adr++)
    c:=adr

{PRI READ_PARAMETER|a,i                                                          'Parameterabfrage beim Basic-Start
    if ios.ram_rdbyte(SMARK_RAM)<>222                                           'Startparameter-Flag lesen
       a:=ios#PARAM
       i:=0
       repeat while tline[i++]:=ios.ram_rdbyte(a++)                             'Parametertext einlesen
       tline[i]:=0
       if i>0
          tp:= @tline                                                           'Parameterzeile nach tp verschieben
          tokenize                                                              'Befehle in Token konvertieren
          texec                                                                 'Befehle ausführen
          ios.paradel                                                           'Startparameter löschen
       ios.ram_wrbyte(222,SMARK_RAM)                                            'Startparameter-Marker löschen
}

DAT

{{
                            TERMS OF USE: MIT License

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, exprESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
}}
