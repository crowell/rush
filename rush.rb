#!/usr/bin/env ruby
require 'colorize'
require 'trollop'

opts = Trollop::options do
  opt :nasm, "nasm binary", :default => "nasm"
  opt :output, "shellcode output name", :default => "output"
  opt :objdump, "objdump binary", :default => "objdump"
  opt :raw, "save raw shellcode", :default => false
  opt :elf, "run elf of shellcode", :default => false
  opt :compiler, "compiler for compiling shellcode", :default => "gcc"
  opt :bits, "number of bits (64/32)", :default=>32
end

# first thing is going to be compile to an elf
asm = ARGV[0]
if ARGV.size < 1
  puts "USAGE: ./rush.rb <file.asm>"
  abort
end

elf = "elf"
compiler = opts[:compiler]
if opts[:bits] == 64
  elf = "elf64"
end
if opts[:bits] == 32
  compiler = compiler + " -m32"
end
assemble = "#{opts[:nasm]} -f #{elf} #{asm} -o #{opts[:output] + '.o'}"
`#{assemble}`

# now extract it
disass = `#{opts[:objdump]} -d #{opts[:output] + '.o'}`
regexp = /^\s+[0-9a-f]+:\t([[0-9a-f][0-9a-f] ]+)/
matches = disass.scan(regexp)
shellcode = ""
rawsc = ""
matches.each{|match|
  flattened = match.flatten[0].strip
  bytes = flattened.split(" ")
  bytes.each{|byte|
    shellcode = shellcode + "\\x" + byte
    rawsc = rawsc + byte.hex.chr
  }
}

puts shellcode

if opts[:raw] == true
  File.open("#{opts[:output]}.raw", 'w') {|file|
    file.write(rawsc)
  }
end

if opts[:elf] == true
  compile = "#{compiler} -o #{opts[:output]} #{opts[:output]}.o -nostartfiles -nostdlib -nodefaultlibs"
  `#{compile}`
end
