parse arg input

do while lines(input)>0
   myline=linein(input)
   IF INDEX(myline,".hdi.")>0 THEN
      DO
        PARSE var myline . rsc .
        say rsc
        END
end

exit