
# Work in progress...
# Modelling a ruby gem to generalise xtxt use
# in ruby applications.


require './utils.rb' # additions to class String

module Xtxt

    NSM = "\xFF\xFE".ascii!  # next stream marker
    NFM = "\xFF\xFD".ascii!  # next frame marker
    NCM = "\xFF\xFC".ascii!  # next chunk marker


    # A stream at rest is roughly equivalent to 
    # the contents of an utf-8 text file.  

    class Stream
        def initialize(text="")
            @lines=[]
        end

        def empty?
        end

        def line(lineno)
        end

        def line_width(lineno)
        end

        def longest_line
        end

        # Save stream as plain text file
        def save_to_file()
        end

        def to_s
        end
    end

    # work in progress
    class Chunk
        def initialize
            @streams=[]
        end

        def chunk(chunkno)
        end
    end


    class Frame
        def initialize
            @lines=[]
        end

        def to_a
            @lines
        end

        def to_s
            @lines.join(" ")
        end
    end


    class Xtext
        attr :stream_count
        attr :chunk_count
        attr :streams
        attr :chunks

        def initialize(text="")
            @streams = []
        end

        def frame(frameno)
        end

        def line(frameno,lineno)
        end

        def delete_line(streamno,frameno)
        end

        def delete_frame(frameno)
        end

        def set_line(streamno,frameno, aline)
        end

        def set_frame(streamno,frameno, aframe)
        end
        alias_method :[],:set_line

        # The user can concatenate plain 
        # texts and extended texts to constitute 
        # a new combined set of streams.
        # To avoid overriding standard concatenation 
        # methods and symbols for String we
        # chose to use the >> method, which is 
        # typically unused by the class String. 
        # When >> appears in this context it means
        # "append to", with the left argument being
        # the source and the right argument being
        # the target. Thus,  stream1 >> stream2
        # in our context means "append stream1 to stream2"
        # 
        # Xtext  >> Xtext => Xtext (streams of both xtexts)
        #
        # String >> Xtext => Xtext (string becomes stream0
        #          with the rest of the streams following)
        #                        
        # Xtext  >> String => Xtext (A new stream made from
        #          the contents of String is appended as
        #          the last stream of Xtext)
        #
        # Xtext  >> Xtext::Stream = Xtext (A new stream is
        #          added as the last Stream of Xtext)
        # 
        # String >> String => Xtext
        #
        # To enable for stream concatenation using
        # String + Xtext and String + String
        # we don't tweak the String plus method
        # directly, because that could potentially
        # trigger undesired effects for some programs.
        # Stream concatention for Strings is enabled
        # with String#enable_xtext(true|false) and checked 
        # with String#xtext_enabled?
        # The method String#concat_stream is available
        # and will still  the xtext_enabled? flag when used.
        
        def >>(text)
        end

        def concat_stream(text)
        end

        # load_from_file and save_to_file accept 
        # an open File object or a String with 
        # a filename. If a File object is passed,
        # and it is already opened, it must be
        # opened with the appropriate read or write
        # mode for the operation that needs to be
        # performed. If the File object is not
        # opened, load_from_file will open it
        # in read only mode, and return the File
        # object opened. It will otherwise close
        # the File object after reads or writes. 
        def load_from_file(afile)
        end

        def save_to_file(afile)
        end

        def load_from_string(text)
        end

        def delete_stream(streamno)
        end

        def move_stream(fromno,tono)
        end

    end
end

