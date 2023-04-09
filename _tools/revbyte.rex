parse arg fin fout

if fout="" then
   fout=fin||".out"

IF EXIST(fout)\="" THEN "del "||fout

len=chars(fin)

a=charin(fin,,len)
t=charout(fout,reverse(a))

say "Reversed:" len "bytes"
exit

EXIST:
PARSE ARG filename
RETURN STREAM(filename,"C","QUERY EXISTS")
