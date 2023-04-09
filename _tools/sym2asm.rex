PARSE ARG filein fileout

IF ARG()=0 THEN DO
   SAY "SJASM to EmuzWin SYMbol table convertor by osg 2019"
   SAY "Syntax : sym2asm.rex <source_file.sym> [destination_file]"
   EXIT
END

IF fileout = "" THEN fileout = LEFT(filein,LASTPOS(".",filein)) || "asm"

filelen = CHARS(filein)
linecnt = LINES(filein,"C")

SAY "File   :" || filein
SAY "Output :" || fileout
SAY ""
SAY "Size:" || filelen || " Lines: " || linecnt

IF EXIST(fileout)\="" THEN "DEL "||fileout

DO linecnt
  line = LINEIN(filein)
  PARSE VAR line label "equ 0x0000" value
  s = CHANGESTR(".",label,"_") || " equ #" || value
  t = LINEOUT(fileout, s)
END

EXIT

EXIST:
PARSE ARG filename
RETURN STREAM(filename,"C","QUERY EXISTS")
