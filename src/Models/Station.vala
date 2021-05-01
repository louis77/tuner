/*
* Copyright (c) 2020-2021 Louis Brauer <louis77@member.fsf.org>
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

public class Tuner.Model.Station : Object {
    public string id { get; set; }
    public string title { get; set; }
    public string location { get; set; }
    public string url { get; set; }
    public bool starred { get; set; }
    public string homepage { get; set; }
    public string codec { get; set; }
    public int bitrate { get; set; }

    public string? favicon_url { get; set; }
    public uint clickcount = 0;

    public Station (string id, string title, string location, string url) {
        Object ();

        this.id = id;
        this.title = title;
        this.location = location;
        this.url = url;
        this.starred = starred;
    }

    public void toggle_starred () {
        this.starred = !this.starred;
    }

    public string to_string() {
        return @"[$(this.id)] $(this.title)";
    }

}
