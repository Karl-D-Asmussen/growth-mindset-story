#! /usr/bin/ruby2.4

require './tool'
require 'distribution'

END { main(ARGV) if $0 == __FILE__ }

def main(argv)
  import(argv[0])
  things = what_things
  puts show(things).join(' ')
  target = values(things).sum.round(2)
  success, roll, margin = roll(target)
  puts '%.02f vs %.02f' % [target, roll]
  puts '%s %+.02f' % [success ? 'success' : 'failure', margin]
end

def result(target, success, roll, margin)
  ['%.02f vs %.02f' % [target, roll],
   '%s %+.02f' % [success ? 'success' : 'failure', margin]].freeze
end

def roll(target)
  r = Random.rand while (r ||= 1.0) == 1.0
  r = Distribution::LogNormal::GSL_::p_value(r, Math.log(10), 1).round(2)
  [ r <= target, r, target - r ].freeze
end

def what_things
  $stdin.each_line.collect do |line|
    line = line.chomp
    if /^\s*[+-]\s*\d+.\d\d$/ =~ line
      line.gsub(/\s+/,'').to_f
    elsif /^\w+(?:\s+\w+)*$/ =~ line
      line.split
    else
      raise SyntaxError, "#{line}"
    end
  end.sort_by do |a, b|
    case a
    when Float
      case b
      when Float then 0
      when Array then -1
      end
    when Array
      case b
      when Float then 1
      when Array then 0
      end
    end
  end
end

def show(things)
  things.collect do |thing|
    case thing
    when Array
      thing.join(':')
    when Float
      "%+.02f" % thing
    end
  end
end

def values(things)
  things.collect do |thing|
    case thing
    when Float
      thing
    when Array
      val = $DATA.dig(*thing)
      raise TypeError, "#{thing.join(':')} is not a stat" unless val.is_a?(Float)
      val
    end
  end
end
