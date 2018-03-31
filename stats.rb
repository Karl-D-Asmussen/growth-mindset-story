
MEAN = 10
STDDEV = Math::E
def cdf(x)
  mean = Math.log(MEAN)
  sd = Math.log(STDDEV)
  0.5 + Math.erf( (Math.log(x) - mean) / (Math.sqrt(2.0) * sd) ) / 2.0
end

RACIAL = { str: 0.0, agi: 0.0, con: 0.0, cha: 2.0, wis: 0.0, int: 1.0 }
FEAT = { str: 0.0, agi: 0.0, con: 0.0, cha: 1.0, wis: 1.0, int: 1.0 }

trace_var :$ABI do |val|
  puts "STR #{str = val[:str] + FEAT[:str] + RACIAL[:str]} (#{cdf str})"
  puts "AGI #{agi = val[:agi] + FEAT[:agi] + RACIAL[:agi]} (#{cdf agi})"
  puts "CON #{con = val[:con] + FEAT[:con] + RACIAL[:con]} (#{cdf con})"
  puts "CHA #{cha = val[:cha] + FEAT[:cha] + RACIAL[:cha]} (#{cdf cha})"
  puts "WIS #{wis = val[:wis] + FEAT[:wis] + RACIAL[:wis]} (#{cdf wis})"
  puts "INT #{int = val[:int] + FEAT[:int] + RACIAL[:int]} (#{cdf int})"
  puts "COST #{val.values.sum - 6.0*8.0}"
end
$ABI = { str: 8.0, agi: 8.0, con: 8.0, cha: 8.0, wis: 8.0, int: 8.0 }
