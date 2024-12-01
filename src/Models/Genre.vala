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
        "Easy",
        "Folk",
        "Hits",
        "Jazz",
        "Pop",
        "Rock",
        "Soul"
        };   

    public  const string[] SUBGENRES = {
        "Alternative",
        "Electronic", 
        "House",
        "Metal",
        "Latino",
        "Oldies",
        "Punk",
        "Rap",
        "Reggae",
        "Salsa"
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
        ,"Public Radio"
        , "News"
        , "Religion"
        , "Sport"
        ,"Talk"
    };               
}




