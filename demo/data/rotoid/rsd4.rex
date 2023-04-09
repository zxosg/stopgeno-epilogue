parse arg fin fsym

if (fin="") then
   do
     say "Rotoid Engine Scene Decompiler. (C) Omega 2019 / 09.05.2019"
     say "-- syntax: rsd.rex scene_binary_file [assembler_symbolic_file]"
     say ""; say "Decompiled file has extension .a80 and produces sjasmplus Z80 assembler file."
     say "If symbolic file (.SYM) is supplied, decompiler will use labels instead of addresses."
     exit
   end

fout=fin||".a80"

IF EXIST(fout)\="" THEN "del "||fout

if fsym = "" then fsym="q:\Development\Dev-ZX\_Kernel\main.sym"

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

/* ***  generation of code ***
    **  header
*/
t=lineout(fout,"; "||copies("-",32))
t=lineout(fout,";  input file: "||fin)
t=lineout(fout,";      lenght: "||chars(fin))
if fsym<>"" then
   do
     t=lineout(fout,"; symbol file: "||fsym)
   end
t=lineout(fout,"; "||date()||" "||time())

/*  ** get animation length
*/
   str.1=c2x(charin(fin,,1))
   str.2=c2x(charin(fin,,1))
   alen = str.2||str.1

/*  ** copy animation block to right place
*/
t=lineout(fout,"	ld  hl,._scene_data")
t=lineout(fout,"	ld  de,.anim")
t=lineout(fout,"	ld  bc,#"||alen)
t=lineout(fout,"	ldir")

/* ** copy scene data
*/
t=lineout(fout,"	ld  de,scene")
t=lineout(fout,"	ld  bc,sceneSetup.len")
t=lineout(fout,"	ldir")

l = x2d(alen)+2         /* move data pointer after animation block) */
do i=1 to 4
   do j=2 to par.i.1
      l=l + par.i.j.1
   end
end

t = charin(fin,l,1)
lf= "0d"x||"0a"x

do until (chars(fin)=0)
   str.1=c2x(charin(fin,,1))
   str.2=c2x(charin(fin,,1))
   str = str.2||str.1
--   a = findLabel(str)                     -- execute

   str.1=c2x(charin(fin,,1))
   str.2=c2x(charin(fin,,1))
   str = str.2||str.1
   mob = findLabel(str)                     -- mob object

   str.1=c2x(charin(fin,,1))
   str.2=c2x(charin(fin,,1))
   str = str.2||str.1
   data = ", "||findLabel(str)                     -- data pointer

   size =", #"||c2x(charin(fin,,1))
   angl =", #"||c2x(charin(fin,,1))

   str.1=c2x(charin(fin,,1))
   str.2=c2x(charin(fin,,1))
   posx = ", #"||str.2||str.1

   str.1=c2x(charin(fin,,1))
   str.2=c2x(charin(fin,,1))
   posy = ", #"||str.2||str.1

   str.1=c2x(charin(fin,,1))
   str.2=c2x(charin(fin,,1))
   posz= ", #"||str.2||str.1

   /*
   o = "	setMob "||mob||data||size||angl||posx||posy||posz
   o = "	ld   de,"||mob
   */

   t = lineout(fout,"	ld   de,"||mob)
   t = lineout(fout,"	ld   c,10")
   t = lineout(fout,"	ldir")
   say "processing object :" mob
end

t=lineout(fout,"	jp   ._cont_setup")
t=lineout(fout,"._scene_data:")

/* ** store animation block (dbs)
*/

   t=lineout(fout,"")
   t=lineout(fout,"; animation")
   t=charin(fin,3,0)
   x=x2d(alen)

   say "processing animation size : " x


   do while x>0
      str.1=c2x(charin(fin,,1))
      str.2=c2x(charin(fin,,1))
      str  =str.2||str.1
      exe  =findLabel(str)

      select
            when x2d(str)=0 then do
                 say "... found end of animation block"
                 t=lineout(fout,"	dw #00" || "	; exit")
                 leave
                 end
            when exe="rotoid.animate.moveCyc" then do
                 say "... found exe :" exe
                 t=lineout(fout,"	dw " || exe || "	; exec")

                 str.1=c2x(charin(fin,,1))
                 str.2=c2x(charin(fin,,1))
                 str  =str.2||str.1

                 do j=0 to 8
                    adr=d2x(x2d(str)-j)
                    lbl=findlabel(adr)
                    if lbl<>"" then leave
                    -- say j str adr lbl
                 end
                 say "... found obj :" lbl
                 say "... offset    :" j

                 t=lineout(fout,"	dw " || lbl || "+" || j || "	; mob object")

                 call putdb("	; count reset")
                 call putdb("	; delay")
                 call putdb("	; count_current")
                 call putdw("	; accel_current")
                 call putdw("	; accel_temp")
                 call putdw("	; v0")
                 t=lineout(fout,"")

                 x=x-13
                 end
            otherwise
                 say "error in animation block"
      end
      say x " bytes remaining"
      -- pull txt
   end

do i=1 to 5
   call section(i)
end
t=lineout(fout,"._cont_setup:")

exit

section:
s=arg(1)
x=0

/* reposition input file, skip variable animation length header */

t = charin(fin,x2d(alen)+2,1)
do until (chars(fin)=0)
   x=x+1
   if x>s & (s<>5) then return
   if s=x | (s=5 & x>4) then do
      t=lineout(fout,"")
      t=lineout(fout,"; "||par.x)
      say "processing section:" par.x
   end
   do y=2 to par.x.1
      a   = ""
      b   = ""
      rem = copies(";",x>4 & y<=3)

      if (par.x.y.1=1) then
         do
           str=c2x(charin(fin,,1))
           if s=x | (s=5 & x>4) then
              t=lineout(fout,"	db  #"||str||"	;"||par.x.y)
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
                 if a="" then do
                    a="#"||str
                    say "Warning! Label not found:" str
                    b="	; *** Warning! Fixed Address! *** "
                 end
              end
           else
              do
                 a = ""
                 b = ""
              end
           if s=x | (s=5 & x>4) then
              t=lineout(fout,rem||"	dw   " || a || b || "#"||str||"	;"||par.x.y)
         end
   end
end

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

putdb:
parse arg comment
str.1=c2x(charin(fin,,1))
t = lineout(fout,"	db #" || str.1 || comment)
return

putdw:
parse arg comment
   str.1=c2x(charin(fin,,1))
   str.2=c2x(charin(fin,,1))
   str = str.2||str.1
t = lineout(fout,"	dw #" || str || comment)
return

EXIST:
PARSE ARG filename
RETURN STREAM(filename,"C","QUERY EXISTS")