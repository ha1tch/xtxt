cc = 64           # character count
cp = 195          # codepage base
cn = 220-195      # number of codepages
ot = ""           # output buffer
ot.force_encoding("ascii-8bit")

maxcols=20
cols=0
require 'pp'
0.upto(cn-1) {|cpx|
    sb = ""  # string buffer
    sb.force_encoding("ascii-8bit")
    0.upto(cc-1) {|idx|
	    sb = sb+"  "
        b = [ cp+cpx, 128+idx ]
        sb.setbyte(sb.bytes.size-2, b.first)
        sb.setbyte(sb.bytes.size-1, b.last)

        cols=cols+1
        if cols>=maxcols then
            sb = sb.chomp + "\n"
            cols=0
        end
        #pp sb.bytes
    }
    ot = ot + sb  #+ "\n"
}

#ot.unicode_normalize!
#puts ot.unicode_normalized?
File.open("utfchars.txt", "w").write(ot)
