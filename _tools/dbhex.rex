parse arg fin fout width

prefix="#"
posfix=""
syntax="	defb  "
chlen=2
flins=0

if width="" then
   width=8

say "Binary file to assembler defb definition. (C) osg '09"
say "use: rexx.exe dbhex.rex source_file dest_file [bytes_per_line]"
say " format: hexadecimal"
say " prefix:" prefix
say "postfix:" posfix
say
say " input file:" fin
say "output file:" fout
say " bytes/line:" width

t=lineout(fout,"; input file:"||fin)
len=chars(fin)

do i=1 to len by width
	str=c2x(charin(fin,,width))
	len=length(str)
	lin=syntax
	sep=""
	do j=1 to len by chlen
		lin=lin||sep||prefix||substr(str,j,chlen)||posfix
		sep=","
	end
	t=lineout(fout,lin,)
	flins=flins+1
end
say "lines processed" flins
