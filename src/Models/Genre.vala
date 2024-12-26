/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

using Gee;

namespace Tuner.Model.Genre {

    private static Set<string> PREDEFINED;

    public static bool in_genre(string genre)
    {
        if ( PREDEFINED == null)
        {
            PREDEFINED = new HashSet<string>();
            foreach( var a in GENRES) {PREDEFINED.add(a); }
            foreach( var a in SUBGENRES) {PREDEFINED.add(a); }
            foreach( var a in ERAS) {PREDEFINED.add(a); }
            foreach( var a in TALK) {PREDEFINED.add(a); }
        }
        return PREDEFINED.contains(genre);
    }

    public  const string[] GENRES = {
        "Blues",
        "Classical",
        "Country",
        "Dance",
        "Disco",
        "Easy",
        "Folk",
        "Hits",
        "Jazz",
        "Oldies",
        "Pop",
        "Rap",
        "Rock",
        "Soul"
        };   

    public  const string[] SUBGENRES = {
        "Alternative",
        "Ambient", 
        "Club", 
        "Electronic", 
        "Funk",
        "HipHop",
        "House",
        "Indie",
        "Metal",
        "Latino",
        "Punk",
        "Reggae",
        "Salsa",
        "World Music"
    };     
        
    public  const string[] ERAS = {
        "40s",
        "50s",
        "60s",
        "70s",
        "80s",
        "90s",
        "2000s",
        "2010s",
        "Contemporary"
    };         
        
    public  const string[] TALK = 
    {   "AM"
        ,"Comedy"
        ,"College Radio"
        ,"Community Radio"
        ,"Culture"
        ,"Educational"
        ,"Kids"
        ,"Public Radio"
        ,"News"
        ,"Religion"
        ,"Sport"
        ,"Talk"
    };               
}




