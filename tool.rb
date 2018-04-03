#! /usr/bin/ruby2.4
#
require 'yaml'

filenames = Dir['*.mkdn'].grep(/^\d+\.mkdn$/).sort_by { |s| /\d+/ =~ s; $&.to_i }
things = {}

filenames.each do |filename|
  File.open filename do |file|
    file.each_line do |line|
      if /<!--(.+)::(.+)=(.+)-->/ =~ line
        ns = $1.split.join
        it = $2.split.join
        (things[ns] ||= {})[it] ||= "0.00"
        things[ns][it] = "%.02f" % (things[ns][it].to_r + $3.strip.to_r)
      end
      if /<!--(.+)::(.+)\|(.+)-->/ =~ line
        ns = $1.split.join
        it = $2.split.join
        (things[ns] ||= {})[it] ||= []
        things[ns][it] << $3.strip
      end
    end
  end
  File.open filename.sub('.mkdn','.yaml'), 'w' do |file|
    file.write(YAML::dump(things))
  end
end

