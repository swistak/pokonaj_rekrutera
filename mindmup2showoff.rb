require 'fileutils'
require 'json'
require 'stringex'

include FileUtils

fname = ARGV[0] || "pokonaj_rekrutera.mup"

# See https://github.com/mindmup/mapjs/wiki/Data-Format
#
# Version 2
#
#  {
#    formatVersion:2, /*numeric */
#    id: _idea id_, /* numeric */
#    title: _idea title_, /* string */
#    attr : {  /* key-value map of style properties, optional */
#      style: { }, /* key-value map of style properties, optional */
#      collapsed: true/false /* optional */
#      attachment: { contentType: _content type_, content: _content_ }
#  }
#  ideas: { 
#    _rank_: {_sub idea_}, 
#    _rank2_: {_sub idea 2_} ... }, /* key-value map of subideas, optional */ 
#  }
#
#  ranks are floats, and identify the order of sub-ideas for visualisations. 
#  first-level children can be positive or negative. in mapjs visualisation 
#  of a mindmap, positive subideas will be painted on the right, top-down 
#  in ascending order, negative subideas will be painted on the left, bottom-up 
#  in ascending order (so order is always ascending clockwise).
#

mup_content = File.read(fname)
mup = JSON.parse(mup_content)

# Showoff
#
#   {
#     "name": "Something",
#     "description": "Example Presentation",
#     "templates" : {
#       "default" : "tpl1.tpl",
#       "special" : "tpl2.tpl"
#     },
#     "sections": [
#       {"section":"one"}
#     ]
#   }

showoff = Hash.new

if mup["formatVersion"] != 2
  puts "Converter only supports version 2 of Mind Mup"
  exit 1
end

showoff["name"] = mup["title"]
showoff["description"] = "Generated from mindmup."
sections = showoff["sections"] = [{"section" => "00.title"}]

sorted_ideas = lambda{|node|
  node["ideas"].
    map{|rank, idea| [rank.to_f, idea]}.
    sort_by{|rank, idea| [-rank/rank.abs, rank] } # Positive first, then negative
}

sorted_ideas[mup].each_with_index do |rank_idea, index|
  rank, idea = *rank_idea
  section_name = idea["title"].to_url(:replace_whitespace_with => "_")
  dir_name = "%02d.%s" % [index + 1, section_name]
  mkdir_p dir_name
  
  sections.push("section" => dir_name)

  file_name = "%02d.%s.md" % [0, "intro"]
  File.open(File.join(dir_name, file_name), "w") do |f|
    title, subtitle = idea["title"].split(".", 2)
    f.puts "!SLIDE"
    f.puts
    f.puts "# #{title} #"
    f.puts "## #{subtitle} ##"
  end

  sorted_ideas[idea].each_with_index do |subidea_rank, j|
    subrank, subidea = *subidea_rank

    subsection_name = subidea["title"].to_url(:replace_whitespace_with => "_")
    file_name = "%02d.%s.md" % [j + 1, subsection_name]

    File.open(File.join(dir_name, file_name), "w") do |f|
      bullets = []

      collect_bullets = lambda do |node, level|
        bullets.push([level, node["title"]])

        sorted_ideas[node].each do |r, sn|
          collect_bullets[sn, level + 1]
        end if node["ideas"]
      end

      make_slide = lambda do
        f.puts "!SLIDE smaller incremental"
        f.puts
        f.puts "### #{idea["title"]}  ###"
        f.puts "## #{subidea["title"]} ##"
        f.puts
      end

      make_slide.call

      if subidea["ideas"]
        sorted_ideas[subidea].each do |r, sn|
          collect_bullets[sn, 0]
        end

        counter = 1
        bullets.each do |bullet|
          l, text = *bullet

          if counter > 3 && l == 0
            f.puts; make_slide.call
            counter = 0
          end

          f.puts("    "*l + ["-", "*"][l%2] + " " + text)
          counter += 1
        end
      end 
    end
  end
end

File.open("showoff.json", "w") do |f|
  f.write JSON.pretty_generate(showoff)
end
