PARSE ARG mode fin fout .

IF mode="" THEN
   HELP()

IF LEFT(mode,1)\="-" THEN -- no mode defined, default is "-r8"
   do
      fout=fin
      fin=mode
      mode="-r8"
   end

IF fout="" THEN
   fout=fin||".out"

IF EXIST(fout)\="" THEN "del "||fout

len = CHARS(fin)
a = CHARIN(fin,,len)

SIGNAL ON SYNTAX

SELECT
   WHEN LEFT(mode,3)="-r8" THEN
        DO
          a=reverse(a) -- flip
        END

   WHEN LEFT(mode,3)="-1" THEN
        DO
          a=c2x(a) -- to hexa
          a=x2b(a) -- to binary
          a=reverse(a) -- flip
          a=b2x(a) -- from bin to hexa
          a=x2c(a) -- from hexa to chars
          IF RIGHT(mode,1)="b" THEN
             a=reverse(a) -- flip
        END

   WHEN LEFT(mode,3)="-4" THEN
        DO
          a=C2X(a) -- to hexa
          a=REVERSE(a) -- flip
          a=X2C(a) -- from hexa to chars
          IF RIGHT(mode,1)="b" THEN
             a=reverse(a) -- flip
        END

   WHEN LEFT(mode,2)="-x" THEN
        DO
           m=X2C(RIGHT(mode,2))
           a=BITXOR(a,,m)
        END

   WHEN LEFT(mode,2)="-a" THEN
        DO
           m=X2C(RIGHT(mode,2))
           a=BITAND(a,,m)
        END

   WHEN LEFT(mode,2)="-o" THEN
        DO
           m=X2C(RIGHT(mode,2))
           a=BITOR(a,,m)
        END

   OTHERWISE
        SAY "Invalid mode:" mode
        EXIT
   END

t=CHAROUT(fout,a)

SAY "Created:" fout "Size:" len "bytes. Mode:" mode
EXIT

EXIST:
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
     SAY "Reverse content of the file. (C) Omega 2019 / 07.07.2019"
     SAY
     SAY "rev [mode] input_file [output_file]"
     SAY " mode:"
     SAY " -r8 ..... reverse file order in bytes [default; without switch]"
     SAY " -r1[b] .. reverse file order in bits"
     SAY " -r4[b] .. reverse file order in nibbles (4bits)"
     SAY " -r<n>b .. reverse byte content, but maintain file order."
     SAY " -xNN .... XOR file content with byte NN (hexadecimal format)."
     SAY " -oNN .... OR"
     SAY " -aNN .... AND"
     SAY
     SAY " output_file"
     SAY " - if no filename is specified, <input_file>.out will be used."
     SAY " - Note: program overwrites existing output_file."
     EXIT