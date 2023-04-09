PARSE ARG input

IF WORDS(input)=0 THEN
   HELP()

i   = 1       -- arg counter

DO WHILE WORD(input,i)<>""
int = 1       -- 0 equalize to 0 and 255
              -- 1 trunc to integer
              -- 2 round
val = ""      -- use int or equalized
nf  = 0       -- number of files processed

DROP pos num file.1 file.2

f = 1   -- cmd counter
DO WHILE LEFT(WORD(input,i),1)="-"
   DO
      cmd.f = SUBSTR(WORD(input,i),2,1)
      par.f = SUBSTR(WORD(input,i),3)
      IF f=1 & DATATYPE(cmd.f,"U") THEN nf=2
      IF f=1 & DATATYPE(cmd.f,"L") THEN nf=1
      IF f=1 & cmd.f="n"           THEN nf=0
      SELECT
        WHEN cmd.f="s" & f>1 THEN pos=SD(par.f)
        WHEN cmd.f="l" & f>1 THEN num=SD(par.f)
        WHEN cmd.f="e" & f>1 THEN int=SD(par.f)
        OTHERWISE
        END
      i=i+1 ; f=f+1
   END
END

f  = 1  -- file counter
DO WHILE EXIST(WORD(input,i))<>"" & nf>0
   DO
     file.f=WORD(input,i)
     file.f.len = CHARS(WORD(input,i))
     file.f.str = CHARIN(WORD(input,i),,file.f.len)
     t = STREAM(file.f.str,"C","CLOSE")
     i=i+1 ; f=f+1
     nf=nf-1
   END
END
fout = WORD(input,i)

IF nf>0 THEN DO ; SAY "Missing input file" ; EXIT ; END
IF LEFT(fout,1)="-" | fout="" THEN DO ; fout=file.1||".out" ; END
ELSE i=i+1

IF SYMBOL("pos")="LIT" THEN pos=0
IF SYMBOL("num")="LIT" THEN num=file.1.len-pos

val = SD(par.1)
a   = file.1.str
c   = file.2.str

SELECT
   WHEN INDEX("aA",cmd.1)>0   THEN off=255
   WHEN INDEX("mdMD",cmd.1)>0 THEN off=1
   OTHERWISE                       off=0
   END

SELECT
   WHEN (INDEX("aoxpsmd",cmd.1)>0)  THEN b = COPIES(D2C(off),pos)||COPIES(D2C(val),num)
   WHEN (INDEX("g",cmd.1)>0)        THEN b = SUBSTR(a,1,pos)||COPIES(D2C(val),num)
   WHEN (INDEX("G",cmd.1)>0)        THEN c = SUBSTR(a,1,pos)||SUBSTR(c,pos+1,num,D2C(off))
   WHEN (INDEX("AOXPSMD",cmd.1)>0)  THEN c = COPIES(D2C(off),pos)||SUBSTR(c,pos+1,num,D2C(off))
   OTHERWISE
   END

-- operation
SELECT
   WHEN cmd.1="x" THEN c = BITXOR(a,b)
   WHEN cmd.1="a" THEN c = BITAND(a,b)
   WHEN cmd.1="o" THEN c = BITOR(a,b)
   WHEN cmd.1="p" THEN c = BYTEADD(a,b)
   WHEN cmd.1="s" THEN c = BYTESUB(a,b)
   WHEN cmd.1="m" THEN c = BYTEMUL(a,b)
   WHEN cmd.1="d" THEN c = BYTEDIV(a,b)
   WHEN cmd.1="g" THEN c = BYTEAVG(a,b)
   WHEN cmd.1="f" THEN c = OVERLAY(COPIES(D2C(val),num),a,pos+1)
   WHEN cmd.1="n" THEN c = COPIES(D2C(val),num)
   WHEN cmd.1="w" THEN c = BITSWAP(a,val,pos,num)

   WHEN cmd.1="X" THEN c = BITXOR(a,c)
   WHEN cmd.1="A" THEN c = BITAND(a,c)
   WHEN cmd.1="O" THEN c = BITOR(a,c)
   WHEN cmd.1="P" THEN c = BYTEADD(a,c)
   WHEN cmd.1="S" THEN c = BYTESUB(a,c)
   WHEN cmd.1="M" THEN c = BYTEMUL(a,c)
   WHEN cmd.1="D" THEN c = BYTEDIV(a,c)
   WHEN cmd.1="G" THEN c = BYTEAVG(a,c)
   WHEN cmd.1="F" THEN c = OVERLAY(SUBSTR(c,1,num),a,pos+1)
   WHEN cmd.1="R" THEN c = OVERLAY(SUBSTR(c,pos,num),a,pos+1)
   OTHERWISE
       DO
          SAY "Unknown operation:" o
          EXIT
       END
   END

-- save
t = STREAM(fout,"C","CREATE")
t = CHAROUT(fout,c)
t = STREAM(fout,"C","CLOSE")

ic =     "wnxaopsmdgfr"
ic = ic||"XAOPSMDGFR"

oc =     "swap newfile xor and or plus(add) substract multiply divide average fill replace " -- lower case commands
oc = oc||"XOR AND OR PLUS(ADD) SUBSTRACT MULTIPLY DIVIDE AVERAGE FILL REPLACE"      -- upper case commands

IF INDEX("n",cmd.1)=0 THEN DO
   SAY "File in :" file.1
   SAY "Length  :" file.1.len
   END
SAY "File out:" fout
SAY "Command :" WORD(oc,INDEX(ic,cmd.1)) "["||cmd.1||"]"
SAY "Numbers :" WORD("Equalize Integer Round",int+1)
IF SYMBOL("file.2")="LIT" THEN SAY "Value   :" val
SAY "Start   :" pos
SAY "Modified:" num

-- MAIN LOOP
END
EXIT

ROUND: PROCEDURE
RETURN TRUNC(ARG(1)+0.5)

FITBYTE: PROCEDURE EXPOSE int
v=TRUNC(ARG(1)+0.5*(int=2))
IF int=1 THEN RETURN C2D(D2C(v,1))
RETURN (v>=0)*(v<=255)*v+255*(v>255)

BITSWAP: PROCEDURE
PARSE ARG a,val,pos,num
x=""
DO i=pos+1 to pos+num
      v=X2B(C2X(SUBSTR(a,i,1)))
      w=""
         DO j=1 to 8
            k=SUBSTR(val,j,1)
            SELECT
              WHEN DATATYPE(k,"N") THEN w=w||SUBSTR(v,8-k,1)
              -- set
              WHEN k="s"           THEN w=w||"1"
              -- reset
              WHEN k="r"           THEN w=w||"0"
              -- keep original bit
              WHEN k="k"           THEN w=w||SUBSTR(v,j,1)
              -- invert original bit
              WHEN k="i"           THEN w=w||(1-SUBSTR(v,j,1))
              -- Raise error if unknown letter is used (a bit of err handler abuse;)
              OTHERWISE                 w=" !SYNTAX ERROR IN PARAMETTER! "||k||" "
              END
         END
      x=x||X2C(B2X(w))
END
RETURN OVERLAY(x,a,pos+1)

BYTEDIV: PROCEDURE EXPOSE off int
PARSE ARG a,b
x=""
DO i=1 to LENGTH(a)
   v=C2D(SUBSTR(a,i,1))
   w=C2D(SUBSTR(b,i,1,D2C(off)))
   IF w=0 THEN v=0                  -- divide by zero
   ELSE        v=v/w
   v=FITBYTE(v)
   x=x||D2C(v)
END
RETURN x

BYTEAVG: PROCEDURE EXPOSE off int pos
PARSE ARG a,b
x=""
l=LENGTH(b)
DO i=1 to LENGTH(a)
   v=C2D(SUBSTR(a,i,1))
   w=C2D(SUBSTR(b,i,1,D2C(off)))
   IF i<=l THEN
      v=(v+w)/2
   v=FITBYTE(v)
   x=x||D2C(v)
END
RETURN x

BYTEMUL: PROCEDURE EXPOSE off int
PARSE ARG a,b
x=""
DO i=1 to LENGTH(a)
   v=C2D(SUBSTR(a,i,1))
   w=C2D(SUBSTR(b,i,1,D2C(off)))
   v=v*w
   v=FITBYTE(v)
   x=x||D2C(v)
END
RETURN x

BYTEADD: PROCEDURE EXPOSE off int
PARSE ARG a,b
x=""
DO i=1 to LENGTH(a)
   v=C2D(SUBSTR(a,i,1))
   w=C2D(SUBSTR(b,i,1,D2C(off)))
   v=v+w
   v=FITBYTE(v)
   x=x||D2C(v)
END
RETURN x

BYTESUB: PROCEDURE EXPOSE off int
PARSE ARG a,b
x=""
DO i=1 to LENGTH(a)
   v=C2D(SUBSTR(a,i,1))
   w=C2D(SUBSTR(b,i,1,D2C(off)))
   v=v-w
   v=FITBYTE(v)
   x=x||D2C(v)
END
RETURN x

SD: PROCEDURE
PARSE ARG s
IF POS("#",s)>0 THEN RETURN S2D(s)
IF POS("%",s)>0 THEN RETURN S2D(s)
IF POS("x",s)>0 THEN RETURN S2D(s)
IF POS(".",s)>0 THEN RETURN S2D2(s)
RETURN s

-- string decimal. Format: nnn.x .. hex ; nnn.b .. bin
S2D2: PROCEDURE
PARSE ARG value "." base
IF base<>"" THEN
   DO
      INTERPRET "num='"||value"'"||base
      value = C2D(num)
   END
RETURN value

-- string decimal; nnn .. hex; %nnn .. bin
S2D: PROCEDURE
IF LEFT(ARG(1),2)="0x" THEN RETURN X2D(SUBSTR(ARG(1),3))
PARSE ARG type 2 value
SELECT
   WHEN type="#" THEN
       d = X2D(value)
   WHEN type="%" THEN
       DO
          d = B2X(value)
          d = X2D(d)
       END
   OTHERWISE
   END
RETURN d

EXIST: PROCEDURE
PARSE ARG filename
RETURN STREAM(filename,"C","QUERY EXISTS")

SYNTAX:
     SAY "Error at line:" sigl
     SAY CONDITION("D")
     SAY sourceline(sigl)
     SAY
     SAY "To see HELP, run the program without parametters."
     EXIT
HELP:
     SAY "Combine Files - CoFi. (C) Omega 2019 / 18.07.2019"
     SAY
     SAY "cofi -mode [-eNN] [-sNNN] [-lNNN] input_file_1 [input_file_2] [output_file]"
     SAY
     SAY "<mode> is case sensitive."
     SAY " - lowercase letter describing TYPE of operation and VALUE. ONE input file required"
     SAY " - UPPERCASE letter describing TYPE of operation. TWO input files are required."
     SAY
     SAY "TYPE:"
     SAY " x .... XOR    p .... ADD    d .... DIV (divide by zero is NOT raised!"
     SAY " o .... OR     s .... SUB                0 will be used as resulting value)"
     SAY " a .... AND    m .... MUL    g .... AVG"
     SAY " f .... FILL    (fill content with provided value/file content)"
     SAY " R .... REPLACE (works with files, replaces bytes at the same positions)"
     SAY " w .... sWap bits (argument is new order of bits. e.g. -w01237654)"
     SAY "                  (special bit operations: s-SET, r-RESET, i-INVERT, k-KEEP)"
     SAY
     SAY " -sNNN ... Start offset, if not specified 0 is assumed."
     SAY " -lNNN ... Length starting from offset."
     SAY
     SAY "Number format:"
     SAY " NNN .. DEC | #NNN, NNN.x ... HEX | %NNN, NNN.b .... BIN"
     SAY " 128           #80   80.x           %10000000 10000000.b"
     SAY
     SAY "-e switch determines how numbers will be rounded."
     SAY "   0 ... value is equalized. 0 for value<0; 255 for value>255"
     SAY "   1 ... value is truncated to whole numbers, signed 8bit"
     SAY "   2 ... valie is rounded to whole numbers."
     SAY
     SAY "output_file"
     SAY " - if no filename is specified, <input_file>.out will be used."
     SAY " - Note: program overwrites existing output_file."
     SAY
     SAY "Example:"
     SAY " reset 6th bit of file content, starting offset 6144 bytes:"
     SAY " cofi.rex -a#bf -s6144 zxscreen.scr"
     SAY
     SAY " combine two files and ADD them together:"
     SAY " cofi.rex -P table1.bin table2.bin"
     EXIT