module GraphQL
  module Compatibility
    # Include me into a minitest class
    # to add assertions about parse errors
    module ParseErrorSpecification
      def assert_raises_parse_error(query_string)
        assert_raises(GraphQL::ParseError) {
          parse(query_string)
        }
      end

      def test_it_includes_line_and_column
        err = assert_raises_parse_error("
          query getCoupons {
            allCoupons: {data{id}}
          }
        ")

        assert_includes(err.message, '"{"')
        assert_equal(3, err.line)
        assert_equal(25, err.col)
      end

      def test_it_rejects_unterminated_strings
        assert_raises_parse_error('{ " }')
        assert_raises_parse_error(%|{ "\n" }|)
      end

      def test_it_rejects_unexpected_ends
        assert_raises_parse_error("query { stuff { thing }")
      end

      def assert_rejects_character(char)
        err = assert_raises_parse_error("{ field#{char} }")
        assert_includes(err.message, char.inspect, "The message includes the invalid character")
      end

      def test_it_rejects_invalid_characters
        assert_rejects_character(";")
        assert_rejects_character("\a")
        assert_rejects_character("\xef")
        assert_rejects_character("\v")
        assert_rejects_character("\f")
        assert_rejects_character("\xa0")
      end

      def test_it_rejects_bad_unicode
        assert_raises_parse_error(%|{ field(arg:"\\x") }|)
        assert_raises_parse_error(%|{ field(arg:"\\u1") }|)
        assert_raises_parse_error(%|{ field(arg:"\\u0XX1") }|)
        assert_raises_parse_error(%|{ field(arg:"\\uXXXX") }|)
        assert_raises_parse_error(%|{ field(arg:"\\uFXXX") }|)
        assert_raises_parse_error(%|{ field(arg:"\\uXXXF") }|)
      end

      def assert_empty_document(query_string)
        doc = parse(query_string)
        assert_equal 0, doc.definitions.length
      end

      def test_it_parses_blank_queries
        assert_empty_document("")
        assert_empty_document(" ")
        assert_empty_document("\t \t")
      end

      def test_it_restricts_on
        assert_raises_parse_error("{ ...on }")
        assert_raises_parse_error("fragment on on Type { field }")
      end

      def test_it_rejects_null
        err = assert_raises_parse_error("{ field(input: null) }")
        assert_includes(err.message, "null")
      end
    end
  end
end
