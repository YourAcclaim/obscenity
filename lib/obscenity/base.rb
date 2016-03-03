module Obscenity
  class Base
    class << self

      def blacklist
        @blacklist ||= set_list_content(Obscenity.config.blacklist)
      end

      def blacklist=(value)
        @blacklist = value == :default ? set_list_content(Obscenity::Config.new.blacklist) : value
      end

      def whitelist
        @whitelist ||= set_list_content(Obscenity.config.whitelist)
      end

      def whitelist=(value)
        @whitelist = value == :default ? set_list_content(Obscenity::Config.new.whitelist) : value
      end

      def profane?(text)
        return(false) unless text.to_s.size >= 3
        blacklist.each do |foul|
          return(true) if text =~ term_regex(foul) && !whitelist.include?(foul)
        end
        false
      end

      def sanitize(text)
        return(text) unless text.to_s.size >= 3
        blacklist.each do |foul|
          text.gsub!(term_regex(foul), replace(foul)) unless whitelist.include?(foul)
        end
        @scoped_replacement = nil
        text
      end

      def replacement(chars)
        @scoped_replacement = chars
        self
      end

      def offensive(text)
        words = []
        return(words) unless text.to_s.size >= 3
        blacklist.each do |foul|
          words << foul if text =~ term_regex(foul) && !whitelist.include?(foul)
        end
        words.uniq
      end

      def replace(word)
        content = @scoped_replacement || Obscenity.config.replacement
        case content
        when :vowels then word.gsub(/[aeiou]/i, '*')
        when :stars  then '*' * word.size
        when :nonconsonants then word.gsub(/[^bcdfghjklmnpqrstvwxyz]/i, '*')
        when :default, :garbled then '$@!#%'
        else content
        end
      end

      private
      def end_word_boundary(term)
        if /\b\z/ =~ term
          '(?=_|\b)'
        else
          '(?=_|\z|\s|-|\.|\?|\!|,|:|;|&|"|\'|\(|\))'
        end

      end

      def set_list_content(list)
        case list
        when Array then list
        when String, Pathname then YAML.load_file( list.to_s )
        else []
        end
      end

      def start_word_boundary(term)
        if /\A\b/ =~ term
          '(?<=_|\b)'
        else
          '(?<=_|\A|\s|-|\.|\?|\!|,|:|;|&|"|\'|\(|\))'
        end
      end

      def term_regex(foul)
        /#{start_word_boundary(foul)}#{Regexp.escape(foul)}#{end_word_boundary(foul)}/i
      end
    end
  end
end
