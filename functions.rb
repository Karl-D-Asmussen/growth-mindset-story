
require 'distribution'
require './tool'

def seed(x) Random.srand(x.hash) end

def tiefling
  list %w[Race Name], this: ['Tiefling']
  stat %w[Race Speed], at: 20.00
  stat %w[Race Imagination], at: 5.00
  stat %w[Race Ability Charisma], at: 2.00
  stat %w[Race Ability Intellect], at: 1.00
end

ABILITIES=%w[Strength Agility Fortitude Charisma Wisdom Intellect]

def specify_abilities(*inorder)
  str, agi, frt, cha, wis, int =
    inorder.to_enum(:zip, ABILITIES.map { |s| dig_soft %w[Race Ability], s, default: 0.00 }).map { |a, b| a + b }

  $stderr.puts "#{str} #{agi} #{frt} #{cha} #{wis} #{int}"

  stat %w[Ability Strength], at: str
  stat %w[Ability Agility], at: agi
  stat %w[Ability Fortitude], at: frt
  stat %w[Ability Charisma], at: cha
  stat %w[Ability Wisdom], at: wis
  stat %w[Ability Intellect], at: int

  sum = str + agi + frt + cha + wis + int
  sum -= 6*8.00
  sum -= ABILITIES.map { |s| dig_soft %w[Race Ability], s, default: 0.00 }.sum
  $stderr.puts "Total ability score point use: #{sum}"
end

def dig_abilities
  ABILITIES.map { |s| dig 'Ability', s }.
    to_enum(:zip, ABILITIES.map { |s| dig_soft %w[Bonus Ability], s, default: 0.00 }).map { |a, b| a + b }
end

def compute_aptitudes
  str, agi, frt, cha, wis, int = dig_abilities
  $stderr.puts "#{str} #{agi} #{frt} #{cha} #{wis} #{int}"
  
  stat %w[Aptitude Vim], at: (str+cha)/4.00
  stat %w[Aptitude Reflex], at: (agi+wis)/4.00
  stat %w[Aptitude Will], at: (frt+int)/4.00

  rspd = dig %w[Race Speed]
  rima = dig %w[Race Imagination]

  stat %w[Aptitude Speed], at: rspd + [str,agi].max
  stat %w[Aptitude Imagination], at: rima + [int,wis].max
  stat %w[Aptitude Pulchritude], at: [frt, cha].max
end

APTITUDES=%w[Vim Reflex Will Speed Imagination Pulchritude]

def dig_aptitudes
  APTITUDES.map { |s| dig 'Aptitude', s }.
    to_enum(:zip, APTITUDES.map { |s| dig_soft %w[Bonus Aptitude], s, default: 0.00 }).map { |a, b| a + b }
end

def ability_aptitude_table
  str, agi, frt, cha, wis, int = dig_abilities
  vim, rfx, wil, spd, ima, pul = dig_aptitudes

  tables = <<IT
|||||||||
|-:|:-:|-:|:-:|:-|-:|:-:|-:|:-:|
| _Strength_ | _%.02f_ | _Charisma_ | _%.02f_ | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | _Vim_ | _%.02f_ | _Speed_ | _%.02f_ |
| _Agility_ | _%.02f_ | _Wisdom_ | _%.02f_ | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | _Reflex_ | _%.02f_ | _Imagination_ | _%.02f_ |
| _Fortitude_ | _%.02f_ | _Intellect_ | _%.02f_ | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | _Will_ | _%.02f_ | _Pulchritude_ | _%.02f_ |
IT

  tables % [str, cha, vim, spd, agi, wis, rfx, ima, frt, int, wil, pul]
end

def roll(*digs, tag: nil)
  fields = digs.select { |x| x.is_a? Array }
  bonuses = digs.select { |x| x.is_a? Float }
  pretty = fields.map { |x| x.join(':') }
  values = fields.map { |x| q = dig_soft x, default: 0.0;
                        raise TypeError, "#{x.join(':')} is not a number" unless q.is_a? Float;
                        q }

  line = caller_locations(1,1).first.lineno

  t = values.sum
 
  r = Random.rand while (r ||= 1.0) == 1.0
  r = Distribution::LogNormal::GSL_::p_value(r, Math.log(10), 1).round(2)

  if tag
    tag = "#{tag} (#{line})"
  else
    tag = line.to_s
  end

  STDERR.puts("--- #{tag} ---")
  STDERR.puts("    #{pretty.join ' '} #{bonuses.map(&:to_s).join(' ')}")
  STDERR.puts("    #{r} vs. #{t} = #{r <= t ? 'success' : 'failure'} by #{(r - t).abs.round(2)}")
end

def skill_table

  tables = "||||||\n|:-:|:-:|:-:|:-:|:-:|\n"
  
  %w[Cognition Practice Knowledge Willworking].each do |c|
    prof = dig_soft c, default: nil
    next unless prof
    tables << "| --- | --- | ___#{c}___ | --- | --- |\n"
    prof.each do |k, v|
      tables << "| _#{k}_ | · | · | · | · |\n"
      v.each.each_slice(5) do |sl|
        tables << '| ' + sl.map(&'_%s %.02f_ '.method(:%)).join('| ') + '| '*(6-sl.size) + "\n"
      end
    end
  end
  
  tables
end
