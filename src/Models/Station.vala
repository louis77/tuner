/*
* Copyright (c) 2020 Louis Brauer (https://github.com/louis77)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Louis Brauer <louis77@member.fsf.org>
*/

public class Tuner.Model.Station : Object {
    public string id { get; set; }
    public string title { get; set; }
    public string location { get; set; }
    public string url { get; set; }
    public bool starred { get; set; }

    public string? favicon_url { get; set; }
    public uint clickcount = 0;

    public Station (string id, string title, string location, string url) {
        this.id = id;
        this.title = title;
        this.location = location;
        this.url = url;
    }

}
