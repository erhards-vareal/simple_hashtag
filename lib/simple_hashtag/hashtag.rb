module SimpleHashtag
  class Hashtag < ActiveRecord::Base
    self.table_name = 'simple_hashtag_hashtags'

    has_many :hashtaggings

    validates :name, uniqueness: true

    # 日本語を対応するために使用したRegex: https://gist.github.com/terrancesnyder/1345094

    # TODO: Beef up the regex (ie.:what if content is HTML)
    # this is how Twitter does it:
    # https://github.com/twitter/twitter-text-rb/blob/master/lib/twitter-text/regex.rb
    HASHTAG_REGEX = /(?:\s|　|^)([#]([ゝヽゞヾ〱〲々〃ー−０-９ｦ-ﾟァ-ヶぁ-ゞＡ-ｚ一-龯a-z0-9\-_]+))/i

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
