parse arg input

s=0
do while lines(input)>0
   myline=linein(input)
   SELECT
     WHEN INDEX(myline,"STRUCT")>0 THEN
      DO
        s=1
        t=WORD(myline,2)||d2c(9)
        END
     WHEN INDEX(myline,"ENDS")>0 THEN
      DO
        t=input||d2c(9)||t
        say t
        END
     OTHERWISE
      DO
        PARSE var myline var ":" type def ";" .
        IF STRIP(type)="db" THEN type=".B"
        IF STRIP(type)="dw" THEN type=".W"
        t=t||STRIP(var)||type||"("||STRIP(def)||") "
        END
     END
end
