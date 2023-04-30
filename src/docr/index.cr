module Docr
  class Index
    struct Result
      getter doc_ids : Hash(Int32, Bool)
      getter frequency : Hash(Int32, Int32)

      def initialize
        @doc_ids = {} of Int32 => Bool
        @frequency = {} of Int32 => Int32
      end
    end

    getter trigrams : Hash(UInt32, Result)
    getter doc_ids : Hash(Int32, Bool)
    getter max_doc_id : Int32

    def initialize
      @trigrams = {} of UInt32 => Result
      @doc_ids = {} of Int32 => Bool
      @max_doc_id = 0
    end

    def parse_trigram(str : String) : Array(UInt32)
      return [] of UInt32 if str.empty?
      results = [] of UInt32

      0.upto(str.size - 3) do |i|
        trigram = str[i].ord.to_u32 << 16 | str[i + 1].ord.to_u32 << 8 | str[i + 2].ord.to_u32
        results << trigram
      end

      results
    end

    def add(doc : String) : Int32
      new_id = @max_doc_id + 1
      trigrams = parse_trigram doc

      trigrams.each do |trigram|
        result : Result

        if current = @trigrams[trigram]?
          if current.doc_ids.has_key? new_id
            current.frequency[new_id] = current.frequency[new_id] + 1
          else
            current.doc_ids[new_id] = true
            current.frequency[new_id] = 1
          end
          result = current
        else
          result = Result.new
          result.doc_ids[new_id] = true
          result.frequency[new_id] = 1
        end

        @trigrams[trigram] = result
      end

      @max_doc_id = new_id
      @doc_ids[new_id] = true

      new_id
    end

    def delete(doc : String, id : Int32) : Nil
      trigrams = parse_trigram doc
      trigrams.each do |trigram|
        if current = @trigrams[trigram]?
          if (freq = current.frequency[id]?) && freq > 1
            current.frequency[id] = freq - 1
          else
            current.frequency.delete id
            current.doc_ids.delete id
          end
        end
      end
    end

    def intersect(first : Hash(Int32, Bool), second : Hash(Int32, Bool)) : Hash(Int32, Bool)
      ret_ids = check_ids = {} of Int32 => Bool

      if first.size >= second.size
        ret_ids = second
        check_ids = first
      else
        ret_ids = first
        check_ids = second
      end

      ret_ids.each do |id|
        ret_ids.delete id if check_ids.has_key? id
      end

      ret_ids
    end

    def query(doc : String) : Array(Int32)
      trigrams = parse_trigram doc

      return @doc_ids.keys if trigrams.empty?
      return [] of Int32 unless ret_ids = @trigrams[trigrams.first]?.try &.doc_ids

      trigrams.shift
      trigrams.each do |trigram|
        return [] of Int32 unless check_ids = @trigrams[trigram]?.try &.doc_ids
        ret_ids = intersect ret_ids, check_ids
      end

      ret_ids.keys
    end
  end
end
