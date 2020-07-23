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

public class Tuner.AboutDialog : Gtk.AboutDialog {
    public AboutDialog (Gtk.Window window) {
        Object ();
        set_destroy_with_parent (true);
        set_transient_for (window);
        set_modal (true);
    
        artists = {"https://faleksandar.com/"};
        authors = {"Louis Brauer"};
        documenters = null;
        translator_credits = "French translation by NathanBnm https://github.com/NathanBnm"; 
        logo_icon_name = Application._instance.get_application_id ();
        program_name = "Tuner for elementary OS";
        comments = "Listen to internet radio stations";
        copyright = "Copyright © 2020 Louis Brauer";
        version = @"v$(Application.APP_VERSION)";
    
        license = """Copyright (c) 2020 Louis Brauer (https://github.com/louis77)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public
License along with this program; if not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA

Authored by: Louis Brauer <louis77@member.fsf.org>""";
        wrap_license = true;
    
        website = "https://github.com/louis77/tuner";
        website_label = "Visit us on github.com";
    
        response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
                hide_on_delete ();
            }
        });
    }
}