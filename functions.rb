
require 'distribution'
require './tool'

def seed(x) Random.srand(x.hash) end

def tiefling
  list %w[Race Name], this: ['Tiefling', 'Setite']
  stat %w[Race Speed], at: 20.00
  stat %w[Race Imagination], at: 5.00
  stat %w[Race Ability Charisma], at: 2.00
  stat %w[Race Ability Intellect], at: 1.00

  list %w[Race Feature List], this: [
    'Elemental Resilience',
    'Radiance Sensitivity',
    'Darkvision',
    'Magic Talent',
    '[REDACTED]'
  ]
  stat %w[Race Feature Resistances Freezing], at: 0.50
  stat %w[Race Feature Resistances Fire], at: 0.50
  stat %w[Race Feature Resistances Radiant], at: 1.50
  stat %w[Race Feature Senses Darkvision], at: 10.00
end

def show_race
  
  show_list(%w[Race Feature List], title: "_#{dig(%w[Race Name]).join(', ')}:_\n\n")
end

DAMAGE_TYPES = %w[Blunt Sharp Piercing Fire Freezing Acid Toxic Thunder Lightning Entropic Radiant Force Void Psychic]
def make_body
  DAMAGE_TYPES.each do |type|
    stat %w[Body Resistance], type, at: dig_soft(%w[Race Features Resistances], type, default: 1.00)
  end
  str, agi, frt, cha, wis, int = dig_abilities
  stat %w[Body Health], at: [str, agi, frt].max
  stat %w[Body Sanity], at: [cha, wis, int].max
  stat %w[Body Hit\ Points], at: (str + agi + frt)
  stat %w[Body Mad\ Points], at: (cha + wis + int)
  list %w[Body Injuries], this: []
  list %w[Body Conditions], this: ['Dark Triad Personality']
end

def dig_resistance(type)
  dig(%w[Body Resistance], type) + dig_soft(%w[Bonus Resistance], type)
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
| _Agility_ | _%.02f_ | _Wisdom_ | _%.02f_ | | _Reflex_ | _%.02f_ | _Imagination_ | _%.02f_ |
| _Fortitude_ | _%.02f_ | _Intellect_ | _%.02f_ | | _Will_ | _%.02f_ | _Pulchritude_ | _%.02f_ |
IT

  tables % [str, cha, vim, spd, agi, wis, rfx, ima, frt, int, wil, pul]
end

def roll(*digs, tag: nil)
  fields = digs.select { |x| x.is_a? Array }
  bonuses = digs.select { |x| x.respond_to?(:to_f) }.map(&:to_f)
  pretty = fields.map { |x| x.join(':') }
  values = fields.map { |x| q = dig_soft x, default: 0.0;
                        raise TypeError, "#{x.join(':')} is not a number" unless q.is_a? Float;
                        q }

  line = caller_locations(1,1).first.lineno
        
  t = [values.sum + bonuses.sum, 0.01].max.round(2)
 
  r = Random.rand while (r ||= 1.0) == 1.0
  r = Distribution::LogNormal::GSL_::p_value(r, Math.log(10), 1).round(2)

  if tag
    tag = "#{tag} (#{line})"
  else
    tag = line.to_s
  end

  $stderr.puts("--- #{tag} ---")
  $stderr.puts("    #{pretty.join ' '} #{bonuses.map(&:to_s).join(' ')}")
  $stderr.puts("    #{r} vs. #{t} = #{r <= t ? 'success' : 'failure'} by #{(r - t).abs.round(2)}")
end

def skill_table(cat=//, sub=//)

  tables = "| | | |\n|:-:|:-:|:-:|\n"
  
  %w[Cognition Practice Knowledge Willworking].each do |c|
    next unless cat =~ c
    prof = dig_soft c, default: nil
    next unless prof 
    tables << "| | | |\n"
    tables << "| --------- | --- _#{c}_ --- | --------- |\n"
    prof.each.sort_by { |k, v| k }.each do |k, v|
      next unless sub =~ k
      tables << "| | | |\n"
      tables << "| --- | _#{k}_ | --- |\n"
      v.each.sort_by {|k, v| k}.each_slice(3) do |sl|
        begin
          tables << '| ' + sl.map(&'_%s %.02f_ '.method(:%)).join('| ') + '| '*(4-sl.size) + "\n"
        rescue => e
          $stderr.puts sl.to_s
          raise
        end
      end
    end
  end
        
  tables
end

BODY = %w[Health Sanity Hit\ Points Mad\ Points]
def dig_body
  BODY.map { |s| dig('Body', s) + dig_soft(%w[Bonus Body], s, default: 0.0) }
end

def body_table
  ht, san, hp, mp = dig_body
  <<END % [ht, hp, san, mp]
| | | | | |
|-:|:-:|:-:|-:|:-:|
| _Health_ | _%.02f_ | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | _Don't Get Hit Points_ | _%.02f_ |
| _Sanity_ | _%.02f_ | | _Don't Go Mad Points_ | _%.02f_ |
END
end

def show_list(*dig, title: nil, tpl: "- _%s_\n")
  list(*dig) 
  
  title.to_s + dig(*dig).map { |i| tpl % i }.join
end

def repeat(n, tag: nil)
  r = Random.rand(n)
  line = caller_locations(1,1).first.lineno
  if tag
    tag = "#{tag} (#{line})"
  else
    tag = line.to_s
  end
  
  $stderr.puts "#{tag} repeating #{r} times"
  r.times { yield }
end

def roll_many(*digs, n: 10, tag: nil)
  fields = digs.select { |x| x.is_a? Array }
  bonuses = digs.select { |x| x.respond_to?(:to_f) }.map(&:to_f)
  pretty = fields.map { |x| x.join(':') }
  values = fields.map { |x| q = dig_soft x, default: 0.0;
                        raise TypeError, "#{x.join(':')} is not a number" unless q.is_a? Float;
                        q }

  line = caller_locations(1,1).first.lineno
        
  t = [values.sum + bonuses.sum, 0.01].max.round(2)

  p = Distribution::LogNormal::GSL_::cdf(t, Math.log(10), 1).round(2)
  
  s = n.times.collect {
    r = Random.rand while (r ||= 1.0) == 1.0
    r = Distribution::LogNormal::GSL_::p_value(r, Math.log(10), 1).round(2)
    (t - r).round(2)
  }

  if tag
    tag = "#{tag} (#{line})"
  else
    tag = line.to_s
  end

  $stderr.puts("--- #{tag} ---")
  $stderr.puts("    #{pretty.join ' '} #{bonuses.map(&:to_s).join(' ')}")
  $stderr.puts("    Binom(#{n}, #{p}) = #{s.collect { |x| ((x <=> 0) + 1) <=> 0 }.sum} successes")
  $stderr.puts("    Cumulative success/failure margin = #{s.sum}")
end
