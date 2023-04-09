/* rac - run after compile, osg 2019
         used for sjasm, pspad

regina.exe %dir%rac.rex %dir%run.sna 2 q:\tools\
*/

"start /wait regina.exe %dir%sym2asm_main.sym.rex"

/* CALL sym2asm_main.sym.rex */

PARSE ARG filein emulator toolpath

IF toolpath="" THEN toolpath="q:\Tools\"
IF emulator="" THEN emulator=1

e.1="emuzwin\emuzwin.exe"
e.2="specemu2016\specemu.exe"
e.3="zxspin07\zxspin.exe"
e.4="zxspin\zxspin.exe"
e.5="unreal\unreal.exe"
e.6="emuzwin\emuzwin.bat"

toolpath||e.emulator filein

EXIT

EXIST:
PARSE ARG filename
RETURN STREAM(filename,"C","QUERY EXISTS")
