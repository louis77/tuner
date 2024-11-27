/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

namespace Tuner.Model {
    public class Genre {
        public string name;
        public string[] tags;

        public Genre (string name, string[] tags) {
            this.name = name;
            this.tags = tags;
        }
    }

    public Genre[] genres() {
        return {
            new Genre (_("Alternative"), {"alternative"}),
            new Genre (_("Blues"), {"blues"}),
            new Genre (_("Classical"), {"classical"}),
            new Genre (_("Country"), {"country"}),
            new Genre (_("Dance"), {"dance"}),
            new Genre (_("Easy Listening"), {"easy"}),
            new Genre (_("Electronic"), {"electronic"}),
            new Genre (_("Folk"), {"folk"}),
            new Genre (_("Hits"), {"hits"}),
            new Genre (_("House"), {"house"}),
            new Genre (_("Jazz"), {"jazz"}),
            new Genre (_("Metal"), {"metal"}),
            new Genre (_("Latino"), {"latino"}),
            new Genre (_("Oldies"), {"oldies"}),
            new Genre (_("Pop"), {"pop"}),
            new Genre (_("Punk"), {"punk"}),
            new Genre (_("Rap"), {"rap"}),
            new Genre (_("Reggae"), {"reggae"}),
            new Genre (_("Rock"), {"rock"}),
            new Genre (_("Salsa"), {"salsa"}),
            new Genre (_("Soul"), {"soul"}),
        };
    }

    public Genre[] eras() {
        return {
            new Genre (_("40s"), {"1940s"}),
            new Genre (_("50s"), {"50s"}),
            new Genre (_("60s"), {"60s"}),
            new Genre (_("70s"), {"70s"}),
            new Genre (_("80s"), {"80s"}),
            new Genre (_("90s"), {"90s"}),
            new Genre (_("00s"), {"2000s"}),
            new Genre (_("10s"), {"2010s"}),
            new Genre (_("Charts"), {"top40"}),

            //  new Genre (_("40s"), {"40s","1940s","40er"}),
            //  new Genre (_("50s"), {"50s","1950s","50er"}),
            //  new Genre (_("60s"), {"60s","1960s","60er"}),
            //  new Genre (_("70s"), {"70s","1970s","70er"}),
            //  new Genre (_("80s"), {"80s","1980s","80er"}),
            //  new Genre (_("90s"), {"90s","1990s","90er"}),
            //  new Genre (_("00s"), {"2000s","00s","00er"}),
            //  new Genre (_("10s"), {"2010s","10s","10er"}),
            //  new Genre (_("Charts"), {"top40","top100"}),
        };
    }

    public Genre[] talk() {
        return {
            new Genre (_("A.M."), {"am"}),
            new Genre (_("Public Radio"), {"public radio"}),
            new Genre (_("News"), {"news"}),
            new Genre (_("Religion"), {"religion"}),
            new Genre (_("Sport"), {"sport"}),
            new Genre (_("Talk"), {"talk"}),                    
        };
    }
}

