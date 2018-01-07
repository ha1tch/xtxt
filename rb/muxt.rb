#!/usr/bin/ruby
usage = "Usage: muxt output_filename filename1 filename2 [filename3, ...]"

if ARGV.size < 3 then 
    STDERR.puts "Error: bad arguments"
    STDERR.puts usage 
    exit 1
end

outfname = ARGV.shift 
outfname=outfname+".xtxt" if outfname == outfname.rpartition(".").last 
   
puts "Muxing: ("+ ARGV.join(", ")+") into: #{outfname}"

streams = []
ARGV.each {|fname|
	lines = File.open(fname).readlines
	begin
		0.upto(lines.size-1) {|ln| lines[ln].unicode_normalize!}
	rescue
		STDERR.puts "Error: Invalid unicode in #{fname}"
		exit 1
	end
	streams << lines
}

NSM = "\xFF\xFE"  # next stream marker
NFM = "\xFF\xFD"  # next frame marker
NCM = "\xFF\xFC"  # next chunk marker

output = ""

stream_sizes = []
streams.each {|astream| 
	stream_sizes << astream.size
}

longest = (stream_sizes.max) - 1

0.upto(longest) {|lineno|
	txt=""
	streams.each {|astream|
        aline = astream[lineno] ? astream[lineno] : ""
        txt << aline + NSM  
    }
    output <<  txt + NFM
    
}

begin
    File.open(outfname, "w").write(output)
rescue
    STDERR.puts "Error: attempting to write #{outfname}"
    exit 1
end

puts "#{outfname} muxed OK"
