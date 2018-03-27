module SimpleHashtag
  class Hashtag < ActiveRecord::Base
    self.table_name = 'simple_hashtag_hashtags'

    has_many :hashtaggings

    validates :name, uniqueness: true

    # 日本語を対応するために使用したRegex: https://gist.github.com/terrancesnyder/1345094

    # http://www.rikai.com/library/kanjitables/kanji_codes.unicode.shtml
    # Basic Latin: \u0000-\u00FF
    # Arrows: \u2190-\u21FF
    # Various Symbols: \u2600-\u26FF
    # Geometric Shapes: \u25A0-\u25FF
    # Mathematical Operators: \u2200-\u22FF
    # Radicals: \u2E80-\u2FDF
    # Common Punctuation: \u2000-\u206F
    # CJK Symbols: \u3001-\u303F
    # Unicode Hiragana: \u3040-\u309F
    # Unicode Katakana (including Phonetics): \u30A0-\u31FF
    # Unicode Kanbun: \u3190-\u319F
    # Full- & Half Width: \uFF00-\uFFEF
    # Common used Kanji: \u4e00-\u9faf

    HASHTAG_REGEX = /(?:|^)([#]([“‐々〇〻①-⑳Ⅰ-ⅹa-z0-9\u2190-\u21FF\u2600-\u26FF\u25A0-\u25FF\u2200-\u22FF\u2E80-\u2FDF\u3001-\u303F\u2000-\u206F\u3040-\u309F\u30A0-\u30FF\u3190-\u319F\uFF00-\uFFEF\u4e00-\u9faf)])+)/i

    def self.find_by_name(name)
      Hashtag.where('lower(name) =?', name.downcase).first
    end

    def self.find_or_create_by_name(name, &block)
      find_by_name(name) || create(name: name, &block)
    end

    def name=(val)
      write_attribute(:name, val.downcase)
    end

    def name
      read_attribute(:name).downcase
    end

    def hashtaggables
      hashtaggings.includes(:hashtaggable).collect(&:hashtaggable)
    end

    def hashtagged_types
      hashtaggings.pluck(:hashtaggable_type).uniq
    end

    def hashtagged_ids_by_types
      hashtagged_ids ||= {}
      hashtaggings.each do |h|
        hashtagged_ids[h.hashtaggable_type] ||= []
        hashtagged_ids[h.hashtaggable_type] << h.hashtaggable_id
      end
      hashtagged_ids
    end

    def hashtagged_ids_for_type(type)
      hashtagged_ids_by_types[type]
    end

    def to_s
      name
    end

    # From DB
    def self.clean_orphans
      # TODO: Make this method call a single SQL query
      orphans = all.select { |h| h.hashtaggables.empty? }
      orphans.map(&:destroy)
    end
  end
end
