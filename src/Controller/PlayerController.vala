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


public class Tuner.PlayerController {

    private Gst.Player _player;

    public PlayerController() {
    	_player = new Gst.Player(null, null);

    	print("Player Controller created.");
    }

    public void playURI(string uri) {
    	_player.uri = uri;
    	_player.play();

    	print("Player URI set and playing started");
    }

    public void stop() {
    	_player.stop();

    	print("Player stopped.");
    }

}

/*
	    // Build the pipeline:
	    Gst.Element pipeline;
	    try {
		    pipeline = Gst.parse_launch ("playbin uri=http://barbaradio.hoerradar.de/barbaradio-live-mp3-hq");
	    } catch (Error e) {
		    print ("Error: %s\n", e.message);
		    return;
	    }

	    // Start playing:
	    pipeline.set_state (Gst.State.PLAYING);

	    // Wait until error or EOS:
	    Gst.Bus bus = pipeline.get_bus ();
	    bus.message.connect ( (msg) => {
	        print("Received message");
	    });

	    // bus.timed_pop_filtered (Gst.CLOCK_TIME_NONE, Gst.MessageType.ERROR | Gst.MessageType.EOS);

	    // Free resources:
	    // pipeline.set_state (Gst.State.NULL);

*/
