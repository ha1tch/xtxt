#!/usr/bin/ruby

# this script generates an invalid xtxt file.
# useful when testing muxcat's marker slicing.

badtext = "111111111\n".force_encoding("ascii-8bit")
badtext << "\xFF\xFE"
badtext << "222222222\n"
#badtext << "\xFF"  # this wrecks stream order
badtext << "\xFF\xFE\xFF\xFD"
badtext << "333333333\n"

#badtext << "\xFF\xEE" # invalid marker

# if closing tags are disabled, muxcat 
# should still work, but the last frame
# (the line with 3s) won't be displayed.
badtext << "\xFF\xFE\xFF\xFE\xFF\xFD" 

require 'pp'
pp badtext.bytes

File.open("bad.xtxt","w").write(badtext)