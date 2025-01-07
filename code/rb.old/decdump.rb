

fname = ARGV.first

txt = File.open(fname).read

nformat = " %3d "
col = 1
header="      "
1.upto(10) {|i|
    header <<  nformat.%(i)
}
header << "\n"
header << "      "+ "---- "*10 << "\n"

puts header

o = ""
idx=1
ln = 0

o =nformat.%(ln)+":"
txt.bytes.each {|b|
      o << nformat.%(b)
      idx=idx+1
      if idx==11 then
            idx=1
            o << "\n"
            ln=ln+1
            o << nformat.%(ln*10)+":"
        end
}

puts o 

