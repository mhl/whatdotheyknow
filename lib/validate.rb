# validate.rb:
# mySociety library of validation functions, such as valid email address.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: validate.rb,v 1.7 2009/08/21 17:10:09 francis Exp $

module MySociety
    module Validate

        # Stop someone writing all in capitals, or all lower case letters.
        def Validate.uses_mixed_capitals(s)
            # count Roman alphabet lower and upper case letters
            capitals = 0
            lowercase = 0 
            s.each_char do |c|
                capitals = capitals + 1 if c.match(/[A-Z]/)
                lowercase = lowercase + 1 if c.match(/[a-z]/)
            end

            # allow short things (e.g. short titles might be validly all caps)
            # (also avoids division by zero)
            return true if (capitals + lowercase < 20)

            # what proportion of roman A-Z letters are capitals?
            percent_capitals = capitals.to_f / (capitals + lowercase).to_f * 100

            # anything more than 75% caps, or less than 0.5% capitals
            # XXX should check these against database of old FOI requests etc.
            #raise percent_capitals.to_s
            if percent_capitals > 75.0 || percent_capitals < 0.5
                return false
            end

            return true
        end

        def Validate.email_match_regexp
            # This is derived from the grammar in RFC2822.
            # mailbox = local-part "@" domain
            # local-part = dot-string | quoted-string
            # dot-string = atom ("." atom)*
            # atom = atext+
            # atext = any character other than space, specials or controls
            # quoted-string = '"' (qtext|quoted-pair)* '"'
            # qtext = any character other than '"', '\', or CR
            # quoted-pair = "\" any character
            # domain = sub-domain ("." sub-domain)* | address-literal
            # sub-domain = [A-Za-z0-9][A-Za-z0-9-]*
            # XXX ignore address-literal because nobody uses those...

            specials = '()<>@,;:\\\\".\\[\\]'
            controls = '\\000-\\037\\177'
            highbit = '\\200-\\377'
            atext = "[^#{specials} #{controls}#{highbit}]"
            atom = "#{atext}+"
            dot_string = "#{atom}(\\s*\\.\\s*#{atom})*"
            qtext = "[^\"\\\\\\r\\n#{highbit}]"
            quoted_pair = '\\.'
            quoted_string = "\"(#{qtext}|#{quoted_pair})*\""
            local_part = "(#{dot_string}|#{quoted_string})"
            sub_domain = '[A-Za-z0-9][A-Za-z0-9-]*'
            domain = "#{sub_domain}(\\s*\\.\\s*#{sub_domain})*"

            return "#{local_part}\\s*@\\s*#{domain}"
        end

        def Validate.is_valid_email(addr)
            is_valid_address_re = Regexp.new("^#{Validate.email_match_regexp}\$")

            return addr =~ is_valid_address_re
        end

        # For finding email addresses in a body of text.
        # XXX Less exact than the one above, but I had problems in Ruby's
        # regexp engine with the one above crashing it.
        def Validate.email_find_regexp
            return Regexp.new("(\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}\\b)")
        end


        # validate_postcode POSTCODE
        # Return true is POSTCODE is in the proper format for a UK postcode. Does not
        # require spaces in the appropriate place.
        def Validate.is_valid_postcode(postcode)
            return Validate.postcode_match_internal(postcode, "^", "$")
        end
        def Validate.contains_postcode?(postcode)
            return Validate.postcode_match_internal(postcode, "\\b", "\\b")
        end

        def Validate.postcode_match_internal(postcode, pre, post)
            # Our test postcode
            if (postcode.match("/#{pre}zz9\s*9z[zy]$/i"))
                return true 
            end
            
            # See http://www.govtalk.gov.uk/gdsc/html/noframes/PostCode-2-1-Release.htm
            inn  = 'ABDEFGHJLNPQRSTUWXYZ'
            fst = 'ABCDEFGHIJKLMNOPRSTUWYZ'
            sec = 'ABCDEFGHJKLMNOPQRSTUVWXY'
            thd = 'ABCDEFGHJKSTUW'
            fth = 'ABEHMNPRVWXY'
            num0 = '123456789' # Technically allowed in spec, but none exist
            num = '0123456789'
            nom = '0123456789'
            gap = '\s\.'	

            if (postcode.match(/#{pre}[#{fst}][#{num0}][#{gap}]*[#{nom}][#{inn}][#{inn}]#{post}/i) ||
                postcode.match(/#{pre}[#{fst}][#{num0}][#{num}][#{gap}]*[#{nom}][#{inn}][#{inn}]#{post}/i) ||
                postcode.match(/#{pre}[#{fst}][#{sec}][#{num}][#{gap}]*[#{nom}][#{inn}][#{inn}]#{post}/i) ||
                postcode.match(/#{pre}[#{fst}][#{sec}][#{num0}][#{num}][#{gap}]*[#{nom}][#{inn}][#{inn}]#{post}/i) ||
                postcode.match(/#{pre}[#{fst}][#{num0}][#{thd}][#{gap}]*[#{nom}][#{inn}][#{inn}]#{post}/i) ||
                postcode.match(/#{pre}[#{fst}][#{sec}][#{num0}][#{fth}][#{gap}]*[#{nom}][#{inn}][#{inn}]#{post}/i))
                return true
            else
                return false
            end
        end

    end
end


