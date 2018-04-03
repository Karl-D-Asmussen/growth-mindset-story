#! /usr/bin/ruby2.4

require 'yaml'
require 'distribution'

require './tool'

Math::LOG_10 = Math::log(10.0)
NADA = Hash.new(0.0).freeze

File.open(ARGV[0].gsub(/\D+/,'') + '.yaml') do |file|
  data = YAML.load(file)
  sum = 0.to_r
  names = []
  bonuses = []
  ARGV[1..-1].map do |thing|
    if /(.+)::(.+)/ =~ thing
      ns = $1.split.join
      it = $2.split.join

      num = data.dig(ns, it)
      if num.nil?
        num = '0'
        $stderr.puts "null #{ns}::#{it}"
      end
      num =
        begin
          num.to_r
        rescue 
          $stderr.puts "nan #{num}"
          0.to_r
        end

      sum += num
      names << '%s::%s (num)' % [ns, it, num]
    elsif /(\+|-)\d+\.\d+/ =~ thing
      num = $&.to_r
      sum += num
      bonuses << ' %s %.02f' % [ ("%+i" % (num<=>0))[0], num.abs ]
    end
  end
  if names.empty?
    names << 'Null::Null (0.00)'
  end
  roll = Distribution::LogNormal::GSL_::p_value(Random::rand, Math::log(10.0), 1.0).to_r
  puts [names.join(' + '), bonuses.join].join
  puts "%.02f vs %.02f; %s %+.02f" % [sum, roll, (roll <= sum ? "success" : "failure"), sum - roll]
end

