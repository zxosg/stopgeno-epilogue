parse arg fin fout

if fout="" then
   fout=fin||".out"

IF EXIST(fout)\="" THEN "del "||fout

len=chars(fin)

a=charin(fin,,len)
a=c2x(a)          -- to hexa
a=reverse(a)      -- flip
a=x2c(a)          -- from hexa to chars
t=charout(fout,a)

say "Reversed:" len "bytes"
exit

EXIST:
PARSE ARG filename
RETURN STREAM(filename,"C","QUERY EXISTS")
