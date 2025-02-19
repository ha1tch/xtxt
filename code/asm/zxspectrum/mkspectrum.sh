
# haitch@duck.com
# https://github.com/ha1tch/xtxt/tree/main/code/asm
#
# Licensed under the Do Whatever You Want License. 
# You are hereby commanded to comply with the license.

echo "asm: count-frames for the ZX Spectrum 48k"
~/prj/pasmo/pasmo-0.5.5/pasmo  count-frames.zxspectrum.z80.asm cf-zxs48k.bin

echo "asm: count-frames for the ZX Spectrum +3"
~/prj/pasmo/pasmo-0.5.5/pasmo  count-frames-zxspectrumplus3.z80.asm cf-zxsplus3.bin

echo "asm: count-streams for the ZX Spectrum +3"
~/prj/pasmo/pasmo-0.5.5/pasmo  count-streams.zxspectrumplus3.z80.asm cs-zxsplus3.bin

ls -al c?-*.bin
