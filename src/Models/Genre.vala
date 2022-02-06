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
