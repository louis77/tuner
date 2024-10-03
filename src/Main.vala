/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */
 
public static int main (string[] args) {
    Gst.init (ref args);

    var app = Tuner.Application.instance;
    return app.run (args);
}
