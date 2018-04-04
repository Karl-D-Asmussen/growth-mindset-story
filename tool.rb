#! /usr/bin/ruby2.4

END { _run(ARGV[0]) if $0 == __FILE__ }

require 'yaml'
require 'erb'
require 'pathname'

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

def bump(*dig, by: 0.01)
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
    elsif to.nil? and it.is_a?(Array) and it.all? { |s| s.is_a?(String) }
      it
    else
      raise TypeError, "#{dig.flatten.join(':')} is not a stat"
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

def _capture
  data = $DATA
  $DATA = {}
  yield
  return $DATA
ensure
  $DATA = data
end

def _run(filename)
  f = Pathname.new(filename)
  h = f.sub_ext('.html')
  if f.readable? and f.file?
    _pandoc(f.to_s, ERB.new(f.read(), nil, '<> > -').result)
    _export(f.to_s)
  else
    raise IOError, "cannot open file #{f} for reading" unless y.readable? and y.file?
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

  unless system("pandoc -f markdown -t html -o #{h} #{x}")
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
