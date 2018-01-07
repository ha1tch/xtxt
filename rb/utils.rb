
class String
    attr :xtext_enabled

    def ascii!
        self.force_encoding("ascii-8bit")
    end

    def iso!
        self.force_encoding("iso-8859-1")
    end

    def usascii!
        self.force_encoding("us-ascii")
    end

    def utf8!
        self.force_encoding("utf-8")
    end

    def concat_stream(text)
    end

    def enable_xtext(flag)
    end
    
    alias_method :xtext!, :enable_xtext

    def xtext_enabled?
    end
end