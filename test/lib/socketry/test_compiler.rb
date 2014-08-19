#!/usr/bin/env ruby

require 'benchmark'
require 'fileutils'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')

require 'socketry/compiler'

unless path = ARGV.shift
  puts "Usage: #{$0} <file-path>"
  exit 1
end

OUTPUT = 'output.dat'

srand
for method in Socketry::Compiler::METHODS
  puts "\nUsing method #{method}:"
  compiler = Socketry::Compiler.new(:method => method)
  output_size = 0
  
  file_size = File.size(path)
    
  result = nil
  count = 0
  time = Benchmark.measure do
    result = compiler.compile_file(path) do |input_offset, piece_info|
      #puts "#{piece[:size]} / #{Socketry::Compiler::DEFAULTS[:piece_size]}"
      output_size += piece_info[:output][:size]
      count += 1
      print "#{'%3d' % (input_offset*100.0/file_size)}% [#{input_offset} / #{file_size}]: #{count}\r"
      $stdout.flush
    end
  end
  
  puts ""
  puts "hash: #{Digest.hexencode(result[:input][:hash])}"
  puts "pieces: #{result[:pieces].size}"
  print "time: #{time}"
  puts "speed: #{result[:input][:size]/time.real/1024/1024} MB/s"
  
  if result[:input][:size] != 0
    puts "compression rate: #{output_size*1.0/result[:input][:size]}"
  else
    puts "output_size: #{output_size} (input size is 0)"
  end
  
  # create output placeholder
  compiler.create_placeholder_file(OUTPUT, result[:input][:size])

  # # extract and insert random piece
  # # piece_index = rand(result[:pieces].size)
  # piece_index = 0
  # print "Extracting piece #{piece_index} from #{path}: "
  # piece = compiler.extract_piece_from_file(path, result[:pieces][piece_index], result[:options])
  # puts "OK"
  # print "Inserting piece #{piece_index} into #{OUTPUT}: "
  # compiler.insert_piece_into_file(OUTPUT, piece, result[:pieces][piece_index], result[:options])
  # puts "OK"
  
  # randomly extract and reassemble
  puts "Randomly extracting and reasembling into #{OUTPUT}"
  piece_infos = result[:pieces].dup
  piece_infos = piece_infos.sort_by { rand }
  
  piece_infos.each_with_index do |piece_info, i|
    print "[ #{i + 1} / #{piece_infos.size} ]\r"
    $stdout.flush
    piece = compiler.extract_piece_from_file(path, piece_info, result[:options])
    compiler.insert_piece_into_file(OUTPUT, piece, piece_info, result[:options])
  end
  
  print "Checking integrity of #{OUTPUT}: "
  compiler.check_file_integrity(OUTPUT, result[:input][:size], result[:input][:hash], result[:options])
  puts "OK"
  
  FileUtils.rm(OUTPUT)
  
end
