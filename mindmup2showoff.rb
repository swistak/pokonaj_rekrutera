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

showoff["title"] = mup["title"]
showoff["description"] = "Generated from mindmup."
sections = showoff["sections"] = []

sorted_ideas = mup["ideas"].
  map{|rank, idea| [rank.to_f, idea]}.
  sort_by{|rank, idea| [-rank/rank.abs, rank] } # Positive first, then negative

sorted_ideas.each_with_index do |rank_idea, index|
  rank, idea = *rank_idea
  dir_name = idea["title"].
    to_url(:replace_whitespace_with => "_")

  mkdir_p "%02d.%s" % [index, dir_name]

  p [index, rank, dir_name]
end
