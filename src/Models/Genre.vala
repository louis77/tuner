/*
* Copyright (c) 2020-2021 Louis Brauer <louis@brauer.family>
*
* This file is part of Tuner.
*
* Tuner is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Tuner is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Tuner.  If not, see <http://www.gnu.org/licenses/>.
*
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
            new Genre (_("70s"), {"70s"}),
            new Genre (_("80s"), {"80s"}),
            new Genre (_("90s"), {"90s"}),
            new Genre (_("Classical"), {"classical"}),
            new Genre (_("Country"), {"country"}),
            new Genre (_("Dance"), {"dance"}),
            new Genre (_("Electronic"), {"electronic"}),
            new Genre (_("House"), {"house"}),
            new Genre (_("Jazz"), {"jazz"}),
            new Genre (_("Pop"), {"pop"}),
            new Genre (_("Rock"), {"rock"})
        };
    }
}
