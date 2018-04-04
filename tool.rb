#! /usr/bin/ruby2.4
#
require 'yaml'

filenames = Dir['*.mkdn'].grep(/^\d+\.mkdn$/).sort_by { |s| /\d+/ =~ s; $&.to_i }
things = Hash.new { |h,k| h[k] = {} }

filenames.each do |filename|
  File.open filename do |file|
    file.each_line.each_with_index do |line, linenum|
      linenum += 1
      if /<!--(.+)::(.+)=(\s*\d+\.\d\d\s*)-->/ =~ line
        ns = $1.split.join
        it = $2.split.join
        if things.dig(ns, it).is_a? Array
          $stderr.puts "#{filename}:#{linenum} type overwrite"
        end
        things[ns][it] = $3.strip
      elsif /<!--(.+)::(.+)\+=(\s*\d+\.\d\d\s*)-->/ =~ line
        ns = $1.split.join
        it = $2.split.join
        if things.dig(ns, it).is_a? Array
          $stderr.puts "#{filename}:#{linenum} type error"
          things[ns][it] = '0.00'
        end
        things[ns][it] = '%.02f' % (things[ns][it].to_r + $3.strip.to_r)
      elsif /<!--(.+)::(.+)@(.*)-->/ =~ line
        ns = $1.split.join
        it = $2.split.join
        if things.dig(ns, it).is_a? String
          $stderr.puts "#{filename}:#{linenum} type overwrite"
        end
        things[ns][it] = ($3.strip.empty? ? [] : [$3.strip])
      elsif /<!--(.+)::(.+)\+@(.*)-->/ =~ line
        ns = $1.split.join
        it = $2.split.join
        if things.dig(ns, it).is_a? String
          $stderr.puts "#{filename}:#{linenum} type error"
          things[ns][it] = []
        end
        things[ns][it] << $3.strip
      elsif /<!--(.+)::(.+)!\s*-->/ =~ line
        ns = $1.split.join
        it = $2.split.join
        if things.dig(ns, it)
          things[ns].delete(it)
          if things[ns].empty?
            things.delete(ns)
          end
        else
          $stderr.puts "#{filename}:#{linenum} not found"
        end
      elsif /<!--(.+)::(.+)\?\s*-->/ =~ line
        ns = $1.split.join
        it = $2.split.join
        $stderr.puts "#{filename}:#{linenum} #{ns}::#{it} := #{things.dig(ns, it).inspect}"
      elsif /<!--.*-->/ =~ line
        $stderr.puts "#{filename}:#{linenum} syntax error"
      end
    end
  end
  File.open filename.sub('.mkdn','.yaml'), 'w' do |file|
    file.write(YAML::dump(things))
  end
end

