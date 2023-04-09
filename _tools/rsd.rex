parse arg fin fsym

if (fin="") then
   do
     say "Rotoid Engine Scene Decompiler. (C) Omega 2019 / 09.05.2019"
     say "-- syntax: rsd.rex scene_binary_file [assembler_symbolic_file]"
     say ""; say "Decompiled file has extension .a80 and produces sjasmplus Z80 assembler file."
     say "If symbolic file (.SYM) is supplier, decompiler will use labels instead of addresses."
     exit
   end

fout=fin||".a80"

IF EXIST(fout)\="" THEN "del "||fout

fsym_cnt = LINES(fsym,"C")

i=1 ; j=1
par.i = "scene:"
j=j+1 ; par.i.j = ".posx:" ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".posy:" ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".posz:" ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".far:"  ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".fade:" ; par.i.j.1 = 2
par.i.1 = j

i=i+1 ; j=1
par.i = "light:"
j=j+1 ; par.i.j = ".posx:"   ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".posz:"   ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".bright:" ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".contrs:" ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".angle:"  ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".leff:"   ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".reff:"   ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".shade:"  ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".mode:"   ; par.i.j.1 = 1
par.i.1 = j

i=i+1 ; j=1
par.i = "screen:"
j=j+1 ; par.i.j = ".posx:"  ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".posy:"  ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".cltop:" ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".clbot:" ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".color:" ; par.i.j.1 = 1
par.i.1 = j

i=i+1 ; j=1
par.i = "currObj:"
j=j+1 ; par.i.j = ".ptr:"    ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".angle:"  ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".ldata:"  ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".posx16:" ; par.i.j.1 = 2
par.i.1 = j


do  o=1 to 20
i=i+1 ; j=1
par.i = "obj_"||o||":"
j=j+1 ; par.i.j = ".drwexe:" ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".mobptr:" ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".datptr:" ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".par1:"   ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".par2:"   ; par.i.j.1 = 1
j=j+1 ; par.i.j = ".posx:"   ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".posy:"   ; par.i.j.1 = 2
j=j+1 ; par.i.j = ".posz:"   ; par.i.j.1 = 2
par.i.1 = j
end

t=lineout(fout,"; "||copies("-",32))
t=lineout(fout,";  input file: "||fin)
t=lineout(fout,";      lenght: "||chars(fin))
if fsym<>"" then
   do
     t=lineout(fout,"; symbol file: "||fsym)
   end
t=lineout(fout,"; "||date()||" "||time())

x=0
do until (chars(fin)=0)
   x=x+1
   say ; say par.x
   t=lineout(fout,"")
   t=lineout(fout,par.x)
   do y=2 to par.x.1
      a="";b=""
      if (par.x.y.1=1) then
         do
           str=c2x(charin(fin,,1))
           t=lineout(fout,par.x.y||"	db  #"||str)
         end
      else
         do
           str.1=c2x(charin(fin,,1))
           str.2=c2x(charin(fin,,1))
           str = str.2||str.1
           if (x>4 & y<5 & fsym\="") then
              do
                 a = findLabel(str)
                 b = "	;"
              end
           else
              do
                 a = ""
                 b = ""
              end
           t=lineout(fout,par.x.y||"	dw   " || a || b || "#"||str)
         end
      say par.x.y||" "||a||b||"#"||str
   end
end

exit

findLabel:
parse arg addr
line = linein(fsym,1,0)

do fsym_cnt
   line = linein(fsym)
   parse var line label ":" "equ" address
   if (pos(addr,address)>0) then
      do
        return label
      end
end
return ""

EXIST:
PARSE ARG filename
RETURN STREAM(filename,"C","QUERY EXISTS")