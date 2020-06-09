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
* Authored by: Louis Brauer <louis@brauer.family>
*/

using Gee;

class Tuner.Model.LocalDirectory : IDirectoryProvider {

    public ArrayList<StationModel> all() {

        var stations = new ArrayList<StationModel>();

        stations.add(new StationModel ("Barba Radio 1", "Germany", "http://barbaradio.hoerradar.de/barbaradio-live-mp3-hq"));
        stations.add(new StationModel ("Radio 1", "Zurich", "http://radio.nello.tv/128k"));
        stations.add(new StationModel ("SRF 1 General", "Zurich", "http://stream.srg-ssr.ch/m/drs1/mp3_128"));

        return stations;

    }

}
