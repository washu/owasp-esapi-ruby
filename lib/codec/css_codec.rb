#
# Implementation of the Codec interface for backslash encoding used in CSS.

module Owasp
  module Esapi
    module Codec
      class CssCodec < BaseCodec

        # Returns backslash encoded character.
        def encode_char(immune, input)
          # check immune
          return input if immune.include?(input)
          # check for alpha numeric
          hex = hex(input)
          # add a space at end to terminate under css
          return "\\#{hex} " unless hex.nil? or hex.empty?
          input
        end

        # decode a character from the PushableString
        # We follow the rules defined for CSS by w3
        # http://www.w3.org/TR/CSS21/syndata.html#characters
        # All CSS syntax is case-insensitive within the ASCII range (i.e., [a-z] and [A-Z] are equivalent), except for parts that are not under the control of CSS. For example,
        # the case-sensitivity of values of the HTML attributes "id" and "class", of font names, and of URIs lies outside the scope of this specification.
        # Note in particular that element names are case-insensitive in HTML, but case-sensitive in XML. In CSS, identifiers (including element names, classes, and IDs in selectors)
        # can contain only the characters [a-zA-Z0-9] and ISO 10646 characters U+00A0 and higher, plus the hyphen (-)  and the underscore (_); they cannot start with a digit,
        # two hyphens, or a hyphen followed by a digit. Identifiers can also contain escaped characters and any ISO 10646 character as a numeric code (see next item). For instance,
        # the identifier "B&W?" may be written as "B\&W\?" or "B\26 W\3F". Note that Unicode is code-by-code equivalent to ISO 10646 (see [UNICODE] and [ISO10646]).
        # In CSS 2.1, a backslash (\) character can indicate one of three types of character escape. Inside a CSS comment, a backslash stands for itself, and if a backslash is
        # immediately followed by the end of the style sheet, it also stands for itself (i.e., a DELIM token).
        #
        # First, inside a string, a backslash followed by a newline is ignored (i.e., the string is deemed not to contain either the backslash or the newline).
        # Outside a string, a backslash followed by a newline stands for itself (i.e., a DELIM followed  by a newline).
        # <P>
        # Second, it cancels the meaning of special CSS characters. Any character (except a hexadecimal digit, linefeed, carriage return, or form feed) can be escaped
        # with a backslash to remove its special meaning. For example, "\"" is a string consisting of one double quote. Style sheet preprocessors must not remove these backslashes
        # from a style sheet since that would change the style sheet's meaning.
        # <P>
        # Third, backslash escapes allow authors to refer to characters they cannot easily put in a document.  In this case, the backslash is followed by at most six
        # hexadecimal digits (0..9A..F), which stand for the ISO 10646 ([ISO10646]) character with that number, which must not be zero. (It is undefined in CSS 2.1 what happens
        # if a style sheet does contain a character with Unicode codepoint zero.) If a character in the range [0-9a-fA-F] follows the hexadecimal number, the end of the number
        # needs to be made clear. There are two ways to do that:
        # 1. with a space (or other white space character): "\26 B" ("&B"). In this case, user agents should treat a "CR/LF" pair (U+000D/U+000A) as a single white space character.
        # 2. by providing exactly 6 hexadecimal digits: "\000026B" ("&B")
        # In fact, these two methods may be combined. Only one white space character is ignored after a hexadecimal escape. Note that this means that a "real" space after the
        # escape sequence must be doubled.If the number is outside the range allowed by Unicode (e.g., "\110000" is above the maximum 10FFFF allowed in current Unicode), the UA
        # may replace the escape with the "replacement character" (U+FFFD). If the character is to be displayed, the UA should show a visible symbol, such as a
        # "missing character" glyph (cf. 15.2, point 5). Note: Backslash escapes are always considered to be part of an identifier or a string (i.e., "\7B" is not punctuation,
        # even though "{" is, and "\32" is allowed at the start of a class name, even though "2" is not). The identifier "te\st" is exactly the same identifier as "test".
        def decode_char(input)

          input.mark
          first = input.next
          if first.nil? or !first.eql?('\\')
            input.reset
            return nil
          end
          second = input.next
          if second.nil?
            input.reset
            return nil
          end
          # rule execution
          fallthrough = false
          if second == "\r"
            # speical whitespace cases
            if input.peek?("\n")
              input.next
              fallthrough = true
            end
          end
          # handle the skip ahead. Ruby case doesnt allow for fall through so we inlined the small setup
          return decode_char(input) if second == "\n" || second == "\f" || second == "\u0000" || fallthrough
          # non hex test
          return second if !input.hex?(second)
          # check for 6 hex digits for rule 3
          tmp = second
          for i in 1..5 do
            c = input.next
            if c.nil? or c =~ /\s/
              break
            end
            if input.hex?(c)
              tmp << c
            else
              input.push(c)
            end
          end
          # check the codepoint and if outside of range, return teh replacement
          begin
            i = tmp.hex
            return i.chr(Encoding::UTF_8) if i >= START_CODE_POINT and i <= END_CODE_POINT
            return "\ufffd"
          rescue Exception => e
            raise EncodingError.new("Received an exception while parsing a string verified to be hex")
          end
        end
      end
    end
  end
end
