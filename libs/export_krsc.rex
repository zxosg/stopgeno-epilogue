parse arg input

do while lines(input)>0
   myline=linein(input)
   IF LEFT(myline,1)<>";" & INDEX(myline,".hdi.")>0 THEN
      DO
        PARSE var myline "rload" rsc .
        say rsc
        END
end

exit