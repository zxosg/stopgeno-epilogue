parse arg input

do while lines(input)>0
   myline=linein(input)
   IF INDEX(myline,"MACRO")>0 THEN
      DO
        PARSE var myline "MACRO" name params
        params = strip(params)
        say input||d2c(9)||name||d2c(9)||params
        END
end

exit