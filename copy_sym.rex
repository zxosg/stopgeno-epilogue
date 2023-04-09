date=STREAM('main.sym','C','QUERY TIMESTAMP')
date=CHANGESTR("-",date,"")
date=CHANGESTR(":",date,"")
date=CHANGESTR(" ",date,"_")
date=RIGHT(date,13)
"COPY main.sym demo\data\rotoid\main_"||date||".sym"

EXIT

EXIST:
PARSE ARG filename
RETURN STREAM(filename,"C","QUERY EXISTS")
