gem 'minitest'
require 'minitest/autorun'
require 'standoff'

class StandoffTest < Minitest::Test
  def test_hello_world
    assert_equal "hello world",
      "hello world"
  end

  def test_create_tag_no_attributes
    tag = Standoff::Tag.new(:content => "tylenol",
                            :name => "medication",
                            :start => 5,
                            :end => 11)
    assert tag.is_a? Standoff::Tag
  end

  def test_tag_overlap
    gold = Standoff::Tag.new(:start => 5, :end => 8)
    inside = Standoff::Tag.new(:start => 6, :end => 7)
    early = Standoff::Tag.new(:start => 1, :end => 4)
    late = Standoff::Tag.new(:start => 11, :end => 14)
    same = Standoff::Tag.new(:start => 5, :end => 8)
    overlap = Standoff::Tag.new(:start => 1, :end => 6)
    assert gold.overlap(inside)
    assert ! gold.overlap(early)
    assert gold.overlap(same)
    assert gold.overlap(overlap)
    assert ! gold.overlap(late)
  end

  def test_create_tag_one_attribute
    tag = Standoff::Tag.new(:content => "tylenol",
                            :name => "medication",
                            :attributes => {:normalized => :tylenol},
                            :start => 5,
                            :end => 11)
    assert tag.is_a? Standoff::Tag
    assert_equal tag.name, "medication"
    assert_equal tag.content, "tylenol"
    assert_equal tag.start, 5
    assert_equal tag.end, 11
    assert_equal tag.attributes[:normalized], :tylenol
  end

  def test_create_annotated_string_no_tags
    as = Standoff::AnnotatedString.new(:signal => "take tylenol daily")
    assert as.is_a? Standoff::AnnotatedString
  end

  def test_create_annotated_string_with_tags
    med_name_tag = Standoff::Tag.new(:content => "tylenol",
                                     :name => "medication",
                                     :attributes => {:normalized => :tylenol},
                                     :start => 5,
                                     :end => 11)
    frequency_tag = Standoff::Tag.new(:content => "daily",
                                      :name => "freq",
                                      :attributes => {:normalized => :qd},
                                      :start => 13,
                                      :end => 17)
    as = Standoff::AnnotatedString.new(:signal => "take tylenol daily", :tags => [med_name_tag, frequency_tag])
    assert as.is_a? Standoff::AnnotatedString
  end

  def test_annotated_string_tag_accessor
    tags = []
    tags << Standoff::Tag.new(:content => "1", :name => "number", :start => 0, :end => 0)
    tags << Standoff::Tag.new(:content => "a", :name => "letter", :start => 2, :end => 2)
    tags << Standoff::Tag.new(:content => "b", :name => "letter", :start => 4, :end => 4)
    tags << Standoff::Tag.new(:content => "4", :name => "number", :start => 6, :end => 6)
    as = Standoff::AnnotatedString.new(:signal => "1 a b 4", :tags => tags)
    assert as.is_a? Standoff::AnnotatedString
    assert_equal as.tags.length, 4
    assert_equal as.tags("letter").length, 2
    assert_equal as.tags("imaginary").length, 0
  end
end
