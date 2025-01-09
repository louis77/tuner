/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file PlayerController.vala
 */

using Gst;

/**
 * @class Metadata
 *
 * @brief Stream Metadata transform
 *
 */
public class Tuner.Model.Metadata : GLib.Object
{
    private static string[,] METADATA_TITLES =
        // Ordered array of tags and descriptions
    {
        {"title",            _("Title")                                },
        {"artist",           _("Artist")                               },
        {"album",            _("Album")                                },
        {"image",            _("Image")                                },
        {"genre",            _("Genre")                                },
        {"homepage",         _("Homepage")                             },
        {"organization",     _("Organization")                         },
        {"location",         _("Location")                             },
        {"extended-comment", _("Extended Comment")                     },
        {"bitrate",          _("Bitrate")                              },
        {"audio-codec",      _("Audio Codec")                          },
        {"channel-mode",     _("Channel Mode")                         },
        {"track-number",     _("Track Number")                         },
        {"track-count",      _("Track Count")                          },
        {"nominal-bitrate",  _("Nominal Bitrate")                      },
        {"minimum-bitrate",  _("Minimum Bitrate")                      },
        {"maximum-bitrate",  _("Maximim Bitrate")                      },
        {"container-format", ("Container Format")                      },
        {"application-name", _("Application Name")                     },
        {"encoder",          _("Encoder")                              },
        {"encoder-version",  _("Encoder Version")                      },
        {"datetime",         _("Date Time")                            },
        {"private-data",     _("Private Data")                         },
        {"has-crc",          _("Has CRC")                              }
    };

    private static Gee.List<string> METADATA_TAGS =  new Gee.ArrayList<string> ();

    static construct  {

        uint8 tag_index = 0;
        foreach ( var tag in METADATA_TITLES )
        // Replicating the order in METADATA_TITLES
        {
            if ((tag_index++)%2 == 0)
                METADATA_TAGS.insert (tag_index/2, tag );
        }
    }

    public string all_tags { get; private set; default = ""; }
    public string title { get; private set; default = ""; }
    public string artist { get; private set; default = ""; }
    public string image { get; private set; default = ""; }
    public string genre { get; private set; default = ""; }
    public string homepage { get; private set; default = ""; }
    public string audio_info { get; private set; default = ""; }
    public string org_loc { get; private set; default = ""; }
    public string pretty_print { get; private set; default = ""; }

    private Gee.Map<string,string> _metadata_values = new Gee.HashMap<string,string>();  // Hope it come out in order

    
    /**
    * Extracts the metadata from the media stream.
    *
    * @param media_info The media information stream
    * @return true if the metadata has changed
    */
    internal bool process_media_info_update (PlayerMediaInfo media_info) 
    {
        var streamlist = media_info.get_stream_list ().copy ();

        title        = "";
        artist       = "";
        image        = "";
        genre        = "";
        homepage     = "";
        audio_info   = "";
        org_loc      = "";
        pretty_print = "";

        foreach (var stream in streamlist)     // Hopefully just one metadata stream
        {
            var? tags = stream.get_tags (); // Get the raw tags

            if (tags == null)
                break;                                              // No tags, break on this metadata stream

            if (all_tags == tags.to_string ())
                return false;                                                                    // Compare to all tags and if no change return false

            all_tags = tags.to_string ();
            debug(@"All Tags: $all_tags");

            string? s = null;
            bool    b = false;
            uint    u = 0;

            tags.foreach ((list, tag) =>
            {
                var index = METADATA_TAGS.index_of (tag);

                if (index == -1)
                {
                    warning(@"New meta tag: $tag");
                    return;
                }

                var type = (list.get_value_index(tag, 0)).type();

                switch (type)
                {
                    case  GLib.Type.STRING:
                        list.get_string(tag, out s);
                        _metadata_values.set ( tag,  s);
                        break;
                    case  GLib.Type.UINT:
                        list.get_uint(tag, out u);
                        if ( u > 1000)
                            _metadata_values.set ( tag,  @"$(u/1000)K");
                        else
                            _metadata_values.set ( tag,  u.to_string ());
                        break;
                    case  GLib.Type.BOOLEAN:
                        list.get_boolean (tag, out b);
                        _metadata_values.set ( tag,  b.to_string ());
                        break;
                    default:
                        warning(@"New Tag type: $(type.name())");
                        break;
                }
            }); // tags.foreach

            if (_metadata_values.has_key ("title" ))
                _title = _metadata_values.get ("title");
            if (_metadata_values.has_key ("artist" ))
                _artist = _metadata_values.get ("artist");
            if (_metadata_values.has_key ("image" ))
                _image = _metadata_values.get ("image");
            if (_metadata_values.has_key ("genre" ))
                _genre = _metadata_values.get ("genre");
            if (_metadata_values.has_key ("homepage" ))
                _homepage = _metadata_values.get ("homepage");

            if (_metadata_values.has_key ("audio_codec" ))
                _audio_info = _metadata_values.get ("audio_codec ");
            if (_metadata_values.has_key ("bitrate" ))
                _audio_info += _metadata_values.get ("bitrate ");
            if (_metadata_values.has_key ("channel_mode" ))
                _audio_info += _metadata_values.get ("channel_mode");
            if (_audio_info != null && _audio_info.length > 0)
                _audio_info = safestrip(_audio_info);

            if (_metadata_values.has_key ("organization" ))
                _org_loc = _metadata_values.get ("organization ");
            if (_metadata_values.has_key ("location" ))
                _org_loc += _metadata_values.get ("location");
            if (_org_loc != null && _org_loc.length > 0)
                org_loc = safestrip(_org_loc);

            StringBuilder sb = new StringBuilder ();
            foreach ( var tag in METADATA_TAGS )
            // Pretty print
            {
                if (_metadata_values.has_key(tag))
                {
                    sb.append ( METADATA_TITLES[METADATA_TAGS.index_of (tag),1])
                    .append(" : ")
                    .append( _metadata_values.get (tag))
                    .append("\n");
                }
            }
            pretty_print = sb.truncate (sb.len-1).str;
        }     // foreach

        return true;
    }         // process_media_info_update
}     // Metadata
