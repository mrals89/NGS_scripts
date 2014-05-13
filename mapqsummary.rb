#!/home/mrals/.rvm/rubies/ruby-2.0.0-p247/bin/ruby
=begin
------------------------------------------------------------------------------
--                                                                          --
--                                 MATTEW RALSTON                           --
--                                                                          --
--                               S K E L E T O N . R B                      --
--                                                                          --
------------------------------------------------------------------------------
-- TITLE                                                                    --
--                                                                          --
--  Summer 2013                                                             --
--                                                                          --
------------------------------------------------------------------------------
-- This file is designed ...
--                                                                          --
------------------------------------------------------------------------------
=end

################################################
#
#               R E Q U I R E
#
################################################





################################################
#
#               U S E R    V A R I A B L E S
#
################################################


PWD="/home/mrals/ETP/Expression"
INFILES=`ls #{PWD}/*.bed`.split("\n")

################################################
#
#               S U B - R O U T I N E S
#
################################################

################################################

################################################

def parse(file)
  liszt=[]
  File.open(file,'r').each do |line|
    liszt << line.split[-2]
  end
  return liszt
end


def main
  dict={}
  INFILES.each do |file|
    dict[file[0...-4]] = parse(file)
  end
  File.open('/home/mrals/ETP/summary/mapq_summary.txt','w') do |file|
    file.puts(dict.keys.join("\t"))
    temp=[]
    dict.each {|key,value| temp << value.size}
    temp.max.times do |x|
      temp=[]
      dict.each {|key,value| value[x].class == NilClass ? temp << "N/A" : temp << value[x]}
      file.puts(temp.join("\t"))
    end
  end
end

#*****************************************************************************#
################################################
#
#-----------------------------------------------
#
#                   M A I N
#-----------------------------------------------
#
################################################


main




##########################  E O F   ############################################
