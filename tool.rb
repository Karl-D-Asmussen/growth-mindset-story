#! /usr/bin/ruby2.4

END { _run(ARGV[0]) if $0 == __FILE__ }

require 'yaml'
require 'erb'
require 'pathname'

require './functions'

$DATA = {}

def import(filename)
  f = Pathname.new(filename)
  y = f.sub_ext('.yaml')
  if f.file? and f.readable?
    if y.file? and y.readable? and y.mtime > f.mtime
      $DATA = YAML.load(y.read())
    else
      _run(f.to_s)
    end
  else
    raise IOError, "cannot open file #{f} for reading" unless y.readable? and y.file?
  end
end

def dig(*dig)
  val = $DATA.dig(*(dig.flatten))
  case val
  when Float, Array, Hash
    val
  else
    raise TypeError, "#{dig.flatten.join(':')} not a stat"
  end
end

def dig_soft(*dig, default: nil)
  val = $DATA.dig(*(dig.flatten))
  case val
  when Float, Array, Hash
    val
  when nil
    default
  else
    raise TypeError, "#{dig.flatten.join(':')} not a stat"
  end
end


def with(*dig)
  dig = dig.flatten
  raise TypeError, "#{dig.find {|x| not x.is_a?(String)}} is not a string" unless
    dig.all? {|s| s.is_a?(String)} and not dig.empty?

  at = $DATA
  dig[0...-1].each do |ix|
    at = (at[ix] ||= {})
  end
  at[dig.last] = yield at[dig.last]
end

def namespace(*dig)
  with(dig) do |it|
    case it
    when nil then {}
    when Hash then it
    else raise TypeError, "#{dig.join(':')} is not a namespace"
    end
  end
end

def stat(*dig, at: nil)
  raise TypeError, "#{at} is neither nil nor Float" unless
    at.nil? or at.is_a?(Float)

  with(*dig) do |it|
    if it.nil? or at
      (at || 0.00).round(2)
    elsif at.nil? and it.is_a?(Float)
      it
    else
      raise TypeError, "#{dig.fatten.join(':')} is not a stat"
    end
  end
end

$BUMP=0.01
def bump(*dig, by: $BUMP)
  raise TypeError, "#{by} is not a Float" unless
    by.is_a?(Float)

  stat(*dig)

  with(*dig) do |it|
    (it + by).round(2)
  end
end

def list(*dig, this: nil)
  raise TypeError, "#{this} is neither nil nor String nor Array of Strings" unless
    this.nil? or this.is_a?(String) or (this.is_a?(Array) and this.all? { |s| s.is_a?(String) })

  this = [this] if this.is_a?(String)

  with(*dig) do |it|
    if it.nil? or this
      this || []
    elsif this.nil? and it.is_a?(Array) and it.all? { |s| s.is_a?(String) }
      it
    else
      raise TypeError, "#{dig.flatten.join(':')} is not a notepad"
    end
  end
end

def post(*dig, this:)
  raise TypeError, "#{this} is neither String nor Array of Strings" unless
    this.is_a?(String) or (this.is_a?(Array) and this.all? { |s| s.is_a?(String) })

  this = [this] if this.is_a?(String)

  list(*dig)

  with(*dig) do |it|
    it.concat(this)
  end
end

def delete(*dig, ix: nil, mat: nil) 
  if ix
    list(*dig)
    with(*dig) do |it|
      $stderr.puts("deleted #{dig.flatten.join(':')} [#{ix}] = #{it.slice!(ix)}")
      it
    end
  elsif mat
    list(*dig)
    with(*dig) do |it|
      $stderr.puts("deleted #{dig.flatten.join(':')} [#{mat}] = #{it.grep(mat)}")
      it.grep_v(mat)
    end
  else
    namespace(*(dig[0...-1]))
    with(*(dig[0...-1])) do |it|
      $stderr.puts("deleted #{dig.flatten.join(':')} = #{it.delete(dig.last)}")
      it
    end
  end
end

def _capture
  data = $DATA
  $DATA = {}
  yield
  return $DATA
ensure
  $DATA = data
end

$FIRST_RUN = false
def _run(filename)
  f = Pathname.new(filename)
  h = f.sub_ext('.html')
  if f.readable? and f.file?
    if $FIRST_RUN
      $stderr = File.open('/dev/null', 'w')
    else
      $FIRST_RUN = true
    end
    erb = ERB.new(f.read(), nil, '<> > -', )
    erb.filename = f.to_s
    _pandoc(f.to_s, erb.result)
    $stderr = STDERR
    _export(f.to_s)
  else
    raise IOError, "cannot open file #{f} for reading" unless f.readable? and f.file?
  end
  return nil
end

def _pandoc(filename, data)
  f = Pathname.new(filename)
  x = f.dirname / ('.' + f.basename.to_s)
  h = f.sub_ext('.html')

  if not x.exist? or x.writable?
    x.write(data)
  else
    raise IOError, "could not open file #{x} for writing"
  end

  unless system("pandoc -Sf markdown -t html -o #{h} #{x}")
    raise IOError, "pandoc borked on #{f}"
  end

  x.unlink
end

def _export(filename)
  f = Pathname.new(filename)
  y = f.sub_ext('.yaml')
  raise IOError, "cannot open file #{y} for writing" unless y.writable? or not y.exist?
  y.write(YAML.dump($DATA))
  return nil
end
