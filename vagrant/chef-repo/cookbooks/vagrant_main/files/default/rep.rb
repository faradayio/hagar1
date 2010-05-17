#!/usr/bin/env ruby

require 'fileutils'
require 'rubygems'
require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/object/blank
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3

class StringReplacer
  NEWLINE = "AijQA6tD1wkWqgvLzXD"
  START_MARKER = '# START StringReplacer %s -- DO NOT MODIFY'
  END_MARKER = "# END StringReplacer %s -- DO NOT MODIFY#{NEWLINE}"
  
  attr_accessor :path
  def initialize(path)
    @path = path
  end
  
  def replace!(replacement, id, after_line)
    id = 1 unless id.present?
    after_line = nil unless after_line.present?
    new_path = "#{path}.new"
    backup_path = "#{path}.bak"
    current_start_marker = START_MARKER % id.to_s
    current_end_marker = END_MARKER % id.to_s
    replacement_with_markers = current_start_marker + NEWLINE + replacement + NEWLINE + current_end_marker
    text = IO.read(path).gsub("\n", NEWLINE)
    if text.include? current_start_marker
      text.sub! /#{Regexp.escape current_start_marker}.*#{Regexp.escape current_end_marker}/, replacement_with_markers
    elsif after_line
      text.sub! /(#{Regexp.escape after_line}#{Regexp.escape NEWLINE})/, '\1' + replacement_with_markers
    else
      text << NEWLINE << replacement_with_markers
    end
    text.gsub! NEWLINE, "\n"
    File.open(new_path, 'w') { |f| f.write text }
    FileUtils.mv path, backup_path
    FileUtils.mv new_path, path
  end
end

target, replacement, id, after_line = ARGV

s = StringReplacer.new(target)
s.replace! replacement, id, after_line
